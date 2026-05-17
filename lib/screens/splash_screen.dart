import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/rider_home_screen.dart';
import '../screens/driver_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize app and check for existing session
  Future<void> _initializeApp() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🚀 SPLASH SCREEN INIT');
      addDebugMessage('═══════════════════════════════════════');

      print('DEBUG: Starting initialization');

      // Wait 2 seconds for splash animation
      addDebugMessage('⏳ Waiting 2 seconds...');
      await Future.delayed(const Duration(seconds: 2));

      print('DEBUG: 2 second delay complete');

      // Check for existing session
      await _checkSession();
      
      print('DEBUG: Session check complete');
    } catch (e) {
      print('DEBUG: Error in splash: $e');
      addDebugMessage('❌ Error in splash: $e');
      _navigateToAuth();
    }
  }

  /// Check if user has existing session
  Future<void> _checkSession() async {
    try {
      addDebugMessage('🔍 Checking saved credentials...');
      print('DEBUG: Checking credentials');

      final token = StorageService.getToken();
      final userId = StorageService.getUserId();
      final username = StorageService.getUsername();
      final role = StorageService.getRole();

      print('DEBUG: Token: $token');
      print('DEBUG: UserId: $userId');
      print('DEBUG: Username: $username');
      print('DEBUG: Role: $role');

      addDebugMessage('Token: ${token != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage('User ID: ${userId != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage('Username: ${username != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage('Role: ${role != null ? '✅ Found' : '❌ Not found'}');

      // Check if all required data exists
      if (token != null && userId != null && username != null && role != null) {
        addDebugMessage('✅ Valid session found');
        addDebugMessage('═══════════════════════════════════════');
        
        print('DEBUG: Valid session - navigating to ${role == 'DRIVER' ? 'driver' : 'rider'} home');

        // Navigate to appropriate home screen based on role
        if (mounted) {
          if (role == 'DRIVER') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => DriverHomeScreen(
                  userId: userId,
                  username: username,
                  token: token,
                ),
              ),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const RiderHomeScreen(),
              ),
              (route) => false,
            );
          }
        }
      } else {
        addDebugMessage('❌ No valid session - going to AuthScreen');
        addDebugMessage('═══════════════════════════════════════');
        
        print('DEBUG: No valid session - navigating to auth');
        _navigateToAuth();
      }
    } catch (e) {
      print('DEBUG: Error checking session: $e');
      addDebugMessage('❌ Error checking session: $e');
      _navigateToAuth();
    }
  }

  /// Navigate to auth screen
  void _navigateToAuth() {
    if (mounted) {
      print('DEBUG: Navigating to AuthScreen');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6366F1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.directions_car,
                size: 60,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            const Text(
              'Uber Clone',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Your Ride, Your Way',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),

            // Loading Text
            const Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}