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
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/swipe_button.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/bearing_utils.dart';
import '../utils/address_utils.dart';
import '../services/recorded_screen_mixin.dart';

class DriverNavigationToRiderScreen extends StatefulWidget {
  final int rideId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  const DriverNavigationToRiderScreen({
    super.key,
    required this.rideId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  @override
  State<DriverNavigationToRiderScreen> createState() =>
      _DriverNavigationToRiderScreenState();
}

class _DriverNavigationToRiderScreenState
    extends State<DriverNavigationToRiderScreen> with RecordedScreenMixin<DriverNavigationToRiderScreen> {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  late final LatLng _pickupLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;
  double _driverHeading = 0;
  String? _mapStyle;
  bool _showDriverMarker = true;
  bool _isArriving = false;
  int _remainingMinutes = 15;
  double? _distanceKm;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  LatLng? _animatedDriverPos;
  Timer? _driverAnimTimer;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();
    recordEvent(eventName: 'NAVIGATION_STARTED');
    _loadMapStyle();

    _pickupLocation = LatLng(widget.pickupLat, widget.pickupLng);

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER NAVIGATION TO RIDER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('Pickup: ${widget.pickupLat}, ${widget.pickupLng}');
    addDebugMessage('Address: ${widget.pickupAddress}');
    addDebugMessage('═══════════════════════════════════════');

    _initYellowPin();
    _initCarIcon();
    _initializeNavigation();
    _fetchChatPartnerId();
    _setupRideEventListeners();
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

  Future<void> _initializeNavigation() async {
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

    addDebugMessage('▶️ Starting navigation location stream (50m filter)');

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;

        final newLocation = LatLng(position.latitude, position.longitude);
        _driverLocation = newLocation;
        _driverHeading = position.heading;
        _startDriverMarkerAnimation(newLocation);

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
        addDebugMessage('❌ Navigation stream error: $error');
      },
      onDone: () {
        addDebugMessage('⏹️ Navigation stream closed');
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
      addDebugMessage('⏹️ Navigation location stream stopped');
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
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress}'),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _pickupLocation,
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
    _fitBounds();
  }

  void _fitBounds() {
    if (_driverLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _pickupLocation.latitude
            ? _driverLocation!.latitude - 0.01
            : _pickupLocation.latitude - 0.01,
        _driverLocation!.longitude < _pickupLocation.longitude
            ? _driverLocation!.longitude - 0.01
            : _pickupLocation.longitude - 0.01,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _pickupLocation.latitude
            ? _driverLocation!.latitude + 0.01
            : _pickupLocation.latitude + 0.01,
        _driverLocation!.longitude > _pickupLocation.longitude
            ? _driverLocation!.longitude + 0.01
            : _pickupLocation.longitude + 0.01,
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _notifyArrival() async {
    recordEvent(eventName: 'DRIVER_ARRIVED');
    try {
      _stopLocationStream();
      setState(() => _isArriving = true);

      addDebugMessage('📍 Notifying driver arrival...');

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.driverArrived(widget.rideId, token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider notified!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Verify ride is still active before navigating
        if (token != null) {
          final ride = await RideService.getRideDetails(widget.rideId, token);
          if (ride != null && ride.status != 'CANCELLED' && ride.status != 'COMPLETED' && mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/driver-active-ride',
              arguments: {
                'rideId': widget.rideId,
                'dropoffAddress': widget.dropoffAddress,
                'dropoffLat': widget.dropoffLat,
                'dropoffLng': widget.dropoffLng,
              },
            );
          } else if (mounted) {
            addDebugMessage('⚠️ Ride was ${ride?.status} — returning to home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride was cancelled'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
          }
        } else if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/driver-active-ride',
            arguments: {
              'rideId': widget.rideId,
              'dropoffAddress': widget.dropoffAddress,
              'dropoffLat': widget.dropoffLat,
              'dropoffLng': widget.dropoffLng,
            },
          );
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isArriving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

  Future<void> _openGoogleMaps() async {
    addDebugMessage('▶️ _openGoogleMaps — starting background nav');
    try {
      await BackgroundNavigationService().start(
        rideId: widget.rideId,
        navigationType: 'pickup',
        destinationAddress: widget.pickupAddress,
      );
    } catch (e) {
      addDebugMessage('⚠️ _openGoogleMaps start error: $e');
    }

    await _openMapsApp(widget.pickupLat, widget.pickupLng);
  }

  Future<void> _openMapsApp(double lat, double lng) async {
    final appUri = Uri.parse(
      'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
    );
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        addDebugMessage('Google Maps app opened: $appUri');
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
        addDebugMessage('Google Maps opened: $uri');
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
        addDebugMessage('Could not launch, copied URL instead: $uri');
      }
    } catch (e) {
      addDebugMessage('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          button: true,
          label: 'Back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'Navigate to Rider',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                button: true,
                label: 'Chat with rider',
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  tooltip: 'Chat with Rider',
                  onPressed: _openChat,
                ),
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
              target: _pickupLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: true,
            style: _mapStyle,
          ),
          PositionedDirectional(
            top: 16,
            end: 16,
            child:             Semantics(
              button: true,
              label: 'Toggle driver marker',
              child: FloatingActionButton(
                heroTag: 'toggle_marker_nav',
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
          ),
          if (_isArriving)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isArriving ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    color: AppColors.mapOverlay,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 80),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'You have arrived!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Rider has been notified',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // ── Bottom sheet ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.xl),
                  topRight: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppShadows.large,
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
                  // ── Premium Address Card ──────────────────────────
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: AppRadius.lgRadius,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: AppRadius.smRadius,
                          ),
                          child: const Icon(Icons.location_on,
                              color: AppColors.error, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PICKUP',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textTertiary,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.pickupAddress,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                formatLatLng(widget.pickupLat, widget.pickupLng),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // ── Time & Distance Side by Side ──────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.lgRadius,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '$_remainingMinutes',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'min',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Container(
                          padding: AppSpacing.cardPadding,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: AppRadius.lgRadius,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.straighten,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _distanceKm?.toStringAsFixed(1) ?? '--',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'km',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Semantics(
                    button: true,
                    label: "I've Arrived",
                    child: SwipeButton(
                      label: "I've Arrived",
                      processingLabel: 'Notifying...',
                      icon: Icons.check_circle,
                      onConfirmed: _notifyArrival,
                      isDisabled: _isArriving,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async { await _openGoogleMaps(); },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Open Google Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdRadius,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    button: true,
                    label: 'Cancel ride',
                    child: PremiumButton(
                      label: 'Cancel Ride',
                      onPressed: _showCancelRideDialog,
                      variant: ButtonVariant.danger,
                      icon: Icons.close,
                    ),
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

  void _setupRideEventListeners() {
    _rideEventsSub?.cancel();
    _rideEventsSub = WebSocketService.rideEvents.listen((event) {
      if (!mounted) return;
      final type = event['type'];
      if (type == 'ride_cancelled') {
        final reason = event['reason'] as String? ?? 'The ride was cancelled';
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
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
      }
    });
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
    return PositionedDirectional(
      end: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
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
    _rideEventsSub?.cancel();
    _driverAnimTimer?.cancel();
    mapController?.dispose();
    BackgroundNavigationService().stop();
    super.dispose();
  }
}
