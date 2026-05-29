import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static bool _isManualDisconnect = false;
  
  static Function(Map<String, dynamic>)? onMessageReceived;
  static Function(int, String)? onUserOnline;
  static Function(int)? onUserOffline;
  static Function(int, bool)? onTyping;
  static Function(Map<String, dynamic>)? onRideStatusUpdate;
  
  // ✅ STEP 5: Stream controllers for ride events and location
  static final _rideEventController = StreamController<Map<String, dynamic>>.broadcast();
  static final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  static final _connectionStateController = StreamController<String>.broadcast();
  static final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // ✅ Expose as streams
  static Stream<Map<String, dynamic>> get rideEvents => _rideEventController.stream;
  static Stream<Map<String, dynamic>> get driverLocationEvents => _driverLocationController.stream;
  static Stream<String> get connectionState => _connectionStateController.stream;
  static Stream<Map<String, dynamic>> get chatMessages => _chatMessageController.stream;

  static Future<void> connect(int userId, String username) async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔌 WebSocket CONNECTING');
      addDebugMessage('User ID: $userId');
      addDebugMessage('Username: $username');

      // ✅ STEP 5 FIX: Close previous connection if exists
      if (_channel != null) {
        try {
          addDebugMessage('⚠️ Closing previous connection...');
          _channel?.sink.close();
          _channel = null;
        } catch (e) {
          addDebugMessage('⚠️ Previous channel close error: $e');
        }
      }

      final baseUrl = StorageService.getServerUrl();
      addDebugMessage('Base URL: $baseUrl');
      
      final wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      final fullUrl = '$wsUrl/ws-chat';
      addDebugMessage('WebSocket URL: $fullUrl');
      
      try {
        // ✅ STEP 5 FIX: Create new connection
        _channel = WebSocketChannel.connect(
          Uri.parse(fullUrl),
        );
        
        _isConnected = true;
        _connectionStateController.add('connected');
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
            _connectionStateController.add('error');
            
            // ✅ STEP 5 FIX: Auto-reconnect after 5 seconds
            Future.delayed(const Duration(seconds: 5), () {
              if (!_isConnected && !_isManualDisconnect) {
                addDebugMessage('🔄 Auto-reconnecting...');
                connect(userId, username);
              }
            });
          },
          onDone: () {
            addDebugMessage('🔌 WebSocket closed');
            _isConnected = false;
            
            // ✅ ONLY EMIT if this is NOT a manual disconnect
            if (!_isManualDisconnect) {
              _connectionStateController.add('disconnected');
            }
          },
        );
      } catch (e) {
        addDebugMessage('❌ WebSocket connection error: $e');
        _isConnected = false;
        _connectionStateController.add('error');
      }
      
      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Error in connect(): $e');
      _isConnected = false;
      _connectionStateController.add('error');
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
  
  // ✅ STEP 5: Send ride-related messages
  static void sendRideMessage(String type, Map<String, dynamic> payload) {
    if (!_isConnected) {
      addDebugMessage('⚠️ Not connected, cannot send ride message');
      return;
    }
    
    final message = {
      'type': type,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel?.sink.add(jsonEncode(message));
    addDebugMessage('📤 Sent: $type');
  }
  
  static void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'];
    
    addDebugMessage('📨 Handling message type: $type');
    
    switch (type) {
      case 'message':
        onMessageReceived?.call(message);
        _chatMessageController.add(message);
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
      
      // ✅ STEP 5: RIDE EVENTS
      case 'ride_available':
      case 'ride_accepted':
      case 'ride_confirmed':
      case 'driver_arrived':
      case 'ride_started':
      case 'ride_completed':
      case 'search_timeout':
      case 'ride_cancelled':
        addDebugMessage('🚗 Ride event: $type');
        _rideEventController.add(message);
        onRideStatusUpdate?.call(message);
        break;
        
      // ✅ DRIVER LOCATION UPDATE - emit to both streams
      case 'driver_location':
        addDebugMessage('📍 Driver location update');
        _rideEventController.add(message);
        _driverLocationController.add(message);
        break;
        
      case 'pong':
        addDebugMessage('💓 Heartbeat response');
        break;
    }
  }
  
  static bool isConnected() => _isConnected;
  
  // ✅ STEP 5: Cleanup streams
  static void dispose() {
    _rideEventController.close();
    _driverLocationController.close();
    _connectionStateController.close();
    _chatMessageController.close();
  }

  static void disconnect() {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔌 Disconnecting WebSocket...');
      
      // ✅ SET FLAG to prevent onDone from emitting again
      _isManualDisconnect = true;
      
      // Send offline message before closing
      if (_isConnected) {
        final offlineMessage = {
          'type': 'offline',
          'senderId': 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        try {
          _channel?.sink.add(jsonEncode(offlineMessage));
          addDebugMessage('📤 Sent offline notification');
        } catch (e) {
          addDebugMessage('⚠️ Error sending offline: $e');
        }
      }
      
      // Small delay to ensure message is sent
      Future.delayed(const Duration(milliseconds: 200), () {
        try {
          _channel?.sink.close();
          addDebugMessage('✅ Channel closed');
        } catch (e) {
          addDebugMessage('⚠️ Error closing channel: $e');
        }
        
        _isConnected = false;
        _channel = null;
        
        // ✅ EMIT ONCE AND ONLY ONCE
        _connectionStateController.add('disconnected');
        addDebugMessage('🔌 WebSocket Disconnected');
        addDebugMessage('═══════════════════════════════════════');
        
        // Reset flag after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _isManualDisconnect = false;
        });
      });
      
    } catch (e) {
      addDebugMessage('❌ Error in disconnect(): $e');
      _isConnected = false;
      _connectionStateController.add('disconnected');
      _isManualDisconnect = false;
    }
  }
}