import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import 'package:intl/intl.dart';
import 'debug_screen.dart';

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
  late Timer _typingTimer; // ✅ Now properly declared
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
    
    // ✅ Setup refresh timer
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadChatHistory();
      }
    });

    // ✅ Initialize _typingTimer as dummy (will be replaced)
    _typingTimer = Timer(Duration.zero, () {});
    _typingTimer.cancel(); // Start as cancelled

    // ✅ Setup WebSocket listeners
    WebSocketService.onMessageReceived = _handleIncomingMessage;
    WebSocketService.onTyping = _handleTypingIndicator;
    
    addDebugMessage('✅ Chat screen initialized');
  }

  @override
  void dispose() {
    addDebugMessage('🚮 Disposing chat screen');
    _messageController.dispose();
    _refreshTimer.cancel(); // ✅ Always cancel
    if (_typingTimer.isActive) {
      _typingTimer.cancel(); // ✅ Safe cancel
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
        
        // Send via WebSocket
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
    // ✅ Cancel previous timer safely
    if (_typingTimer.isActive) {
      _typingTimer.cancel();
    }
    
    WebSocketService.sendTyping(
      widget.currentUserId,
      widget.receiverId,
      true,
    );
    
    // ✅ Create new timer for 2 seconds
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.receiverName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isSent =
                              message.senderId == widget.currentUserId;
                          
                          return Align(
                            alignment: isSent
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSent
                                    ? const Color(0xFF6366F1)
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    message.content,
                                    style: TextStyle(
                                      color: isSent
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        DateFormat('HH:mm')
                                            .format(message.sentAt),
                                        style: TextStyle(
                                          color: isSent
                                              ? Colors.white70
                                              : Colors.black54,
                                          fontSize: 11,
                                        ),
                                      ),
                                      if (isSent) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          message.status == 'seen'
                                              ? Icons.done_all
                                              : Icons.done,
                                          size: 14,
                                          color: isSent
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ],
                                    ],
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
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.receiverName} is typing...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (_) => _sendTypingIndicator(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  mini: true,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}