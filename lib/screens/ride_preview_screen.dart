import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/currency_service.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/marker_factory.dart';
import '../utils/map_style_loader.dart';
import '../widgets/swipe_button.dart';

class RidePreviewScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String pickupAddress;
  final String dropoffAddress;
  final double? estimatedFare;

  // Rider info for driver mode
  final String? riderName;
  final double? riderRating;
  final int? riderRideCount;

  // Driver mode
  final bool driverMode;
  final VoidCallback? onAccept;
  final VoidCallback? onIgnore;

  const RidePreviewScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.estimatedFare,
    this.riderName,
    this.riderRating,
    this.riderRideCount,
    this.driverMode = false,
    this.onAccept,
    this.onIgnore,
  });

  @override
  State<RidePreviewScreen> createState() => _RidePreviewScreenState();
}

class _RidePreviewScreenState extends State<RidePreviewScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String? _mapStyle;
  Timer? _autoDismissTimer;

  BitmapDescriptor? _pickupMarker;
  BitmapDescriptor? _dropoffMarker;
  BitmapDescriptor? _driverMarker;
  BitmapDescriptor _dotMarker = BitmapDescriptor.defaultMarker;
  Timer? _dotTimer;
  double _dotProgress = 0.0;
  List<LatLng> _currentPolylinePoints = [];
  LatLng? _driverLocation;
  int? _etaMinutes;
  bool _pickupEtaLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    addDebugMessage('RidePreviewScreen opened');
    _loadAllMarkers();
    _loadDriverLocationAndEta();
    if (!widget.driverMode) {
      _autoDismissTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _loadRouteImmediately() async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.pickupLat, widget.pickupLng),
        13,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadRoute();
    _fitAllPoints();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _loadAllMarkers() async {
    try {
      _pickupMarker = await MarkerFactory.stickPickupLabeled;
      _dropoffMarker = await MarkerFactory.stickDropoffLabeled;
      _dotMarker = await MarkerFactory.userLocation;
      _driverMarker = await MarkerFactory.driver;
      if (mounted) {
        _addMarkers();
        _fitAllPoints();
      }
    } catch (e) {
      addDebugMessage('Marker load error: $e');
    }
  }

  Future<void> _loadDriverLocationAndEta() async {
    if (!widget.driverMode) return;
    try {
      final location = await LocationService.getCurrentLocation();
      if (location != null && mounted) {
        _driverLocation = LatLng(location.latitude, location.longitude);
        final route = await DirectionsService.getDirections(
          origin: _driverLocation!,
          destination: LatLng(widget.pickupLat, widget.pickupLng),
        );
        if (route != null && route.isSuccess && route.durationMinutes != null) {
          _etaMinutes = route.durationMinutes;
        }
        _pickupEtaLoading = false;
        if (mounted) {
          _addMarkers();
          _fitAllPoints();
          setState(() {});
        }
      } else {
        if (mounted) {
          _pickupEtaLoading = false;
          setState(() {});
        }
      }
    } catch (e) {
      addDebugMessage('Driver location/ETA error: $e');
      _pickupEtaLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _addMarkers() {
    if (_pickupMarker == null || _dropoffMarker == null) return;
    if (!mounted) return;
    setState(() {
      _markers.clear();
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: _pickupMarker!,
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress}'),
      ));
      _markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: _dropoffMarker!,
        infoWindow: InfoWindow(title: 'Dropoff: ${widget.dropoffAddress}'),
      ));
      if (_driverLocation != null && _driverMarker != null) {
        _markers.add(Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: _driverMarker!,
          infoWindow: const InfoWindow(title: 'You are here'),
        ));
      }
    });
  }

  Future<void> _loadRoute() async {
    try {
      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
      );

      if (route != null && route.isSuccess && route.polylinePoints != null) {
        _currentPolylinePoints = route.polylinePoints!;
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.primary,
              width: 5,
              geodesic: true,
            ),
          );
        });
        _startMovingDotAnimation();
      }
    } catch (e) {
      addDebugMessage('Route load error: $e');
    }
  }

  // ── Moving dot animation (travels along route polyline) ──────────
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

  void _fitAllPoints() {
    final points = <LatLng>[
      LatLng(widget.pickupLat, widget.pickupLng),
      LatLng(widget.dropoffLat, widget.dropoffLng),
    ];
    if (_driverLocation != null) points.add(_driverLocation!);

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(LatLngBounds(
        southwest: LatLng(minLat - 0.01, minLng - 0.01),
        northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
      ), 80),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController!.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.pickupLat, widget.pickupLng),
        13,
      ),
    );
    _loadRouteImmediately();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _stopMovingDotAnimation();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: AppColors.primaryLight,
        title: Semantics(
          label: 'Trip preview',
          child: const Text('Trip Preview'),
        ),
        actions: [
          Center(
            child: Semantics(
              label: 'Auto-closes in 6 seconds',
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.15),
                  borderRadius: AppRadius.xlRadius,
                ),
                child: Text(
                  'Auto-closes in 6s',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryLight.withValues(alpha: 0.7)),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Semantics(
            label: 'Route map',
            child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 13,
            ),
            markers: {
              ..._markers,
              if (widget.driverMode && _dotProgress <= 1.0 && _currentPolylinePoints.length > 1)
                Marker(
                  markerId: const MarkerId('moving_dot'),
                  position: _interpolateAlongRoute(_dotProgress),
                  icon: _dotMarker,
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 10,
                ),
            },
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: _mapStyle,
            ),
          ),
          PositionedDirectional(
            start: 16,
            end: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Semantics(
              label: widget.driverMode ? 'Ride request details' : 'Trip preview',
              child: Container(
                padding: AppSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.xlRadius,
                  boxShadow: AppShadows.large,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.driverMode && widget.riderName != null) ...[
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            child: Text(
                              widget.riderName!.isNotEmpty
                                  ? widget.riderName![0].toUpperCase()
                                  : 'R',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.riderName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 12, color: AppColors.warning),
                                    const SizedBox(width: 2),
                                    Text(
                                      (widget.riderRating ?? 0).toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                    if (widget.riderRideCount != null) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.riderRideCount} rides',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.pickupAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.driverMode && _etaMinutes != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 16, top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.timer, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Pickup in $_etaMinutes min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (widget.driverMode && _pickupEtaLoading)
                      const Padding(
                        padding: EdgeInsetsDirectional.only(start: 16, top: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Calculating ETA...',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.dropoffAddress,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.estimatedFare != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money, size: 16, color: AppColors.primary),
                          Text(
                            CurrencyService.format(widget.estimatedFare!),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (widget.driverMode)
                      Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Ignore ride request',
                              child: TextButton(
                                onPressed: () {
                                  widget.onIgnore?.call();
                                  Navigator.of(context).pop();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.textTertiary,
                                  backgroundColor: AppColors.surfaceVariant,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdRadius,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('IGNORE', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Semantics(
                              label: 'Accept ride request, swipe to confirm',
                              child: SwipeButton(
                                label: 'ACCEPT RIDE',
                                icon: Icons.arrow_forward_ios,
                                onConfirmed: () {
                                  widget.onAccept?.call();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Semantics(
                        label: 'Return to offer',
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdRadius,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Return to Offer', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (!widget.driverMode)
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 60,
              start: 0,
              end: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sheet),
                    ),
                    child: Semantics(
                      label: 'Loading route',
                      child: const Text(
                        'Loading route...',
                        style: TextStyle(color: AppColors.primaryLight, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
