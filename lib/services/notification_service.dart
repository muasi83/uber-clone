import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/debug_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? navigatorKey;

  static bool _initialized = false;
  static int _messageId = 0;

  static int get _nextId => ++_messageId;

  static bool get isInitialized => _initialized;

  // Dedicated channels
  static const String _chatChannelId = 'chat_messages';
  static const String _rideAlertChannelId = 'ride_alerts';

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: settings);

    // Create high-priority ride alert channel
    await _createRideAlertChannel();

    _initialized = true;
    addDebugMessage('✅ NotificationService initialized');
  }

  static Future<void> _createRideAlertChannel() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _rideAlertChannelId,
            'Ride Alerts',
            description: 'High-priority ride request notifications',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Colors.red,
          ),
        );
        addDebugMessage('✅ Ride alert notification channel created');
      }
    } catch (e) {
      addDebugMessage('⚠️ Failed to create ride alert channel: $e');
    }
  }

  static Future<void> requestIosPermissions() async {
    if (!_initialized) return;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<void> showChatNotification({
    required String senderName,
    required String message,
    int? senderId,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      _chatChannelId,
      'Chat Messages',
      channelDescription: 'New chat messages during your ride',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _nextId,
      title: senderName,
      body: message,
      notificationDetails: details,
      payload: senderId?.toString(),
    );

    addDebugMessage('🔔 Chat notification shown: $senderName: $message');
  }

  /// Show a high-priority ride alert notification (for background FCM)
  static Future<void> showRideAlertNotification({
    required String title,
    required String body,
    int? rideId,
  }) async {
    if (!_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      _rideAlertChannelId,
      'Ride Alerts',
      channelDescription: 'High-priority ride request notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      color: const Color(0xFF9DBB2D),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: _nextId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: rideId?.toString(),
    );

    addDebugMessage('🔔 Ride alert notification shown: $title');
  }
}
