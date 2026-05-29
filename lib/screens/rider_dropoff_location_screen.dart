import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/directions_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/glass_card.dart';

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

  bool _isDropoffConfirmed = false;

  LatLng? _lastRoutedDestination;
  DateTime? _lastRouteAt;

  bool _loggedGeocodingErrorOnce = false;

  double? _routeDistanceKm;
  int? _routeDurationMin;

  @override
  void initState() {
    super.initState();

    _dropoffLocation = LatLng(widget.pickupLat, widget.pickupLng);
    _updateMarkers();

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

      String address =
          'Lat: ${location.latitude.toStringAsFixed(4)}, Lng: ${location.longitude.toStringAsFixed(4)}';

      try {
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
    if (_lastRouteAt != null && now.difference(_lastRouteAt!).inMilliseconds < 900) {
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

    setState(() {
      _isDropoffConfirmed = true;
    });

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

    return Scaffold(
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

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Set Destination',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
          ),

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

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
                      color: Colors.white.withValues(alpha: 0.5),
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
                            color: Colors.green,
                          ),
                          child: const Center(
                            child: Text('A',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        AppSpacing.hGapMd,
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
                    AppSpacing.gapMd,
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
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            _dropoffAddress.isEmpty
                                ? 'Move map to set dropoff'
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
                    AppSpacing.gapMd,
                    if (_isLoadingRoute)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          AppSpacing.hGapSm,
                          Text('Calculating route...'),
                        ],
                      )
                    else if (_routeDistanceKm != null && _routeDurationMin != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.route, size: 16, color: AppColors.primary),
                              AppSpacing.hGapXs,
                              Text('${_routeDistanceKm!.toStringAsFixed(2)} km',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: AppColors.primary),
                              AppSpacing.hGapXs,
                              Text('$_routeDurationMin min',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    AppSpacing.gapMd,
                    PremiumButton(
                      label: 'Confirm drop-off point',
                      onPressed: routeReady ? _confirmDropoffPoint : null,
                      variant: ButtonVariant.gradient,
                    ),
                  ] else ...[
                    // Phase 2: Reviewing dropoff
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.trip_origin, color: Colors.green, size: 24),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup',
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapMd,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 24),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dropoff',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 2),
                              Text(
                                _dropoffAddress.isEmpty
                                    ? 'Lat: ${_dropoffLocation!.latitude.toStringAsFixed(4)}, Lng: ${_dropoffLocation!.longitude.toStringAsFixed(4)}'
                                    : _dropoffAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
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
                          _routeInfoChip(
                              Icons.route,
                              '${_routeDistanceKm!.toStringAsFixed(1)} km'),
                          _routeInfoChip(
                              Icons.access_time,
                              '$_routeDurationMin min'),
                        ],
                      ),
                    AppSpacing.gapSm,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _changeDropoff,
                        child: Text('Change drop-off',
                            style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                    AppSpacing.gapSm,
                    PremiumButton(
                      label: 'Request Ride',
                      onPressed: routeReady ? _requestRide : null,
                      variant: ButtonVariant.gradient,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
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
              style: TextStyle(
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
    if (!kIsWeb) {
      mapController?.dispose();
    }
    super.dispose();
  }
}
