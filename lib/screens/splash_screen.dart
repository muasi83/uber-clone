import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
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

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) setState(() => _locationRequired = true);

      final granted = await _requestLocation();
      if (!granted || !mounted) return;

      await _checkSession();
    } catch (e) {
      _navigateToAuth();
    }
  }

  Future<bool> _requestLocation() async {
    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationDeniedForever = true);
        return false;
      }

      return false;
    } catch (e) {
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
    final granted = await _requestLocation();
    if (granted && mounted) {
      await _checkSession();
    } else if (mounted) {
      setState(() => _locationDeniedForever = true);
    }
  }

  Future<void> _checkSession() async {
    try {
      final token = StorageService.getToken();
      final userId = StorageService.getUserId();
      final username = StorageService.getUsername();
      final role = StorageService.getRole();

      if (token != null &&
          userId != null &&
          username != null &&
          role != null) {
        final activeRideId = StorageService.getActiveRideId();
        if (activeRideId != null) {
          StorageService.clearActiveRideId();
        }

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
        _navigateToAuth();
      }
    } catch (e) {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    if (mounted) {
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
        child: _locationRequired
            ? _buildLocationRequest()
            : _buildSplashContent(),
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
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'Location permission was permanently denied. Please enable it in Settings.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                ),
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
                  foregroundColor: AppColors.textPrimary,
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
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: () {
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
