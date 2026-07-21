import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../services/recorded_screen_mixin.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUsername;
  final int receiverId;
  final String receiverName;
  final String token;
  final int? rideId;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUsername,
    required this.receiverId,
    required this.receiverName,
    required this.token,
    this.rideId,
  });

  static void clearCache(int userId1, int userId2) {
    _ChatScreenState.clearCacheForRide(userId1, userId2);
  }

  static void clearAllCache() {
    _ChatScreenState._messageCache.clear();
  }

  /// The receiver ID of the currently open chat, or null if no chat is open.
  static int? activeChatPartnerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin, RecordedScreenMixin<ChatScreen> {
  final _messageController = TextEditingController();
  List<Message> messages = [];
  bool isLoading = true;
  late Timer _refreshTimer;
  late Timer _typingTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isReceiverTyping = false;
  late AnimationController _typingDotsController;

  static final Map<String, List<Message>> _messageCache = {};

  static const List<Map<String, String>> _quickReplies = [
    {'text': 'On my way', 'emoji': '\u{1F697}'},
    {'text': 'Be there soon', 'emoji': '\u{23F3}'},
    {'text': 'Thanks!', 'emoji': '\u{1F64F}'},
    {'text': 'OK', 'emoji': '\u{1F44C}'},
  ];

  String get _cacheKey {
    final a = widget.currentUserId;
    final b = widget.receiverId;
    return '${a < b ? a : b}-${a < b ? b : a}';
  }

  static void clearCacheForRide(int userId1, int userId2) {
    final a = userId1;
    final b = userId2;
    final key = '${a < b ? a : b}-${a < b ? b : a}';
    _messageCache.remove(key);
  }

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'SCREEN_OPENED');

    _typingDotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    final cached = _messageCache[_cacheKey];
    if (cached != null) {
      messages = List.from(cached);
      isLoading = false;
    }

    _loadChatHistory();

    _loadPendingMessages();

    WebSocketService.unreadCounts[widget.receiverId] = 0;
    WebSocketService.sendMessageRead(widget.currentUserId, widget.receiverId);

    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadChatHistory();
    });

    _typingTimer = Timer(Duration.zero, () {});
    _typingTimer.cancel();

    WebSocketService.onMessageReceived = _handleIncomingMessage;
    WebSocketService.onTyping = _handleTypingIndicator;

    ChatScreen.activeChatPartnerId = widget.receiverId;
  }

  @override
  void dispose() {
    _messageCache[_cacheKey] = List.from(messages);
    _messageController.dispose();
    _refreshTimer.cancel();
    if (_typingTimer.isActive) _typingTimer.cancel();
    _scrollController.dispose();
    _typingDotsController.dispose();
    ChatScreen.activeChatPartnerId = null;
    super.dispose();
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final type = message['type'] as String? ?? 'message';

    if (type == 'message_delivered') {
      setState(() {
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].senderId == widget.currentUserId &&
              messages[i].status == 'sent') {
            messages[i] = messages[i].copyWith(status: 'delivered', isDelivered: true);
          }
        }
      });
      return;
    }

    if (type == 'message_read') {
      setState(() {
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].senderId == widget.currentUserId) {
            messages[i] = messages[i].copyWith(status: 'seen', isRead: true);
          }
        }
      });
      return;
    }

    final senderId = message['senderId'];
    final receiverId = message['receiverId'];

    if ((senderId == widget.receiverId && receiverId == widget.currentUserId) ||
        (senderId == widget.currentUserId && receiverId == widget.receiverId)) {
      if (senderId == widget.receiverId) {
        WebSocketService.sendMessageDelivered(0, senderId, receiverId);
      }

      final newMessage = Message(
        senderId: senderId,
        receiverId: receiverId,
        content: message['content'] ?? '',
        status: message['status'] ?? 'sent',
        isRead: false,
        isDelivered: senderId == widget.currentUserId,
      );

      if (mounted) {
        setState(() {
          messages.add(newMessage);
          _messageCache[_cacheKey] = List.from(messages);
        });
        _scrollToBottom();
      }
    }
  }

  void _loadPendingMessages() {
    final pending = WebSocketService.getPendingMessages(
      widget.currentUserId,
      widget.receiverId,
    );
    if (pending.isEmpty) return;

    final newMessages = pending.map((msg) {
      final senderId = msg['senderId'] as int? ?? 0;
      final receiverId = msg['receiverId'] as int? ?? 0;
      return Message(
        senderId: senderId,
        receiverId: receiverId,
        content: msg['content'] as String? ?? '',
        status: msg['status'] as String? ?? 'sent',
        isRead: false,
        isDelivered: senderId == widget.currentUserId,
      );
    }).where((m) {
      return !messages.any((existing) =>
        existing.content == m.content &&
        existing.senderId == m.senderId);
    }).toList();

    if (newMessages.isNotEmpty && mounted) {
      setState(() {
        messages.addAll(newMessages);
        _messageCache[_cacheKey] = List.from(messages);
      });
      _scrollToBottom();
    }
  }

  void _handleTypingIndicator(int senderId, bool isTyping) {
    if (!mounted) return;
    if (senderId == widget.receiverId) {
      setState(() => _isReceiverTyping = isTyping);
    }
  }

  Future<void> _loadChatHistory() async {
    if (!mounted) return;

    try {
      final baseUrl = StorageService.getChatHistoryUrl();
      final url =
          '$baseUrl?userId1=${widget.currentUserId}&userId2=${widget.receiverId}';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;

        if (mounted) {
          setState(() {
            if (jsonList.isNotEmpty) {
              messages = jsonList
                  .map((m) {
                    try {
                      return Message.fromJson(m);
                    } catch (e) {
                      return null;
                    }
                  })
                  .whereType<Message>()
                  .toList();
              _messageCache[_cacheKey] = List.from(messages);
            }
            isLoading = false;
          });

          _scrollToBottom();
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final content = _messageController.text;
    _messageController.clear();
    HapticFeedback.lightImpact();
    recordEvent(eventName: 'MESSAGE_SENT');

    if (mounted) {
      setState(() {
        messages.add(Message(
          senderId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: content,
          status: 'sent',
          isDelivered: true,
        ));
        _messageCache[_cacheKey] = List.from(messages);
      });
    }

    _scrollToBottom();

    try {
      final url = StorageService.getChatSendUrl();

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({
              'receiverId': widget.receiverId,
              'content': content,
              if (widget.rideId != null) 'rideId': widget.rideId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      WebSocketService.sendMessage(
        widget.currentUserId,
        widget.receiverId,
        content,
        widget.currentUsername,
      );

      if (response.statusCode == 200) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _loadChatHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send message'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.smRadius,
            ),
          ),
        );
      }
    }
  }

  void _sendTypingIndicator() {
    if (_typingTimer.isActive) _typingTimer.cancel();

    WebSocketService.sendTyping(
      widget.currentUserId,
      widget.receiverId,
      true,
    );

    _typingTimer = Timer(const Duration(seconds: 2), () {
      WebSocketService.sendTyping(
        widget.currentUserId,
        widget.receiverId,
        false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        surfaceTintColor: AppColors.surface,
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    widget.receiverName.isNotEmpty
                        ? widget.receiverName[0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.hGapMd,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_isReceiverTyping)
                  Row(
                    children: [
                      _buildTypingDots(size: 5),
                      AppSpacing.hGapXs,
                      Text(
                        'typing',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                : messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          if (_isReceiverTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            AppSpacing.gapLg,
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            AppSpacing.gapXs,
            Text(
              'Send a message to start chatting',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDate = DateTime(date.year, date.month, date.day);

    final diff = today.difference(msgDate).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(date);
  }

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _dateLabel(date),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    final messageItems = <dynamic>[];
    String? lastDateKey;
    for (final message in messages) {
      final dateKey = DateFormat('yyyy-MM-dd').format(message.sentAt);
      if (dateKey != lastDateKey) {
        messageItems.add(message.sentAt);
        lastDateKey = dateKey;
      }
      messageItems.add(message);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messageItems.length,
      itemBuilder: (context, index) {
        final item = messageItems[index];
        if (item is DateTime) {
          return _buildDateSeparator(item);
        }
        return _buildMessageBubble(item as Message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isSent = message.senderId == widget.currentUserId;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: 6,
        start: isSent ? 60 : 0,
        end: isSent ? 0 : 60,
      ),
      child: Align(
        alignment: isSent ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Column(
          crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSent ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isSent
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isSent
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: AppShadows.small,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: (isSent
                            ? Theme.of(context).textTheme.bodyMedium
                            : Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(
                      color: isSent
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.sentAt),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isSent
                                  ? AppColors.primaryLight.withValues(alpha: 0.7)
                                  : AppColors.textTertiary,
                            ),
                      ),
                      if (isSent) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'seen'
                              ? Icons.done_all
                              : message.status == 'delivered'
                                  ? Icons.done_all
                                  : Icons.done,
                          size: 14,
                          color: message.status == 'seen'
                              ? Colors.blue
                              : message.status == 'delivered'
                                  ? AppColors.secondaryLight
                                  : AppColors.primaryLight.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDots({double size = 6}) {
    return SizedBox(
      width: (size + 4) * 3,
      height: size + 4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _typingDotsController,
            builder: (context, child) {
              final phase = (index * 0.33) * 2 * math.pi;
              final t = (_typingDotsController.value * 2 * math.pi) + phase;
              final scale = 0.3 + (math.sin(t).abs() * 0.7);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      color: AppColors.textTertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.xlRadius,
              boxShadow: AppShadows.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDots(),
                AppSpacing.hGapSm,
                Text(
                  '${widget.receiverName} is typing...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _quickReplies.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final reply = _quickReplies[index];
          return ActionChip(
            avatar: Text(reply['emoji']!, style: const TextStyle(fontSize: 14)),
            label: Text(
              reply['text']!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.4),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () {
              _messageController.text = reply['text']!;
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: _messageController.text.length),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickReplies(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (_) => _sendTypingIndicator(),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        maxLines: 5,
                        minLines: 1,
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  Semantics(
                    button: true,
                    label: 'Send message',
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.small,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: AppColors.primaryLight,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
