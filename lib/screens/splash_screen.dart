import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../services/storage_service.dart';
import '../services/ride_service.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../screens/auth_screen.dart';
import '../screens/rider_home_screen.dart';
import '../screens/rider_active_ride_screen.dart';
import '../screens/driver_home_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  /// Minimum time the splash logo stays visible (may extend for init).
  static const Duration _minSplashTime = Duration(seconds: 2);

  /// Exact launcher artwork, centered on white. Responsive ~2x.
  static const String _logoAsset =
      'assets/images/new_icon.png_20260910161159.jpeg';

  bool _showWelcome = false;
  bool _logoHidden = false;
  bool _welcomeRevealing = false;
  bool _locationDeniedForever = false;
  bool _notificationGranted = false;
  bool _notificationDeniedForever = false;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  /// Enforces the minimum splash hold: proceeds only after BOTH the
  /// 2-second gate elapsed AND the caller finished initialization.
  Future<void> _waitForMinSplashTime(DateTime start) async {
    final elapsed = DateTime.now().difference(start);
    if (elapsed < _minSplashTime) {
      await Future.delayed(_minSplashTime - elapsed);
    }
  }

  /// Navigates to [page] with a circular center-out reveal directly
  /// into the destination. Same destination as before, only wrapped.
  void _go(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      _CircularRevealRoute(page: page),
      (route) => false,
    );
  }

  /// Reveals the in-place permission overlay with the same circular
  /// center-out motion, then shows it. Logo hides at reveal start.
  void _revealWelcome() {
    if (!mounted || _showWelcome) return;
    setState(() {
      _logoHidden = true;
      _welcomeRevealing = true;
    });
  }

  Future<void> _initializeApp() async {
    final start = DateTime.now();
    try {
      final locationGranted = await _isLocationGranted();
      final notificationGranted = await NotificationService.isNotificationPermissionGranted();

      if (!mounted) return;

      if (locationGranted && notificationGranted) {
        await _waitForMinSplashTime(start);
        _checkSession();
      } else {
        await _waitForMinSplashTime(start);
        if (!mounted) return;
        setState(() {
          _locationGranted = locationGranted;
          _notificationGranted = notificationGranted;
          if (!locationGranted) {
            _locationDeniedForever = false;
          }
          if (!notificationGranted) {
            _notificationDeniedForever = false;
          }
        });
        _revealWelcome();
      }
    } catch (e) {
      _navigateToAuth();
    }
  }

  /// Read-only OS check of the current Location permission state.
  /// Returns true only when Location is actually granted (always/whileInUse).
  Future<bool> _isLocationGranted() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _showWelcome && mounted) {
      _refreshPermissionState();
    }
  }

  /// Re-read actual OS permission state and update the overlay UI.
  /// Called on resume; never triggers _checkSession() or navigation here.
  Future<void> _refreshPermissionState() async {
    try {
      final locationGranted = await _isLocationGranted();
      final notificationGranted = await NotificationService.isNotificationPermissionGranted();
      if (!mounted) return;
      setState(() {
        _locationGranted = locationGranted;
        _notificationGranted = notificationGranted;
        if (locationGranted) {
          _locationDeniedForever = false;
        }
        if (notificationGranted) {
          _notificationDeniedForever = false;
        }
      });
    } catch (e) {
      // Ignore refresh errors; the next render keeps the last known state.
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
            _go(DriverHomeScreen(
              userId: userId,
              username: username,
              token: token,
            ));
          } else {
            final pendingRideId = await RideService.getPendingPaymentRideId(token);
            if (pendingRideId != null && mounted) {
              final ride = await RideService.getRideDetails(pendingRideId, token);
              if (ride != null && ride.id != null && mounted) {
                _go(RiderActiveRideScreen(
                  rideId: ride.id!,
                  pickupLat: ride.pickupLatitude,
                  pickupLng: ride.pickupLongitude,
                  dropoffLat: ride.dropoffLatitude,
                  dropoffLng: ride.dropoffLongitude,
                  dropoffAddress: ride.dropoffAddress,
                ));
                return;
              }
            }

            if (!mounted) return;
            _go(const RiderHomeScreen());
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
      _go(const AuthScreen());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _showWelcome
          ? _buildWelcomeOverlay()
          : Stack(
              children: [
                _buildSplashContent(),
                if (_welcomeRevealing)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      onEnd: () {
                        if (mounted) {
                          setState(() {
                            _showWelcome = true;
                            _welcomeRevealing = false;
                          });
                        }
                      },
                      builder: (context, progress, _) {
                        return ClipPath(
                          clipper: _CircleRevealClipper(progress: progress),
                          child: _buildWelcomeOverlay(),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  double _logoSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width * 0.35).clamp(140.0, 220.0).toDouble();
  }

  double _smallLogoSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return (width * 0.18).clamp(72.0, 120.0).toDouble();
  }

  Widget _buildSplashContent() {
    if (_logoHidden) {
      return const SizedBox.expand();
    }
    final size = _logoSize(context);
    return Center(
      child: Image.asset(
        _logoAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildWelcomeOverlay() {
    final l10n = AppLocalizations.of(context);
    final smallSize = _smallLogoSize(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Image.asset(
              _logoAsset,
              width: smallSize,
              height: smallSize,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeToTaligo,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'To provide the best experience:',
              style: AppTypography.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
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
        color: AppColors.surface,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.outline,
        ),
        boxShadow: AppShadows.small,
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
                  color: AppColors.textPrimary,
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
              color: AppColors.textSecondary,
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

/// Circular center-out reveal clipper for the splash transition.
class _CircleRevealClipper extends CustomClipper<Path> {
  final double progress;

  _CircleRevealClipper({required this.progress});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius =
        math.sqrt(size.width * size.width + size.height * size.height) / 2;
    return Path()
      ..addOval(
        Rect.fromCircle(center: center, radius: maxRadius * progress),
      );
  }

  @override
  bool shouldReclip(_CircleRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Route that reveals [page] through an expanding center circle (~600ms).
class _CircularRevealRoute extends PageRouteBuilder {
  _CircularRevealRoute({required Widget page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, __, child) {
            return ClipPath(
              clipper: _CircleRevealClipper(progress: animation.value),
              child: child,
            );
          },
        );
}
