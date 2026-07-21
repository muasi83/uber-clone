import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';

class RiderLocationPermissionScreen extends StatefulWidget {
  final Function(bool) onPermissionResult;

  const RiderLocationPermissionScreen({
    super.key,
    required this.onPermissionResult,
  });

  @override
  State<RiderLocationPermissionScreen> createState() =>
      _RiderLocationPermissionScreenState();
}

class _RiderLocationPermissionScreenState
    extends State<RiderLocationPermissionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _bounceController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('📍 LOCATION PERMISSION SCREEN LOADED');
    addDebugMessage('═══════════════════════════════════════');

    _checkLocationService();

    // Bounce animation for pin icon
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    // Pulse animation for button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  Future<void> _checkLocationService() async {
    try {
      final isEnabled = await LocationService.isLocationServiceEnabled();
      if (!isEnabled) {
        addDebugMessage('⚠️ Location services disabled');
      }
    } catch (e) {
      addDebugMessage('❌ Error checking location service: $e');
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔐 REQUESTING LOCATION PERMISSION');

      final permission = await LocationService.requestLocationPermission();

      addDebugMessage('Permission result: $permission');

      if (permission == LocationPermission.denied) {
        addDebugMessage('❌ Permission denied by user');
        if (mounted) {
          _showError('Location permission is required to request rides');
        }
        widget.onPermissionResult(false);
      } else if (permission == LocationPermission.deniedForever) {
        addDebugMessage('❌ Permission denied forever');
        if (mounted) {
          _showSettingsDialog();
        }
        widget.onPermissionResult(false);
      } else if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        addDebugMessage('✅ Location permission granted!');
        if (mounted) {
          _showSuccess('Location permission granted!');
          Future.delayed(const Duration(seconds: 1), () {
            widget.onPermissionResult(true);
          });
        }
      }

      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        _showError('Error requesting permission: $e');
      }
      widget.onPermissionResult(false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission was denied permanently. Please enable it in app settings to use RideNow.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onPermissionResult(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              LocationService.openAppSettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        widget.onPermissionResult(false);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated location pin icon
                ScaleTransition(
                  scale: Tween(begin: 0.85, end: 1.1).animate(
                    CurvedAnimation(
                      parent: _bounceController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                AppSpacing.gapXxxl,
                const Text(
                  'Enable Location',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                AppSpacing.gapMd,
                const Text(
                  'We need your location to find nearby drivers and provide accurate ETAs',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 1),
                // Pulse animation on button
                ScaleTransition(
                  scale: Tween(begin: 0.98, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _pulseController,
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: PremiumButton(
                    label: 'Enable Location',
                    onPressed:
                        _isLoading ? null : _requestLocationPermission,
                    isLoading: _isLoading,
                    icon: Icons.location_on,
                  ),
                ),
                AppSpacing.gapLg,
                TextButton(
                  onPressed: () {
                    addDebugMessage('⏭️ User skipped location permission');
                    widget.onPermissionResult(false);
                  },
                  child: const Text(
                    'Not Now',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
