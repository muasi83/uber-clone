import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/storage_service.dart';

import 'screens/auth_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_navigation_to_rider_screen.dart';
import 'screens/driver_ride_summary_screen.dart';
import 'screens/rider_active_ride_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/rider_ride_completed_screen.dart';
import 'screens/rider_route_preview_screen.dart';
import 'screens/rider_searching_driver_screen.dart';
import 'screens/rider_tracking_screen.dart';
import 'screens/rider_trip_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/test_websocket_screen.dart';

import 'screens/driver_active_ride_screen.dart' as driver_active;

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.init();
  } catch (_) {}

  try {
    Intl.defaultLocale = 'en_US';
  } catch (_) {}

  await NotificationService.init();

  _setupNotificationListeners();

  runApp(const MyApp());
}

void _setupNotificationListeners() {
  WebSocketService.chatMessages.listen((message) {
    final senderId = message['senderId'] as int?;
    final senderName = message['senderName'] as String? ?? 'Someone';
    final content = message['content'] as String? ?? '';
    NotificationService.showChatNotification(
      senderName: senderName,
      message: content,
      senderId: senderId,
    );
  });

  WebSocketService.rideEvents.listen((event) {
    final type = event['type'] as String?;
    String title;
    String body;

    switch (type) {
      case 'ride_available':
        title = 'New Ride Request';
        body = 'A passenger is nearby and needs a ride';
        break;
      case 'ride_accepted':
        title = 'Ride Accepted';
        body = 'A driver is on their way to pick you up';
        break;
      case 'ride_confirmed':
        title = 'Ride Confirmed';
        body = 'Your ride has been confirmed';
        break;
      case 'driver_arrived':
        title = 'Driver Arrived';
        body = 'Your driver has arrived at the pickup location';
        break;
      case 'ride_started':
        title = 'Ride Started';
        body = 'Your ride has started';
        break;
      case 'ride_completed':
        title = 'Ride Completed';
        body = 'You have reached your destination';
        break;
      case 'ride_cancelled':
        title = 'Ride Cancelled';
        body = 'The ride has been cancelled';
        break;
      case 'search_timeout':
        title = 'No Drivers Found';
        body = 'No drivers are available nearby right now';
        break;
      default:
        return;
    }

    NotificationService.showRideNotification(
      title: title,
      body: body,
      payload: type,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),

      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthScreen(),
        '/debug': (_) => const DebugScreen(),
        '/test-websocket': (_) => const TestWebSocketScreen(),

        // Rider
        '/rider-home': (_) => const RiderHomeScreen(),

        '/rider-route-preview': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-route-preview');
          }
          return RiderRoutePreviewScreen(
            pickupLat: (args['pickupLat'] as num).toDouble(),
            pickupLng: (args['pickupLng'] as num).toDouble(),
            pickupAddress: args['pickupAddress'] as String,
            dropoffLat: (args['dropoffLat'] as num).toDouble(),
            dropoffLng: (args['dropoffLng'] as num).toDouble(),
            dropoffAddress: args['dropoffAddress'] as String,
            estimatedDistance: (args['estimatedDistance'] as num).toDouble(),
            estimatedFare: (args['estimatedFare'] as num).toDouble(),
            estimatedDuration: (args['estimatedDuration'] as num).toInt(),
            rideType: args['rideType'] as String,
          );
        },

        '/rider-trip-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-trip-details');
          }
          return RiderTripDetailsScreen(
            pickupLat: (args['pickupLat'] as num).toDouble(),
            pickupLng: (args['pickupLng'] as num).toDouble(),
            pickupAddress: args['pickupAddress'] as String,
            dropoffLat: (args['dropoffLat'] as num).toDouble(),
            dropoffLng: (args['dropoffLng'] as num).toDouble(),
            dropoffAddress: args['dropoffAddress'] as String,
            estimatedDistance: (args['estimatedDistance'] as num).toDouble(),
            estimatedDuration: (args['estimatedDuration'] as num).toInt(),
            initialRideType: (args['rideType'] as String?) ?? 'ECONOMY',
          );
        },

        '/rider-searching': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-searching');
          }
          return RiderSearchingDriverScreen(
            rideId: (args['rideId'] as num).toInt(),
            pickupAddress: args['pickupAddress'] as String,
            dropoffAddress: args['dropoffAddress'] as String,
            estimatedFare: (args['estimatedFare'] as num).toDouble(),
          );
        },

        '/rider-tracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-tracking');
          }
          return RiderTrackingScreen(
            rideId: (args['rideId'] as num).toInt(),
            driverData: (args['driverData'] as Map).cast<String, dynamic>(),
          );
        },

        '/rider-active-ride': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-active-ride');
          }
          return RiderActiveRideScreen(
            rideId: (args['rideId'] as num).toInt(),
            pickupLat: (args['pickupLat'] as num).toDouble(),
            pickupLng: (args['pickupLng'] as num).toDouble(),
            dropoffLat: (args['dropoffLat'] as num).toDouble(),
            dropoffLng: (args['dropoffLng'] as num).toDouble(),
            dropoffAddress: args['dropoffAddress'] as String,
          );
        },

        '/rider-completed': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /rider-completed');
          }
          return RiderRideCompletedScreen(
            rideId: (args['rideId'] as num).toInt(),
            totalFare: (args['totalFare'] as num?)?.toDouble(),
            distance: (args['distance'] as num?)?.toDouble(),
            duration: (args['duration'] as num?)?.toInt(),
          );
        },

        // Driver
        '/driver-home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;

          final token = (args is Map ? args['token'] : null) as String? ??
              StorageService.getToken();
          final username = (args is Map ? args['username'] : null) as String? ??
              StorageService.getUsername();
          final userIdRaw = (args is Map ? args['userId'] : null) ??
              StorageService.getUserId();

          final userId = (userIdRaw is num) ? userIdRaw.toInt() : null;

          if (token == null || username == null || userId == null) {
            return _routeError(
              'Missing driver session data.\n'
              'token=$token\nusername=$username\nuserId=$userId',
            );
          }

          return DriverHomeScreen(
            userId: userId,
            username: username,
            token: token,
          );
        },

        '/driver-navigation': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /driver-navigation');
          }
          return DriverNavigationToRiderScreen(
            rideId: (args['rideId'] as num).toInt(),
            pickupAddress: args['pickupAddress'] as String,
            pickupLat: (args['pickupLat'] as num).toDouble(),
            pickupLng: (args['pickupLng'] as num).toDouble(),
            dropoffAddress: args['dropoffAddress'] as String,
            dropoffLat: (args['dropoffLat'] as num).toDouble(),
            dropoffLng: (args['dropoffLng'] as num).toDouble(),
          );
        },

        '/driver-active-ride': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /driver-active-ride');
          }
          return driver_active.DriverActiveRideScreen(
            rideId: (args['rideId'] as num).toInt(),
            dropoffAddress: args['dropoffAddress'] as String,
            dropoffLat: (args['dropoffLat'] as num).toDouble(),
            dropoffLng: (args['dropoffLng'] as num).toDouble(),
          );
        },

        '/driver-summary': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError('Missing arguments for /driver-summary');
          }
          return DriverRideSummaryScreen(
            rideId: (args['rideId'] as num).toInt(),
          );
        },
      },
    );
  }
}

Widget _routeError(String message) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Navigation Error'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    ),
  );
}
