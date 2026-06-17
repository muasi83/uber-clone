import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/directions_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../utils/marker_utils.dart';
import '../widgets/premium_button.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class RiderActiveRideScreen extends StatefulWidget {
  final int rideId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;

  const RiderActiveRideScreen({
    super.key,
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
  });

  @override
  State<RiderActiveRideScreen> createState() => _RiderActiveRideScreenState();
}

class _RiderActiveRideScreenState extends State<RiderActiveRideScreen> {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  LatLng? _riderLocation;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  int _remainingMinutes = 0;
  String? _driverName;
  int? _otherUserId;
  bool _rideCompleting = false;
  double _driverHeading = 0;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _userLocationMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  Timer? _statusPollTimer;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initCarIcon();
    _initYellowPin();
    _initUserLocationMarker();
    _setupWebSocketListeners();
    _getRiderLocation();
    _updateRoute();
    _fetchDriverInfo();
    _startStatusPolling();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 ACTIVE RIDE');
    addDebugMessage('Destination: ${widget.dropoffAddress}');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initUserLocationMarker() async {
    _userLocationMarker = await MarkerFactory.userLocation;
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
  }

  Future<void> _getRiderLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _riderLocation = LatLng(pos.latitude, pos.longitude);
          _updateMarkers();
        });
      }
    } catch (e) {
      addDebugMessage('⚠️ Could not get rider location: $e');
    }
  }

  void _setupWebSocketListeners() {
    try {
      _driverLocationSub = WebSocketService.driverLocationEvents.listen((event) {
        if (!mounted) return;
        final payload = event['payload'] ?? event;
        final lat = (payload['latitude'] ?? payload['lat']) as double?;
        final lng = (payload['longitude'] ?? payload['lng']) as double?;

          if (lat != null && lng != null) {
            setState(() {
              final prev = _driverLocation;
              _driverLocation = LatLng(lat, lng);
              final heading = payload['heading'];
              if (heading != null) {
                _driverHeading = (heading as num).toDouble();
              } else if (prev != null) {
                _driverHeading = _bearingBetween(prev, _driverLocation!);
              }
              addDebugMessage(
                'driver_location heading=$_driverHeading '
                'from(${prev?.latitude.toStringAsFixed(5) ?? '?'},${prev?.longitude.toStringAsFixed(5) ?? '?'}) '
                'to(${_driverLocation!.latitude.toStringAsFixed(5)},${_driverLocation!.longitude.toStringAsFixed(5)})'
              );
              _updateMarkers();
            });

          _updateRoute();
        }
      });

      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        if (!mounted) return;
        if (event['type'] == 'ride_completed') {
          if (_rideCompleting) return;
          _rideCompleting = true;
          _statusPollTimer?.cancel();
          Navigator.pushReplacementNamed(
            context,
            '/rider-completed',
            arguments: {
              'rideId': widget.rideId,
              'totalFare': event['payload']?['totalFare'],
              'distance': event['payload']?['distance'],
              'duration': event['payload']?['duration'],
            },
          );
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error: $e');
    }
  }

  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _rideCompleting) return;
      try {
        final token = StorageService.getToken();
        if (token == null) return;
        final ride = await RideService.getRideDetails(widget.rideId, token);
        if (ride == null || !mounted || _rideCompleting) return;

        if (ride.status == 'COMPLETED') {
          _rideCompleting = true;
          _statusPollTimer?.cancel();
          addDebugMessage('✅ Poll detected ride COMPLETED');
          Navigator.pushReplacementNamed(
            context,
            '/rider-completed',
            arguments: {
              'rideId': widget.rideId,
              'totalFare': ride.finalFare,
              'distance': ride.estimatedDistance,
              'duration': ride.estimatedDuration,
            },
          );
        }
      } catch (e) {
        addDebugMessage('⚠️ Status poll error: $e');
      }
    });
  }

  Future<void> _fetchDriverInfo() async {
    final token = StorageService.getToken();
    if (token == null) return;
    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride != null && ride.driver != null && mounted) {
        setState(() {
          _driverName = ride.driver!.fullName;
          _otherUserId = ride.driver!.id;
        });
      }
    } catch (e) {
      addDebugMessage('⚠️ Driver info error: $e');
    }
  }

  Widget _buildUnreadBadge() {
    if (_otherUserId == null) return const SizedBox.shrink();
    final count = WebSocketService.unreadCounts[_otherUserId!] ?? 0;
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
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _updateMarkers() {
    final updated = <Marker>{};

    if (_riderLocation != null) {
      updated.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _riderLocation!,
          icon: _userLocationMarker,
        ),
      );
    }

    if (_driverLocation != null) {
      addDebugMessage('_updateMarkers rotation=$_driverHeading');
      updated.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _carIcon,
          rotation: _carRotation(_driverHeading % 360),
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    }

    updated.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: _yellowPinMarker,
      ),
    );

    _markers = updated;
  }

  Future<void> _updateRoute() async {
    final origin = _driverLocation ?? LatLng(widget.pickupLat, widget.pickupLng);
    final destination = LatLng(widget.dropoffLat, widget.dropoffLng);
    if (origin.latitude == 0 && origin.longitude == 0) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
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
      addDebugMessage('⚠️ Route error: $e');
    }
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

  /// Car image front faces DOWN (south). Add 180° so rotation=0 → north.
  double _carRotation(double heading) => (heading + 180) % 360;

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
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
          'En Route',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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
            style: _mapStyle,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
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
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl,
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
                        color: AppColors.textTertiary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.cardPaddingCompact,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated arrival',
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_remainingMinutes min remaining',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapLg,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.outline.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 3,
                    ),
                  ),
                  AppSpacing.gapLg,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.dropoffAddress,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_driverName != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Divider(
                        height: 1,
                        color: AppColors.outline.withValues(alpha: 0.6),
                      ),
                    ),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _driverName![0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            _driverName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
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
                  ],
                  const SizedBox(height: 16),
                  PremiumButton(
                    label: 'Cancel Ride',
                    onPressed: _showCancelRideDialog,
                    variant: ButtonVariant.danger,
                    icon: Icons.close,
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
    final result = await showCancelRideDialog(context);
    if (result != null && result.confirmed && mounted) {
      final reason = result.reason;
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
      addDebugMessage('❌ Chat error: $e');
    }
  }

  @override
  void dispose() {
    _rideCompleting = false;
    _statusPollTimer?.cancel();
    _rideEventsSub?.cancel();
    _driverLocationSub?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
