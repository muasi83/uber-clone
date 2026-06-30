import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'storage_service.dart';
import 'ride_service.dart';
import 'notification_service.dart';
import '../screens/debug_screen.dart';

/// Top-level background FCM handler (must be outside class, runs in separate isolate)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Initialize notifications plugin in background isolate
  if (!NotificationService.isInitialized) {
    await NotificationService.init();
  }

  final data = message.data;
  final type = data['type'] ?? '';
  final title = message.notification?.title ?? data['title'] ?? 'New Ride Request';
  final body = message.notification?.body ?? data['body'] ?? 'A passenger needs a ride!';

  if (type == 'ride_available') {
    await NotificationService.showRideAlertNotification(
      title: title,
      body: body,
      rideId: data['rideId'] != null ? int.tryParse(data['rideId']!) : null,
    );
  }
}

class FirebaseService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _currentFcmToken;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      addDebugMessage('✅ Firebase initialized');

      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

      await _requestPermissions();

      _currentFcmToken = await _messaging.getToken();
      addDebugMessage('📱 FCM token: ${_currentFcmToken?.substring(0, 20)}...');

      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }
    } catch (e) {
      addDebugMessage('❌ Firebase init error: $e');
    }
  }

  static Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      addDebugMessage('🔔 FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      addDebugMessage('❌ FCM permission error: $e');
    }
  }

  static Future<void> _onTokenRefresh(String token) async {
    _currentFcmToken = token;
    addDebugMessage('🔄 FCM token refreshed');
    await _sendTokenToServer(token);
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    addDebugMessage('📩 Foreground FCM: ${message.notification?.title}');
    final data = message.data;
    final type = data['type'] ?? '';
    final title = message.notification?.title ?? '';
    final body = message.notification?.body ?? '';

    if (type == 'chat') {
      final senderId = data['senderId'] != null ? int.tryParse(data['senderId']!) : null;
      final senderName = data['senderName'] ?? title;
      final content = data['content'] ?? body;
      await NotificationService.showChatNotification(
        senderName: senderName,
        message: content,
        senderId: senderId,
      );
    } else if (type == 'ride_available' ||
               type == 'payment_confirmed' ||
               type == 'payment_finalized' ||
               type == 'payment_refunded') {
      return;
    } else {
      await NotificationService.showChatNotification(
        senderName: title,
        message: body,
      );
    }
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    addDebugMessage('👆 FCM tapped: ${message.notification?.title}');
    _handleNotificationTap(message.data);
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final rideId = data['rideId'] != null ? int.tryParse(data['rideId']!) : null;
    final screen = data['screen'] ?? '';

    addDebugMessage('🔗 FCM navigate: type=$type rideId=$rideId screen=$screen');
    if (rideId != null && NotificationService.navigatorKey?.currentContext != null) {
      final nav = NotificationService.navigatorKey?.currentState;
      if (nav != null) {
        if (screen == 'chat') {
          nav.pushNamed('/chat', arguments: {'rideId': rideId});
        } else {
          nav.pushNamed('/rider-tracking', arguments: {'rideId': rideId});
        }
      }
    }
  }

  static Future<void> sendTokenToServer() async {
    if (_currentFcmToken == null) return;
    await _sendTokenToServer(_currentFcmToken!);
  }

  static Future<void> _sendTokenToServer(String token) async {
    final authToken = StorageService.getToken();
    if (authToken == null) {
      addDebugMessage('⏸️ Skipping FCM token upload — not logged in');
      return;
    }
    final success = await RideService.registerDeviceToken(token, authToken);
    if (success) {
      addDebugMessage('✅ FCM token sent to server');
    } else {
      addDebugMessage('❌ Failed to send FCM token to server');
    }
  }
}
