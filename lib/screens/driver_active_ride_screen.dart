import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ride_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final int rideId;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  const DriverActiveRideScreen({
    super.key,
    required this.rideId,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  @override
  State<DriverActiveRideScreen> createState() =>
      _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  late GoogleMapController mapController;
  LatLng? _driverLocation;
  late final LatLng _destinationLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;
  bool _rideStarted = false;
  bool _isCompleting = false;
  int _remainingMinutes = 0;
  double? _distanceKm;
  DateTime? _startTime;
  Timer? _rideTimer;

  StreamSubscription<Position>? _positionStream;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();

    _destinationLocation = LatLng(widget.dropoffLat, widget.dropoffLng);

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 ACTIVE RIDE - HEADING TO DESTINATION');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('Destination: ${widget.dropoffLat}, ${widget.dropoffLng}');
    addDebugMessage('Address: ${widget.dropoffAddress}');
    addDebugMessage('═══════════════════════════════════════');

    _initYellowPin();
    _initializeRide();
    _fetchChatPartnerId();
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initializeRide() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _driverLocation = LatLng(position.latitude, position.longitude);
      addDebugMessage('✅ Driver location: ${position.latitude}, ${position.longitude}');

      _updateMarkers();
      _updateRoute();
      _startLocationStream();

      if (mounted) setState(() {});
    } catch (e) {
      addDebugMessage('❌ Init error: $e');
    }
  }

  void _startLocationStream() {
    _stopLocationStream();

    addDebugMessage('▶️ Starting active ride location stream (50m filter)');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;

        _driverLocation = LatLng(position.latitude, position.longitude);

        addDebugMessage(
          '📍 Driver moved 50m+ — ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        );

        try {
          final token = StorageService.getToken();
          if (token != null) {
            await RideService.updateDriverLocation(
              rideId: widget.rideId,
              latitude: position.latitude,
              longitude: position.longitude,
              token: token,
            );
            addDebugMessage('✅ Rider notified of driver location via REST');
          }

          WebSocketService.sendRideMessage('driver_location', {
            'driverId': StorageService.getUserId(),
            'rideId': widget.rideId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
          });
          addDebugMessage('✅ Rider notified of driver location via WebSocket');
        } catch (e) {
          addDebugMessage('⚠️ Failed to update rider location: $e');
        }

        if (mounted) {
          _updateMarkers();
          _updateRoute();
          setState(() {});
        }
      },
      onError: (error) {
        addDebugMessage('❌ Active ride stream error: $error');
      },
      onDone: () {
        addDebugMessage('⏹️ Active ride stream closed');
      },
    );
  }

  void _stopLocationStream() {
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
      addDebugMessage('⏹️ Active ride location stream stopped');
    }
  }

  Future<void> _updateMarkers() async {
    _markers.clear();

    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: await MarkerFactory.driver,
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationLocation,
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: widget.dropoffAddress),
      ),
    );

    setState(() {});
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _destinationLocation,
      );

      if (route != null && route.isSuccess && mounted) {
        _polylines.clear();

        if (route.polylinePoints != null && route.polylinePoints!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.mapRouteLine,
              width: 5,
              geodesic: true,
            ),
          );
        }

        setState(() {
          _remainingMinutes = route.durationMinutes ?? 0;
          _distanceKm = route.distanceKm;
        });

        addDebugMessage(
          '✅ Route updated — ${route.distanceKm?.toStringAsFixed(1)} km, $_remainingMinutes min',
        );
      }
    } catch (e) {
      addDebugMessage('⚠️ Route error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _startRide() async {
    try {
      setState(() {
        _rideStarted = true;
        _startTime = DateTime.now();
      });

      _rideTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.startRide(widget.rideId, token);
      }

      addDebugMessage('✅ Ride started');

      WebSocketService.sendRideMessage('ride_started', {
        'rideId': widget.rideId,
        'status': 'STARTED',
        'dropoffLatitude': widget.dropoffLat,
        'dropoffLongitude': widget.dropoffLng,
        'dropoffAddress': widget.dropoffAddress,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      _rideTimer?.cancel();
      if (mounted) {
        setState(() => _rideStarted = false);
      }
    }
  }

  Future<void> _completeRide() async {
    try {
      setState(() => _isCompleting = true);

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.completeRide(widget.rideId, token);
      }

      _stopLocationStream();

      addDebugMessage('✅ Ride completed');

      WebSocketService.sendRideMessage('ride_completed', {
        'rideId': widget.rideId,
        'status': 'COMPLETED',
      });

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/driver-summary',
          arguments: {
            'rideId': widget.rideId,
          },
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatElapsedTime() {
    if (_startTime == null) return '00:00';
    final elapsed = DateTime.now().difference(_startTime!);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _rideStarted ? 'Active Ride' : 'Ready to Start',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                tooltip: 'Chat with Rider',
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
            initialCameraPosition: CameraPosition(
              target: _destinationLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            style: _mapStyle,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusXxl),
                  topRight: Radius.circular(AppSpacing.radiusXxl),
                ),
                boxShadow: AppSpacing.shadowXl,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.dropoffAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$_remainingMinutes min',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_distanceKm != null)
                        Text(
                          '${_distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  if (_rideStarted) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppColors.textTertiary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatElapsedTime(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                  _rideStarted
                      ? PremiumButton(
                          label: _isCompleting ? 'Completing...' : 'Complete Ride',
                          icon: _isCompleting ? Icons.hourglass_empty : Icons.flag,
                          onPressed: _isCompleting ? null : _completeRide,
                          variant: ButtonVariant.danger,
                        )
                      : PremiumButton(
                          label: 'Start Ride',
                          icon: Icons.play_arrow,
                          onPressed: _startRide,
                          variant: ButtonVariant.success,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _fetchChatPartnerId() async {
    final token = StorageService.getToken();
    if (token == null) return;
    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride != null && mounted) {
        _otherUserId = ride.rider.id;
      }
    } catch (_) {}
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
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    final token = StorageService.getToken();
    final currentUserId = StorageService.getUserId();
    final currentUsername = StorageService.getUsername();
    if (token == null || currentUserId == null || currentUsername == null) return;

    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null) return;

      final otherUser = ride.rider;
      if (otherUser.id == null) return;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              receiverId: otherUser.id!,
              receiverName: otherUser.fullName,
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
    _stopLocationStream();
    _rideTimer?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
