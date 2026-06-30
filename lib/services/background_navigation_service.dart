import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/debug_screen.dart';
import 'ride_service.dart';
import 'websocket_service.dart';
import 'storage_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class BackgroundNavigationService {
  static final BackgroundNavigationService _instance =
      BackgroundNavigationService._();
  factory BackgroundNavigationService() => _instance;
  BackgroundNavigationService._();

  Timer? _locationTimer;
  bool _isRunning = false;
  int? _rideId;
  String? _navigationType;
  bool _serviceInitialized = false;

  static const String _channelId = 'navigation_channel';

  bool get isRunning => _isRunning;

  Future<void> initialize() async {
    if (_serviceInitialized) return;
    _serviceInitialized = true;

    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        'Navigation Service',
        description: 'Background location tracking during navigation',
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      final FlutterBackgroundService service = FlutterBackgroundService();

      await service.configure(
        androidConfiguration: AndroidConfiguration(
          onStart: _onStart,
          autoStart: false,
          isForegroundMode: true,
          notificationChannelId: _channelId,
          initialNotificationTitle: 'Navigation Active',
          initialNotificationContent: 'Updating rider on your location...',
          foregroundServiceNotificationId: 888,
          foregroundServiceTypes: [AndroidForegroundType.location],
        ),
        iosConfiguration: IosConfiguration(
          autoStart: false,
          onForeground: _onStart,
          onBackground: _onIosBackground,
        ),
      );
    } catch (e) {
      addDebugMessage('⚠️ Background service not available on this platform: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) {
    service.on('stop').listen((event) {
      service.stopSelf();
    });
  }

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  Future<void> start({
    required int rideId,
    required String navigationType,
    required String destinationAddress,
  }) async {
    if (_isRunning) return;

    _rideId = rideId;
    _navigationType = navigationType;

    addDebugMessage(
      '🚀 Starting background navigation: $navigationType for ride $rideId',
    );

    try {
      final FlutterBackgroundService service = FlutterBackgroundService();
      await service.startService();
      _isRunning = true;

      _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _sendLocation();
      });
      _sendLocation();
    } catch (e) {
      addDebugMessage(
        '⚠️ Could not start background service: $e — location sharing disabled for this session',
      );
      _rideId = null;
      _navigationType = null;
    }
  }

  Future<void> stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    _rideId = null;
    _navigationType = null;
    _locationTimer?.cancel();
    _locationTimer = null;

    addDebugMessage('🛑 Stopping background navigation');

    final FlutterBackgroundService service = FlutterBackgroundService();
    service.invoke('stop');
  }

  static Future<void> _sendLocation() async {
    final instance = _instance;
    final rideId = instance._rideId;
    final navigationType = instance._navigationType;
    if (rideId == null || navigationType == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 8),
        ),
      );

      addDebugMessage(
        '📍 Background nav: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)} ($navigationType)',
      );

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.updateDriverLocation(
          rideId: rideId,
          latitude: position.latitude,
          longitude: position.longitude,
          token: token,
        );
      }

      WebSocketService.sendRideMessage('driver_location', {
        'driverId': StorageService.getUserId(),
        'rideId': rideId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'heading': position.heading,
        'navigationType': navigationType,
      });
    } catch (e) {
      addDebugMessage('⚠️ Background nav location error: $e');
    }
  }
}
