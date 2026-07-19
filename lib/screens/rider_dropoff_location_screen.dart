import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/directions_service.dart';
import '../services/websocket_service.dart';
import '../services/location_service.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../utils/bearing_utils.dart';
import '../utils/address_utils.dart';
import '../models/ride_model.dart';
import '../screens/debug_screen.dart';
import '../screens/rider_searching_driver_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/glass_card.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class RiderDropoffLocationScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final Ride? initialTrip;

  const RiderDropoffLocationScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.initialTrip,
  });

  @override
  State<RiderDropoffLocationScreen> createState() =>
      _RiderDropoffLocationScreenState();
}

class _RiderDropoffLocationScreenState
    extends State<RiderDropoffLocationScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;

  LatLng? _dropoffLocation;
  String _dropoffAddress = '';

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _currentPolylinePoints = [];

  bool _isLoadingAddress = false;
  bool _isLoadingRoute = false;

  Timer? _addressLookupTimer;

  bool _isDropoffConfirmed = false;

  LatLng? _lastRoutedDestination;
  DateTime? _lastRouteAt;

  bool _loggedGeocodingErrorOnce = false;

  // Driver markers on map
  final Map<String, Marker> _driverMarkers = {};
  final Map<String, LatLng> _lastPollPositions = {};
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  Timer? _driverPollTimer;

  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _stickPickupIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _stickDropoffIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _dotMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  double? _routeDistanceKm;
  int? _routeDurationMin;

  // Trip details panel state
  bool _showTripDetails = false;
  bool _isAutoReviewing = false;
  String _selectedRideType = 'ECONOMY';
  String _selectedPaymentMethod = 'CASH';
  double _selectedFare = 0.0;
  bool _isSubmitting = false;

  // Pulse animation
  Timer? _dotTimer;
  double _dotProgress = 0.0;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;
  late DraggableScrollableController _sheetController;
  bool _isSheetExpanded = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.decelerate),
    );
    _bounceController.addListener(() => setState(() {}));

    _sheetController = DraggableScrollableController();
    _sheetController.addListener(() {
      if (_sheetController.size > 0.4) {
        if (!_isSheetExpanded) setState(() => _isSheetExpanded = true);
      } else {
        if (_isSheetExpanded) setState(() => _isSheetExpanded = false);
      }
    });

    _loadMapStyle();

    if (widget.initialTrip != null) {
      final trip = widget.initialTrip!;
      _dropoffLocation = LatLng(trip.dropoffLatitude, trip.dropoffLongitude);
      _dropoffAddress = trip.dropoffAddress;
      _isAutoReviewing = true;
      _calculateRoute(
        LatLng(widget.pickupLat, widget.pickupLng),
        _dropoffLocation!,
      );
    } else {
      _dropoffLocation = LatLng(widget.pickupLat, widget.pickupLng);
    }
    _updateMarkers();

    if (!_isAutoReviewing) {
      _lookupAddress(_dropoffLocation!);
    }
    _initDriverMarkerIcon();
    _initYellowPin();
    _initStickPickupIcon();
    _initStickDropoffIcon();
    _initDotMarker();
    _startDriverPolling();
    _setupDriverLocationListener();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(
          LatLng(widget.pickupLat, widget.pickupLng), 17),
    );
  }

  void _onCameraMove(CameraPosition position) {
    if (_isDropoffConfirmed || _isSheetExpanded || _isAutoReviewing) return;

    _dropoffLocation = position.target;
    _bounceController.reset();
    _updateMarkers();
  }

  Future<void> _onCameraIdle() async {
    try {
      if (mapController == null) return;

      if (_isDropoffConfirmed || _isSheetExpanded || _isAutoReviewing) return;

      final region = await mapController!.getVisibleRegion();
      final center = LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );

      _dropoffLocation = center;
      _updateMarkers();
      _bounceController.forward(from: 0.0);
      _lookupAddress(center);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Dropoff onCameraIdle error: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_stickPickupIcon != BitmapDescriptor.defaultMarker) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLng),
          icon: _stickPickupIcon,
          anchor: const Offset(0.5, 0.85),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    if (mounted) setState(() {});
  }

  Future<void> _lookupAddress(LatLng location) async {
    _addressLookupTimer?.cancel();

    _addressLookupTimer = Timer(const Duration(milliseconds: 450), () async {
      if (!mounted) return;

      setState(() => _isLoadingAddress = true);

      String address = '';

      try {
        final formattedAddress = await LocationService.getFormattedAddress(
          location.latitude,
          location.longitude,
        );

        if (formattedAddress != null && formattedAddress.isNotEmpty) {
          address = formattedAddress;
        } else {
          address =
              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
        }

        if (!mounted) return;
        setState(() {
          _dropoffAddress = address;
          _isLoadingAddress = false;
        });

        if (!_isDropoffConfirmed) {
          await _calculateRouteIfNeeded();
        }
      } catch (e) {
        if (!_loggedGeocodingErrorOnce) {
          _loggedGeocodingErrorOnce = true;
          if (kDebugMode) {
              debugPrint(
                '⚠️ Reverse geocoding failed once (dropoff). Using Lat/Lng fallback. Error: $e',
            );
          }
        }

        if (!mounted) return;
        setState(() {
          _dropoffAddress = address;
          _isLoadingAddress = false;
        });

        if (!_isDropoffConfirmed) {
          await _calculateRouteIfNeeded();
        }
      }
    });
  }

  Future<void> _calculateRouteIfNeeded() async {
    if (_dropoffLocation == null) return;

    final origin = LatLng(widget.pickupLat, widget.pickupLng);
    final dest = _dropoffLocation!;

    final kmFromPickup = _haversineKm(origin, dest);
    if (kmFromPickup < 0.05) {
      if (mounted) {
        setState(() {
          _polylines.clear();
          _currentPolylinePoints = [];
          _routeDistanceKm = null;
          _routeDurationMin = null;
          _isLoadingRoute = false;
        });
      }
      return;
    }

    final now = DateTime.now();
    if (_lastRouteAt != null &&
        now.difference(_lastRouteAt!).inMilliseconds < 900) {
      return;
    }

    if (_lastRoutedDestination != null) {
      final movedKm = _haversineKm(_lastRoutedDestination!, dest);
      if (movedKm < 0.07) return;
    }

    _lastRouteAt = now;
    _lastRoutedDestination = dest;

    await _calculateRoute(origin, dest);
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    if (_isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

    try {
      final result = await DirectionsService.getDirections(
        origin: origin,
        destination: destination,
      );

      if (!mounted) return;

      if (result == null || !result.isSuccess) {
        setState(() => _isLoadingRoute = false);
        return;
      }

      final points = result.polylinePoints ?? <LatLng>[];

      _polylines.clear();
      _currentPolylinePoints = points;

      if (points.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: AppColors.primary,
            width: 3,
            geodesic: true,
          ),
        );
      }

      setState(() {
        _routeDistanceKm = result.distanceKm;
        _routeDurationMin = result.durationMinutes;
        _isLoadingRoute = false;
      });
      if (_isAutoReviewing) _autoShowReview();
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoute = false);
      if (kDebugMode) debugPrint('❌ Route calculation error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // DRIVER MARKERS
  // ═════════════════════════════════════════════════════════════════

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initStickPickupIcon() async {
    _stickPickupIcon = await MarkerFactory.stickPickup;
    if (mounted) _updateMarkers();
  }

  Future<void> _initStickDropoffIcon() async {
    _stickDropoffIcon = await MarkerFactory.stickDropoff;
    if (mounted) setState(() {});
  }

  Future<void> _initDotMarker() async {
    _dotMarker = await MarkerFactory.userLocation;
  }

  Future<void> _initDriverMarkerIcon() async {
    try {
      _driverMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      addDebugMessage('⚠️ Car icon fallback: $e');
      _driverMarkerIcon = await MarkerFactory.driver;
    }
  }

  void _startDriverPolling() {
    _fetchNearbyDrivers();
    _driverPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _fetchNearbyDrivers();
    });
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_dropoffLocation == null) return;
    try {
      final drivers = await DriverService.getNearbyDrivers(
        latitude: _dropoffLocation!.latitude,
        longitude: _dropoffLocation!.longitude,
        radiusKm: 5.0,
      );
      if (!mounted) return;
      _updateDriverMarkers(drivers);
      addDebugMessage('📍 Nearby drivers found: ${_driverMarkers.length}');
    } catch (e) {
      addDebugMessage('❌ Error fetching nearby drivers: $e');
    }
  }

  void _updateDriverMarkers(List<DriverProfile> drivers) {
    final currentIds = <String>{};
    for (final driver in drivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null)
        continue;
      if (!driver.isOnline) continue;
      final driverId = driver.user.id;
      if (driverId == null) continue;
      final id = 'driver_$driverId';
      currentIds.add(id);
      final position =
          LatLng(driver.currentLatitude!, driver.currentLongitude!);
      final existing = _driverMarkers[id];
      final lastPollPos = _lastPollPositions[id];
      double rotation;
      if (existing == null) {
        rotation = 0;
      } else if (lastPollPos != null && lastPollPos != position) {
        rotation = _bearingBetween(lastPollPos, position);
      } else {
        rotation = existing.rotation;
      }
      _lastPollPositions[id] = position;
      _driverMarkers[id] = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: _driverMarkerIcon,
        rotation: normalizeCarHeading(rotation),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(title: driver.user.fullName),
      );
    }
    _driverMarkers.removeWhere((key, _) => !currentIds.contains(key));
    _lastPollPositions.removeWhere((key, _) => !currentIds.contains(key));
    if (mounted) setState(() {});
  }

  void _loadMapStyle() {
    _mapStyle = MapStyleLoader.cachedStyle;
  }

  void _setupDriverLocationListener() {
    _driverLocationSub?.cancel();
    _driverLocationSub = WebSocketService.driverLocationEvents.listen((event) {
      _handleDriverLocationEvent(event);
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



  void _handleDriverLocationEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';
    final payload = event['payload'] as Map<String, dynamic>? ?? event;
    final driverId = payload['driverId'];
    final lat = payload['latitude'] ?? payload['lat'];
    final lng = payload['longitude'] ?? payload['lng'];
    if (driverId == null || lat == null || lng == null) return;
    final id = 'driver_$driverId';
    final position = LatLng((lat as num).toDouble(), (lng as num).toDouble());

    final existing = _driverMarkers[id];
    if (type == 'driver_heading') {
      if (existing == null) return;
      final heading = payload['heading'];
      if (heading == null) return;
      final rotation = normalizeCarHeading((heading as num).toDouble() % 360);
      if (existing.rotation == rotation) return;
      _driverMarkers[id] = Marker(
        markerId: existing.markerId,
        position: existing.position,
        icon: _driverMarkerIcon,
        rotation: rotation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: existing.infoWindow,
      );
      if (mounted) setState(() {});
      return;
    }

    if (existing != null && existing.position == position) return;

    final heading = payload['heading'];
    double rotation;
    if (heading != null) {
      rotation = normalizeCarHeading((heading as num).toDouble() % 360);
    } else if (existing != null) {
      rotation = normalizeCarHeading(_bearingBetween(existing.position, position));
    } else {
      rotation = normalizeCarHeading(0);
    }

    _driverMarkers[id] = Marker(
      markerId: MarkerId(id),
      position: position,
      icon: _driverMarkerIcon,
      rotation: rotation,
      anchor: const Offset(0.5, 0.5),
      flat: true,
      infoWindow:
          existing?.infoWindow ?? InfoWindow(title: 'Driver #$driverId'),
    );
    if (mounted) setState(() {});
  }

  void _confirmDropoffPoint() {
    if (_dropoffLocation == null) return;

    if (_routeDistanceKm == null || _routeDurationMin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculating route...'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    _fitBoundsToRouteForReview();
    _selectedFare = _calculateFare('ECONOMY');
    setState(() {
      _isDropoffConfirmed = true;
      _showTripDetails = true;
    });
    _startMovingDotAnimation();
  }

  void _autoShowReview() {
    _selectedFare = _calculateFare('ECONOMY');
    setState(() {
      _isDropoffConfirmed = true;
      _showTripDetails = true;
    });
    _startMovingDotAnimation();
  }

  void _fitBoundsToRouteForReview() {
    if (mapController == null) return;
    if (_currentPolylinePoints.isEmpty) return;

    double minLat = _currentPolylinePoints.first.latitude;
    double maxLat = _currentPolylinePoints.first.latitude;
    double minLng = _currentPolylinePoints.first.longitude;
    double maxLng = _currentPolylinePoints.first.longitude;

    for (final p in _currentPolylinePoints) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 140));
  }

  void _changeDropoff() {
    setState(() {
      _isDropoffConfirmed = false;
      _isSheetExpanded = false;
    });
  }

  double _calculateFare(String rideType) {
    double baseFare;
    double ratePerKm;
    switch (rideType) {
      case 'LUXURY':
        baseFare = 6.0;
        ratePerKm = 0.50;
        break;
      case 'COMFORT':
        baseFare = 4.0;
        ratePerKm = 0.35;
        break;
      case 'WOMEN_DRIVER':
        baseFare = 3.0;
        ratePerKm = 0.25;
        break;
      case 'ECONOMY':
      default:
        baseFare = 2.0;
        ratePerKm = 0.20;
        break;
    }
    return baseFare + ((_routeDistanceKm ?? 0.0) * ratePerKm);
  }

  double _getRatePerKm(String rideType) {
    switch (rideType) {
      case 'LUXURY':
        return 0.50;
      case 'COMFORT':
        return 0.35;
      case 'WOMEN_DRIVER':
        return 0.25;
      case 'ECONOMY':
      default:
        return 0.20;
    }
  }

  void _updateRideType(String rideType) {
    setState(() {
      _selectedRideType = rideType;
      _selectedFare = _calculateFare(rideType);
    });
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildPaymentOption('WALLET', Icons.account_balance_wallet),
            _buildPaymentOption('CASH', Icons.money),
            _buildPaymentOption('CARD', Icons.credit_card),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  LatLng _interpolateAlongRoute(double progress) {
    if (_currentPolylinePoints.isEmpty) return LatLng(widget.pickupLat, widget.pickupLng);
    if (_currentPolylinePoints.length == 1) return _currentPolylinePoints.first;
    if (progress >= 1.0) return _currentPolylinePoints.last;
    if (progress <= 0.0) return _currentPolylinePoints.first;

    final totalSegments = _currentPolylinePoints.length - 1;
    final rawIndex = progress * totalSegments;
    final segIndex = rawIndex.floor();
    final segProgress = rawIndex - segIndex;

    final from = _currentPolylinePoints[segIndex];
    final to = _currentPolylinePoints[segIndex + 1];
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * segProgress,
      from.longitude + (to.longitude - from.longitude) * segProgress,
    );
  }

  void _startMovingDotAnimation() {
    _dotTimer?.cancel();
    _dotProgress = 0.0;
    _dotTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!mounted) return;
      setState(() {
        _dotProgress += 0.008;
        if (_dotProgress >= 1.2) {
          _dotProgress = 0.0;
        }
      });
    });
  }

  void _stopMovingDotAnimation() {
    _dotTimer?.cancel();
    _dotTimer = null;
    _dotProgress = 0.0;
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(method),
      trailing: _selectedPaymentMethod == method
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        Navigator.pop(context);
      },
    );
  }

  void _dismissTripDetails() {
    _stopMovingDotAnimation();
    if (_isAutoReviewing) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _showTripDetails = false;
      _isSheetExpanded = false;
    });
  }

  Future<void> _submitRideRequest() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📤 SUBMITTING RIDE REQUEST');
      addDebugMessage('Type: $_selectedRideType');
      addDebugMessage('Payment: $_selectedPaymentMethod');
      addDebugMessage('═══════════════════════════════════════');

      final token = StorageService.getToken();
      if (token == null) {
        _showError('Authentication error');
        return;
      }

      final dropoffAddress = _dropoffAddress.isEmpty
          ? 'Dropoff location'
          : _dropoffAddress;

      final ride = await RideService.requestRide(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        pickupAddress: widget.pickupAddress,
        dropoffLat: _dropoffLocation!.latitude,
        dropoffLng: _dropoffLocation!.longitude,
        dropoffAddress: dropoffAddress,
        rideType: _selectedRideType,
        paymentMethod: _selectedPaymentMethod,
        estimatedDistance: _routeDistanceKm ?? 0.0,
        estimatedFare: _selectedFare,
        estimatedDuration: _routeDurationMin ?? 0,
        token: token,
      );

      if (ride != null && mounted) {
        _stopMovingDotAnimation();
        addDebugMessage('✅ Ride created: ${ride.id}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiderSearchingDriverScreen(
              rideId: ride.id!,
              pickupAddress: widget.pickupAddress,
              dropoffAddress: dropoffAddress,
              estimatedFare: _selectedFare,
            ),
          ),
        );
      } else {
        _showError('Failed to request ride');
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLng = _degToRad(b.longitude - a.longitude);

    final aa = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(a.latitude)) *
            math.cos(_degToRad(b.latitude)) *
            (math.sin(dLng / 2) * math.sin(dLng / 2));

    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return r * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  @override
  Widget build(BuildContext context) {
    final initial = LatLng(widget.pickupLat, widget.pickupLng);

    final routeReady = !_isLoadingRoute &&
        _routeDistanceKm != null &&
        _routeDurationMin != null;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: CameraPosition(target: initial, zoom: 15),
            markers: {
              ..._markers,
              ..._driverMarkers.values.toSet(),
              if (_isDropoffConfirmed && _dropoffLocation != null && _stickDropoffIcon != BitmapDescriptor.defaultMarker)
                Marker(
                  markerId: const MarkerId('dropoff'),
                  position: _dropoffLocation!,
                  icon: _stickDropoffIcon,
                  anchor: const Offset(0.5, 0.85),
                  infoWindow: const InfoWindow(title: 'Dropoff'),
                ),
              if (_showTripDetails && _currentPolylinePoints.length > 1 && _dotProgress <= 1.0)
                Marker(
                  markerId: const MarkerId('moving_dot'),
                  position: _interpolateAlongRoute(_dotProgress),
                  icon: _dotMarker,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 10,
                ),
            },
            polylines: _showTripDetails ? _polylines : {},
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            scrollGesturesEnabled: !_isSheetExpanded,
            zoomGesturesEnabled: !_isSheetExpanded,
            rotateGesturesEnabled: !_isSheetExpanded,
            tiltGesturesEnabled: !_isSheetExpanded,
            style: _mapStyle,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
                title: const Text(
                  'Set Destination',
                  style: TextStyle(color: AppColors.primary),
                ),
                centerTitle: true,
              ),
            ),
          ),
          if (!_isDropoffConfirmed)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: _buildDropPin(_bounceAnim.value),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: GlassCard(
              borderRadius: AppSpacing.radiusXxl,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (!_isDropoffConfirmed) ...[
                    // Phase 1: Selecting dropoff
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.pickupMarker,
                          ),
                          child: const Center(
                            child: Text('A',
                                style: TextStyle(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.bold)),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.pickupAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text(
                                formatLatLng(
                                    widget.pickupLat, widget.pickupLng),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.warning,
                          ),
                          child: const Center(
                            child: Text('B',
                                style: TextStyle(
                                  color: AppColors.primaryLight,
                                  fontWeight: FontWeight.bold)),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dropoffAddress.isEmpty
                                    ? 'Move map to set dropoff'
                                    : _dropoffAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                              if (_dropoffLocation != null &&
                                  _dropoffAddress.isNotEmpty)
                                Text(
                                  formatLatLng(_dropoffLocation!.latitude,
                                      _dropoffLocation!.longitude),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textTertiary),
                                ),
                            ],
                          ),
                        ),
                        if (_isLoadingAddress)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    if (_isLoadingRoute)
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          AppSpacing.hGapSm,
                          Text('Calculating route...'),
                        ],
                      ),
                    AppSpacing.gapMd,
                    PremiumButton(
                      label: 'Confirm drop-off point',
                      onPressed: routeReady ? _confirmDropoffPoint : null,
                      variant: ButtonVariant.gradient,
                    ),
                  ] else if (!_showTripDetails) ...[
                    // Dropoff confirmed, sheet not visible — show minimal card
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trip_origin,
                            color: AppColors.pickupMarker, size: 24),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pickup',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(widget.pickupAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                formatLatLng(
                                    widget.pickupLat, widget.pickupLng),
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            color: AppColors.dropoffMarker, size: 24),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Dropoff',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                _dropoffAddress.isEmpty
                                    ? 'Dropoff location'
                                    : _dropoffAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                              if (_dropoffLocation != null &&
                                  _dropoffAddress.isNotEmpty)
                                Text(
                                  formatLatLng(_dropoffLocation!.latitude,
                                      _dropoffLocation!.longitude),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textTertiary),
                                ),
                            ],
                          ),

                      
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xxl),
                    if (_routeDistanceKm != null && _routeDurationMin != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _routeInfoChip(Icons.route,
                              '${_routeDistanceKm!.toStringAsFixed(1)} km'),
                          _routeInfoChip(
                              Icons.access_time, '$_routeDurationMin min'),
                        ],
                      ),
                    AppSpacing.gapSm,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _changeDropoff,
                        child: const Text('Change drop-off',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                    AppSpacing.gapSm,
                    PremiumButton(
                      label: 'Review Ride',
                      onPressed: () {
                        setState(() => _showTripDetails = true);
                        _startMovingDotAnimation();
                      },
                      variant: ButtonVariant.gradient,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_showTripDetails) _buildTripDetailsSheet(),
        ],
      ),
    );
  }

  Widget _buildDropPin(double bounce) {
    return SizedBox(
      width: 48,
      height: 80,
      child: CustomPaint(
        painter: _DropPinPainter(bounce: bounce),
      ),
    );
  }

  Widget _buildTripDetailsSheet() {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textTertiary),
                    onPressed: _dismissTripDetails,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ),
              // Addresses
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.trip_origin, color: AppColors.pickupMarker, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pickupAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          formatLatLng(widget.pickupLat, widget.pickupLng),
                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: List.generate(3, (i) => Container(
                    width: 2, height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  )),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: AppColors.dropoffMarker, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dropoffAddress.isEmpty
                              ? 'Dropoff location'
                              : _dropoffAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (_dropoffLocation != null && _dropoffAddress.isNotEmpty)
                          Text(
                            formatLatLng(_dropoffLocation!.latitude, _dropoffLocation!.longitude),
                            style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _routeInfoChip(Icons.route, '${_routeDistanceKm!.toStringAsFixed(1)} km'),
                  _routeInfoChip(Icons.access_time, '$_routeDurationMin min'),
                ],
              ),
              const Divider(height: 24),

              // Ride type selection
              const Text('Select ride type',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildRideTypeCard(
                type: 'ECONOMY', icon: Icons.local_taxi,
                description: 'Affordable, everyday rides', rate: '\$0.20/km',
                isSelected: _selectedRideType == 'ECONOMY',
              ),
              const SizedBox(height: 12),
              _buildRideTypeCard(
                type: 'LUXURY', icon: Icons.directions_car,
                description: 'Premium vehicles, top drivers', rate: '\$0.35/km',
                isSelected: _selectedRideType == 'LUXURY',
              ),
              const SizedBox(height: 12),
              _buildRideTypeCard(
                type: 'WOMEN_DRIVER', icon: Icons.face,
                description: 'Ride with a female driver', rate: '\$0.25/km',
                isSelected: _selectedRideType == 'WOMEN_DRIVER',
              ),
              const SizedBox(height: 16),

              // Payment method
              const Text('Payment method',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showPaymentMethodSelector,
                child: PremiumCard(
                  padding: const EdgeInsets.all(12),
                  hasRipple: true,
                  child: Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _selectedPaymentMethod == 'WALLET'
                              ? Icons.account_balance_wallet
                              : _selectedPaymentMethod == 'CASH' ? Icons.money : Icons.credit_card,
                          color: AppColors.primary, size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_selectedPaymentMethod,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 22),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price breakdown
              PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _priceRow('Base fare', '\$2.00'),
                    const SizedBox(height: 12),
                    _priceRow(
                      'Distance (${_routeDistanceKm!.toStringAsFixed(1)} km)',
                      '\$${(_routeDistanceKm! * _getRatePerKm(_selectedRideType)).toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _priceRow('Total', '\$${_selectedFare.toStringAsFixed(2)}', isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm button
              PremiumButton(
                label: _isSubmitting ? 'Requesting...' : 'Confirm Ride',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitRideRequest,
                icon: _isSubmitting ? null : Icons.check_circle_outline,
                variant: ButtonVariant.gradient,
                height: 56,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRideTypeCard({
    required String type,
    required IconData icon,
    required String description,
    required String rate,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _updateRideType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textTertiary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(type, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    )),
                    const SizedBox(height: 2),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(rate, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(height: 2),
                  Text('\$${_calculateFare(type).toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary)),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: AppColors.primaryLight, size: 16),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          fontSize: isTotal ? 14 : 13,
          fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
          color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
        )),
        Text(value, style: TextStyle(
          fontSize: isTotal ? 16 : 13,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
          color: isTotal ? AppColors.primary : AppColors.textPrimary,
        )),
      ],
    );
  }

  Widget _routeInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          AppSpacing.hGapXs,
          Text(text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13,
              )),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressLookupTimer?.cancel();
    _driverPollTimer?.cancel();
    _driverLocationSub?.cancel();
    _dotTimer?.cancel();
    _bounceController.dispose();
    _sheetController.dispose();
    if (!kIsWeb) {
      mapController?.dispose();
    }
    super.dispose();
  }
}

