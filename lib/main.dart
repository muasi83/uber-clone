/*import 'package:flutter/material.dart';
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

// IMPORTANT: alias driver active ride to avoid name conflicts
import 'screens/driver_active_ride_screen.dart' as driver_active;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.init();
  } catch (_) {}

  try {
    Intl.defaultLocale = 'en_US';
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _routeError(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
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
            //estimatedFare: (args['estimatedFare'] as num).toDouble(),
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

          // ✅ Accept args OR fallback to StorageService
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
}*/


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

// IMPORTANT: alias driver active ride to avoid name conflicts
import 'screens/driver_active_ride_screen.dart' as driver_active;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.init();
  } catch (_) {}

  try {
    Intl.defaultLocale = 'en_US';
  } catch (_) {}

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _routeError(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Error'),
        backgroundColor: const Color(0xFF6366F1),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uber Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
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
            //estimatedFare: (args['estimatedFare'] as num).toDouble(),
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

          // ✅ Accept args OR fallback to StorageService
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