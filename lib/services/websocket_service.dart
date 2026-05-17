import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  
  static Function(Map<String, dynamic>)? onMessageReceived;
  static Function(int, String)? onUserOnline;
  static Function(int)? onUserOffline;
  static Function(int, bool)? onTyping;
  static Function(Map<String, dynamic>)? onRideStatusUpdate;  // NEW
  
static Future<void> connect(int userId, String username) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔌 WebSocket CONNECTING');
      addDebugMessage('User ID: $userId');
      addDebugMessage('Username: $username');

      final baseUrl = StorageService.getServerUrl();
      addDebugMessage('Base URL: $baseUrl');
      
      final wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      final fullUrl = '$wsUrl/ws-chat';
      addDebugMessage('WebSocket URL: $fullUrl');
      
      try {
        _channel = WebSocketChannel.connect(
          Uri.parse(fullUrl),
        );
        
        _isConnected = true;
        addDebugMessage('✅ WebSocket Connected!');
        
        // Send login message
        _sendLoginMessage(userId, username);
        
        // Listen for messages
        _channel?.stream.listen(
          (message) {
            addDebugMessage('📨 Message received: $message');
            try {
              final decoded = jsonDecode(message);
              addDebugMessage('✅ Decoded: ${decoded['type']}');
              _handleMessage(decoded);
            } catch (e) {
              addDebugMessage('❌ Decode error: $e');
            }
          },
          onError: (error) {
            addDebugMessage('❌ WebSocket Error: $error');
            _isConnected = false;
            // Auto-reconnect after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (!_isConnected) {
                addDebugMessage('🔄 Auto-reconnecting...');
                connect(userId, username);
              }
            });
          },
          onDone: () {
            addDebugMessage('🔌 WebSocket closed');
            _isConnected = false;
          },
        );
      } catch (e) {
        addDebugMessage('❌ WebSocket connection error: $e');
        _isConnected = false;
      }
      
      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Error in connect(): $e');
      _isConnected = false;
    }
  }

  static void _sendLoginMessage(int userId, String username) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'login',
      'senderId': userId,
      'senderName': username,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void sendMessage(int senderId, int receiverId, String content, String senderName) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'message',
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'senderName': senderName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void sendTyping(int senderId, int receiverId, bool isTyping) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'typing',
      'senderId': senderId,
      'receiverId': receiverId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void sendRideStatusUpdate(int rideId, String status, int driverId) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'ride_status_update',
      'rideId': rideId,
      'status': status,
      'driverId': driverId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void setOnline(int userId, String username) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'online',
      'senderId': userId,
      'senderName': username,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void setOffline(int userId) {
    if (!_isConnected) return;
    
    final message = {
      'type': 'offline',
      'senderId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  static void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'];
    
    switch (type) {
      case 'message':
        onMessageReceived?.call(message);
        break;
      case 'user_online':
        onUserOnline?.call(message['senderId'], message['senderName'] ?? '');
        break;
      case 'user_offline':
        onUserOffline?.call(message['senderId']);
        break;
      case 'typing':
        onTyping?.call(message['senderId'], message['isTyping'] ?? false);
        break;
      case 'ride_status_update':
        onRideStatusUpdate?.call(message);
        break;
    }
  }
  
  static bool isConnected() => _isConnected;
  
  static void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
  }
}