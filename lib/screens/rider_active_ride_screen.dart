import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/currency_service.dart';
import '../services/directions_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

import '../utils/marker_utils.dart';
import '../utils/bearing_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/address_utils.dart';
import '../widgets/cancel_ride_dialog.dart';
import '../widgets/payment_dialog.dart';
import '../services/recorded_screen_mixin.dart';
import '../services/event_recorder_service.dart';

class RiderActiveRideScreen extends StatefulWidget {
  final int rideId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double? initialDriverLat;
  final double? initialDriverLng;

  const RiderActiveRideScreen({
    super.key,
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    this.initialDriverLat,
    this.initialDriverLng,
  });

  @override
  State<RiderActiveRideScreen> createState() => _RiderActiveRideScreenState();
}

class _RiderActiveRideScreenState extends State<RiderActiveRideScreen> with RecordedScreenMixin<RiderActiveRideScreen> {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  LatLng? _riderLocation;
  Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  int _remainingMinutes = 0;
  String? _driverName;
  int? _otherUserId;
  bool _rideCompleting = false;
  bool _paymentInProgress = false;
  double _paymentAmount = 0.0;
  double _driverHeading = 0;
  BitmapDescriptor _carIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _userLocationMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  Timer? _driverAnimTimer;
  LatLng? _animatedDriverPos;

