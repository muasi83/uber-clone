import 'dart:math';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/rider_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _logoVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _logoVisible = true);
    });
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

      addDebugMessage(
          'Token: ${token != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage(
          'User ID: ${userId != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage(
          'Username: ${username != null ? '✅ Found' : '❌ Not found'}');
      addDebugMessage(
          'Role: ${role != null ? '✅ Found' : '❌ Not found'}');

      // Check if all required data exists
      if (token != null &&
          userId != null &&
          username != null &&
          role != null) {
        addDebugMessage('✅ Valid session found');
        addDebugMessage('═══════════════════════════════════════');

        print(
            'DEBUG: Valid session - navigating to ${role == 'DRIVER' ? 'driver' : 'rider'} home');

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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.darkGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Animated logo with fade-in and scale bounce
            AnimatedOpacity(
              opacity: _logoVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'RideNow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Premium Ride Sharing',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            _BouncingDots(controller: _animationController),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'v1.0.0',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  final AnimationController controller;

  const _BouncingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.25;
            final t = (controller.value + delay) % 1.0;
            final scale =
                0.4 + 0.6 * (t < 0.5 ? t / 0.5 : (1.0 - t) / 0.5);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
