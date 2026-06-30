import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ride_service.dart';
import '../services/directions_service.dart';
import '../services/background_navigation_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../widgets/received_payment_dialog.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/bearing_utils.dart';

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
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  late final LatLng _destinationLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;
  double _driverHeading = 0;
  String? _mapStyle;
  bool _showDriverMarker = true;
  bool _rideStarted = false;
  bool _isCompleting = false;
  bool _awaitingPayment = false;
  int _remainingMinutes = 0;
  double? _distanceKm;
  DateTime? _startTime;
  Timer? _rideTimer;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  LatLng? _animatedDriverPos;
  Timer? _driverAnimTimer;
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
    _initCarIcon();
    _initializeRide();
    _fetchChatPartnerId();
    _setupPaymentListeners();
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initCarIcon() async {
    try {
      _carIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      addDebugMessage('⚠️ Car icon fallback: $e');
      _carIcon = await MarkerFactory.driver;
    }
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
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;

        _driverLocation = LatLng(position.latitude, position.longitude);
        _driverHeading = position.heading;
        _startDriverMarkerAnimation(_driverLocation!);

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

  void _startDriverMarkerAnimation(LatLng target) {
    _driverAnimTimer?.cancel();
    final origin = _animatedDriverPos ?? _driverLocation ?? target;

    const steps = 30;
    var step = 0;

    _driverAnimTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      step++;
      final t = step / steps;
      final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();

      _animatedDriverPos = LatLng(
        origin.latitude + (target.latitude - origin.latitude) * eased,
        origin.longitude + (target.longitude - origin.longitude) * eased,
      );

      _updateMarkers();

      if (step >= steps) {
        _driverAnimTimer?.cancel();
        _driverAnimTimer = null;
        _animatedDriverPos = null;
        _updateMarkers();
      }
    });
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

    if (_driverLocation != null && _showDriverMarker) {
      final pos = _animatedDriverPos ?? _driverLocation!;
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: pos,
          icon: _carIcon,
          flat: true,
          rotation: normalizeCarHeading(_driverHeading % 360),
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

    if (mounted) setState(() {});
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

  void _setupPaymentListeners() {
    _rideEventsSub = WebSocketService.rideEvents.listen((event) async {
      if (!mounted) return;
      final type = event['type'];

      if (type == 'ride_cancelled') {
        _awaitingPayment = false;
        final reason = event['reason'] as String? ?? 'The ride was cancelled';
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.cancel, color: AppColors.error, size: 24),
                SizedBox(width: 8),
                Text('Ride Cancelled'),
              ],
            ),
            content: Text('The rider cancelled the ride.\nReason: $reason'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
                },
                child: const Text('OK', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
        );
        return;
      }

      if (!_awaitingPayment) return;
      if (type == 'payment_confirmed') {
        final amount = (event['payload']?['amount'] as num?)?.toDouble() ?? 0.0;
        final result = await showReceivedPaymentDialog(context, amount: amount);
        if (result == null || !mounted) return;

        final token = StorageService.getToken();
        if (token == null) return;

        if (result.received) {
          await RideService.confirmPaymentReceived(widget.rideId, token);
        } else {
          await RideService.disputePayment(widget.rideId, token,
              reason: result.reason ?? 'Driver disputed payment');
        }
      } else if (type == 'payment_finalized' || type == 'payment_refunded') {
        _awaitingPayment = false;
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/driver-summary',
            arguments: {
              'rideId': widget.rideId,
            },
          );
        }
      }
    });
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

      ChatScreen.clearAllCache();

      WebSocketService.sendRideMessage('ride_completed', {
        'rideId': widget.rideId,
        'status': 'COMPLETED',
      });

      setState(() {
        _isCompleting = false;
        _awaitingPayment = true;
      });
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
          style: const TextStyle(color: AppColors.primary),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'toggle_marker_driver_active',
              mini: true,
              onPressed: () {
                setState(() => _showDriverMarker = !_showDriverMarker);
                _updateMarkers();
              },
              backgroundColor: _showDriverMarker
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
              child: Icon(
                Icons.my_location,
                color: _showDriverMarker ? AppColors.primaryLight : AppColors.textSecondary,
                size: 20,
              ),
            ),
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
                      ? _awaitingPayment
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Waiting for payment...'),
                                ],
                              ),
                            )
                          : PremiumButton(
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
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async { await _openGoogleMapsToDestination(); },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Navigate to Destination'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
        await RideService.cancelRide(widget.rideId, token, reason: reason);
        ChatScreen.clearAllCache();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride cancelled'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
        }
      } catch (e) {
        addDebugMessage('❌ Error cancelling ride: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _openGoogleMapsToDestination() async {
    addDebugMessage('▶️ _openGoogleMapsToDestination — starting background nav');
    try {
      await BackgroundNavigationService().start(
        rideId: widget.rideId,
        navigationType: 'dropoff',
        destinationAddress: widget.dropoffAddress,
      );
    } catch (e) {
      addDebugMessage('⚠️ _openGoogleMapsToDestination start error: $e');
    }

    await _openMapsApp(widget.dropoffLat, widget.dropoffLng);
  }

  Future<void> _openMapsApp(double lat, double lng) async {
    final appUri = Uri.parse(
      'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
    );
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      addDebugMessage('⚠️ Maps app unavailable, using web: $e');
    }
    await _launchUrl(Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    ));
  }

  Future<void> _launchUrl(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Maps — link copied to clipboard'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      addDebugMessage('Error launching maps: $e');
    }
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
          style: const TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
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
              rideId: widget.rideId,
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
    _driverAnimTimer?.cancel();
    _rideTimer?.cancel();
    _rideEventsSub?.cancel();
    mapController?.dispose();
    BackgroundNavigationService().stop();
    super.dispose();
  }
}