  Timer? _statusPollTimer;
  Timer? _paymentPollTimer;
  bool _paymentPollInProgress = false;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  Timer? _driverTimeout;
  Timer? _routeDebounceTimer;
  StreamSubscription<String>? _connectionStateSub;
  bool _wasDisconnected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDriverLat != null && widget.initialDriverLng != null) {
      _driverLocation = LatLng(widget.initialDriverLat!, widget.initialDriverLng!);
    }
    recordEvent(
      eventName: 'SCREEN_OPENED',
      category: 'FRONTEND',
      summary: 'RiderActiveRideScreen opened',
    );
    _loadMapStyle();
    _initCarIcon();
    _initYellowPin();
    _initUserLocationMarker();
    _setupWebSocketListeners();
    _getRiderLocation();
    _updateRoute();
    _fetchDriverInfo();
    _startStatusPolling();
    _driverTimeout = Timer(const Duration(seconds: 3), _fetchDriverCurrentLocation);

    _setupConnectionStateListener();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 ACTIVE RIDE');
    addDebugMessage('Destination: ${widget.dropoffAddress}');
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
        addDebugMessage('🔄 WebSocket reconnected - rehydrating ride state');
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
      if (ride == null || !mounted || _rideCompleting) return;

      if (ride.driverLatitude != null && ride.driverLongitude != null) {
        setState(() {
          _driverLocation = LatLng(ride.driverLatitude!, ride.driverLongitude!);
          _driverName = ride.driver?.fullName ?? _driverName;
          _otherUserId = ride.driver?.id ?? _otherUserId;
        });
        _updateMarkers();
        _updateRoute();
        addDebugMessage('✅ Ride state rehydrated after reconnect');
      }

      if (ride.status == 'CANCELLED') {
        if (_rideCompleting) return;
        _rideCompleting = true;
        _statusPollTimer?.cancel();
        ChatScreen.clearAllCache();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/rider-home',
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ride.cancellationReason ?? 'The ride was cancelled'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (ride.status == 'COMPLETED') {
        if (_paymentInProgress || _rideCompleting) return;
        _rideCompleting = true;
        _statusPollTimer?.cancel();
        addDebugMessage('✅ Reconnect detected ride COMPLETED');
        ChatScreen.clearAllCache();

        final paymentStatus = await RideService.getPaymentStatus(widget.rideId, token);
        if (!mounted) return;
        final status = paymentStatus?['status'] as String?;
        if (status == 'COMPLETED') {
          _paymentInProgress = false;
          _rideCompleting = false;
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/rider-completed',
              arguments: {
                'rideId': widget.rideId,
                'totalFare': paymentStatus?['amount'] ?? ride.finalFare,
              },
            );
          }
          return;
        }

        _handlePayment(totalFare: ride.finalFare);
        return;
      }
    } catch (e) {
      addDebugMessage('⚠️ Reconnect rehydration error: $e');
    }
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
    if (mounted) _updateMarkers();
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
        _driverTimeout?.cancel();
        _driverTimeout = null;
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

            addDebugMessage(
              'driver_location heading=$_driverHeading '
              'from(${prev?.latitude.toStringAsFixed(5) ?? '?'},${prev?.longitude.toStringAsFixed(5) ?? '?'}) '
              'to(${_driverLocation!.latitude.toStringAsFixed(5)},${_driverLocation!.longitude.toStringAsFixed(5)})'
            );

          _routeDebounceTimer?.cancel();
          _routeDebounceTimer = Timer(const Duration(milliseconds: 1500), _updateRoute);
        }
      });

      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        if (!mounted) return;
        if (event['type'] == 'ride_completed') {
          recordEvent(
            eventName: 'RIDE_COMPLETED',
            category: 'FRONTEND',
            summary: 'Ride completed by driver',
          );
          if (_rideCompleting) return;
          _rideCompleting = true;
          _statusPollTimer?.cancel();
          ChatScreen.clearAllCache();
          final payload = event['payload'] as Map<String, dynamic>? ?? {};
          _handlePayment(
            totalFare: payload['totalFare'] ?? 0.0,
            paymentMethod: payload['paymentMethod'] as String? ?? 'WALLET',
          );
        } else if (event['type'] == 'payment_finalized') {
          if (!_paymentInProgress) return;
          _paymentInProgress = false;
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/rider-completed',
              arguments: {
                'rideId': widget.rideId,
                'totalFare': event['payload']?['totalFare'],
                'paymentStatus': 'PAID',
              },
            );
          }
        } else if (event['type'] == 'payment_refunded') {
          if (!_paymentInProgress) return;
          _paymentInProgress = false;
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/rider-completed',
              arguments: {
                'rideId': widget.rideId,
                'totalFare': event['payload']?['totalFare'],
                'paymentStatus': 'REFUNDED',
              },
            );
          }
        } else if (event['type'] == 'ride_cancelled') {
          recordEvent(
            eventName: 'RIDE_CANCELLED',
            category: 'FRONTEND',
            summary: 'Ride cancelled via WebSocket',
          );
          _statusPollTimer?.cancel();
          ChatScreen.clearAllCache();
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/rider-home',
            (route) => false,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(event['reason'] as String? ?? 'The ride was cancelled'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error: $e');
    }
  }

  Future<void> _handlePayment({required dynamic totalFare, String paymentMethod = 'WALLET'}) async {
    _paymentAmount = (totalFare as num?)?.toDouble() ?? 0.0;

    if (paymentMethod == 'CASH') {
      final confirmed = await showRecordedDialog<bool>(
        context: context,
        dialogType: 'cash_payment',
        dialogText: 'Cash Payment confirmation',
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
          title: const Text('Cash Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please pay the driver directly:'),
              const SizedBox(height: 16),
              Text(
                '${CurrencyService.format(_paymentAmount)}',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Fare',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/rider-completed',
          arguments: {
            'rideId': widget.rideId,
            'totalFare': _paymentAmount,
            'paymentStatus': 'CASH',
          },
        );
      }
      return;
    }

    _paymentInProgress = true;
    _startPaymentPolling();

    final result = await showPaymentDialog(context, amount: _paymentAmount);
    if (result != null && result.confirmed && mounted) {
      await _confirmPaymentWithRetry();
    } else {
      _paymentPollTimer?.cancel();
      _paymentInProgress = false;
      _rideCompleting = false;
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/rider-home', (route) => false);
      }
    }
  }

  Future<void> _confirmPaymentWithRetry() async {
    while (mounted) {
      final token = StorageService.getToken();
      if (token == null) return;

      String? error;
      try {
        error = await RideService.confirmPayment(widget.rideId, token);
      } catch (e) {
        addDebugMessage('⚠️ Payment confirm error: $e');
        error = 'Unexpected error: $e';
      }

      if (error == null && mounted) {
        _paymentInProgress = false;
        _rideCompleting = false;
        Navigator.pushReplacementNamed(
          context,
          '/rider-completed',
          arguments: {
            'rideId': widget.rideId,
            'totalFare': _paymentAmount,
          },
        );
        return;
      }

      if (!mounted) return;

      final retry = await showRecordedDialog<bool>(
        context: context,
        dialogType: 'payment_retry',
        dialogText: 'Payment Failed retry dialog',
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
          title: const Text('Payment Failed'),
          content: Text(error ?? 'Payment confirmation failed'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (retry != true) {
        _paymentPollTimer?.cancel();
        _paymentInProgress = false;
        _rideCompleting = false;
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/rider-home', (route) => false);
        }
        return;
      }
    }
  }

  void _startPaymentPolling() {
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!mounted || !_paymentInProgress || _paymentPollInProgress) {
        if (!mounted || !_paymentInProgress) _paymentPollTimer?.cancel();
        return;
      }
      _paymentPollInProgress = true;

      final token = StorageService.getToken();
      if (token == null) { _paymentPollInProgress = false; return; }

      final status = await RideService.getPaymentStatus(widget.rideId, token);
      if (!mounted || !_paymentInProgress) {
        _paymentPollInProgress = false;
        _paymentPollTimer?.cancel();
        return;
      }
      _paymentPollInProgress = false;

      if (status == null) return;

      final paymentStatus = status['status'] as String?;
      if (paymentStatus == 'COMPLETED') {
        _paymentPollTimer?.cancel();
        _paymentInProgress = false;
        _rideCompleting = false;
        Navigator.pushReplacementNamed(
          context,
          '/rider-completed',
          arguments: {
            'rideId': widget.rideId,
            'totalFare': status['amount'] ?? _paymentAmount,
          },
        );
      }
    });
  }

  void _startStatusPolling() {
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || _rideCompleting) return;
      try {
        final token = StorageService.getToken();
        if (token == null) return;
        final ride = await RideService.getRideDetails(widget.rideId, token);
        if (ride == null || !mounted || _rideCompleting) return;

        if (ride.status == 'CANCELLED') {
          if (_rideCompleting) return;
      recordEvent(
        eventName: 'RIDE_CANCELLED',
        category: 'FRONTEND',
        summary: 'Poll detected ride cancelled',
      );
      _rideCompleting = true;
      _statusPollTimer?.cancel();
      ChatScreen.clearAllCache();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/rider-home',
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ride.cancellationReason ?? 'The ride was cancelled'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (ride.status == 'COMPLETED') {
      recordEvent(
        eventName: 'RIDE_COMPLETED',
        category: 'FRONTEND',
        summary: 'Poll detected ride completed',
      );
          if (_paymentInProgress) return;
          _rideCompleting = true;
          _statusPollTimer?.cancel();
          addDebugMessage('✅ Poll detected ride COMPLETED');
          ChatScreen.clearAllCache();

          final paymentStatus = await RideService.getPaymentStatus(widget.rideId, token);
          final status = paymentStatus?['status'] as String?;
          if (status == 'COMPLETED') {
            _paymentInProgress = false;
            _rideCompleting = false;
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/rider-completed',
                arguments: {
                  'rideId': widget.rideId,
                  'totalFare': paymentStatus?['amount'] ?? ride.finalFare,
                },
              );
            }
            return;
          }

          _handlePayment(totalFare: ride.finalFare);
        }
      } catch (e) {
        addDebugMessage('⚠️ Status poll error: $e');
      }
    });
  }

  Future<void> _fetchDriverCurrentLocation() async {
    if (!mounted || _driverLocation != null) return;
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      addDebugMessage('Fetching driver location fallback...');
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || !mounted || _driverLocation != null) return;
      if (ride.driverLatitude != null && ride.driverLongitude != null) {
        setState(() {
          _driverLocation = LatLng(ride.driverLatitude!, ride.driverLongitude!);
        });
        _updateMarkers();
        _updateRoute();
        addDebugMessage('✅ Driver location from ride details API');
      }
    } catch (e) {
      addDebugMessage('⚠️ Fallback driver location error: $e');
    }
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
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



  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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
          label: 'Cancel ride',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
            onPressed: _showCancelRideDialog,
          ),
        ),
        title: Text(
          'En Route',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Semantics(
                button: true,
                label: 'Chat with driver',
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
                  tooltip: 'Chat with Driver',
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
                  top: Radius.circular(AppRadius.xl),
                ),
                boxShadow: AppShadows.large,
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Estimated arrival',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppSpacing.gapSm,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            AppSpacing.hGapSm,
                            Text(
                              '$_remainingMinutes min remaining',
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
                  ),
                  AppSpacing.gapLg,

                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 0.65),
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
                  AppSpacing.gapLg,

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
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
                            Text(
                              'Destination',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AppSpacing.gapXs,
                            Text(
                              widget.dropoffAddress,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatLatLng(
                                  widget.dropoffLat, widget.dropoffLng),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                              ),
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
                          radius: 16,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            _driverName![0].toUpperCase(),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            _driverName!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
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
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Semantics(
                                button: true,
                                label: 'Chat with driver',
                                child: IconButton(
                                  icon: const Icon(Icons.chat_rounded,
                                      color: AppColors.primary, size: 20),
                                  onPressed: _openChat,
                                ),
                              ),
                            ),
                            _buildUnreadBadge(),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
      addDebugMessage('❌ Chat error: $e');
    }
  }

  Future<void> _showCancelRideDialog() async {
    await showRecordedDialog(
      context: context,
      dialogType: 'cannot_cancel',
      dialogText: 'Cannot cancel ride dialog',
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlRadius),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Text('Cannot Cancel'),
          ],
        ),
        content: const Text(
          'The trip has already started. Please ask your driver to cancel the ride.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rideCompleting = false;
    _driverAnimTimer?.cancel();
    _statusPollTimer?.cancel();
    _paymentPollTimer?.cancel();
    _driverTimeout?.cancel();
    _routeDebounceTimer?.cancel();
    _rideEventsSub?.cancel();
    _driverLocationSub?.cancel();
    _connectionStateSub?.cancel();
    mapController?.dispose();
    super.dispose();
  }
}
