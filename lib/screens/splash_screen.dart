import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/ride_service.dart';
import '../services/firebase_service.dart';
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
  bool _showWelcome = false;
  bool _locationDeniedForever = false;
  bool _notificationGranted = false;
  bool _notificationDeniedForever = false;
  bool _locationGranted = false;

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

      if (mounted) setState(() => _showWelcome = true);
    } catch (e) {
      _navigateToAuth();
    }
  }

  Future<void> _enableLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      setState(() {
        _locationGranted = true;
        _locationDeniedForever = false;
      });
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationGranted = false;
        _locationDeniedForever = true;
      });
    } else {
      setState(() {
        _locationGranted = false;
        _locationDeniedForever = false;
      });
    }
  }

  Future<void> _enableNotification() async {
    final granted = await FirebaseService.requestNotificationPermission();
    if (!mounted) return;
    if (granted) {
      setState(() {
        _notificationGranted = true;
        _notificationDeniedForever = false;
      });
    } else {
      setState(() {
        _notificationGranted = false;
        _notificationDeniedForever = true;
      });
    }
  }

  void _openAppSettings() async {
    await Geolocator.openAppSettings();
    if (!mounted) return;
    setState(() {
      _locationDeniedForever = false;
      _notificationDeniedForever = false;
    });
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
        child: _showWelcome
            ? _buildWelcomeOverlay()
            : _buildSplashContent(),
      ),
    );
  }

  Widget _buildSplashContent() {
    final l10n = AppLocalizations.of(context);
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
          l10n.ridenow,
          style: AppTypography.textTheme.displayMedium?.copyWith(
            color: AppColors.primaryLight,
          ),
        ),
        AppSpacing.gapSm,
        Text(
          l10n.premiumRideSharing,
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.primaryLight.withValues(alpha: 0.7),
            letterSpacing: 1.0,
          ),
        ),
        const Spacer(),
        _BouncingDots(controller: _animationController),
        AppSpacing.gapLg,
        Text(
          l10n.version('v1.0.0'),
          style: AppTypography.textTheme.bodySmall?.copyWith(
            color: AppColors.primaryLight.withValues(alpha: 0.38),
            letterSpacing: 0.5,
          ),
        ),
        AppSpacing.gapXxl,
      ],
    );
  }

  Widget _buildWelcomeOverlay() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.xlRadius,
                boxShadow: AppShadows.large,
              ),
              child: const Icon(
                Icons.directions_car,
                size: 48,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to U-Go',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To provide the best experience:',
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryLight.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 40),
            _buildPermissionCard(
              icon: Icons.location_on,
              title: 'Location',
              description: 'Find nearby drivers and track your trip',
              granted: _locationGranted,
              deniedForever: _locationDeniedForever,
              onEnable: _enableLocation,
              onOpenSettings: _openAppSettings,
            ),
            const SizedBox(height: 16),
            _buildPermissionCard(
              icon: Icons.notifications,
              title: 'Notifications',
              description: 'Receive ride updates and messages',
              granted: _notificationGranted,
              deniedForever: _notificationDeniedForever,
              onEnable: _enableNotification,
              onOpenSettings: _openAppSettings,
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _checkSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Continue'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool granted,
    required bool deniedForever,
    required VoidCallback onEnable,
    required VoidCallback onOpenSettings,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.1),
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: granted ? AppColors.success : AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                style: AppTypography.textTheme.titleMedium?.copyWith(
                  color: AppColors.primaryLight,
                ),
              ),
              const Spacer(),
              if (granted)
                const Icon(Icons.check_circle, size: 20, color: AppColors.success),
            ],
          ),
          const SizedBox(height: 4),
          Text(description,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.primaryLight.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          if (granted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdRadius,
              ),
              child: const Center(
                child: Text('Enabled',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else if (deniedForever)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEnable,
                icon: Icon(icon, size: 16),
                label: Text('Enable $title'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdRadius,
                  ),
                ),
              ),
            ),
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
