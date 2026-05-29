import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'package:intl/intl.dart';
import 'debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String currentUsername;
  final int receiverId;
  final String receiverName;
  final String token;

  const ChatScreen({
    Key? key,
    required this.currentUserId,
    required this.currentUsername,
    required this.receiverId,
    required this.receiverName,
    required this.token,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<Message> messages = [];
  bool isLoading = true;
  late Timer _refreshTimer;
  late Timer _typingTimer;
  final ScrollController _scrollController = ScrollController();
  bool _isReceiverTyping = false;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('💬 CHAT SCREEN INIT');
    addDebugMessage('With: ${widget.receiverName}');
    addDebugMessage('═══════════════════════════════════════');

    _loadChatHistory();

    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadChatHistory();
      }
    });

    _typingTimer = Timer(Duration.zero, () {});
    _typingTimer.cancel();

    WebSocketService.onMessageReceived = _handleIncomingMessage;
    WebSocketService.onTyping = _handleTypingIndicator;

    addDebugMessage('✅ Chat screen initialized');
  }

  @override
  void dispose() {
    addDebugMessage('🚮 Disposing chat screen');
    _messageController.dispose();
    _refreshTimer.cancel();
    if (_typingTimer.isActive) {
      _typingTimer.cancel();
    }
    _scrollController.dispose();
    super.dispose();
    addDebugMessage('✅ Chat screen disposed');
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final senderId = message['senderId'];
    final receiverId = message['receiverId'];

    if ((senderId == widget.receiverId && receiverId == widget.currentUserId) ||
        (senderId == widget.currentUserId && receiverId == widget.receiverId)) {

      final newMessage = Message(
        senderId: senderId,
        receiverId: receiverId,
        content: message['content'] ?? '',
        status: message['status'] ?? 'sent',
        isRead: false,
      );

      if (mounted) {
        setState(() {
          messages.add(newMessage);
        });
        _scrollToBottom();
        addDebugMessage('📨 Message received: ${message['content']}');
      }
    }
  }

  void _handleTypingIndicator(int senderId, bool isTyping) {
    if (!mounted) return;

    if (senderId == widget.receiverId) {
      if (mounted) {
        setState(() => _isReceiverTyping = isTyping);
      }
      addDebugMessage('✏️ Typing: $isTyping');
    }
  }

  Future<void> _loadChatHistory() async {
    if (!mounted) return;

    try {
      final baseUrl = StorageService.getChatHistoryUrl();
      final url =
          '$baseUrl?userId1=${widget.currentUserId}&userId2=${widget.receiverId}';

      addDebugMessage('📋 Loading chat history...');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonList = jsonDecode(response.body) as List;

        if (mounted) {
          setState(() {
            messages = jsonList
                .map((m) {
                  try {
                    return Message.fromJson(m);
                  } catch (e) {
                    addDebugMessage('❌ Error parsing message: $e');
                    return null;
                  }
                })
                .whereType<Message>()
                .toList();
            isLoading = false;
          });

          _scrollToBottom();
          addDebugMessage('✅ Loaded ${messages.length} messages');
        }
      } else {
        addDebugMessage('❌ Error: ${response.statusCode}');
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
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

    if (mounted) {
      setState(() {
        messages.add(Message(
          senderId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: content,
          status: 'sent',
        ));
      });
    }

    _scrollToBottom();

    try {
      addDebugMessage('📤 Sending message: $content');

      final url = StorageService.getChatSendUrl();

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
              'ngrok-skip-browser-warning': 'true',
            },
            body: jsonEncode({
              'receiverId': widget.receiverId,
              'content': content,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        addDebugMessage('✅ Message sent successfully');

        WebSocketService.sendMessage(
          widget.currentUserId,
          widget.receiverId,
          content,
          widget.currentUsername,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _loadChatHistory();
        }
      } else {
        addDebugMessage('❌ Send failed: ${response.statusCode}');
      }
    } catch (e) {
      addDebugMessage('❌ Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendTypingIndicator() {
    if (_typingTimer.isActive) {
      _typingTimer.cancel();
    }

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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                      color: Colors.white,
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isReceiverTyping)
                  Text(
                    'typing...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.white),
            tooltip: 'Debug Console',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DebugScreen(),
                ),
              );
            },
          ),
        ],
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
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: AppColors.primary.withValues(alpha: 0.6),
                              ),
                            ),
                            AppSpacing.gapXl,
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.gapSm,
                            Text(
                              'Send a message to start chatting',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSent =
                              message.senderId == widget.currentUserId;

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: 6,
                              left: isSent ? 60 : 0,
                              right: isSent ? 0 : 60,
                            ),
                            child: Align(
                              alignment: isSent
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: isSent
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSent
                                          ? AppColors.primary
                                          : AppColors.surfaceVariant,
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
                                      maxWidth: MediaQuery.of(context)
                                              .size
                                              .width *
                                          0.72,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              DateFormat('HH:mm')
                                                  .format(message.sentAt),
                                              style: TextStyle(
                                                color: isSent
                                                    ? Colors.white60
                                                    : AppColors.textTertiary,
                                                fontSize: 11,
                                              ),
                                            ),
                                            if (isSent) ...[
                                              AppSpacing.hGapXs,
                                              Icon(
                                                message.status == 'seen'
                                                    ? Icons.done_all
                                                    : Icons.done,
                                                size: 14,
                                                color: message.status == 'seen'
                                                    ? AppColors.secondaryLight
                                                    : Colors.white60,
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
                      ),
          ),
          if (_isReceiverTyping)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
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
                          style: TextStyle(
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
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                        border: Border.all(
                          color: AppColors.outline,
                          width: 1,
                        ),
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
                        color: Colors.white,
                        size: 20,
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
