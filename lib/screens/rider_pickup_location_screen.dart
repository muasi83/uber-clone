import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/glass_card.dart';
import '../services/websocket_service.dart';
import '../services/location_service.dart';
import '../services/driver_service.dart';
import '../models/ride_model.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/bearing_utils.dart';
import '../utils/marker_factory.dart';
import '../utils/address_utils.dart';

class RiderPickupLocationScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const RiderPickupLocationScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<RiderPickupLocationScreen> createState() =>
      _RiderPickupLocationScreenState();
}

class _RiderPickupLocationScreenState extends State<RiderPickupLocationScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? mapController;

  LatLng? _pickupLocation;
  String _pickupAddress = '';
  final Set<Marker> _markers = {};

  bool _isLoadingAddress = false;
  Timer? _addressLookupTimer;

  LatLng? _lastLookupCenter;
  bool _loggedGeocodingErrorOnce = false;

  // Driver markers on map
  final Map<String, Marker> _driverMarkers = {};
  final Map<String, LatLng> _lastPollPositions = {};
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  Timer? _driverPollTimer;

  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

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

    _loadMapStyle();

    _pickupLocation = LatLng(widget.initialLat, widget.initialLng);

    _lookupAddress(_pickupLocation!);
    _updateMarkers();
    _initDriverMarkerIcon();
    _initYellowPin();
    _startDriverPolling();
    _setupDriverLocationListener();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    mapController?.moveCamera(
      CameraUpdate.newLatLng(_pickupLocation!),
    );
  }

  void _onCameraMove(CameraPosition position) {
    _pickupLocation = position.target;
    _bounceController.reset();
    _updateMarkers();
  }

  Future<void> _onCameraIdle() async {
    try {
      if (mapController == null) return;

      final position = await mapController!.getVisibleRegion();

      final center = LatLng(
        (position.northeast.latitude + position.southwest.latitude) / 2,
        (position.northeast.longitude + position.southwest.longitude) / 2,
      );

      if (_lastLookupCenter != null) {
        final dLat = (center.latitude - _lastLookupCenter!.latitude).abs();
        final dLng = (center.longitude - _lastLookupCenter!.longitude).abs();
        if (dLat < 0.00005 && dLng < 0.00005) {
          return;
        }
      }

      _lastLookupCenter = center;

      _pickupLocation = center;

      _updateMarkers();
      _bounceController.forward(from: 0.0);

      _lookupAddress(center);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Camera idle error: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _lookupAddress(LatLng location) async {
    _addressLookupTimer?.cancel();

    _addressLookupTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;

        setState(() {
          _isLoadingAddress = true;
        });

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
            _pickupAddress = address;
            _isLoadingAddress = false;
          });
        } catch (e) {
          if (!_loggedGeocodingErrorOnce) {
            _loggedGeocodingErrorOnce = true;
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Reverse geocoding failed once (will fallback to Lat/Lng). Error: $e');
            }
          }

          if (!mounted) return;

          setState(() {
            _pickupAddress = address;
            _isLoadingAddress = false;
          });
        }
      },
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // DRIVER MARKERS
  // ═════════════════════════════════════════════════════════════════

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
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
    if (_pickupLocation == null) return;
    try {
      final drivers = await DriverService.getNearbyDrivers(
        latitude: _pickupLocation!.latitude,
        longitude: _pickupLocation!.longitude,
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

  void _confirmPickup() {
    if (_pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a pickup location',
          ),
          backgroundColor: AppColors.error,
        ),
      );

      return;
    }

    addDebugMessage(
      '✅ Pickup confirmed: $_pickupAddress',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderDropoffLocationScreen(
          pickupLat: _pickupLocation!.latitude,
          pickupLng: _pickupLocation!.longitude,
          pickupAddress: _pickupAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? const LatLng(0, 0),
              zoom: 17,
            ),
            markers: {..._markers, ..._driverMarkers.values.toSet()},
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
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
                  'Set Pickup Location',
                  style: TextStyle(color: AppColors.primary),
                ),
                centerTitle: true,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: SizedBox(
                width: 48,
                height: 80,
                child: CustomPaint(
                  painter: _PickupDropPinPainter(bounce: _bounceAnim.value),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: GlassCard(
              borderRadius: AppSpacing.radiusXxl,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Text(
                          'Finding address...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pickupAddress.isEmpty
                                    ? 'Tap map to set pickup'
                                    : _pickupAddress,
                                style: TextStyle(
                                  fontSize: _pickupAddress.isEmpty ? 15 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: _pickupAddress.isEmpty
                                      ? AppColors.textTertiary
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_pickupLocation != null && _pickupAddress.isNotEmpty)
                                Text(
                                  formatLatLng(
                                      _pickupLocation!.latitude,
                                      _pickupLocation!.longitude),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  AppSpacing.gapLg,
                  PremiumButton(
                    label: 'Confirm Pickup',
                    onPressed: _confirmPickup,
                    variant: ButtonVariant.gradient,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + 180,
            child: FloatingActionButton.small(
              heroTag: 'centerPickupMap',
              onPressed: () {
                if (_pickupLocation != null && mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
                  );
                }
              },
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addressLookupTimer?.cancel();
    _driverPollTimer?.cancel();
    _driverLocationSub?.cancel();
    _bounceController.dispose();
    mapController?.dispose();

    super.dispose();
  }
}

class _PickupDropPinPainter extends CustomPainter {
  final double bounce;

  _PickupDropPinPainter({this.bounce = 0.0});

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
      ..color = AppColors.pickupMarker
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
        ..color = AppColors.pickupMarker.withValues(alpha: (1.0 - t) * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(centerX, bottomY + 3), ringRadius, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickupDropPinPainter oldDelegate) =>
      oldDelegate.bounce != bounce;
}
