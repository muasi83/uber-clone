import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';

class RiderSearchingDriverScreen extends StatefulWidget {
  final int rideId;
  final String pickupAddress;
  final String dropoffAddress;
  final double estimatedFare;

  const RiderSearchingDriverScreen({
    super.key,
    required this.rideId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.estimatedFare,
  });

  @override
  State<RiderSearchingDriverScreen> createState() =>
      _RiderSearchingDriverScreenState();
}

class _RiderSearchingDriverScreenState extends State<RiderSearchingDriverScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _driverFound = false;
  bool _showTimeoutDialog = false;
  Timer? _acceptanceTimer;
  int _searchSeconds = 0;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _ensureWebSocketConnected();
    _setupWebSocketListeners();
    _startSearchTimeout();
    _startPolling();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🔍 SEARCHING FOR DRIVER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  void _ensureWebSocketConnected() {
    if (!WebSocketService.isConnected()) {
      final userId = StorageService.getUserId();
      final username = StorageService.getUsername();
      if (userId != null && username != null) {
        addDebugMessage('🔌 Connecting WebSocket for rider...');
        WebSocketService.connect(userId, username);
      }
    }
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_driverFound || !mounted) return;
      _checkRideStatus();
    });
  }

  Future<void> _checkRideStatus() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;

      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || !mounted) return;

      if (ride.status == 'ACCEPTED' && ride.driver != null) {
        addDebugMessage('✅ Poll detected ride ACCEPTED by ${ride.driver!.fullName}');

        _handleRideAccepted({
          'payload': {
            'rideId': widget.rideId,
            'driverName': ride.driver!.fullName,
            'driverId': ride.driver!.id,
            'pickupLatitude': ride.pickupLatitude,
            'pickupLongitude': ride.pickupLongitude,
            'vehicleColor': '',
            'vehicleModel': '',
            'licensePlate': '',
          },
        });
      }
    } catch (e) {
      addDebugMessage('⚠️ Poll error: $e');
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _setupWebSocketListeners() {
    try {
      addDebugMessage('🔌 Setting up WebSocket listeners for searching...');

      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        final type = event['type'] ?? '';
        addDebugMessage('📡 Ride event received: $type');

        if (type == 'ride_accepted') {
          _handleRideAccepted(event);
        } else if (type == 'search_timeout') {
          _showSearchTimeoutDialog();
        } else if (type == 'ride_cancelled') {
          _handleRideCancelled(event);
        }
      });

      addDebugMessage('✅ WebSocket listeners configured');
    } catch (e) {
      addDebugMessage('❌ Error setting up listeners: $e');
    }
  }

  void _startSearchTimeout() {
    _acceptanceTimer?.cancel();
    _acceptanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _searchSeconds++);

      if (_searchSeconds >= 60 && !_showTimeoutDialog) {
        addDebugMessage('⏰ 60 seconds passed - showing timeout dialog');
        _showSearchTimeoutDialog();
      }
    });
  }

  void _handleRideAccepted(Map<String, dynamic> event) {
    addDebugMessage('✅ RIDE ACCEPTED EVENT');
    addDebugMessage('Driver: ${event['payload']?['driverName'] ?? 'Unknown'}');

    if (mounted) {
      setState(() {
        _driverFound = true;
      });

      _acceptanceTimer?.cancel();
      _pulseController.stop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Driver Found!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/rider-tracking',
            arguments: {
              'rideId': widget.rideId,
              'driverData': event['payload'],
            },
          );
        }
      });
    }
  }

  void _handleRideCancelled(Map<String, dynamic> event) {
    addDebugMessage('❌ Ride cancelled: ${event['reason'] ?? 'Unknown'}');

    _acceptanceTimer?.cancel();
    _pulseController.stop();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 48),
          title: const Text('Ride Cancelled'),
          content: Text(event['reason'] ?? 'Your ride was cancelled'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/rider-home',
                  (route) => false,
                );
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      );
    }
  }

  void _showSearchTimeoutDialog() {
    if (_showTimeoutDialog || _driverFound) return;

    setState(() => _showTimeoutDialog = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.access_time, color: Colors.orange, size: 48),
          title: const Text('No Drivers Available'),
          content: const Text(
            'We couldn\'t find a driver nearby. Would you like to continue searching?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelSearch();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _continueSearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _continueSearch() async {
    try {
      addDebugMessage('🔄 Continuing search with expanded radius...');

      final token = StorageService.getToken();
      if (token == null) return;

      await RideService.continueSearch(widget.rideId, token);

      setState(() {
        _showTimeoutDialog = false;
        _searchSeconds = 0;
      });

      _startSearchTimeout();

      addDebugMessage('✅ Search resumed');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Continuing search with expanded radius...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error continuing search: $e');
    }
  }

  Future<void> _showCancelSearchDialog() async {
    final reasonController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this ride?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, {'action': 'no'}), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'action': 'yes', 'reason': reasonController.text.trim()}),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result != null && result['action'] == 'yes' && mounted) {
      await _cancelSearch(result['reason'] ?? 'Rider cancelled search');
    }
  }

  Future<void> _cancelSearch([String reason = 'Rider cancelled search']) async {
    try {
      addDebugMessage('❌ Cancelling search...');

      final token = StorageService.getToken();
      if (token == null) return;

      await RideService.cancelRide(widget.rideId, token, reason: reason);

      _acceptanceTimer?.cancel();
      _pulseController.stop();

      addDebugMessage('✅ Search cancelled');

      if (mounted) {
        WebSocketService.sendRideMessage('ride_cancelled', {
          'rideId': widget.rideId,
          'reason': reason,
        });

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/rider-home',
          (route) => false,
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error cancelling search: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressString = List.generate(3, (i) {
      final cycle = (_searchSeconds % 3);
      return i <= cycle ? '.' : '  ';
    }).join(' ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelSearchDialog();
      },
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: _driverFound
            ? _buildDriverFoundContent()
            : _buildSearchingContent(progressString),
      ),
    ),
    );
  }

  Widget _buildSearchingContent(String progressString) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_taxi,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppSpacing.gapHuge,
            const Text(
              'Finding your driver',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapMd,
            Text(
              'Searching nearby drivers$progressString',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Text(
                '${_searchSeconds}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.colossal),
              child: PremiumButton(
                label: 'Cancel Search',
                onPressed: _cancelSearch,
                variant: ButtonVariant.outline,
                icon: Icons.close,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverFoundContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: Colors.green,
            ),
          ),
          AppSpacing.gapXl,
          const Text(
            'Driver Found!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.gapSm,
          Text(
            'Redirecting to tracking...',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _acceptanceTimer?.cancel();
    _pollTimer?.cancel();
    _rideEventsSub?.cancel();
    super.dispose();
  }
}
