import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/debug_screen.dart';
import 'storage_service.dart';

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

  static void handleNotificationTap(String payload) {
    addDebugMessage('🔔 Notification tapped from sheet: $payload');
    final navigator = navigatorKey?.currentState;
    if (navigator == null || payload.isEmpty) return;

    if (payload == 'ride_accepted' || payload == 'ride_started' || payload == 'driver_arrived') {
      navigator.pushNamed('/rider-tracking');
    } else if (payload == 'ride_completed') {
      navigator.pushNamed('/rider-completed');
    } else if (payload == 'ride_cancelled' || payload == 'search_timeout') {
      navigator.pushNamedAndRemoveUntil('/rider-home', (route) => false);
    } else if (payload == 'ride_available' || payload == 'ride_confirmed') {
      navigator.pushNamed('/driver-home');
    } else {
      navigator.pushNamedAndRemoveUntil('/rider-home', (route) => false);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    addDebugMessage('🔔 Notification tapped: ${response.payload}');
    final navigator = navigatorKey?.currentState;
    if (navigator == null || response.payload == null) return;

    final payload = response.payload!;
    if (payload == 'ride_accepted' || payload == 'ride_started' || payload == 'driver_arrived') {
      navigator.pushNamed('/rider-tracking');
    } else if (payload == 'ride_completed') {
      navigator.pushNamed('/rider-completed');
    } else if (payload == 'ride_cancelled' || payload == 'search_timeout') {
      navigator.pushNamedAndRemoveUntil('/rider-home', (route) => false);
    } else if (payload == 'ride_available' || payload == 'ride_confirmed') {
      navigator.pushNamed('/driver-home');
    } else {
      navigator.pushNamedAndRemoveUntil('/rider-home', (route) => false);
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

  static Future<int> getUnreadCount(String token) async {
    try {
      final url = StorageService.getNotificationsUnreadCountUrl();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
    } catch (e) {
      addDebugMessage('⚠️ Failed to get unread count: $e');
    }
    return 0;
  }

  static Future<List<Map<String, dynamic>>> fetchNotifications(String token) async {
    try {
      final url = StorageService.getNotificationsUrl();
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as List;
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      addDebugMessage('⚠️ Failed to fetch notifications: $e');
    }
    return [];
  }

  static Future<void> markAllAsRead(String token) async {
    try {
      await http.post(
        Uri.parse('${StorageService.getNotificationsUrl()}/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      addDebugMessage('⚠️ Failed to mark all as read: $e');
    }
  }

  static Future<void> clearNotifications(String token) async {
    try {
      await http.delete(
        Uri.parse(StorageService.getNotificationsUrl()),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      addDebugMessage('⚠️ Failed to clear notifications: $e');
    }
  }
}
