import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../services/currency_service.dart';
import '../services/driver_service.dart';
import '../services/ride_service.dart';
import '../services/ride_recovery_service.dart';
import '../models/ride_model.dart';
import '../screens/rider_pickup_location_screen.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/bearing_utils.dart';
import '../utils/address_utils.dart';
import '../widgets/bottom_sheet_handle.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../screens/settings_screen.dart';
import '../screens/trip_history_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/admin_driver_list_screen.dart';
import '../services/recorded_screen_mixin.dart';
import '../services/event_recorder_service.dart';
import '../services/location_monitor_service.dart';
import 'rides_screen.dart';
import 'account_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> with RecordedScreenMixin<RiderHomeScreen>, WidgetsBindingObserver {
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
  String? _mapStyle;

  List<Ride> _recentTrips = [];
  bool _isLoadingHistory = false;
  late DraggableScrollableController _sheetController;
  bool _isSheetExpanded = false;

  bool _isAdmin = false;
  int _riderTabIndex = 0;
  int _adminTabIndex = 0;
  StreamSubscription<bool>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _isAdmin = StorageService.getRole() == 'ADMIN';
    WidgetsBinding.instance.addObserver(this);
    _gpsSub = LocationMonitorService().onStatusChanged.listen((enabled) {
      if (enabled && _initError.isNotEmpty && mounted) {
        _initError = '';
        _initializeMap();
      }
    });
    _loadMapStyle();
    _initializeMap();
    _connectWebSocket();
    _setupWebSocketListeners();
    _initDriverMarkerIcon();
    _initCustomMarkers();
    _startDriverPolling();
    _checkActiveRide();
    EventRecorderService.recordEvent(
      rideId: null,
      eventName: 'HOME_SCREEN_OPENED',
      category: 'FRONTEND',
      summary: 'Rider home screen opened',
      screenName: screenName,
    );
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
    recordEvent(
      eventName: 'SNACKBAR_SHOWN',
      category: 'UI',
      summary: 'Force logout snackbar: signed out from another device',
      extraDetails: {'snackbarType': 'force_logout'},
    );
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
        rotation: normalizeCarHeading(rotation),
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
              recordEvent(
                eventName: 'SNACKBAR_SHOWN',
                category: 'UI',
                summary: 'Ride status change: $type',
                extraDetails: {'snackbarType': 'ride_status', 'rideEventType': type},
              );
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
                    borderRadius: AppRadius.smRadius,
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
                  const Icon(Icons.chat, color: AppColors.primaryLight, size: 18),
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
    rotation = normalizeCarHeading(rotation);

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
    final rotation = normalizeCarHeading((heading as num).toDouble());

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
      await Future.any([
        _initializeLocation(),
        Future.delayed(const Duration(seconds: 30)),
      ]);
      if (!mounted) return;
      if (_currentLocation == null) {
        setState(() {
          _isInitializing = false;
          _initError = 'Location initialization timed out. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = 'Failed to get location. Please enable location services.';
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission()
          .timeout(const Duration(seconds: 5));
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission()
            .timeout(const Duration(seconds: 10));
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _initError = 'Location permission required';
          });
        }
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
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
          if (mounted) _initializeLocation();
        });
        return;
      }
      rethrow;
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

      recordEvent(
        eventName: 'DIALOG_SHOWN',
        category: 'UI',
        summary: 'Active Ride Found dialog displayed',
        extraDetails: {'dialogType': 'active_ride_found'},
      );
      final action = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.lgRadius,
          ),
          title: const Text('Active Ride Found'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have a ride from ${activeRide.pickupAddress} to ${activeRide.dropoffAddress} '
                'that was never completed. Cancel it to request a new ride?',
              ),
              const SizedBox(height: 8),
              Text(
                '📍 ${formatLatLng(activeRide.pickupLatitude, activeRide.pickupLongitude)} → ${formatLatLng(activeRide.dropoffLatitude, activeRide.dropoffLongitude)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'later'),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Cancel Ride'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, 'resume'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Resume Trip'),
            ),
          ],
        ),
      );
      if (action == 'resume' && mounted) {
        _resumeActiveRide(activeRide);
      } else if (action == 'cancel' && mounted) {
        final success = await RideService.cancelRide(
          rideId,
          token,
          reason: 'Cancelled by rider (stale ride cleanup)',
        );
        if (success) {
          if (mounted) {
            recordEvent(
              eventName: 'SNACKBAR_SHOWN',
              category: 'UI',
              summary: 'Previous ride cancelled successfully',
              extraDetails: {'snackbarType': 'ride_cancelled', 'outcome': 'success'},
            );
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
            recordEvent(
              eventName: 'SNACKBAR_SHOWN',
              category: 'UI',
              summary: 'Could not cancel ride — local data cleared',
              extraDetails: {'snackbarType': 'ride_cancelled', 'outcome': 'failure'},
            );
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

  void _resumeActiveRide(Ride ride) async {
    final target = RideRecoveryService.getRecoveryTarget(ride);
    if (!mounted) return;

    if (target.canResume) {
      final routeName = switch (target.destination) {
        RideDestination.searching => '/rider-searching',
        RideDestination.tracking => '/rider-tracking',
        RideDestination.activeRide => '/rider-active-ride',
        RideDestination.completed => '/rider-completed',
        RideDestination.cancelled => null,
      };
      if (routeName != null && mounted) {
        await Navigator.pushNamed(context, routeName,
            arguments: target.arguments);
      }
    } else if (mounted) {
      recordEvent(
        eventName: 'SNACKBAR_SHOWN',
        category: 'UI',
        summary: 'Cannot resume ride: ${target.message ?? "unknown"}',
        extraDetails: {'snackbarType': 'ride_resume_error'},
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(target.message ??
              'Cannot resume ride'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _requestRide() async {
    final messenger = ScaffoldMessenger.of(context);
    recordEvent(
      eventName: 'RIDE_REQUEST_INITIATED',
      category: 'BUSINESS',
      summary: 'User initiated ride request',
    );
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
      recordEvent(
        eventName: 'SNACKBAR_SHOWN',
        category: 'UI',
        summary: 'Ride request error: $e',
        extraDetails: {'snackbarType': 'request_error', 'error': '$e'},
      );
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
    recordEvent(
      eventName: 'MODAL_BOTTOM_SHEET_SHOWN',
      category: 'UI',
      summary: 'Menu bottom sheet displayed',
      extraDetails: {'sheetType': 'menu'},
    );
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TripHistoryScreen(),
                    ),
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

  Widget _buildLoadingState() {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_searching_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.gapLg,
            Text(
              'Finding your location...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBodyWithOverlays() {
    if (_isInitializing) {
      return _buildLoadingState();
    } else if (_initError.isNotEmpty) {
      return _buildErrorState();
    }
    return Stack(
      children: [
        _buildMapBody(),
        if (!_mapReady)
          _buildLoadingState(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        body: IndexedStack(
          index: _riderTabIndex,
          children: [
            _buildMapBodyWithOverlays(),
            const RidesScreen(),
            const AccountScreen(),
          ],
        ),
        bottomNavigationBar: _buildRiderBottomNav(),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _adminTabIndex,
        children: [
          Scaffold(
            extendBodyBehindAppBar: true,
            body: _buildMapBodyWithOverlays(),
          ),
          const AdminHomeScreen(),
          const AdminDriverListScreen(),
        ],
      ),
      bottomNavigationBar: _buildAdminBottomNav(),
    );
  }

  Widget _buildAdminBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _adminTabIndex,
        onTap: (index) => setState(() => _adminTabIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'Drivers',
          ),
        ],
      ),
    );
  }

  Widget _buildRiderBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _riderTabIndex,
        onTap: (index) => setState(() => _riderTabIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route_rounded), label: 'Rides'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Account'),
        ],
      ),
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
            Text(
              'Location Unavailable',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            AppSpacing.gapSm,
            Text(
              _initError,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  borderRadius: AppRadius.mdRadius,
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
            child: SafeArea(
              top: true,
              bottom: false,
              child: _buildConnectivityBanner(),
            ),
          ),

        // Menu button
        PositionedDirectional(
          key: const ValueKey('menu'),
          top: MediaQuery.of(context).padding.top + 8,
          start: 16,
          child: Semantics(
            button: true,
            label: 'Menu',
            child: _buildFloatingButton(
              icon: Icons.menu_rounded,
              onPressed: _showMenuSheet,
              heroTag: 'menu',
            ),
          ),
        ),

        // Driver count badge
        if (_driverCount > 0)
          PositionedDirectional(
            key: const ValueKey('driver_count'),
            top: MediaQuery.of(context).padding.top + 8,
            start: 72,
            child: Semantics(
              label: '$_driverCount drivers nearby',
              child: _buildDriverCountBadge(),
            ),
          ),

        // Settings button
        PositionedDirectional(
          key: const ValueKey('settings'),
          top: MediaQuery.of(context).padding.top + 8,
          end: 16,
          child: Semantics(
            button: true,
            label: 'Settings',
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
        ),

        // Gradient overlay above sheet
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).size.height * 0.25,
          height: 60,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.surface.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Recenter button
        PositionedDirectional(
          key: const ValueKey('recenter'),
          bottom: MediaQuery.of(context).size.height * 0.25 + 16,
          end: 16,
          child: Semantics(
            button: true,
            label: 'Recenter map',
            child: _buildFloatingButton(
              icon: Icons.my_location_rounded,
              onPressed: _centerOnLocation,
              heroTag: 'center_location',
            ),
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
              initialChildSize: 0.25,
              minChildSize: 0.1,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: AppShadows.large,
                    ),
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
                          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                          child: _buildSearchBar(),
                        ),
                        if (!_isSheetExpanded && _recentTrips.isNotEmpty)
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
                            child: _buildQuickChips(),
                          ),
                        if (_isSheetExpanded) ...[
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
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'Recent Trips',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._recentTrips.map((ride) => _buildRecentTripItem(ride)),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const TripHistoryScreen(),
                                    ),
                                  );
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      'View All Trips',
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: AppColors.primary,
                                          ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String heroTag,
  }) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      backgroundColor: AppColors.surface.withValues(alpha: 0.95),
      elevation: 0,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdRadius,
          boxShadow: AppShadows.medium,
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
    );
  }

  Widget _buildDriverCountBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('count_$_driverCount'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$_driverCount',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: 4),
            Text(
              'nearby',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  Widget _buildQuickChips() {
    final chips = _recentTrips.take(3).map((ride) => ride.dropoffAddress).toList();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: _requestRide,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outline),
              ),
              child: Center(
                child: Text(
                  chips[index].length > 20
                      ? '${chips[index].substring(0, 20)}\u2026'
                      : chips[index],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),
          );
        },
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
    final timeAgo = _timeAgo(ride.requestedAt ?? ride.completedAt ?? ride.cancelledAt);
    final fare = ride.finalFare ?? ride.estimatedFare;
    return InkWell(
      onTap: () {
        if (ride.status == 'REQUESTED' ||
            ride.status == 'ACCEPTED' ||
            ride.status == 'DRIVER_ARRIVED' ||
            ride.status == 'STARTED') {
          _resumeActiveRide(ride);
          return;
        }
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.route_rounded, size: 22, color: AppColors.primary),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ride.pickupAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          if (timeAgo.isNotEmpty)
                            Text(
                              timeAgo,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 11,
                                  ),
                            ),
                        ],
                      ),
                      AppSpacing.gapXs,
                      Row(
                        children: [
                          Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textTertiary),
                          AppSpacing.hGapXs,
                          Expanded(
                            child: Text(
                              ride.dropoffAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (fare != null) ...[
                        AppSpacing.gapXs,
                        Text(
                          '${CurrencyService.format(fare)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Semantics(
      button: true,
      label: 'Search destination',
      child: InkWell(
        onTap: _requestRide,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.outline),
            boxShadow: AppShadows.small,
          ),
          child: Row(
            children: [
              AppSpacing.hGapLg,
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              AppSpacing.hGapMd,
              Text(
                'Where to?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
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
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: AppColors.primaryLight, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Connection lost — retrying...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initError.isNotEmpty && mounted) {
      _initError = '';
      _initializeMap();
    }
  }

  @override
  void dispose() {
    _driverPollTimer?.cancel();
    _driverLocationSub?.cancel();
    _rideEventsSub?.cancel();
    _chatMessagesSub?.cancel();
    _sheetController.dispose();
    _gpsSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
