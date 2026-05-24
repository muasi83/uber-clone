import 'package:flutter/material.dart';
import 'dart:async';
import '../services/websocket_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupWebSocketListeners();
    _startSearchTimeout();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🔍 SEARCHING FOR DRIVER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
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

      WebSocketService.rideEvents.listen((event) {
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
    _acceptanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

      // Show brief success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Driver Found!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to tracking after 2 seconds
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
                Navigator.pop(context); // Close dialog
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

  Future<void> _cancelSearch() async {
    try {
      addDebugMessage('❌ Cancelling search...');

      final token = StorageService.getToken();
      if (token == null) return;

      await RideService.cancelRide(widget.rideId, token);

      _acceptanceTimer?.cancel();
      _pulseController.stop();

      addDebugMessage('✅ Search cancelled');

      if (mounted) {
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'Finding Driver',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _cancelSearch,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated pulse
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6366F1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.local_taxi,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Status text
            Text(
              'Looking for nearby drivers...',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This may take a moment',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Search timer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Searching: ${_searchSeconds}s',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // Route info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Route',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.pickupAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.arrow_downward,
                        color: Colors.grey, size: 16),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dropoffAddress,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Cancel button
            ElevatedButton.icon(
              onPressed: _cancelSearch,
              icon: const Icon(Icons.close),
              label: const Text('Cancel Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _acceptanceTimer?.cancel();
    super.dispose();
  }
}