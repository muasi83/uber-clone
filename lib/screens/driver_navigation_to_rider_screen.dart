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
import '../l10n/app_localizations.dart';

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

  // Follow engine: pause on touch, silent auto-resume after 30s.
  bool _userInteracted = false;
  int _suppressCameraMove = 0;
  Timer? _followResumeTimer;
  DateTime? _lastFollowFitAt;
  LatLng? _lastFollowFitPos;
  static const Duration _followResumeDelay = Duration(seconds: 30);
  static const Duration _followMinInterval = Duration(seconds: 3);
  static const double _followMinMoveMeters = 50;

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
        // Last-known-good rotation gate: ignore heading jitter unless moved.
        final prevLocation = _driverLocation;
        if (prevLocation == null ||
            _distanceMeters(prevLocation, newLocation) >= 3.0) {
          _driverHeading = position.heading;
        }
        _driverLocation = newLocation;
        _startDriverMarkerAnimation(newLocation);
        if (!_userInteracted && !_isArriving) _maybeFollow(newLocation);

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
          infoWindow: InfoWindow(title: AppLocalizations.of(context).yourLocation),
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: AppLocalizations.of(context).pickup2(widget.pickupAddress)),
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
    _lastFollowFitAt = DateTime.now();
    if (_driverLocation != null) {
      _lastFollowFitPos = _driverLocation;
    }
  }

  void _fitBounds() {
    if (_driverLocation == null) return;

    _suppressCameraMove++;
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
    ).then((_) {
      _suppressCameraMove--;
    }).catchError((_) {
      _suppressCameraMove--;
    });
  }

  void _pauseFollowForUserGesture() {
    _followResumeTimer?.cancel();
    final wasFollowing = !_userInteracted;
    _userInteracted = true;
    if (wasFollowing && mounted) setState(() {});
    _followResumeTimer = Timer(_followResumeDelay, () {
      if (!mounted || _isArriving) return;
      // Silent resume (no hint): gentle refit only.
      setState(() => _userInteracted = false);
      _fitBounds();
      _lastFollowFitAt = DateTime.now();
      if (_driverLocation != null) {
        _lastFollowFitPos = _driverLocation;
      }
    });
  }

  void _cancelFollowResume() {
    _followResumeTimer?.cancel();
    _followResumeTimer = null;
  }

  bool _followAllowed(LatLng driverPos) {
    final now = DateTime.now();
    if (_lastFollowFitAt != null &&
        now.difference(_lastFollowFitAt!) < _followMinInterval) {
      return false;
    }
    if (_lastFollowFitPos != null &&
        _distanceMeters(_lastFollowFitPos!, driverPos) <
            _followMinMoveMeters) {
      return false;
    }
    return true;
  }

  /// Throttled follower: time + distance gates, plus a best-effort
  /// visible-region check (never blocks; falls back to time+distance).
  /// Never called from onCameraMove, so it cannot loop camera moves.
  /// Never runs while the arrival overlay is showing.
  void _maybeFollow(LatLng driverPos) async {
    if (_userInteracted || _isArriving || !mounted) return;
    if (!_followAllowed(driverPos)) return;
    try {
      final region = await mapController?.getVisibleRegion();
      if (!mounted || _userInteracted || _isArriving) return;
      if (region != null &&
          _containsWithMargin(region, driverPos) &&
          _containsWithMargin(region, _pickupLocation)) {
        _lastFollowFitAt = DateTime.now();
        _lastFollowFitPos = driverPos;
        return;
      }
    } catch (_) {
      // Fall through to time+distance throttle only.
    }
    if (!mounted || _userInteracted || _isArriving) return;
    _fitBounds();
    _lastFollowFitAt = DateTime.now();
    _lastFollowFitPos = driverPos;
  }

  bool _containsWithMargin(LatLngBounds region, LatLng point) {
    const margin = 0.15;
    final latSpan = (region.northeast.latitude - region.southwest.latitude).abs();
    final lngSpan = (region.northeast.longitude - region.southwest.longitude).abs();
    return point.latitude >
            region.southwest.latitude + latSpan * margin &&
        point.latitude < region.northeast.latitude - latSpan * margin &&
        point.longitude >
            region.southwest.longitude + lngSpan * margin &&
        point.longitude < region.northeast.longitude - lngSpan * margin;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final s1 = math.sin(dLat / 2);
    final s2 = math.sin(dLng / 2);
    final h = s1 * s1 +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            s2 *
            s2;
    return 2 * earthRadius * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  double _toRadians(double deg) => deg * (math.pi / 180.0);

  Future<void> _notifyArrival() async {
    recordEvent(eventName: 'DRIVER_ARRIVED');
    _cancelFollowResume();
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
          SnackBar(
            content: Text(AppLocalizations.of(context).riderNotified),
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
              SnackBar(
                content: Text(AppLocalizations.of(context).rideWasCancelled),
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
        _cancelFollowResume();
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).rideCancelled2),
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
            SnackBar(
              content: Text(AppLocalizations.of(context).couldNotOpenMapsLinkCopiedToClipboard),
              duration: const Duration(seconds: 3),
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
          label: AppLocalizations.of(context).back,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          AppLocalizations.of(context).navigateToRider,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                button: true,
                label: AppLocalizations.of(context).chatWithRider,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  tooltip: AppLocalizations.of(context).chatWithRider2,
                  onPressed: _openChat,
                ),
              ),
              _buildUnreadBadge(),
            ],
          ),
          Semantics(
            button: true,
            label: 'Call rider',
            child: IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.primary),
              tooltip: 'Call rider',
              onPressed: _callRider,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: (_) {
              if (_suppressCameraMove == 0) {
                _pauseFollowForUserGesture();
              }
            },
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
          if (_userInteracted && !_isArriving)
            Positioned(
              right: 16,
              bottom:
                  MediaQuery.of(context).padding.bottom + 230,
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).recenterMap,
                child: FloatingActionButton.small(
                  heroTag: 'recenterNavToRider',
                  onPressed: () {
                    _cancelFollowResume();
                    setState(() {
                      _userInteracted = false;
                      _fitBounds();
                    });
                    _lastFollowFitAt = DateTime.now();
                    if (_driverLocation != null) {
                      _lastFollowFitPos = _driverLocation;
                    }
                  },
                  backgroundColor: AppColors.surface,
                  child: const Icon(Icons.gps_fixed,
                      color: AppColors.primary),
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
                            AppLocalizations.of(context).youHaveArrived2,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            AppLocalizations.of(context).riderHasBeenNotified,
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
          // ── Bottom floating overlay (hit-test limited to card + buttons).
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // ── Compact pickup card ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.pickupAddress.trim().isNotEmpty
                                    ? widget.pickupAddress
                                    : formatLatLng(widget.pickupLat,
                                        widget.pickupLng),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '$_remainingMinutes min',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${_distanceKm?.toStringAsFixed(1) ?? '--'} km',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // ── Actions (compact side-by-side + cancel link) ─
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _openGoogleMaps();
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(
                            AppLocalizations.of(context).openGoogleMaps,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            backgroundColor:
                                AppColors.surface.withValues(alpha: 0.9),
                            elevation: 2,
                            shadowColor:
                                Colors.black.withValues(alpha: 0.2),
                            side: BorderSide(
                                color: AppColors.primary
                                    .withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.mdRadius,
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(0, 52),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Semantics(
                          button: true,
                          label: AppLocalizations.of(context).iveArrived,
                          child: SwipeButton(
                            label: AppLocalizations.of(context).iveArrived,
                            processingLabel:
                                AppLocalizations.of(context).notifying,
                            icon: Icons.check_circle,
                            onConfirmed: _notifyArrival,
                            isDisabled: _isArriving,
                            height: 52,
                            borderRadius: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: _showCancelRideDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppLocalizations.of(context).cancelRide2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
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
            title: Row(
              children: [
                const Icon(Icons.cancel, color: AppColors.error, size: 24),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context).rideCancelled2),
              ],
            ),
            content: Text(AppLocalizations.of(context).rideCancelled3(reason)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
                },
                child: Text(AppLocalizations.of(context).ok, style: const TextStyle(color: AppColors.primary)),
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

  String? _buildTel(String? countryCode, String? phoneNumber) {
    if (countryCode == null || phoneNumber == null) return null;
    final cc = countryCode.trim();
    final raw = phoneNumber.trim();
    if (cc.isEmpty || raw.isEmpty) return null;
    final ccNorm = cc.startsWith('+') ? cc : '+$cc';
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return null;
    final ccDigits = ccNorm.replaceAll('+', '');
    if (digits.startsWith(ccDigits)) return '+$digits';
    return '$ccNorm$digits';
  }

  Future<void> _callRider() async {
    try {
      final token = StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone not available'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      final ride = await RideService.getRideDetails(widget.rideId, token);
      final tel = _buildTel(ride?.rider.countryCode, ride?.rider.phoneNumber);
      if (tel == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone not available'), behavior: SnackBarBehavior.floating),
        );
        return;
      }
      final uri = Uri(scheme: 'tel', path: tel);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone not available'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      addDebugMessage('Call error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone not available'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _cancelFollowResume();
    _stopLocationStream();
    _rideEventsSub?.cancel();
    _driverAnimTimer?.cancel();
    mapController?.dispose();
    BackgroundNavigationService().stop();
    super.dispose();
  }
}
