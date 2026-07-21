import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/websocket_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/event_recorder_service.dart';
import '../services/ui_event_recorder.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/map_style_loader.dart';
import '../widgets/premium_button.dart';
import '../widgets/cancel_ride_dialog.dart';

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

  String? _mapStyle;
  LatLng? _currentLocation;
  Set<Circle> _searchCircles = {};

  @override
  void initState() {
    super.initState();
    UiEventRecorder.setCurrentRideId(widget.rideId);
    UiEventRecorder.setCurrentScreen('RiderSearchingDriver');
    _setupAnimations();
    _ensureWebSocketConnected();
    _setupWebSocketListeners();
    _startSearchTimeout();
    _startPolling();
    _loadMapStyle();
    _initCurrentLocation();

    EventRecorderService.recordEvent(
      rideId: widget.rideId,
      eventName: 'DRIVER_SEARCH_STARTED',
      category: 'BUSINESS',
      summary: 'Searching for nearby drivers',
      screenName: 'RiderSearchingDriver',
    );

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

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
    if (mounted) setState(() {});
  }

  Future<void> _initCurrentLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (loc != null && mounted) {
      setState(() {
        _currentLocation = LatLng(loc.latitude, loc.longitude);
        _updateSearchCircles();
      });
    }
  }

  void _updateSearchCircles() {
    if (_currentLocation == null) return;
    final baseRadius = 300.0 + (_searchSeconds * 5);
    final pulseOffset = _pulseAnimation.value * 200.0;
    _searchCircles = {
      Circle(
        circleId: const CircleId('search_radius'),
        center: _currentLocation!,
        radius: baseRadius + pulseOffset,
        fillColor: AppColors.primaryLight.withValues(alpha: 0.06),
        strokeColor: AppColors.primaryLight.withValues(alpha: 0.25),
        strokeWidth: 2,
      ),
      Circle(
        circleId: const CircleId('search_dot'),
        center: _currentLocation!,
        radius: 8,
        fillColor: AppColors.primaryLight,
        strokeColor: AppColors.primaryLight,
        strokeWidth: 0,
      ),
    };
  }

  Future<void> _checkRideStatus() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;

      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || !mounted) return;

      if (ride.status == 'CANCELLED') {
        addDebugMessage('❌ Poll detected ride CANCELLED');
        _handleRideCancelled({
          'reason': ride.cancellationReason ?? 'Your ride was cancelled',
        });
        return;
      }

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
            'averageRating': ride.driverAverageRating ?? 4.0,
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
    )..addListener(_onPulseTick);
  }

  void _onPulseTick() {
    if (mounted && _currentLocation != null) {
      _updateSearchCircles();
    }
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
        } else if (type == 'women_driver_timeout') {
          _showWomenDriverTimeoutDialog();
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
      setState(() {
        _searchSeconds++;
        if (_currentLocation != null) _updateSearchCircles();
      });
    });
  }

  void _handleRideAccepted(Map<String, dynamic> event) {
    addDebugMessage('✅ RIDE ACCEPTED EVENT');
    addDebugMessage('Driver: ${event['payload']?['driverName'] ?? 'Unknown'}');

    EventRecorderService.recordEvent(
      rideId: widget.rideId,
      eventName: 'DRIVER_FOUND',
      category: 'BUSINESS',
      summary: 'Driver ${event['payload']?['driverName'] ?? 'Unknown'} accepted the ride',
      screenName: 'RiderSearchingDriver',
      extraDetails: {
        'driverId': event['payload']?['driverId'],
        'driverName': event['payload']?['driverName'],
      },
    );

    if (mounted) {
      setState(() {
        _driverFound = true;
      });

      _acceptanceTimer?.cancel();
      _pollTimer?.cancel();
      _pulseController.stop();

      UiEventRecorder.showSnackBar(
        context: context,
        message: '🎉 Driver Found!',
        type: 'success',
        triggerReason: 'ride_accepted_event',
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

    EventRecorderService.recordEvent(
      rideId: widget.rideId,
      eventName: 'RIDE_CANCELLED',
      category: 'BUSINESS',
      summary: 'Ride cancelled: ${event['reason'] ?? 'Unknown reason'}',
      screenName: 'RiderSearchingDriver',
    );

    if (mounted) {
      UiEventRecorder.showDialog(
        context: context,
        dialogType: 'RideCancelled',
        dialogText: event['reason'] ?? 'Your ride was cancelled',
        triggerReason: 'ride_cancelled_event',
        buttons: ['Back to Home'],
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 48),
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

    EventRecorderService.recordEvent(
      rideId: widget.rideId,
      eventName: 'SEARCH_TIMEOUT',
      category: 'BUSINESS',
      summary: 'No driver found after 60 seconds timeout',
      screenName: 'RiderSearchingDriver',
    );

    if (mounted) {
      UiEventRecorder.showDialog(
        context: context,
        dialogType: 'SearchTimeout',
        dialogText: 'No drivers available nearby',
        triggerReason: '60_second_search_timeout',
        buttons: ['Cancel', 'Continue'],
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.access_time, color: AppColors.warning, size: 48),
          title: const Text('No Drivers Available'),
          content: const Text(
            'We couldn\'t find a driver nearby. Would you like to continue searching?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'cancel');
                _cancelSearch();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'continue');
                _continueSearch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  void _showWomenDriverTimeoutDialog() {
    if (_showTimeoutDialog || _driverFound) return;

    setState(() => _showTimeoutDialog = true);

    EventRecorderService.recordEvent(
      rideId: widget.rideId,
      eventName: 'WOMEN_DRIVER_TIMEOUT',
      category: 'BUSINESS',
      summary: 'No female driver found after 60 seconds',
      screenName: 'RiderSearchingDriver',
    );

    if (mounted) {
      UiEventRecorder.showDialog(
        context: context,
        dialogType: 'WomenDriverTimeout',
        dialogText: 'No women drivers found nearby',
        triggerReason: '60_second_women_driver_timeout',
        buttons: ['Cancel', 'Economy', 'Luxury'],
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.face, color: AppColors.warning, size: 48),
          title: const Text('No Women Drivers Found'),
          content: const Text(
            'No female drivers are available right now. '
            'Would you like to switch to a different ride type?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelSearch();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.error),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchRideType('ECONOMY');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Economy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _switchRideType('LUXURY');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Luxury'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _switchRideType(String newRideType) async {
    try {
      addDebugMessage('🔄 Switching to $newRideType...');

      EventRecorderService.recordEvent(
        rideId: widget.rideId,
        eventName: 'RIDE_TYPE_SWITCHED',
        category: 'BUSINESS',
        summary: 'Rider switched from WOMEN_DRIVER to $newRideType',
        screenName: 'RiderSearchingDriver',
      );

      final token = StorageService.getToken();
      if (token == null) return;

      final ride = await RideService.changeRideType(widget.rideId, newRideType, token);
      if (ride == null) {
        addDebugMessage('❌ Failed to switch ride type');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to switch ride type. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _showTimeoutDialog = false;
        _searchSeconds = 0;
      });

      _startSearchTimeout();

      addDebugMessage('✅ Ride type switched to $newRideType');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Searching for $newRideType drivers...'),
            backgroundColor: AppColors.info,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error switching ride type: $e');
    }
  }

  Future<void> _continueSearch() async {
    try {
      addDebugMessage('🔄 Continuing search with expanded radius...');

      EventRecorderService.recordEvent(
        rideId: widget.rideId,
        eventName: 'DRIVER_SEARCH_EXPANDED',
        category: 'BUSINESS',
        summary: 'Rider chose to continue searching with expanded radius',
        screenName: 'RiderSearchingDriver',
      );

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
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error continuing search: $e');
    }
  }

  Future<void> _showCancelSearchDialog() async {
    final result = await showCancelRideDialog(context);
    if (result != null && result.confirmed && mounted) {
      await _cancelSearch(result.reason);
    }
  }

  Future<void> _cancelSearch([String reason = 'Rider cancelled search']) async {
    try {
      addDebugMessage('❌ Cancelling search...');

      final token = StorageService.getToken();
      if (token == null) return;

      final success = await RideService.cancelRide(widget.rideId, token, reason: reason);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel search. Please try again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

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
    final progressString = List.generate(3, (i) {
      final cycle = (_searchSeconds % 3);
      return i <= cycle ? '.' : '  ';
    }).join(' ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelSearchDialog();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Stack(
            children: [
              if (_currentLocation != null && _mapStyle != null)
                Semantics(
                  label: 'Map showing search area',
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation!,
                      zoom: 14,
                    ),
                    circles: _searchCircles,
                    style: _mapStyle,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    myLocationEnabled: false,
                    compassEnabled: false,

                  ),
                ),
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary,
                      Color(0xBF1A237E),
                      Color(0x991A237E),
                    ],
                  ),
                ),
                child: _driverFound
                    ? _buildDriverFoundContent()
                    : _buildSearchingContent(progressString),
              ),
            ],
          ),
        ),
      ));
  }

  Widget _buildSearchingContent(String progressString) {
    return Semantics(
      label: 'Searching for nearby drivers',
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Searching animation',
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withValues(alpha: 0.15),
                    ),
                    child: Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight.withValues(alpha: 0.24),
                        ),
                        child: Center(
                          child: Semantics(
                            label: 'Taxi icon',
                            child: const Icon(
                              Icons.local_taxi,
                              color: AppColors.primaryLight,
                              size: 54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapHuge,
              Semantics(
                label: 'Finding your driver',
                child: const Text(
                  'Finding your driver',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.gapMd,
              Semantics(
                label: 'Search progress $progressString',
                child: Text(
                  'Searching nearby drivers$progressString',
                  style: TextStyle(
                    color: AppColors.primaryLight.withValues(alpha: 0.7),
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.gapXl,
              Semantics(
                label: 'Search duration $_searchSeconds seconds',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(1000),
                  ),
                  child: Text(
                    '${_searchSeconds}s',
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.colossal),
                child: PremiumButton(
                  label: 'Cancel Search',
                  onPressed: _cancelSearch,
                  variant: ButtonVariant.danger,
                  icon: Icons.close,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverFoundContent() {
    return Semantics(
      label: 'Driver found',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: 'Success checkmark',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(1000),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
            ),
            AppSpacing.gapXl,
            Semantics(
              label: 'Driver found',
              child: const Text(
                'Driver Found!',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            AppSpacing.gapSm,
            Semantics(
              label: 'Redirecting to tracking',
              child: Text(
                'Redirecting to tracking...',
                style: TextStyle(
                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
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
    _pollTimer?.cancel();
    _rideEventsSub?.cancel();
    super.dispose();
  }
}