class _DropPinPainter extends CustomPainter {
  final double bounce;

  _DropPinPainter({this.bounce = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 8;
    final topY = 22.0;

    // ── Shadow (splashes on droplet impact) ──
    double shadowScale;
    if (bounce < 0.55) {
      shadowScale = 1.0;
    } else if (bounce < 0.75) {
      final splash = (bounce - 0.55) / 0.2;
      shadowScale = 1.0 + splash * 1.2;
    } else {
      final settle = (bounce - 0.75) / 0.25;
      shadowScale = 2.2 - settle * 1.2;
    }
    final shadowPaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, bottomY + 3),
        width: 10 * shadowScale,
        height: 4 * shadowScale,
      ),
      shadowPaint,
    );

    // ── Stick ──
    final stickPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, bottomY - 4),
      Offset(centerX, topY + 2),
      stickPaint,
    );

    // ── Bulb ──
    final tipPaint = Paint()
      ..color = AppColors.dropoffMarker
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, topY), 5, tipPaint);

    final centerPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, topY), 2, centerPaint);

    // ── Falling droplet ──
    if (bounce > 0.05 && bounce < 0.7) {
      final dropStart = topY + 6;
      final dropEnd = bottomY - 4;
      final t = ((bounce - 0.05) / 0.65).clamp(0.0, 1.0);
      final dropY = dropStart + (dropEnd - dropStart) * (t * t);
      final dropRadius = 3.0 * (1.0 - t * 0.4);
      canvas.drawCircle(Offset(centerX, dropY), dropRadius, tipPaint);
    }

    // ── Splash ring on impact ──
    if (bounce > 0.55 && bounce < 0.8) {
      final t = (bounce - 0.55) / 0.25;
      final ringRadius = 4 + t * 14;
      final ringPaint = Paint()
        ..color = AppColors.dropoffMarker.withValues(alpha: (1.0 - t) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(centerX, bottomY + 3), ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DropPinPainter oldDelegate) =>
      oldDelegate.bounce != bounce;
}
