import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
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

class _ChatScreenState extends State<ChatScreen> with RecordedScreenMixin<ChatScreen> {
  final _messageController = TextEditingController();
  List<Message> messages = [];
  bool isLoading = true;
  late Timer _refreshTimer;
  late Timer _typingTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isReceiverTyping = false;

  static final Map<String, List<Message>> _messageCache = {};

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
              borderRadius: BorderRadius.circular(10),
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
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryLight),
          onPressed: () => Navigator.pop(context),
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
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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
                        BorderSide(color: AppColors.primaryLight, width: 2),
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
                  style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isReceiverTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      color: AppColors.primaryLight.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          AppSpacing.gapXl,
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.gapSm,
          const Text(
            'Send a message to start chatting',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isSent = message.senderId == widget.currentUserId;

        return Padding(
          padding: EdgeInsets.only(
            bottom: 6,
            left: isSent ? 60 : 0,
            right: isSent ? 0 : 60,
          ),
          child: Align(
            alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment:
                  isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSent ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isSent
                          ? const Radius.circular(18)
                          : const Radius.circular(4),
                      bottomRight: isSent
                          ? const Radius.circular(4)
                          : const Radius.circular(18),
                    ),
                    boxShadow: AppSpacing.shadowSm,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isSent
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.sentAt),
                            style: TextStyle(
                              color: isSent ? AppColors.primaryLight.withValues(alpha: 0.6) : AppColors.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                          if (isSent) ...[
                            AppSpacing.hGapXs,
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
                                      : AppColors.primaryLight.withValues(alpha: 0.6),
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
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textTertiary,
                  ),
                ),
                AppSpacing.hGapSm,
                Text(
                  '${widget.receiverName} is typing...',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(24),
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
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 5,
                  minLines: 1,
                ),
              ),
            ),
            AppSpacing.hGapSm,
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
