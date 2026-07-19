import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/driver_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_badge.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../utils/bearing_utils.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../services/recorded_screen_mixin.dart';
import '../services/event_recorder_service.dart';

class RiderTrackingScreen extends StatefulWidget {
  final int rideId;
  final Map<String, dynamic> driverData;

  const RiderTrackingScreen({
    super.key,
    required this.rideId,
    required this.driverData,
  });

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen>
    with TickerProviderStateMixin, RecordedScreenMixin<RiderTrackingScreen> {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _driverArrived = false;
  bool _rideStarting = false;
  int _remainingMinutes = 0;
  double _driverHeading = 0;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;
  bool _userInteracted = false;
  int _suppressCameraMove = 0;

  Timer? _driverAnimTimer;
  LatLng? _animatedDriverPos;

  Timer? _statusPollTimer;
  Timer? _routeDebounceTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocEventsSub;
  double _driverRating = 4.0;

  @override
  void initState() {
    super.initState();
    recordEvent(
      eventName: 'SCREEN_OPENED',
      category: 'FRONTEND',
      summary: 'RiderTrackingScreen opened',
    );
    _loadMapStyle();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initializeTracking();
    _setupWebSocketListeners();
    _startStatusPolling();
    _initCarIcon();
    _initYellowPin();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('TRACKING DRIVER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final token = StorageService.getToken();
        if (token == null) return;
        final ride = await RideService.getRideDetails(widget.rideId, token);
        if (ride == null || !mounted) return;

        if (ride.status == 'CANCELLED') {
          addDebugMessage('❌ Poll detected ride CANCELLED');
          _statusPollTimer?.cancel();
          ChatScreen.clearAllCache();
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 48),
                title: const Text('Ride Cancelled'),
                content: Text(ride.cancellationReason ?? 'The ride was cancelled'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
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
          return;
        }

        if (ride.status == 'STARTED') {
          if (_rideStarting) return;
          _rideStarting = true;
          addDebugMessage('Poll detected ride STARTED');
          _statusPollTimer?.cancel();
          Navigator.pushReplacementNamed(
            context,
            '/rider-active-ride',
            arguments: {
              'rideId': widget.rideId,
              'pickupLat': ride.pickupLatitude,
              'pickupLng': ride.pickupLongitude,
              'dropoffLat': ride.dropoffLatitude,
              'dropoffLng': ride.dropoffLongitude,
              'dropoffAddress': ride.dropoffAddress,
              'driverLat': _driverLocation?.latitude,
              'driverLng': _driverLocation?.longitude,
            },
          );
        }
      } catch (e) {
        addDebugMessage('Status poll error: $e');
      }
    });
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      addDebugMessage('Car icon fallback: $e');
      _carIcon = await MarkerFactory.driver;
    }
    if (mounted) _updateMarkers();
  }

  void _initializeTracking() {
    final driverLat = widget.driverData['currentLatitude'] as double?;
    final driverLng = widget.driverData['currentLongitude'] as double?;
    if (driverLat != null && driverLng != null && driverLat != 0 && driverLng != 0) {
      _driverLocation = LatLng(driverLat, driverLng);
    } else {
      // Fetch driver location from ride details if not in driverData
      _fetchDriverLocationFromRide();
    }

    _pickupLocation = LatLng(
      widget.driverData['pickupLatitude'] as double? ??
          widget.driverData['pickupLat'] as double? ??
          0,
      widget.driverData['pickupLongitude'] as double? ??
          widget.driverData['pickupLng'] as double? ??
          0,
    );

    _updateMarkers();
    _updateRoute();
    _loadDriverRating();
  }

  Future<void> _fetchDriverLocationFromRide() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || ride.driver == null || !mounted) return;
      // Ride model doesn't have driver location, so we try nearby drivers as fallback
      addDebugMessage('Fetching driver location from API...');
      final drivers = await DriverService.getNearbyDrivers(
        latitude: widget.driverData['pickupLatitude'] as double? ?? 0,
        longitude: widget.driverData['pickupLongitude'] as double? ?? 0,
        radiusKm: 5.0,
      );
      if (!mounted || ride.driver == null) return;
      final driverId = ride.driver!.id;
      for (final d in drivers) {
        if (d.user.id == driverId && d.currentLatitude != null && d.currentLongitude != null) {
          setState(() {
            _driverLocation = LatLng(d.currentLatitude!, d.currentLongitude!);
          });
          _updateMarkers();
          _fitBounds();
          addDebugMessage('✅ Driver location from nearby API');
          return;
        }
      }
      addDebugMessage('⏳ Awaiting first driver_location WS event');
    } catch (e) {
      addDebugMessage('⚠️ Could not fetch driver location: $e');
    }
  }

  void _loadDriverRating() {
    final rating = widget.driverData['averageRating'];
    if (rating != null) {
      _driverRating = (rating as num).toDouble();
    } else {
      _fetchRatingFromRideDetails();
    }
  }

  Future<void> _fetchRatingFromRideDetails() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride != null && ride.driverAverageRating != null && mounted) {
        setState(() => _driverRating = ride.driverAverageRating!);
      }
    } catch (e) {
      addDebugMessage('⚠️ Could not fetch driver rating: $e');
    }
  }

  void _setupWebSocketListeners() {
    try {
      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        if (!mounted) return;
        final type = event['type'] ?? '';

        if (type == 'driver_location') {
          _handleDriverLocationEvent(event);
        } else if (type == 'ride_started') {
          if (_rideStarting) return;
          _rideStarting = true;
          recordEvent(
            eventName: 'RIDE_STARTED',
            category: 'FRONTEND',
            summary: 'Ride started event received',
          );

          addDebugMessage('Ride started — navigating to active ride');
          final payload = event['payload'] as Map<String, dynamic>? ?? {};
          Navigator.pushReplacementNamed(
            context,
            '/rider-active-ride',
            arguments: {
              'rideId': widget.rideId,
              'pickupLat': widget.driverData['pickupLatitude'] ?? 0,
              'pickupLng': widget.driverData['pickupLongitude'] ?? 0,
              'dropoffLat': payload['dropoffLatitude'] ?? widget.driverData['dropoffLatitude'] ?? 0,
              'dropoffLng': payload['dropoffLongitude'] ?? widget.driverData['dropoffLongitude'] ?? 0,
              'dropoffAddress': payload['dropoffAddress'] ?? widget.driverData['dropoffAddress'] ?? '',
              'driverLat': _driverLocation?.latitude,
              'driverLng': _driverLocation?.longitude,
            },
          );
        } else if (type == 'driver_arrived') {
          setState(() => _driverArrived = true);
          recordEvent(
            eventName: 'DRIVER_ARRIVED',
            category: 'FRONTEND',
            summary: 'Driver arrived at pickup',
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your driver has arrived!'),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 5),
            ),
          );

          addDebugMessage('Driver arrived notification');
        } else if (type == 'ride_cancelled') {
          recordEvent(
            eventName: 'RIDE_CANCELLED',
            category: 'FRONTEND',
            summary: 'Ride cancelled event received',
          );
          addDebugMessage('❌ Ride cancelled by driver');
          ChatScreen.clearAllCache();
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 48),
                title: const Text('Ride Cancelled'),
                content: Text(event['reason'] as String? ?? 'The driver cancelled the ride'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
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
      });

      _driverLocEventsSub = WebSocketService.driverLocationEvents.listen((event) {
        if (!mounted) return;
        final type = event['type'] ?? '';
        if (type == 'driver_location' || type == 'driver_heading') {
          _handleDriverLocationEvent(event);
        }
      });
    } catch (e) {
      addDebugMessage('Error setting up listeners: $e');
    }
  }

  Widget _buildUnreadBadge() {
    final driverId = widget.driverData['driverId'] as int?;
    if (driverId == null) return const SizedBox.shrink();
    final count = WebSocketService.unreadCounts[driverId] ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _handleDriverLocationEvent(Map<String, dynamic> event) {
    final payload = event['payload'] ?? event;
    final lat = (payload['latitude'] ?? payload['lat']) as double?;
    final lng = (payload['longitude'] ?? payload['lng']) as double?;

    if (lat != null && lng != null) {
      final prev = _driverLocation;
      final newLoc = LatLng(lat, lng);
      _driverLocation = newLoc;
      final heading = payload['heading'];
      if (heading != null) {
        _driverHeading = (heading as num).toDouble();
      } else if (prev != null) {
        _driverHeading = _bearingBetween(prev, _driverLocation!);
      }
      _startDriverMarkerAnimation(newLoc);
      if (!_userInteracted) _fitBounds();
      _routeDebounceTimer?.cancel();
      _routeDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) _updateRoute();
      });
    }
  }

  void _updateMarkers() {
    final updated = <Marker>{};

    if (_pickupLocation != null) {
      updated.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: _yellowPinMarker,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    final driverPos = _animatedDriverPos ?? _driverLocation;
    if (driverPos != null) {
      addDebugMessage('_updateMarkers rotation=$_driverHeading');
      updated.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPos,
          icon: _carIcon,
          rotation: normalizeCarHeading(_driverHeading % 360),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: InfoWindow(
            title: widget.driverData['driverName'] as String? ?? 'Driver',
          ),
        ),
      );
    }

    _markers = updated;
  }

  void _startDriverMarkerAnimation(LatLng target) {
    _driverAnimTimer?.cancel();
    final from = _animatedDriverPos ?? target;
    final steps = 30;
    var step = 0;
    _driverAnimTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();
      _animatedDriverPos = LatLng(
        from.latitude + (target.latitude - from.latitude) * eased,
        from.longitude + (target.longitude - from.longitude) * eased,
      );
      _updateMarkers();
      if (mounted) setState(() {});
      if (step >= steps) {
        _driverAnimTimer?.cancel();
        _driverAnimTimer = null;
        _animatedDriverPos = target;
        _updateMarkers();
        if (mounted) setState(() {});
      }
    });
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _pickupLocation!,
      );

      if (route != null && route.isSuccess && mounted) {
        _polylines.clear();

        if (route.polylinePoints != null &&
            route.polylinePoints!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.primary,
              width: 5,
              geodesic: true,
            ),
          );
        }

        setState(() {
          _remainingMinutes = route.durationMinutes ?? 0;
        });
      }
    } catch (e) {
      addDebugMessage('Route error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_driverLocation == null || _pickupLocation == null) return;

    _suppressCameraMove++;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _pickupLocation!.latitude
            ? _driverLocation!.latitude - 0.01
            : _pickupLocation!.latitude - 0.01,
        _driverLocation!.longitude < _pickupLocation!.longitude
            ? _driverLocation!.longitude - 0.01
            : _pickupLocation!.longitude - 0.01,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _pickupLocation!.latitude
            ? _driverLocation!.latitude + 0.01
            : _pickupLocation!.latitude + 0.01,
        _driverLocation!.longitude > _pickupLocation!.longitude
            ? _driverLocation!.longitude + 0.01
            : _pickupLocation!.longitude + 0.01,
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    ).then((_) {
      _suppressCameraMove--;
    }).catchError((_) {
      _suppressCameraMove--;
    });
  }

  double _bearingBetween(LatLng from, LatLng to) {
    final dLon = _toRadians(to.longitude - from.longitude);
    final fromLat = _toRadians(from.latitude);
    final toLat = _toRadians(to.latitude);
    final y = math.sin(dLon) * math.cos(toLat);
    final x = math.cos(fromLat) * math.sin(toLat) -
        math.sin(fromLat) * math.cos(toLat) * math.cos(dLon);
    return (_toDegrees(math.atan2(y, x)) + 360) % 360;
  }

  double _toRadians(double deg) => deg * math.pi / 180;
  double _toDegrees(double rad) => rad * 180 / math.pi;



  Future<void> _openChat() async {
    final token = StorageService.getToken();
    final currentUserId = StorageService.getUserId();
    final currentUsername = StorageService.getUsername();
    if (token == null || currentUserId == null || currentUsername == null) return;

    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || ride.driver == null || ride.driver!.id == null) return;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              receiverId: ride.driver!.id!,
              receiverName: ride.driver!.fullName,
              token: token,
              rideId: widget.rideId,
            ),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('Chat error: $e');
    }
  }

  String _driverName() =>
      widget.driverData['driverName'] as String? ?? 'Driver';

  String _vehicleInfo() =>
      '${widget.driverData['vehicleColor'] as String? ?? ''} ${widget.driverData['vehicleModel'] as String? ?? ''} • ${widget.driverData['licensePlate'] as String? ?? 'N/A'}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showCancelRideDialog();
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
          onPressed: () => _showCancelRideDialog(),
        ),
        title: const Text(
          'Trip to Destination',
          style: TextStyle(
            color: AppColors.primaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                tooltip: 'Chat with Driver',
                onPressed: _openChat,
              ),
              _buildUnreadBadge(),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: (_) {
              if (_suppressCameraMove == 0) {
                _userInteracted = true;
              }
            },
            initialCameraPosition: CameraPosition(
              target: (_driverLocation != null && _driverLocation!.latitude != 0)
                  ? _driverLocation!
                  : _pickupLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            padding: const EdgeInsets.only(bottom: 220),
            style: _mapStyle,
          ),

          if (_userInteracted)
            Positioned(
              right: 16,
              bottom: 240,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                onPressed: () {
                  setState(() {
                    _userInteracted = false;
                    _fitBounds();
                  });
                },
                backgroundColor: AppColors.surface,
                child: const Icon(Icons.my_location, color: AppColors.primary),
              ),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusXxl),
                ),
                boxShadow: AppSpacing.shadowXl,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl + 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          _driverName().isNotEmpty
                              ? _driverName()[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverName(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              _vehicleInfo(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Row(
                              children: List.generate(5, (i) {
                                return Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: i < _driverRating.round()
                                      ? AppColors.warning
                                      : AppColors.outlineVariant,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.chat_rounded,
                                  color: AppColors.primary, size: 20),
                              onPressed: _openChat,
                            ),
                          ),
                          _buildUnreadBadge(),
                        ],
                      ),
                    ],
                  ),
                  AppSpacing.gapXl,

                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (!_driverArrived)
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, _) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primary.withValues(alpha: 0.2),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _driverArrived
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.hGapSm,
                      StatusBadge(
                        label: _driverArrived
                            ? 'Arrived'
                            : 'Arriving',
                        color: _driverArrived
                            ? AppColors.success
                            : AppColors.primary,
                        icon: _driverArrived
                            ? Icons.check_circle
                            : Icons.navigation,
                      ),
                      const Spacer(),
                      if (_remainingMinutes > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            AppSpacing.hGapXs,
                            Text(
                              '$_remainingMinutes min',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  Text(
                    _driverArrived
                        ? 'Meet your driver at the pickup location'
                        : 'Approaching your pickup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  AppSpacing.gapLg,

                  if (!_driverArrived)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: AppColors.outline.withValues(alpha: 0.5),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _showCancelRideDialog() async {
    final result = await showCancelRideDialog(context);
    if (result != null && result.confirmed && mounted) {
      final reason = result.reason;
      try {
        final token = StorageService.getToken();
        if (token == null) return;
        final success = await RideService.cancelRide(widget.rideId, token, reason: reason);
        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to cancel ride. Please try again.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
        ChatScreen.clearAllCache();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/rider-home', (route) => false);
        }
      } catch (e) {
        addDebugMessage('❌ Error cancelling ride: $e');
      }
    }
  }

  @override
  void dispose() {
    _rideStarting = false;
    _driverAnimTimer?.cancel();
    _statusPollTimer?.cancel();
    _routeDebounceTimer?.cancel();
    _rideEventsSub?.cancel();
    _driverLocEventsSub?.cancel();
    mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
