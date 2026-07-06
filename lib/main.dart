import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'services/storage_service.dart';
import 'services/crash_reporter.dart';
import 'services/notification_service.dart';
import 'services/websocket_service.dart';
import 'services/background_navigation_service.dart';
import 'services/firebase_service.dart';
import 'utils/map_style_loader.dart';

import 'screens/auth_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_registration_screen.dart';
import 'screens/driver_navigation_to_rider_screen.dart';
import 'screens/driver_ride_summary_screen.dart';
import 'screens/rider_active_ride_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/rider_ride_completed_screen.dart';
import 'screens/rider_searching_driver_screen.dart';
import 'screens/rider_tracking_screen.dart';
import 'screens/rider_trip_details_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_home_screen.dart';
import 'screens/admin_trip_details_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';

import 'screens/driver_active_ride_screen.dart' as driver_active;

import 'theme/app_theme.dart';
import 'theme/app_colors.dart';

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      CrashReporter.init();

      try {
        await StorageService.init();
      } catch (e) {
        CrashReporter.addLog('StorageService.init failed: $e');
      }

      try {
        Intl.defaultLocale = 'en_US';
      } catch (e) {
        CrashReporter.addLog('Intl locale failed: $e');
      }

      await NotificationService.init();
      NotificationService.navigatorKey = _navigatorKey;

      try {
        await FirebaseService.init();
      } catch (e) {
        CrashReporter.addLog('FirebaseService.init failed: $e');
      }

      await BackgroundNavigationService().initialize();

      _setupChatNotificationListener();

      await MapStyleLoader.load();

      runApp(MyApp());
    },
    (error, stack) => CrashReporter.addLog('ZONE ERROR: $error\n$stack'),
  );
}

