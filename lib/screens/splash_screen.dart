import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/storage_service.dart';
import '../services/ride_service.dart';
import '../screens/auth_screen.dart';
import '../screens/rider_home_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

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
            final pendingRideId = await RideService.getPendingPaymentRideId(token);
            if (pendingRideId != null && mounted) {
              final ride = await RideService.getRideDetails(pendingRideId, token);
              if (ride != null && mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/rider-active-ride',
                  (route) => false,
                  arguments: {
                    'rideId': ride.id,
                    'pickupLat': ride.pickupLatitude,
                    'pickupLng': ride.pickupLongitude,
                    'dropoffLat': ride.dropoffLatitude,
                    'dropoffLng': ride.dropoffLongitude,
                    'dropoffAddress': ride.dropoffAddress,
                  },
                );
                return;
              }
            }

            if (!mounted) return;
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
                borderRadius: AppRadius.xlRadius,
                boxShadow: AppShadows.large,
              ),
              child: const Icon(
                Icons.directions_car,
                size: 60,
                color: AppColors.primaryLight,
              ),
            ),
          ),
        ),
        AppSpacing.gapXxl,
        Text(
          'RideNow',
          style: AppTypography.textTheme.displayMedium?.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          'Premium Ride Sharing',
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryLight.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        _BouncingDots(controller: _animationController),
        AppSpacing.gapLg,
        Text(
          'v1.0.0',
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryLight.withValues(alpha: 0.38),
            letterSpacing: 0.5,
          ),
        ),
        AppSpacing.gapXxl,
      ],
    );
  }

  Widget _buildLocationRequest() {
    return Padding(
      padding: AppSpacing.screenPadding.copyWith(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          AppSpacing.gapXxl,
          Text(
            'Location Access Required',
            style: AppTypography.textTheme.headlineMedium?.copyWith(
              color: AppColors.primaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapMd,
          Text(
            'RideNow needs your location to find nearby rides and drivers. This permission is required to use the app.',
            style: AppTypography.textTheme.bodyMedium?.copyWith(
              color: AppColors.primaryLight.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapXxl,
          if (_locationDeniedForever) ...[
            Container(
              padding: AppSpacing.cardPaddingCompact,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Location permission was permanently denied. Please enable it in Settings.',
                style: AppTypography.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.gapLg,
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
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
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
              ),
            ),
            AppSpacing.gapMd,
            TextButton(
              onPressed: () {
                if (mounted) _navigateToAuth();
              },
              child: Text(
                'Not Now',
                style: AppTypography.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryLight.withValues(alpha: 0.54),
                ),
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
                    color: AppColors.primaryLight,
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
