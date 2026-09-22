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
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/status_badge.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../utils/bearing_utils.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/driver_card_data.dart';
import '../widgets/driver_arriving_card.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/recorded_screen_mixin.dart';
import '../services/event_recorder_service.dart';
import '../l10n/app_localizations.dart';

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

  // Follow engine (Option 2): pause on touch, silent auto-resume after 30s.
  Timer? _followResumeTimer;
  DateTime? _lastFollowFitAt;
  LatLng? _lastFollowFitPos;
  static const Duration _followResumeDelay = Duration(seconds: 30);
  static const Duration _followMinInterval = Duration(seconds: 3);
  static const double _followMinMoveMeters = 50;

  Timer? _driverAnimTimer;
  LatLng? _animatedDriverPos;

  Timer? _statusPollTimer;
  Timer? _routeDebounceTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocEventsSub;
  StreamSubscription<String>? _connectionStateSub;
  bool _wasDisconnected = false;
  DriverCardData _cardData =
      const DriverCardData(name: 'Driver', rating: null);

  /// Merges enriched fields (from WS payload, REST ride, reconnect, poll)
  /// into the current card, rebuilding only when something changed.
  bool _applyCard(DriverCardData incoming) {
    final merged = DriverCardData(
      name: incoming.name ?? _cardData.name,
      photoUrl: incoming.photoUrl ?? _cardData.photoUrl,
      vehiclePhotoUrl: incoming.vehiclePhotoUrl ?? _cardData.vehiclePhotoUrl,
      vehicleType: incoming.vehicleType ?? _cardData.vehicleType,
      vehicleNumber: incoming.vehicleNumber ?? _cardData.vehicleNumber,
      vehicleModel: incoming.vehicleModel ?? _cardData.vehicleModel,
      vehicleColor: incoming.vehicleColor ?? _cardData.vehicleColor,
      rating: incoming.rating ?? _cardData.rating,
    );
    final changed =
        merged.name != _cardData.name ||
            merged.photoUrl != _cardData.photoUrl ||
            merged.vehiclePhotoUrl != _cardData.vehiclePhotoUrl ||
            merged.vehicleType != _cardData.vehicleType ||
            merged.vehicleNumber != _cardData.vehicleNumber ||
            merged.vehicleModel != _cardData.vehicleModel ||
            merged.vehicleColor != _cardData.vehicleColor ||
            merged.rating != _cardData.rating;
    if (changed) {
      setState(() => _cardData = merged);
    }
    return changed;
  }

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

    _setupConnectionStateListener();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('TRACKING DRIVER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  void _setupConnectionStateListener() {
    _connectionStateSub = WebSocketService.connectionState.listen((state) {
      if (!mounted) return;
      if (state == 'disconnected') {
        _wasDisconnected = true;
        addDebugMessage('⚠️ WebSocket disconnected - awaiting reconnect');
      } else if (state == 'connected' && _wasDisconnected) {
        _wasDisconnected = false;
        addDebugMessage('🔄 WebSocket reconnected - rehydrating tracking state');
        _handleReconnected();
      }
    });
  }

  Future<void> _handleReconnected() async {
    addDebugMessage('🔄 Reconnected - fetching latest ride state');
    final token = StorageService.getToken();
    if (token == null) return;
    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || !mounted) return;

      if (ride.driverLatitude != null && ride.driverLongitude != null) {
        setState(() {
          _driverLocation = LatLng(ride.driverLatitude!, ride.driverLongitude!);
        });
        _updateMarkers();
        _updateRoute();
        _fitBounds();
        addDebugMessage('✅ Tracking state rehydrated after reconnect');
      }

      if (_applyCard(DriverCardData.fromRide(ride))) {
        addDebugMessage('✅ Driver card enriched after reconnect');
      }

      if (ride.status == 'CANCELLED') {
        if (_rideStarting) return;
        _rideStarting = true;
        _statusPollTimer?.cancel();
        ChatScreen.clearAllCache();
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 48),
              title: Text(AppLocalizations.of(context).rideCancelled),
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
                    child: Text(AppLocalizations.of(context).backToHome),
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
        _statusPollTimer?.cancel();
        _cancelFollowResume();
        if (mounted) {
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
        return;
      }
    } catch (e) {
      addDebugMessage('⚠️ Reconnect rehydration error: $e');
    }
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
                title: Text(AppLocalizations.of(context).rideCancelled),
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
                    child: Text(AppLocalizations.of(context).backToHome),
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
          _cancelFollowResume();
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
          return;
        }

        if (_applyCard(DriverCardData.fromRide(ride))) {
          addDebugMessage('🔄 Driver card refreshed via status poll');
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
        const ImageConfiguration(size: Size(64, 64)),
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
    final incoming = DriverCardData.fromMap(widget.driverData);
    _cardData = DriverCardData(
      name: incoming.name ?? _cardData.name,
      photoUrl: incoming.photoUrl ?? _cardData.photoUrl,
      vehiclePhotoUrl: incoming.vehiclePhotoUrl ?? _cardData.vehiclePhotoUrl,
      vehicleType: incoming.vehicleType ?? _cardData.vehicleType,
      vehicleNumber: incoming.vehicleNumber ?? _cardData.vehicleNumber,
      vehicleModel: incoming.vehicleModel ?? _cardData.vehicleModel,
      vehicleColor: incoming.vehicleColor ?? _cardData.vehicleColor,
      rating: incoming.rating ?? _cardData.rating,
    );
    if (_cardData.rating == null) {
      _fetchRatingFromRideDetails();
    }
  }

  Future<void> _fetchRatingFromRideDetails() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride != null && mounted) {
        _applyCard(DriverCardData.fromRide(ride));
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

        if (type == 'ride_started') {
          if (_rideStarting) return;
          _rideStarting = true;
          _cancelFollowResume();
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
            SnackBar(
              content: Text(AppLocalizations.of(context).yourDriverHasArrivedAtThePickupLocation),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 5),
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
                title: Text(AppLocalizations.of(context).rideCancelled),
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
                    child: Text(AppLocalizations.of(context).backToHome),
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
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
      // Last-known-good rotation gate: ignore heading/bearing unless moved.
      final moved =
          prev == null || _distanceMeters(prev, newLoc) >= 3.0;
      final heading = payload['heading'];
      if (moved) {
        if (heading != null) {
          _driverHeading = (heading as num).toDouble();
        } else if (prev != null) {
          _driverHeading = _bearingBetween(prev, _driverLocation!);
        }
      }
      _startDriverMarkerAnimation(newLoc);
      if (!_userInteracted) _maybeFollow(newLoc);
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
    _lastFollowFitAt = DateTime.now();
    if (_driverLocation != null) {
      _lastFollowFitPos = _driverLocation;
    }
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

  void _pauseFollowForUserGesture() {
    _followResumeTimer?.cancel();
    final wasFollowing = !_userInteracted;
    _userInteracted = true;
    if (wasFollowing && mounted) setState(() {});
    _followResumeTimer = Timer(_followResumeDelay, () {
      if (!mounted) return;
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
  void _maybeFollow(LatLng driverPos) async {
    if (_userInteracted || !mounted) return;
    if (!_followAllowed(driverPos)) return;
    try {
      final region = await mapController?.getVisibleRegion();
      if (!mounted || _userInteracted) return;
      if (region != null &&
          _containsWithMargin(region, driverPos) &&
          _pickupLocation != null &&
          _containsWithMargin(region, _pickupLocation!)) {
        _lastFollowFitAt = DateTime.now();
        _lastFollowFitPos = driverPos;
        return;
      }
    } catch (_) {
      // Fall through to time+distance throttle only.
    }
    if (!mounted || _userInteracted) return;
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

  /// Haversine distance in meters (rotation-gate helper).
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

  Future<void> _callDriver() async {
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
      final tel = _buildTel(ride?.driver?.countryCode, ride?.driver?.phoneNumber);
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
        leading: Semantics(
          button: true,
          label: AppLocalizations.of(context).cancelRide,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: () => _showCancelRideDialog(),
          ),
        ),
        title: Text(
          'Trip to Destination',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                button: true,
                label: AppLocalizations.of(context).chatWithRider,
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                  tooltip: AppLocalizations.of(context).chatWithRider,
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
            onCameraMove: (_) {
              if (_suppressCameraMove == 0) {
                _pauseFollowForUserGesture();
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
              child:               Semantics(
                button: true,
                label: AppLocalizations.of(context).recenterMap,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
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
                  child: const Icon(Icons.my_location, color: AppColors.primary),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppShadows.large,
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

                  DriverArrivingCard(
                    cardData: _cardData,
                    etaText: _remainingMinutes > 0
                        ? AppLocalizations.of(context)
                            .pickupInMin('$_remainingMinutes')
                        : 'Calculating...',
                    onChat: _openChat,
                    onCall: _callDriver,
                    unreadCount: WebSocketService.unreadCounts[
                            widget.driverData['driverId'] as int?] ??
                        0,
                  ),
                  AppSpacing.gapMd,

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
                            ? AppLocalizations.of(context).arrived
                            : AppLocalizations.of(context).arriving,
                        color: _driverArrived
                            ? AppColors.success
                            : AppColors.primary,
                        icon: _driverArrived
                            ? Icons.check_circle
                            : Icons.navigation,
                      ),
                    ],
                  ),
                  AppSpacing.gapMd,

                  if (!_driverArrived)
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 0.85),
                      duration: const Duration(milliseconds: 1500),
                      builder: (context, value, _) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.outline.withValues(alpha: 0.5),
                            ),
                            child: FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: value.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradientH,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  AppSpacing.gapSm,

                  Text(
                    _driverArrived
                        ? 'Meet your driver at the pickup location'
                        : 'Approaching your pickup',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
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
    _cancelFollowResume();
    _driverAnimTimer?.cancel();
    _statusPollTimer?.cancel();
    _routeDebounceTimer?.cancel();
    _rideEventsSub?.cancel();
    _driverLocEventsSub?.cancel();
    _connectionStateSub?.cancel();
    mapController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