void _setupChatNotificationListener() {
  WebSocketService.chatMessages.listen((message) {
    // Don't show notification if already on the chat screen for this conversation
    final partnerId = ChatScreen.activeChatPartnerId;
    if (partnerId != null) {
      final msgSenderId = message['senderId'] as int?;
      final msgReceiverId = message['receiverId'] as int?;
      if (msgSenderId == partnerId || msgReceiverId == partnerId) {
        return;
      }
    }

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
    if (type == null) return;
    String title;
    String body;

    switch (type) {
      case 'ride_available':
        return;
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
      case 'payment_confirmed':
        title = 'Payment Confirmed';
        body = 'Payment has been confirmed';
        break;
      case 'payment_finalized':
        title = 'Payment Finalized';
        body = 'Your payment has been finalized';
        break;
      case 'payment_refunded':
        title = 'Payment Refunded';
        body = 'Your payment has been refunded';
        break;
      default:
        return;
    }

    NotificationService.showChatNotification(
      senderName: title,
      message: body,
    );
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RideNow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),

      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/reset-password': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /reset-password');
          }
          final email = args['email'] as String?;
          final code = args['code'] as String?;
          if (email == null || code == null) {
            return _routeError(context, 'Invalid /reset-password arguments');
          }
          return ResetPasswordScreen(email: email, code: code);
        },
        '/debug': (_) => const DebugScreen(),

        // Rider
        '/rider-home': (_) => const RiderHomeScreen(),

        '/rider-trip-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /rider-trip-details');
          }
          final pickupLat = (args['pickupLat'] as num?)?.toDouble();
          final pickupLng = (args['pickupLng'] as num?)?.toDouble();
          final pickupAddress = args['pickupAddress'] as String?;
          final dropoffLat = (args['dropoffLat'] as num?)?.toDouble();
          final dropoffLng = (args['dropoffLng'] as num?)?.toDouble();
          final dropoffAddress = args['dropoffAddress'] as String?;
          final distance = (args['estimatedDistance'] as num?)?.toDouble();
          final duration = (args['estimatedDuration'] as num?)?.toInt();
          if (pickupLat == null || pickupLng == null || pickupAddress == null ||
              dropoffLat == null || dropoffLng == null || dropoffAddress == null ||
              distance == null || duration == null) {
            return _routeError(context, 'Invalid /rider-trip-details arguments');
          }
          return RiderTripDetailsScreen(
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            pickupAddress: pickupAddress,
            dropoffLat: dropoffLat,
            dropoffLng: dropoffLng,
            dropoffAddress: dropoffAddress,
            estimatedDistance: distance,
            estimatedDuration: duration,
            initialRideType: (args['rideType'] as String?) ?? 'ECONOMY',
          );
        },

        '/rider-searching': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /rider-searching');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          final pickup = args['pickupAddress'] as String?;
          final dropoff = args['dropoffAddress'] as String?;
          final fare = (args['estimatedFare'] as num?)?.toDouble();
          if (rideId == null || pickup == null || dropoff == null || fare == null) {
            return _routeError(context, 'Invalid /rider-searching arguments');
          }
          return RiderSearchingDriverScreen(
            rideId: rideId,
            pickupAddress: pickup,
            dropoffAddress: dropoff,
            estimatedFare: fare,
          );
        },

        '/rider-tracking': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /rider-tracking');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          final driverData = args['driverData'];
          if (rideId == null || driverData is! Map) {
            return _routeError(context, 'Invalid /rider-tracking arguments');
          }
          return RiderTrackingScreen(
            rideId: rideId,
            driverData: driverData.cast<String, dynamic>(),
          );
        },

        '/rider-active-ride': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /rider-active-ride');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          final pLat = (args['pickupLat'] as num?)?.toDouble();
          final pLng = (args['pickupLng'] as num?)?.toDouble();
          final dLat = (args['dropoffLat'] as num?)?.toDouble();
          final dLng = (args['dropoffLng'] as num?)?.toDouble();
          final dropoff = args['dropoffAddress'] as String?;
          if (rideId == null || pLat == null || pLng == null ||
              dLat == null || dLng == null || dropoff == null) {
            return _routeError(context, 'Invalid /rider-active-ride arguments');
          }
          return RiderActiveRideScreen(
            rideId: rideId,
            pickupLat: pLat,
            pickupLng: pLng,
            dropoffLat: dLat,
            dropoffLng: dLng,
            dropoffAddress: dropoff,
          );
        },

        '/rider-completed': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /rider-completed');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          if (rideId == null) {
            return _routeError(context, 'Invalid /rider-completed arguments');
          }
          return RiderRideCompletedScreen(
            rideId: rideId,
            totalFare: (args['totalFare'] as num?)?.toDouble(),
            distance: (args['distance'] as num?)?.toDouble(),
            duration: (args['duration'] as num?)?.toInt(),
          );
        },

        // Driver
        '/driver-registration': (context) {
          final token = StorageService.getToken();
          final username = StorageService.getUsername();
          final userIdRaw = StorageService.getUserId();

          if (token == null || username == null || userIdRaw == null) {
            return _routeError(context, 'Missing driver registration data');
          }

          return DriverRegistrationScreen(
            userId: userIdRaw,
            username: username,
            token: token,
          );
        },

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
            return _routeError(context, 'Missing driver session data');
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
            return _routeError(context, 'Missing arguments for /driver-navigation');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          final pickup = args['pickupAddress'] as String?;
          final pLat = (args['pickupLat'] as num?)?.toDouble();
          final pLng = (args['pickupLng'] as num?)?.toDouble();
          final dropoffAddr = args['dropoffAddress'] as String?;
          final dLat = (args['dropoffLat'] as num?)?.toDouble();
          final dLng = (args['dropoffLng'] as num?)?.toDouble();
          if (rideId == null || pickup == null || pLat == null ||
              pLng == null || dropoffAddr == null || dLat == null || dLng == null) {
            return _routeError(context, 'Invalid /driver-navigation arguments');
          }
          return DriverNavigationToRiderScreen(
            rideId: rideId,
            pickupAddress: pickup,
            pickupLat: pLat,
            pickupLng: pLng,
            dropoffAddress: dropoffAddr,
            dropoffLat: dLat,
            dropoffLng: dLng,
          );
        },

        '/driver-active-ride': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /driver-active-ride');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          final dropoffAddr = args['dropoffAddress'] as String?;
          final dLat = (args['dropoffLat'] as num?)?.toDouble();
          final dLng = (args['dropoffLng'] as num?)?.toDouble();
          if (rideId == null || dropoffAddr == null || dLat == null || dLng == null) {
            return _routeError(context, 'Invalid /driver-active-ride arguments');
          }
          return driver_active.DriverActiveRideScreen(
            rideId: rideId,
            dropoffAddress: dropoffAddr,
            dropoffLat: dLat,
            dropoffLng: dLng,
          );
        },

        '/driver-summary': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /driver-summary');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          if (rideId == null) {
            return _routeError(context, 'Invalid /driver-summary arguments');
          }
          return DriverRideSummaryScreen(
            rideId: rideId,
          );
        },

        // Admin
        '/admin-home': (_) => const AdminHomeScreen(),

        '/admin-trip-details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is! Map<String, dynamic>) {
            return _routeError(context, 'Missing arguments for /admin-trip-details');
          }
          final rideId = (args['rideId'] as num?)?.toInt();
          if (rideId == null) {
            return _routeError(context, 'Invalid /admin-trip-details arguments');
          }
          return AdminTripDetailsScreen(rideId: rideId);
        },
      },
    );
  }
}

Widget _routeError(BuildContext context, String message) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Navigation Error'),
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    ),
  );
}
