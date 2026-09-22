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
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../widgets/swipe_button.dart';
import '../widgets/received_payment_dialog.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/bearing_utils.dart';
import '../utils/address_utils.dart';
import '../services/recorded_screen_mixin.dart';
import '../services/event_recorder_service.dart';
import '../l10n/app_localizations.dart';

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

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> with RecordedScreenMixin<DriverActiveRideScreen> {
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

  // Follow engine: pause on touch, silent auto-resume after 30s.
  bool _userInteracted = false;
  int _suppressCameraMove = 0;
  Timer? _followResumeTimer;
  DateTime? _lastFollowFitAt;
  LatLng? _lastFollowFitPos;
  static const Duration _followResumeDelay = Duration(seconds: 30);
  static const Duration _followMinInterval = Duration(seconds: 3);
  static const double _followMinMoveMeters = 50;
  bool _rideStarted = false;
  bool _isCompleting = false;
  bool _awaitingPayment = false;
  bool _showingPaymentDialog = false;
  String _paymentMethod = 'WALLET';
  bool _cashActionInProgress = false;
  int _remainingMinutes = 0;
  double? _distanceKm;
  DateTime? _startTime;
  Timer? _rideTimer;
  Timer? _paymentPollTimer;

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  LatLng? _animatedDriverPos;
  Timer? _driverAnimTimer;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();
    recordEvent(
      eventName: 'SCREEN_OPENED',
      category: 'FRONTEND',
      summary: 'DriverActiveRideScreen opened',
    );
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

        final newLocation = LatLng(position.latitude, position.longitude);
        // Last-known-good rotation gate: ignore heading jitter unless moved.
        final prevLocation = _driverLocation;
        if (prevLocation == null ||
            _distanceMeters(prevLocation, newLocation) >= 3.0) {
          _driverHeading = position.heading;
        }
        _driverLocation = newLocation;
        _startDriverMarkerAnimation(_driverLocation!);
        if (!_userInteracted) _maybeFollow(_driverLocation!);

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
    _fitBoundsToTrip();
    _lastFollowFitAt = DateTime.now();
    if (_driverLocation != null) {
      _lastFollowFitPos = _driverLocation;
    }
  }

  void _fitBoundsToTrip() {
    if (mapController == null || _driverLocation == null) return;

    _suppressCameraMove++;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _destinationLocation.latitude
            ? _driverLocation!.latitude - 0.01
            : _destinationLocation.latitude - 0.01,
        _driverLocation!.longitude < _destinationLocation.longitude
            ? _driverLocation!.longitude - 0.01
            : _destinationLocation.longitude - 0.01,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _destinationLocation.latitude
            ? _driverLocation!.latitude + 0.01
            : _destinationLocation.latitude + 0.01,
        _driverLocation!.longitude > _destinationLocation.longitude
            ? _driverLocation!.longitude + 0.01
            : _destinationLocation.longitude + 0.01,
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
      _fitBoundsToTrip();
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
          _containsWithMargin(region, _destinationLocation)) {
        _lastFollowFitAt = DateTime.now();
        _lastFollowFitPos = driverPos;
        return;
      }
    } catch (_) {
      // Fall through to time+distance throttle only.
    }
    if (!mounted || _userInteracted) return;
    _fitBoundsToTrip();
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
      recordEvent(
        eventName: 'DRIVER_STARTED_RIDE',
        category: 'FRONTEND',
        summary: 'Driver started the ride',
      );

      WebSocketService.sendRideMessage('ride_started', {
        'rideId': widget.rideId,
        'status': 'STARTED',
        'dropoffLatitude': widget.dropoffLat,
        'dropoffLongitude': widget.dropoffLng,
        'dropoffAddress': widget.dropoffAddress,
      });

      if (mounted) {
        showRecordedSnackBar(
          context: context,
          message: AppLocalizations.of(context).rideStarted2,
          type: 'success',
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

      if (type == 'ride_completed') {
        final payload = event['payload'] as Map<String, dynamic>? ?? {};
        _paymentMethod = payload['paymentMethod'] as String? ?? 'WALLET';
        addDebugMessage('📌 Ride completed — paymentMethod: $_paymentMethod');
        if (mounted) setState(() {});
        return;
      }

      if (type == 'ride_cancelled') {
        _awaitingPayment = false;
        _paymentPollTimer?.cancel();
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
        return;
      }

      if (!_awaitingPayment) return;
      if (_showingPaymentDialog) return;
      if (type == 'payment_confirmed') {
        _showingPaymentDialog = true;
        final amount = (event['payload']?['amount'] as num?)?.toDouble() ?? 0.0;
        final result = await showReceivedPaymentDialog(context, amount: amount);
        _showingPaymentDialog = false;
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
        _paymentPollTimer?.cancel();
        _cancelFollowResume();
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

  void _startPaymentPolling() {
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted || !_awaitingPayment) {
        addDebugMessage('Payment poll cancelled. mounted=$mounted awaiting=$_awaitingPayment');
        _paymentPollTimer?.cancel();
        return;
      }

      final token = StorageService.getToken();
      if (token == null) return;

      final status = await RideService.getPaymentStatus(widget.rideId, token);
      if (!mounted || !_awaitingPayment) return;

      if (status == null) return;

      final paymentStatus = status['status'] as String?;

      if (paymentStatus == 'COMPLETED' && !_showingPaymentDialog) {
        _showingPaymentDialog = true;
        final amount = (status['amount'] as num?)?.toDouble() ?? 0.0;
        final result = await showReceivedPaymentDialog(context, amount: amount);
        _showingPaymentDialog = false;

        if (result == null || !mounted || !_awaitingPayment) return;

        final token = StorageService.getToken();
        if (token == null) return;

        if (result.received) {
          await RideService.confirmPaymentReceived(widget.rideId, token);
        } else {
          await RideService.disputePayment(widget.rideId, token,
              reason: result.reason ?? 'Driver disputed payment');
        }
      } else if (paymentStatus == 'FAILED') {
        _paymentPollTimer?.cancel();
        _awaitingPayment = false;
      }
    });
  }

  Future<void> _completeRide() async {
    try {
      setState(() => _isCompleting = true);

      final token = StorageService.getToken();
      if (token != null) {
        final ride = await RideService.completeRide(widget.rideId, token);
        if (ride != null && ride.paymentMethod != null) {
          _paymentMethod = ride.paymentMethod!;
        }
      }

      _stopLocationStream();
      _cancelFollowResume();

      addDebugMessage('✅ Ride completed');
      recordEvent(
        eventName: 'DRIVER_COMPLETED_RIDE',
        category: 'FRONTEND',
        summary: 'Driver completed the ride',
      );

      ChatScreen.clearAllCache();

      setState(() {
        _isCompleting = false;
        _awaitingPayment = true;
      });
      _startPaymentPolling();
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
        showRecordedSnackBar(
          context: context,
          message: 'Error: $e',
          type: 'error',
        );
      }
    }
  }

  Future<void> _onCashReceived() async {
    setState(() => _cashActionInProgress = true);
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final success = await RideService.cashReceived(widget.rideId, token);
      if (success && mounted) {
        addDebugMessage('✅ Cash received confirmed');
        _awaitingPayment = false;
        _paymentPollTimer?.cancel();
        _cancelFollowResume();
        Navigator.pushReplacementNamed(
          context,
          '/driver-summary',
          arguments: {'rideId': widget.rideId},
        );
      } else if (mounted) {
        showRecordedSnackBar(
          context: context,
          message: 'Failed to confirm cash receipt',
          type: 'error',
        );
      }
    } catch (e) {
      addDebugMessage('❌ Cash received error: $e');
      if (mounted) {
        showRecordedSnackBar(
          context: context,
          message: 'Error: $e',
          type: 'error',
        );
      }
    } finally {
      if (mounted) setState(() => _cashActionInProgress = false);
    }
  }

  Future<void> _onCashUnpaid() async {
    setState(() => _cashActionInProgress = true);
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final success = await RideService.cashUnpaid(widget.rideId, token);
      if (success && mounted) {
        addDebugMessage('✅ Cash marked as unpaid');
        _awaitingPayment = false;
        _paymentPollTimer?.cancel();
        _cancelFollowResume();
        Navigator.pushReplacementNamed(
          context,
          '/driver-summary',
          arguments: {'rideId': widget.rideId},
        );
      } else if (mounted) {
        showRecordedSnackBar(
          context: context,
          message: 'Failed to mark as unpaid',
          type: 'error',
        );
      }
    } catch (e) {
      addDebugMessage('❌ Cash unpaid error: $e');
      if (mounted) {
        showRecordedSnackBar(
          context: context,
          message: 'Error: $e',
          type: 'error',
        );
      }
    } finally {
      if (mounted) setState(() => _cashActionInProgress = false);
    }
  }

  Widget _buildWaitingForPayment() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.lgRadius,
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _PulseAnimation(
            child: Text(
              AppLocalizations.of(context).waitingForPayment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
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
    if (_rideStarted && _awaitingPayment) {
      addDebugMessage('Payment UI: method=$_paymentMethod awaiting=$_awaitingPayment');
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _rideStarted ? AppLocalizations.of(context).activeRide : AppLocalizations.of(context).readyToStart,
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
              target: _destinationLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            style: _mapStyle,
          ),
          if (_userInteracted)
            Positioned(
              right: 16,
              bottom:
                  MediaQuery.of(context).padding.bottom + 280,
              child: Semantics(
                button: true,
                label: AppLocalizations.of(context).recenterMap,
                child: FloatingActionButton.small(
                  heroTag: 'recenterDriverActive',
                  onPressed: () {
                    _cancelFollowResume();
                    setState(() {
                      _userInteracted = false;
                      _fitBoundsToTrip();
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
          PositionedDirectional(
            top: 16,
            end: 16,
            child:             Semantics(
              button: true,
              label: AppLocalizations.of(context).toggleDriverMarker,
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
          ),
          // Top status pill (SafeArea-aware, below AppBar, clear of FAB).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: kToolbarHeight + 4),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.medium,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).rideInProgress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        if (_rideStarted) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatElapsedTime(),
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures()
                                  ],
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom floating overlay (hit-test limited to card + buttons).
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  // ── Destination floating card (compact) ─────────
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
                                widget.dropoffAddress.trim().isNotEmpty
                                    ? widget.dropoffAddress
                                    : formatLatLng(widget.dropoffLat,
                                        widget.dropoffLng),
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
                  // ── Action Section (compact side-by-side) ──────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _openGoogleMapsToDestination();
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: Text(
                            AppLocalizations.of(context)
                                .navigateToDestination,
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
                        child: _rideStarted
                            ? _awaitingPayment
                                ? _paymentMethod == 'CASH'
                                    ? Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)
                                                .didTheCustomerPayInCash,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppColors.textPrimary,
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Semantics(
                                            button: true,
                                            label: AppLocalizations.of(
                                                    context)
                                                .cashReceived,
                                            child: SwipeButton(
                                              label:
                                                  AppLocalizations.of(context)
                                                      .cashReceived,
                                              processingLabel:
                                                  AppLocalizations.of(context)
                                                      .processing,
                                              icon: Icons.check_circle,
                                              onConfirmed: _onCashReceived,
                                              isDisabled:
                                                  _cashActionInProgress,
                                              backgroundColor:
                                                  AppColors.success,
                                              height: 48,
                                              borderRadius: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Semantics(
                                            button: true,
                                            label: 'Mark as unpaid',
                                            child: SwipeButton(
                                              label: AppLocalizations.of(
                                                      context)
                                                  .didNotPay,
                                              processingLabel:
                                                  AppLocalizations.of(context)
                                                      .processing,
                                              icon: Icons.cancel,
                                              onConfirmed: _onCashUnpaid,
                                              isDisabled:
                                                  _cashActionInProgress,
                                              backgroundColor: AppColors.error,
                                              height: 48,
                                              borderRadius: 14,
                                            ),
                                          ),
                                        ],
                                      )
                                    : _buildWaitingForPayment()
                                : Semantics(
                                    button: true,
                                    label: 'Complete ride',
                                    child: SwipeButton(
                                      key: const ValueKey('complete_ride'),
                                      label: AppLocalizations.of(context)
                                          .completeRide,
                                      processingLabel:
                                          AppLocalizations.of(context)
                                              .completing,
                                      icon: Icons.flag,
                                      onConfirmed: _completeRide,
                                      isDisabled: _isCompleting,
                                      backgroundColor: AppColors.error,
                                      height: 52,
                                      borderRadius: 14,
                                    ),
                                  )
                            : Semantics(
                                button: true,
                                label: 'Start ride',
                                child: SwipeButton(
                                  key: const ValueKey('start_ride'),
                                  label: AppLocalizations.of(context).startRide,
                                  icon: Icons.play_arrow,
                                  onConfirmed: _startRide,
                                  backgroundColor: AppColors.success,
                                  height: 52,
                                  borderRadius: 14,
                                ),
                              ),
                      ),
                    ],
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
            SnackBar(
              content: Text(AppLocalizations.of(context).couldNotOpenMapsLinkCopiedToClipboard),
              duration: const Duration(seconds: 3),
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
    _driverAnimTimer?.cancel();
    _rideTimer?.cancel();
    _paymentPollTimer?.cancel();
    _rideEventsSub?.cancel();
    mapController?.dispose();
    BackgroundNavigationService().stop();
    super.dispose();
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;
  const _PulseAnimation({required this.child});

  @override
  State<_PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(opacity: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
