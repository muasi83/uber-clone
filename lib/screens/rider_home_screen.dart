import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../services/notification_service.dart';
import '../models/ride_model.dart';
import '../screens/rider_pickup_location_screen.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/bearing_utils.dart';
import '../widgets/bottom_sheet_handle.dart';
import '../widgets/unread_badge.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../screens/settings_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  GoogleMapController? mapController;
  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  bool _isInitializing = true;
  bool _mapReady = false;
  String _initError = '';

  final Map<String, Marker> _driverMarkers = {};
  final Map<String, LatLng> _lastPollPositions = {};
  int _driverCount = 0;
  Timer? _driverPollTimer;
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _customCurrentMarker = BitmapDescriptor.defaultMarker;
  StreamSubscription<Map<String, dynamic>>? _driverLocationSub;
  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _chatMessagesSub;

  bool _isNetworkAvailable = true;
  int _consecutiveFailures = 0;
  int _locationRetryCount = 0;
  int _unreadNotificationCount = 0;
  Timer? _notificationPollTimer;
  String? _mapStyle;

  List<Ride> _recentTrips = [];
  bool _isLoadingHistory = false;
  late DraggableScrollableController _sheetController;
  bool _isSheetExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeMap();
    _connectWebSocket();
    _setupWebSocketListeners();
    _initDriverMarkerIcon();
    _initCustomMarkers();
    _startDriverPolling();
    _checkActiveRide();
    _startNotificationPolling();
    _loadRecentTrips();

    _sheetController = DraggableScrollableController();
    _sheetController.addListener(() {
      if (_sheetController.size > 0.4) {
        if (!_isSheetExpanded) setState(() => _isSheetExpanded = true);
      } else {
        if (_isSheetExpanded) setState(() => _isSheetExpanded = false);
      }
    });
  }

  Future<void> _loadRecentTrips() async {
    final token = StorageService.getToken();
    if (token == null) return;
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    final rides = await RideService.getRideHistory(token);
    if (!mounted) return;
    setState(() {
      _recentTrips = rides.length > 5 ? rides.sublist(0, 5) : rides;
      _isLoadingHistory = false;
    });
  }

  void _connectWebSocket() {
    final userId = StorageService.getUserId();
    final username = StorageService.getUsername();
    if (userId != null && username != null) {
      WebSocketService.onForceLogout = _handleForceLogout;
      WebSocketService.connect(userId, username);
    }
  }

  void _handleForceLogout() {
    if (!mounted) return;
    WebSocketService.disconnect();
    StorageService.clearAllData();
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out: logged in from another device'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

  Future<void> _initCustomMarkers() async {
    _customCurrentMarker = await MarkerFactory.userLocation;
  }

  void _startDriverPolling() {
    _driverPollTimer?.cancel();
    _fetchNearbyDrivers();
    _driverPollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _fetchNearbyDrivers();
    });
  }

  void _startNotificationPolling() {
    _fetchUnreadCount();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchUnreadCount();
    });
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    final token = StorageService.getToken();
    if (token == null) return;

    try {
      final count = await NotificationService.getUnreadCount(token);
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _fetchNearbyDrivers() async {
    if (_currentLocation == null) return;
    try {
      final drivers = await DriverService.getNearbyDrivers(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radiusKm: 5.0,
      );
      _consecutiveFailures = 0;
      if (!_isNetworkAvailable && mounted) {
        setState(() => _isNetworkAvailable = true);
      }
      if (!mounted) return;
      setState(() {
        _updateDriverMarkers(drivers);
        _driverCount = _driverMarkers.length;
      });
    } catch (e) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= 3 && _isNetworkAvailable && mounted) {
        setState(() => _isNetworkAvailable = false);
      }
    }
  }

  void _updateDriverMarkers(List<DriverProfile> drivers) {
    final currentIds = <String>{};
    for (final driver in drivers) {
      if (driver.currentLatitude == null || driver.currentLongitude == null) {
        continue;
      }
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
        rotation = calculateBearing(lastPollPos, position);
      } else {
        rotation = existing.rotation;
      }
      _lastPollPositions[id] = position;
      _driverMarkers[id] = Marker(
        markerId: MarkerId(id),
        position: position,
        icon: _driverMarkerIcon,
        rotation: (rotation + 180) % 360,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: InfoWindow(
          title: driver.user.fullName,
          snippet:
              '${driver.vehicleModel ?? 'Car'} • ${driver.vehicleColor ?? ''}',
        ),
      );
    }
    _driverMarkers.removeWhere((key, _) => !currentIds.contains(key));
    _lastPollPositions.removeWhere((key, _) => !currentIds.contains(key));
  }

  void _setupWebSocketListeners() {
    try {
      _rideEventsSub?.cancel();
      _rideEventsSub = WebSocketService.rideEvents.listen(
        (event) {
          final type = event['type'] ?? '';
          if (type == 'ride_accepted' || type == 'ride_cancelled') {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    type == 'ride_accepted'
                        ? 'Your ride has been accepted!'
                        : 'Your ride has been cancelled',
                  ),
                  backgroundColor: type == 'ride_accepted'
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          }
        },
        onError: (e) {},
        onDone: () {},
      );
      _driverLocationSub?.cancel();
      _driverLocationSub = WebSocketService.driverLocationEvents.listen(
        (event) {
          _handleDriverLocationEvent(event);
        },
      );
      _chatMessagesSub?.cancel();
      _chatMessagesSub = WebSocketService.chatMessages.listen(
        (event) {
          if (!mounted) return;
          final senderName = event['senderName'] as String? ?? 'Someone';
          final content = event['content'] as String? ?? '';
          if (content.isEmpty) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.chat, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(senderName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        },
      );
    } catch (e) {}
  }

  void _handleDriverLocationEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';
    if (type == 'driver_heading') {
      _handleDriverHeadingEvent(event);
      return;
    }
    final payload = event['payload'] as Map<String, dynamic>? ?? event;
    final driverId = payload['driverId'];
    final lat = payload['latitude'] ?? payload['lat'];
    final lng = payload['longitude'] ?? payload['lng'];
    if (driverId == null || lat == null || lng == null) return;
    final id = 'driver_$driverId';
    final position = LatLng((lat as num).toDouble(), (lng as num).toDouble());
    if (!mounted) return;

    final existing = _driverMarkers[id];
    final heading = payload['heading'];
    double rotation = 0;
    if (heading != null) {
      rotation = (heading as num).toDouble();
    } else if (existing != null) {
      rotation = calculateBearing(existing.position, position);
    }
    rotation = (rotation + 180) % 360;

    if (existing != null &&
        existing.position == position &&
        existing.rotation == rotation) {
      return;
    }

    setState(() {
      if (existing != null) {
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: existing.infoWindow,
        );
      } else {
        _driverMarkers[id] = Marker(
          markerId: MarkerId(id),
          position: position,
          icon: _driverMarkerIcon,
          rotation: rotation,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: InfoWindow(title: 'Driver #$driverId'),
        );
        _driverCount = _driverMarkers.length;
      }
    });
  }

  void _handleDriverHeadingEvent(Map<String, dynamic> event) {
    final payload = event['payload'] as Map<String, dynamic>? ?? event;
    final driverId = payload['driverId'];
    final heading = payload['heading'];
    if (driverId == null || heading == null || !mounted) return;
    final id = 'driver_$driverId';
    final existing = _driverMarkers[id];
    if (existing == null) return;
    final rotation = ((heading as num).toDouble() + 180) % 360;

    if (existing.rotation == rotation) return;

    setState(() {
      _driverMarkers[id] = Marker(
        markerId: existing.markerId,
        position: existing.position,
        icon: _driverMarkerIcon,
        rotation: rotation,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        infoWindow: existing.infoWindow,
      );
    });
  }

  Future<void> _initializeMap() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isInitializing = false;
          _initError = 'Location permission required';
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _currentLocation = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentLocation!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: _customCurrentMarker,
        ),
      );
      if (mounted) {
        setState(() => _isInitializing = false);
      }
      _animateToCurrentLocation();
      _fetchNearbyDrivers();
    } catch (e) {
      if (_locationRetryCount < 3) {
        _locationRetryCount++;
        Future.delayed(Duration(seconds: _locationRetryCount * 2), () {
          if (mounted) _initializeMap();
        });
        return;
      }
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to get location. Please enable location services.';
        });
      }
    }
  }

  void _loadMapStyle() {
    _mapStyle = MapStyleLoader.cachedStyle;
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() => _mapReady = true);
    _animateToCurrentLocation();
  }

  void _animateToCurrentLocation() {
    if (_currentLocation != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  Future<void> _centerOnLocation() async {
    if (_currentLocation != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
    }
  }

  Future<void> _checkActiveRide() async {
    final token = StorageService.getToken();
    if (token == null) return;
    try {
      final activeRide = await RideService.getActiveRide(token);
      if (activeRide == null || !mounted) return;

      final rideId = activeRide.id;
      if (rideId == null) return;

      if (StorageService.isStaleRideSkipped(rideId)) {
        return;
      }

      final cancel = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Active Ride Found'),
          content: Text(
            'You have a ride from ${activeRide.pickupAddress} to ${activeRide.dropoffAddress} '
            'that was never completed. Cancel it to request a new ride?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Ride'),
            ),
          ],
        ),
      );
      if (cancel == true && mounted) {
        final success = await RideService.cancelRide(
          rideId,
          token,
          reason: 'Cancelled by rider (stale ride cleanup)',
        );
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Previous ride cancelled'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          await StorageService.clearActiveRideId();
          await StorageService.saveStaleRideSkipped(rideId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not cancel ride — local data cleared'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        await StorageService.saveStaleRideSkipped(rideId);
      }
    } catch (e) {}
  }

  Future<void> _requestRide() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_currentLocation == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (mounted) {
        await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => RiderPickupLocationScreen(
              initialLat: _currentLocation!.latitude,
              initialLng: _currentLocation!.longitude,
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onLogout() async {
    try {
      _driverPollTimer?.cancel();
      _driverLocationSub?.cancel();

      final userId = StorageService.getUserId();
      final token = StorageService.getToken();
      if (userId != null && token != null) {
        try {
          await http.post(
            Uri.parse('${StorageService.getServerUrl()}/api/users/$userId/logout'),
            headers: {'Authorization': 'Bearer $token'},
          ).timeout(const Duration(seconds: 10));
        } catch (e) {
          // Continue anyway
        }
      }

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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetTopRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
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
                    MaterialPageRoute(
                      builder: (context) => const DebugScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: const Text('Ride History'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to ride history
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
    Widget body;
    if (_isInitializing) {
      body = const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    } else if (_initError.isNotEmpty) {
      body = _buildErrorState();
    } else {
      body = Stack(
        children: [
          _buildMapBody(),
          if (!_mapReady)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
        ],
      );
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: body,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off,
                size: 40,
                color: AppColors.error,
              ),
            ),
            AppSpacing.gapXl,
            const Text(
              'Location Unavailable',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.gapSm,
            Text(
              _initError,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.gapXl,
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _initError = '';
                  _locationRetryCount = 0;
                });
                _initializeMap();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBody() {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          style: _mapStyle,
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
          myLocationEnabled: true,
          scrollGesturesEnabled: !_isSheetExpanded,
          zoomGesturesEnabled: !_isSheetExpanded,
          rotateGesturesEnabled: !_isSheetExpanded,
          tiltGesturesEnabled: !_isSheetExpanded,
        ),

        if (!_isNetworkAvailable)
          Positioned(
            key: const ValueKey('connectivity_banner'),
            top: 0, left: 0, right: 0,
            child: _buildConnectivityBanner(),
          ),

        // Menu button
        Positioned(
          key: const ValueKey('menu'),
          top: MediaQuery.of(context).padding.top + 8,
          left: 16,
          child: _buildFloatingButton(
            icon: Icons.menu_rounded,
            onPressed: _showMenuSheet,
            heroTag: 'menu',
          ),
        ),

        // Driver count badge
        if (_driverCount > 0)
          Positioned(
            key: const ValueKey('driver_count'),
            top: MediaQuery.of(context).padding.top + 8,
            left: 72,
            child: _buildDriverCountBadge(),
          ),

        // Notification button
        Positioned(
          key: const ValueKey('notifications'),
          top: MediaQuery.of(context).padding.top + 8,
          right: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildFloatingButton(
                icon: Icons.notifications_outlined,
                onPressed: _showNotificationSheet,
                heroTag: 'notifications',
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: UnreadBadge(count: _unreadNotificationCount),
                ),
            ],
          ),
        ),

        // Settings button
        Positioned(
          key: const ValueKey('settings'),
          top: MediaQuery.of(context).padding.top + 8,
          right: 16,
          child: _buildFloatingButton(
            icon: Icons.settings_outlined,
            onPressed: () {
              final token = StorageService.getToken();
              final userId = StorageService.getUserId();
              final username = StorageService.getUsername();
              if (token != null && userId != null && username != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      username: username,
                      userId: userId,
                      token: token,
                    ),
                  ),
                );
              }
            },
            heroTag: 'settings',
          ),
        ),

        // Recenter button
        Positioned(
          key: const ValueKey('recenter'),
          bottom: MediaQuery.of(context).size.height * 0.35 + 16,
          right: 16,
          child: _buildFloatingButton(
            icon: Icons.my_location_rounded,
            onPressed: _centerOnLocation,
            heroTag: 'center_location',
          ),
        ),

        // Draggable bottom sheet
        Positioned(
          key: const ValueKey('bottom_sheet'),
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: DraggableScrollableSheet(
              key: const ValueKey('sheet'),
              controller: _sheetController,
              initialChildSize: 0.35,
              minChildSize: 0.1,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.bottomSheetTopRadius),
                  ),
                  child: Container(
                    color: AppColors.surface,
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
                          child: _buildSearchBar(),
                        ),
                        if (_isLoadingHistory)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        else if (_recentTrips.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Recent Trips',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ..._recentTrips.map((ride) => _buildRecentTripItem(ride)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showNotificationSheet() {
    final token = StorageService.getToken();
    if (token == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetTopRadius),
        ),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: NotificationService.fetchNotifications(token),
            builder: (context, snapshot) {
              final notifications = snapshot.data ?? [];
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BottomSheetHandle(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (notifications.isNotEmpty)
                              TextButton(
                                onPressed: () async {
                                  await NotificationService.clearNotifications(token);
                                  setState(() => _unreadNotificationCount = 0);
                                  Navigator.pop(ctx);
                                },
                                child: const Text('Clear All', style: TextStyle(fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: AppColors.outline.withValues(alpha: 0.5)),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (notifications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.notifications_none, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 12),
                              Text(
                                'No notifications yet',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, indent: 20, endIndent: 20,
                                    color: AppColors.outline.withValues(alpha: 0.3)),
                            itemBuilder: (context, index) {
                              final n = notifications[index];
                              return ListTile(
                                leading: Icon(
                                  n['type'] == 'chat' ? Icons.chat : Icons.notifications,
                                  size: 20, color: AppColors.primary,
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                subtitle: Text(
                                  n['body'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: n['isRead'] == true
                                    ? null
                                    : Container(
                                        width: 8, height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary, shape: BoxShape.circle,
                                        ),
                                      ),
                                dense: true,
                                onTap: () {
                                  Navigator.pop(ctx);
                                  NotificationService.handleNotificationTap(n['type'] as String? ?? '');
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 2,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildDriverCountBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('count_$_driverCount'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppSpacing.shadowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
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
      ),
    );
  }

  Widget _buildRecentTripItem(Ride ride) {
    final statusColor = switch (ride.status) {
      'COMPLETED' => AppColors.success,
      'CANCELLED' || 'CANCELED' => AppColors.error,
      'ACCEPTED' || 'STARTED' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
    final statusLabel = switch (ride.status) {
      'COMPLETED' => 'Completed',
      'CANCELLED' || 'CANCELED' => 'Cancelled',
      'ACCEPTED' => 'Accepted',
      'STARTED' => 'In Transit',
      'REQUESTED' => 'Requested',
      _ => ride.status,
    };
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiderDropoffLocationScreen(
              pickupLat: ride.pickupLatitude,
              pickupLng: ride.pickupLongitude,
              pickupAddress: ride.pickupAddress,
              initialTrip: ride,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.route, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.pickupAddress.length > 25
                        ? '${ride.pickupAddress.substring(0, 25)}…'
                        : ride.pickupAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.arrow_forward, size: 11, color: AppColors.textTertiary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ride.dropoffAddress.length > 25
                              ? '${ride.dropoffAddress.substring(0, 25)}…'
                              : ride.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return InkWell(
      onTap: _requestRide,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outline),
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
    );
  }

  Widget _buildConnectivityBanner() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: AppColors.error,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connection lost — retrying...',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _driverPollTimer?.cancel();
    _notificationPollTimer?.cancel();
    _driverLocationSub?.cancel();
    _rideEventsSub?.cancel();
    _chatMessagesSub?.cancel();
    _sheetController.dispose();
    super.dispose();
  }
}
