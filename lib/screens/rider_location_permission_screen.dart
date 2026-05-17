import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../screens/debug_screen.dart';

class RiderLocationPermissionScreen extends StatefulWidget {
  final Function(bool) onPermissionResult;

  const RiderLocationPermissionScreen({
    Key? key,
    required this.onPermissionResult,
  }) : super(key: key);

  @override
  State<RiderLocationPermissionScreen> createState() =>
      _RiderLocationPermissionScreenState();
}

class _RiderLocationPermissionScreenState
    extends State<RiderLocationPermissionScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _serviceEnabled = false;
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
      setState(() {
        _serviceEnabled = isEnabled;
      });

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

  Future<void> _enableLocationServices() async {
    try {
      addDebugMessage('Opening location settings...');
      await LocationService.openLocationSettings();

      // Check again after settings
      Future.delayed(const Duration(seconds: 2), () {
        _checkLocationService();
      });
    } catch (e) {
      addDebugMessage('❌ Error opening settings: $e');
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission was denied permanently. Please enable it in app settings to use Uber Clone.',
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
              style: TextStyle(color: Color(0xFF6366F1)),
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onPermissionResult(false);
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),

                    // Animated Location Pin Icon
                    Center(
                      child: ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.1).animate(
                          CurvedAnimation(
                            parent: _bounceController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.location_on,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title
                    const Text(
                      'Location Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'We need your location to help you find nearby drivers and complete your rides safely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Status Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Location Services Status
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _serviceEnabled
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                                child: Icon(
                                  _serviceEnabled
                                      ? Icons.check
                                      : Icons.warning,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location Services',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _serviceEnabled
                                          ? 'Enabled on your device'
                                          : 'Disabled - Please enable',
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (!_serviceEnabled) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _enableLocationServices,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Enable Location Services',
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Benefits List
                    _buildBenefitItem(
                      icon: Icons.directions_car,
                      title: 'Find Nearby Drivers',
                      subtitle: 'Quickly connect with drivers in your area',
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitItem(
                      icon: Icons.map,
                      title: 'Accurate Navigation',
                      subtitle: 'Get precise pickup and dropoff locations',
                    ),
                    const SizedBox(height: 16),
                    _buildBenefitItem(
                      icon: Icons.security,
                      title: 'Safe & Secure',
                      subtitle: 'Your location is encrypted and private',
                    ),

                    const SizedBox(height: 48),

                    // Main Button with Pulse Animation
                    ScaleTransition(
                      scale: Tween(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _requestLocationPermission,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.white.withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF6366F1),
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      color: Color(0xFF6366F1),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Enable Location Services',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Skip Button
                    TextButton(
                      onPressed: () {
                        addDebugMessage('⏭️ User skipped location permission');
                        widget.onPermissionResult(false);
                      },
                      child: const Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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