import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_badge.dart';

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
    with TickerProviderStateMixin {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _driverArrived = false;
  bool _rideStarting = false;
  int _remainingMinutes = 0;
  double _driverHeading = 0;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;

  Timer? _statusPollTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;

  @override
  void initState() {
    super.initState();
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
            },
          );
        }
      } catch (e) {
        addDebugMessage('Status poll error: $e');
      }
    });
  }

  Future<void> _initCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      addDebugMessage('Car icon fallback: $e');
      _carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }

  void _initializeTracking() {
    final driverLat = widget.driverData['currentLatitude'] as double?;
    final driverLng = widget.driverData['currentLongitude'] as double?;
    if (driverLat != null && driverLng != null && driverLat != 0 && driverLng != 0) {
      _driverLocation = LatLng(driverLat, driverLng);
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
  }

  void _setupWebSocketListeners() {
    try {
      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        if (!mounted) return;
        final type = event['type'] ?? '';

        if (type == 'driver_location') {
          final payload = event['payload'] ?? event;
          final lat = (payload['latitude'] ?? payload['lat']) as double?;
          final lng = (payload['longitude'] ?? payload['lng']) as double?;
          final heading = payload['heading'] as double?;

          if (lat != null && lng != null) {
            setState(() {
              final prev = _driverLocation;
              _driverLocation = LatLng(lat, lng);
              if (heading != null) {
                _driverHeading = heading;
              } else if (prev != null) {
                _driverHeading = _bearingBetween(prev, _driverLocation!);
              }
              _updateMarkers();
              _updateRoute();
              _fitBounds();
            });

            addDebugMessage('Driver location updated: $lat, $lng');
          }
        } else if (type == 'ride_started') {
          if (_rideStarting) return;
          _rideStarting = true;

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
            },
          );
        } else if (type == 'driver_arrived') {
          setState(() => _driverArrived = true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your driver has arrived!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          addDebugMessage('Driver arrived notification');
        }
      });
    } catch (e) {
      addDebugMessage('Error setting up listeners: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _carIcon,
          rotation: _driverHeading,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: InfoWindow(
            title: widget.driverData['driverName'] as String? ?? 'Driver',
          ),
        ),
      );
    }

    setState(() {});
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
    );
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
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white),
            tooltip: 'Chat with Driver',
            onPressed: _openChat,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
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
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
                                  color: i < 4
                                      ? AppColors.warning
                                      : AppColors.outlineVariant,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _showCancelRideDialog() async {
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
      final reason = result['reason'] ?? 'Rider cancelled ride';
      try {
        final token = StorageService.getToken();
        if (token == null) return;
        await RideService.cancelRide(widget.rideId, token, reason: reason);
        if (mounted) {
          WebSocketService.sendRideMessage('ride_cancelled', {
            'rideId': widget.rideId,
            'reason': reason,
          });
          Navigator.pushNamedAndRemoveUntil(context, '/rider-home', (route) => false);
        }
      } catch (e) {
        addDebugMessage('❌ Error cancelling ride: $e');
      }
    }
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    _rideEventsSub?.cancel();
    mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
