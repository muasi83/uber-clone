import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'storage_service.dart';
import '../screens/debug_screen.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static bool _isManualDisconnect = false;
  static bool _isReconnecting = false;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static int _lastUserId = 0;
  static String _lastUsername = '';
  static Timer? _reconnectTimer;
  
  static Function(Map<String, dynamic>)? onMessageReceived;
  static Function(int, String)? onUserOnline;
  static Function(int)? onUserOffline;
  static Function(int, bool)? onTyping;
  static Function(Map<String, dynamic>)? onRideStatusUpdate;
  
  static Timer? _heartbeatTimer;
  static Function()? onForceLogout;
  
  static StreamSubscription<dynamic>? _channelSubscription;

  // ✅ STEP 5: Stream controllers for ride events and location
  static final _rideEventController = StreamController<Map<String, dynamic>>.broadcast();
  static final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  static final _connectionStateController = StreamController<String>.broadcast();
  static final _chatMessageController = StreamController<Map<String, dynamic>>.broadcast();

  // Unread message counts: receiverId -> count
  static final Map<int, int> unreadCounts = {};

  // Buffer for incoming chat messages received while chat screen is closed
  static final Map<String, List<Map<String, dynamic>>> _pendingMessages = {};

  static String _chatKey(int a, int b) => '${a < b ? a : b}-${a < b ? b : a}';

  /// Retrieve and remove pending messages for a given conversation.
  static List<Map<String, dynamic>> getPendingMessages(int userId1, int userId2) {
    return _pendingMessages.remove(_chatKey(userId1, userId2)) ?? [];
  }

  // ✅ Expose as streams
  static Stream<Map<String, dynamic>> get rideEvents => _rideEventController.stream;
  static Stream<Map<String, dynamic>> get driverLocationEvents => _driverLocationController.stream;
  static Stream<String> get connectionState => _connectionStateController.stream;
  static Stream<Map<String, dynamic>> get chatMessages => _chatMessageController.stream;

  static Future<void> connect(int userId, String username) async {
    if (_isReconnecting) return;
    _isReconnecting = true;
    _reconnectTimer?.cancel();
    _lastUserId = userId;
    _lastUsername = username;
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔌 WebSocket CONNECTING');
      addDebugMessage('User ID: $userId');
      addDebugMessage('Username: $username');

      // Reset manual disconnect flag for new connection attempt
      _isManualDisconnect = false;

      // ✅ Cancel previous subscription if exists
      _channelSubscription?.cancel();
      _channelSubscription = null;

      // ✅ Close previous connection if exists
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
      final token = StorageService.getToken();
      addDebugMessage('Base URL: $baseUrl');

      final wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      final fullUrl = token != null
          ? '$wsUrl/ws-chat?token=$token'
          : '$wsUrl/ws-chat';
      addDebugMessage('WebSocket URL: $fullUrl');
      
      try {
        // ✅ Create new connection (async — don't set connected until data flows)
        _channel = WebSocketChannel.connect(
          Uri.parse(fullUrl),
        );
        
        await _channel!.ready.timeout(const Duration(seconds: 10));
        
        _connectionStateController.add('connecting');
        
        // Send login message immediately (queued by browser until open)
        _sendLoginMessage(userId, username);
        
        // Start heartbeat
        _startHeartbeat(userId);
        
        bool _didConnect = false;
        
        // Listen for messages
        _channelSubscription = _channel?.stream.listen(
          (message) {
            // First data received = connection is truly alive
            if (!_didConnect) {
              _didConnect = true;
              _isConnected = true;
              _reconnectAttempts = 0;
              _connectionStateController.add('connected');
              addDebugMessage('✅ WebSocket Connected!');
            }
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
            _isConnected = false;
            _channelSubscription = null;
            addDebugMessage('❌ WebSocket Error: $error');
            _connectionStateController.add('error');
            
            _scheduleReconnect();
          },
          onDone: () {
            addDebugMessage('🔌 WebSocket closed');
            _isConnected = false;
            _channelSubscription = null;
            
            // ✅ ONLY EMIT if this is NOT a manual disconnect
            if (!_isManualDisconnect) {
              _connectionStateController.add('disconnected');
              _scheduleReconnect();
            }
          },
        );
        
        // Timeout: if no data received within 8 seconds, treat as failure
        Future.delayed(const Duration(seconds: 8), () {
          if (!_didConnect && !_isManualDisconnect) {
            addDebugMessage('⏱️ WebSocket connection timeout — no data received within 8s');
            _channel?.sink.close();
            if (!_isConnected) {
              _connectionStateController.add('error');
            }
          }
        });
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
    } finally {
      _isReconnecting = false;
    }
  }

  static void _sendLoginMessage(int userId, String username) {
    if (_channel == null) return;
    
    final message = {
      'type': 'login',
      'senderId': userId,
      'senderName': username,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _channel!.sink.add(jsonEncode(message));
    addDebugMessage('📤 Sent login message');
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

  static void sendMessageDelivered(int messageId, int senderId, int receiverId) {
    if (!_isConnected) return;
    final message = {
      'type': 'message_delivered',
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _channel?.sink.add(jsonEncode(message));
  }

  static void sendMessageRead(int senderId, int receiverId) {
    if (!_isConnected) return;
    final message = {
      'type': 'message_read',
      'senderId': senderId,
      'receiverId': receiverId,
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
  
  static void _scheduleReconnect() {
    if (_isManualDisconnect) return;
    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      addDebugMessage('❌ Max reconnect attempts ($_maxReconnectAttempts) reached. Giving up.');
      _connectionStateController.add('error');
      return;
    }
    final delay = Duration(seconds: [1, 2, 4, 8, 15, 30][(_reconnectAttempts - 1).clamp(0, 5)]);
    addDebugMessage('🔄 Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && !_isManualDisconnect) {
        addDebugMessage('🔄 Auto-reconnecting...');
        connect(_lastUserId, _lastUsername);
      }
    });
  }

  static void _startHeartbeat(int userId) {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (!_isConnected) return;
      final message = {
        'type': 'heartbeat',
        'senderId': userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _channel?.sink.add(jsonEncode(message));
    });
  }
  
  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
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
        // Store in pending buffer for when chat screen opens
        _storePendingMessage(message);
        // Track unread count for receiver
        final msgSenderId = message['senderId'] as int?;
        if (msgSenderId != null) {
          unreadCounts[msgSenderId] = (unreadCounts[msgSenderId] ?? 0) + 1;
        }
        break;
      case 'message_delivered':
        onMessageReceived?.call(message);
        _chatMessageController.add(message);
        break;
      case 'message_read':
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
      case 'payment_confirmed':
      case 'payment_finalized':
      case 'payment_refunded':
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

      // ✅ DRIVER HEADING ONLY - rotation without position
      case 'driver_heading':
        addDebugMessage('🔄 Driver heading update');
        _driverLocationController.add(message);
        break;
        
      case 'pong':
        addDebugMessage('💓 Heartbeat response');
        break;
        
      case 'force_logout':
        addDebugMessage('🚫 Force logout received - signed in from another device');
        onForceLogout?.call();
        break;
    }
  }

  static void _storePendingMessage(Map<String, dynamic> message) {
    final senderId = message['senderId'] as int?;
    final receiverId = message['receiverId'] as int?;
    if (senderId == null || receiverId == null) return;
    final key = _chatKey(senderId, receiverId);
    _pendingMessages.putIfAbsent(key, () => []);
    _pendingMessages[key]!.add(Map<String, dynamic>.from(message));
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
      
      // ✅ SET FLAG to prevent onDone/auto-reconnect
      _isManualDisconnect = true;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      
      _stopHeartbeat();
      
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
      
      // Stop processing incoming messages immediately
      _channelSubscription?.cancel();
      _channelSubscription = null;

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
      });
      
    } catch (e) {
      addDebugMessage('❌ Error in disconnect(): $e');
      _isConnected = false;
      _connectionStateController.add('disconnected');
    }
  }
}