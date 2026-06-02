// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/rider_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _logoVisible = false;
  bool _locationRequired = false;
  bool _locationDeniedForever = false;

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

      // Request location permission before anything else
      addDebugMessage('🔐 Requesting location permission...');
      if (mounted) setState(() => _locationRequired = true);

      final granted = await _requestLocation();
      if (!granted || !mounted) return;

      print('DEBUG: Session check complete');

      // Check for existing session
      await _checkSession();

      print('DEBUG: Session check complete');
    } catch (e) {
      print('DEBUG: Error in splash: $e');
      addDebugMessage('❌ Error in splash: $e');
      _navigateToAuth();
    }
  }

  /// Request location permission, returns true if granted
  Future<bool> _requestLocation() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        addDebugMessage('✅ Location permission granted: $permission');
        return true;
      }

      if (permission == LocationPermission.deniedForever) {
        addDebugMessage('❌ Location denied forever');
        if (mounted) setState(() => _locationDeniedForever = true);
        return false;
      }

      // denied or unableToDetermine
      addDebugMessage('❌ Location permission: $permission');
      return false;
    } catch (e) {
      addDebugMessage('❌ Error requesting location: $e');
      return false;
    }
  }

  void _retryLocationPermission() async {
    setState(() {
      _locationRequired = true;
      _locationDeniedForever = false;
    });
    final granted = await _requestLocation();
    if (granted && mounted) {
      await _checkSession();
    }
  }

  void _openAppSettings() async {
    await Geolocator.openAppSettings();
    // Check again after returning from settings
    final granted = await _requestLocation();
    if (granted && mounted) {
      await _checkSession();
    } else if (mounted) {
      setState(() => _locationDeniedForever = true);
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
        child: _locationRequired ? _buildLocationRequest() : _buildSplashContent(),
      ),
    );
  }

  Widget _buildSplashContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
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
    );
  }

  Widget _buildLocationRequest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(
            Icons.location_on,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.xxl),
          const Text(
            'Location Access Required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'RideNow needs your location to find nearby rides and drivers. This permission is required to use the app.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_locationDeniedForever) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Location permission was permanently denied. Please enable it in Settings.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _retryLocationPermission,
                icon: const Icon(Icons.my_location),
                label: const Text('Grant Location Access'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
                // User declined - show again on next app start
                if (mounted) _navigateToAuth();
              },
              child: const Text(
                'Not Now',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
          const Spacer(),
        ],
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
