import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../screens/debug_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _messageId = 0;

  static int get _nextId => ++_messageId;

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

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _initialized = true;
    addDebugMessage('✅ NotificationService initialized');
  }

  static void _onNotificationTap(NotificationResponse response) {
    addDebugMessage('🔔 Notification tapped: ${response.payload}');
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
      'chat_messages',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
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

  static Future<void> showRideNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;

    const androidDetails = AndroidNotificationDetails(
      'ride_events',
      'Ride Events',
      channelDescription: 'Notifications for ride status updates',
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
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );

    addDebugMessage('🔔 Ride notification shown: $title: $body');
  }
}
