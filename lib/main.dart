import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/rider_home_screen.dart';
import 'screens/driver_home_screen.dart';
import 'screens/driver_registration_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/debug_screen.dart' as debug;

void main() async {
  try {
    print('═══════════════════════════════════════');
    print('🚀 APP STARTING');
    print('═══════════════════════════════════════');

    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter bindings initialized');

    try {
      await StorageService.init();
      print('✅ StorageService initialized');
    } catch (e) {
      print('❌ StorageService init error: $e');
    }

    // ✅ INITIALIZE INTL
    try {
      Intl.defaultLocale = 'en_US';
      print('✅ Intl initialized with locale: en_US');
    } catch (e) {
      print('❌ Intl init error: $e');
    }

    print('✅ All initializations complete');
    print('═══════════════════════════════════════');

    runApp(const MyApp());
  } catch (e) {
    print('❌ FATAL ERROR IN main(): $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      
      // ✅ SET HOME TO SPLASH SCREEN
      home: const SplashScreen(),
      
      // ✅ DEFINE ALL ROUTES
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/rider-home': (context) => const RiderHomeScreen(),
        //'/driver-home': (context) => const DriverHomeScreen(),
        //'/driver-registration': (context) => const DriverRegistrationScreen(),
        '/debug': (context) => const DebugScreen(),
      },
      
      // ✅ FALLBACK FOR UNKNOWN ROUTES
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Unknown Route'),
              backgroundColor: const Color(0xFF6366F1),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Route not found: ${settings.name}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/splash',
                      (route) => false,
                    ),
                    child: const Text('Go to Home'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/*
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/debug_screen.dart';

void main() async {
  try {
    print('═══════════════════════════════════════');
    print('🚀 APP STARTING');
    print('═══════════════════════════════════════');

    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter bindings initialized');

    try {
      await StorageService.init();
      print('✅ StorageService initialized');
    } catch (e) {
      print('❌ StorageService init error: $e');
    }

    // ✅ INITIALIZE INTL
    try {
      Intl.defaultLocale = 'en_US';
      print('✅ Intl initialized with locale: en_US');
    } catch (e) {
      print('❌ Intl init error: $e');
    }

    print('✅ All initializations complete');
    print('═══════════════════════════════════════');

    runApp(const MyApp());
  } catch (e) {
    print('❌ FATAL ERROR IN main(): $e');
    print('Stack trace: ${StackTrace.current}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}*/