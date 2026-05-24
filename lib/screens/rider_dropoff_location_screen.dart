import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/directions_service.dart';

class RiderDropoffLocationScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;

  const RiderDropoffLocationScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
  });

  @override
  State<RiderDropoffLocationScreen> createState() =>
      _RiderDropoffLocationScreenState();
}

class _RiderDropoffLocationScreenState extends State<RiderDropoffLocationScreen> {
  GoogleMapController? mapController;

  LatLng? _dropoffLocation;
  String _dropoffAddress = '';

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> _currentPolylinePoints = [];

  bool _isLoadingAddress = false;
  bool _isLoadingRoute = false;

  Timer? _addressLookupTimer;

  // ✅ Two-phase flow
  bool _isDropoffConfirmed = false;

  // ✅ prevent spam route calls
  LatLng? _lastRoutedDestination;
  DateTime? _lastRouteAt;

  // ✅ prevent spam geocoding errors
  bool _loggedGeocodingErrorOnce = false;

  double? _routeDistanceKm;
  int? _routeDurationMin;

  @override
  void initState() {
    super.initState();

    _dropoffLocation = LatLng(widget.pickupLat, widget.pickupLng);
    _updateMarkers();

    // Lookup once (safe fallback). Route calculation happens after user moves enough.
    _lookupAddress(_dropoffLocation!);
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(widget.pickupLat, widget.pickupLng), 15),
    );
  }

  Future<void> _onCameraIdle() async {
    try {
      if (mapController == null) return;

      // ✅ IMPORTANT: During review phase, moving map must NOT change dropoff
      if (_isDropoffConfirmed) return;

      final region = await mapController!.getVisibleRegion();
      final center = LatLng(
        (region.northeast.latitude + region.southwest.latitude) / 2,
        (region.northeast.longitude + region.southwest.longitude) / 2,
      );

      _dropoffLocation = center;
      _updateMarkers();
      _lookupAddress(center);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Dropoff onCameraIdle error: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        infoWindow: const InfoWindow(title: 'A - Pickup'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLocation!,
          infoWindow: const InfoWindow(title: 'B - Dropoff'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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

      // Always safe fallback
      String address =
          'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';

      try {
        // ✅ Reverse geocoding is unstable on Web; skip it on web
        if (!kIsWeb) {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(const Duration(seconds: 5), onTimeout: () => <Placemark>[]);

          if (placemarks.isNotEmpty) {
            final p = placemarks.first;

            final street = (p.street ?? '').trim();
            final locality = (p.locality ?? '').trim();
            final admin = (p.administrativeArea ?? '').trim();
            final country = (p.country ?? '').trim();

            final parts = <String>[
              if (street.isNotEmpty) street,
              if (locality.isNotEmpty) locality,
              if (admin.isNotEmpty) admin,
              if (country.isNotEmpty) country,
            ];

            final formatted = parts.join(', ').trim();
            if (formatted.isNotEmpty) address = formatted;
          }
        }

        if (!mounted) return;
        setState(() {
          _dropoffAddress = address;
          _isLoadingAddress = false;
        });

        // ✅ During selection phase, keep calculating route as user moves
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

    // Only calculate if moved enough away from pickup
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

    // Rate limit route calls
    final now = DateTime.now();
    if (_lastRouteAt != null && now.difference(_lastRouteAt!).inMilliseconds < 900) {
      return;
    }

    // Destination must change enough
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
            color: Colors.blue,
            width: 5,
            geodesic: true,
          ),
        );
      }

      setState(() {
        _routeDistanceKm = result.distanceKm;
        _routeDurationMin = result.durationMinutes;
        _isLoadingRoute = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingRoute = false);
      if (kDebugMode) debugPrint('❌ Route calculation error: $e');
    }
  }

  void _confirmDropoffPoint() {
    if (_dropoffLocation == null) return;

    if (_routeDistanceKm == null || _routeDurationMin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculating route...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // ✅ Lock selection (review phase)
    setState(() {
      _isDropoffConfirmed = true;
    });

    // Optional: fit bounds ONCE to show the whole route for review
    _fitBoundsToRouteForReview();
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
    // Return to selection phase
    setState(() {
      _isDropoffConfirmed = false;
    });
  }

  void _requestRide() {
    if (_dropoffLocation == null) return;

    if (_routeDistanceKm == null || _routeDurationMin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Route is not ready yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/rider-trip-details',
      arguments: {
        'pickupLat': widget.pickupLat,
        'pickupLng': widget.pickupLng,
        'pickupAddress': widget.pickupAddress,
        'dropoffLat': _dropoffLocation!.latitude,
        'dropoffLng': _dropoffLocation!.longitude,
        'dropoffAddress': _dropoffAddress.isEmpty
            ? 'Lat: ${_dropoffLocation!.latitude.toStringAsFixed(4)}, Lng: ${_dropoffLocation!.longitude.toStringAsFixed(4)}'
            : _dropoffAddress,
        'estimatedDistance': _routeDistanceKm!,
        'estimatedDuration': _routeDurationMin!,
        'rideType': 'ECONOMY',
        'estimatedFare': 0.0,
      },
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

    final routeReady =
        !_isLoadingRoute && _routeDistanceKm != null && _routeDurationMin != null;

    final primaryEnabled = _isDropoffConfirmed ? routeReady : routeReady;

    final primaryText = _isDropoffConfirmed ? 'Request Ride' : 'Confirm drop-off point';

    final primaryOnPressed = _isDropoffConfirmed ? _requestRide : _confirmDropoffPoint;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: CameraPosition(target: initial, zoom: 15),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Center red pin ONLY while selecting
          if (!_isDropoffConfirmed)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
            ),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                          ),
                          child: const Center(
                            child: Text('A',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.pickupAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                          child: const Center(
                            child: Text('B',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _dropoffAddress.isEmpty
                                ? (_isDropoffConfirmed
                                    ? 'Drop-off selected'
                                    : 'Move map to set dropoff')
                                : _dropoffAddress,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 12),
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

                    const SizedBox(height: 12),

                    if (_isLoadingRoute)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Calculating route...'),
                        ],
                      )
                    else if (_routeDistanceKm != null && _routeDurationMin != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_routeDistanceKm!.toStringAsFixed(2)} km',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_routeDurationMin min',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),

                    const SizedBox(height: 14),

                    if (_isDropoffConfirmed)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _changeDropoff,
                          child: const Text('Change drop-off'),
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: primaryEnabled ? primaryOnPressed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          primaryText,
                          style: TextStyle(
                            color: primaryEnabled ? Colors.black87 : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressLookupTimer?.cancel();
    if (!kIsWeb) {
      mapController?.dispose();
    }
    super.dispose();
  }
}