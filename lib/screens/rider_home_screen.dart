import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/driver_service.dart';
import '../models/ride_model.dart';
import '../screens/debug_screen.dart';
import '../screens/rider_pickup_location_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/bottom_sheet_handle.dart';
import '../widgets/glass_card.dart';
import '../widgets/premium_button.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  bool _isInitializing = true;
  String _initError = '';

  // Driver tracking state
  final Map<String, Marker> _driverMarkers = {};
  int _driverCount = 0;
  Timer? _driverPollTimer;
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;

  @override
  void initState() {
    super.initState();
    _initializeMap();
    _connectWebSocket();
    _setupWebSocketListeners();
    _initDriverMarkerIcon();
    _startDriverPolling();
  }

  void _connectWebSocket() {
    final userId = StorageService.getUserId();
    final username = StorageService.getUsername();
    if (userId != null && username != null) {
      addDebugMessage('\u{1F50C}Rider connecting WebSocket...');
      WebSocketService.connect(userId, username);
    } else {
      addDebugMessage('\u{26A0}\u{FE0F}Cannot connect WebSocket: missing userId or username');
    }
  }

  Future<void> _initDriverMarkerIcon() async {
    try {
      _driverMarkerIcon = await _loadCarMarkerIcon();
    } catch (e) {
      addDebugMessage('⚠️ Car icon fallback to pin: $e');
      _driverMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
  }

  Future<BitmapDescriptor> _loadCarMarkerIcon() async {
    return BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(64, 64)),
      'assets/images/car_marker.png',
    );
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

  void _startDriverPolling() {
    _driverPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _fetchNearbyDrivers();
    });
    _fetchNearbyDrivers();
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_currentLocation == null) return;
    try {
      final drivers = await DriverService.getNearbyDrivers(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radiusKm: 3.0,
      );
      if (!mounted) return;
      setState(() {
        _updateDriverMarkers(drivers);
        _driverCount = _driverMarkers.length;
      });
      addDebugMessage('📍 Nearby drivers found: $_driverCount');
    } catch (e) {
      addDebugMessage('❌ Error fetching nearby drivers: $e');
    }
  }

  void _updateDriverMarkers(List<DriverProfile> drivers) {
    final currentIds = <String>{};
    for (final driver in drivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null) {
        continue;
      }
      if (!driver.isOnline) continue;
      final id = 'driver_${driver.id}';
      currentIds.add(id);
      final position = LatLng(driver.currentLatitude!, driver.currentLongitude!);
      final existing = _driverMarkers[id];
      if (existing != null && existing.position != position) {
        final rotation = _bearingBetween(existing.position, position);
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: driver.user.fullName,
            snippet: '${driver.vehicleModel ?? 'Car'} \u2022 ${driver.vehicleColor ?? ''}',
          ),
        );
      } else if (existing == null) {
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: 0,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: driver.user.fullName,
            snippet: '${driver.vehicleModel ?? 'Car'} \u2022 ${driver.vehicleColor ?? ''}',
          ),
        );
      }
    }
    _driverMarkers.removeWhere((key, _) => !currentIds.contains(key));
  }

  void _setupWebSocketListeners() {
    try {
      WebSocketService.rideEvents.listen((event) {
        final type = event['type'] ?? '';
        addDebugMessage('\u{1F4E1}Rider ride event: $type');
        if (type == 'ride_accepted' || type == 'ride_cancelled') {
          addDebugMessage('\u{2705}Ride status update received: $type');
        }
      });
      _driverLocationSub = WebSocketService.driverLocationEvents.listen((event) {
        _handleDriverLocationEvent(event);
      });
    } catch (e) {
      addDebugMessage('\u{26A0}\u{FE0F}WebSocket listener error: $e');
    }
  }

  void _handleDriverLocationEvent(Map<String, dynamic> event) {
    final payload = event['payload'] as Map<String, dynamic>? ?? event;
    final driverId = payload['driverId'];
    final lat = payload['latitude'] ?? payload['lat'];
    final lng = payload['longitude'] ?? payload['lng'];
    if (driverId == null || lat == null || lng == null) return;
    final id = 'driver_$driverId';
    final position = LatLng((lat as num).toDouble(), (lng as num).toDouble());
    if (!mounted) return;
    setState(() {
      final existing = _driverMarkers[id];
      final heading = payload['heading'];
      double rotation = 0;
      if (heading != null) {
        rotation = (heading as num).toDouble();
      } else if (existing != null) {
        rotation = _bearingBetween(existing.position, position);
      }
      if (existing != null) {
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          infoWindow: existing.infoWindow,
        );
      } else {
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(title: 'Driver #$driverId'),
        );
        _driverCount = _driverMarkers.length;
      }
    });
  }

  Future<void> _initializeMap() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        setState(() {
          _isInitializing = false;
          _initError = 'Location permission required';
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        ),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to get location: $e';
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_currentLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  Future<void> _centerOnLocation() async {
    if (_currentLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  Future<void> _requestRide() async {
    try {
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (mounted) {
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => RiderPickupLocationScreen(
              initialLat: _currentLocation!.latitude,
              initialLng: _currentLocation!.longitude,
            ),
          ),
        );
        if (result != null) {}
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onLogout() async {
    try {
      _driverPollTimer?.cancel();
      _driverLocationSub?.cancel();
      WebSocketService.disconnect();
      await StorageService.clearAllData();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {}
  }

  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.bottomSheetTopRadius)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BottomSheetHandle(),
              AppSpacing.gapLg,
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, size: 20),
                title: const Text('Debug'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DebugScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, size: 20),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _onLogout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: _isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _initError.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _initError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isInitializing = true;
                            _initError = '';
                          });
                          _initializeMap();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _currentLocation ?? const LatLng(0, 0),
                        zoom: 15,
                      ),
                      markers: {
                        ..._markers,
                        ..._driverMarkers.values.toSet(),
                      },
                      compassEnabled: true,
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),

                    // Menu button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'menu',
                        backgroundColor: Colors.white.withValues(alpha: 0.85),
                        elevation: 2,
                        onPressed: _showMenuSheet,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),

                    // Driver count badge
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 72,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _driverCount > 0
                            ? Container(
                                key: ValueKey('count_$_driverCount'),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_driverCount',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'nearby',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),

                    // Wallet pill
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '\$12.50',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Recenter button
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.35 + 16,
                      right: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'center_location',
                        onPressed: _centerOnLocation,
                        backgroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),

                    // Draggable bottom sheet
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        child: DraggableScrollableSheet(
                          initialChildSize: 0.35,
                          minChildSize: 0.1,
                          maxChildSize: 0.85,
                          builder: (context, scrollController) {
                            return ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppSpacing.bottomSheetTopRadius),
                              ),
                              child: Container(
                                color: Colors.white,
                                child: ListView(
                                  controller: scrollController,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    const Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 8, bottom: 4),
                                        child: BottomSheetHandle(),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                                      child: InkWell(
                                        onTap: _requestRide,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                        child: Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                          ),
                                          child: const Row(
                                            children: [
                                              SizedBox(width: 16),
                                              Icon(
                                                Icons.search,
                                                color: AppColors.primary,
                                                size: 22,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                'Where to?',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Row(
                                        children: [
                                          _PlaceChip(
                                            icon: Icons.home_rounded,
                                            label: 'Home',
                                          ),
                                          const SizedBox(width: 12),
                                          _PlaceChip(
                                            icon: Icons.work_rounded,
                                            label: 'Work',
                                          ),
                                          const SizedBox(width: 12),
                                          _PlaceChip(
                                            icon: Icons.access_time_rounded,
                                            label: 'Recent',
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      child: Divider(color: AppColors.outline),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Text(
                                        'Saved Places',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _SavedPlaceItem(
                                      icon: Icons.location_on_rounded,
                                      label: 'Central Park',
                                      address: 'New York, NY 10024',
                                    ),
                                    _SavedPlaceItem(
                                      icon: Icons.location_on_rounded,
                                      label: 'Times Square',
                                      address: 'Manhattan, NY 10036',
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _driverPollTimer?.cancel();
    _driverLocationSub?.cancel();
    mapController.dispose();
    super.dispose();
  }
}

class _PlaceChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PlaceChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: AppSpacing.chipPadding,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedPlaceItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String address;

  const _SavedPlaceItem({
    required this.icon,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
