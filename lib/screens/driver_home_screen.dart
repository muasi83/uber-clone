import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/status_badge.dart';
import '../widgets/unread_badge.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/driver_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../screens/settings_screen.dart';
import '../screens/ride_preview_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/trip_history_screen.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class DriverHomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String token;

  const DriverHomeScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
  });

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;
  List<Ride> _availableRides = [];
  Ride? _currentRide;
  DriverProfile? _driverProfile;
  bool _isLoading = false;
  bool _isOnline = false;

  StreamSubscription<Position>? _positionStream;
  LatLng? _driverCurrentLocation;
  double _lastHeading = 0;
  GoogleMapController? _mapController;

  Timer? _ridePollTimer;
  Timer? _locationBroadcastTimer;
  Timer? _notificationPollTimer;

  bool _isAlertPlaying = false;
  bool _isPreviewOpen = false;
  Timer? _alertTimeoutTimer;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _chatMessagesSub;

  bool _isUpdatingLocation = false;
  DateTime _lastLocationUpdate = DateTime.now().subtract(const Duration(seconds: 10));
  int _locationRetryCount = 0;
  int _unreadNotificationCount = 0;
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;

  bool _isAcceptingRide = false;
  String? _mapStyle;
  Set<int?> _knownRideIds = {};

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initMarkerIcons();
    _loadDriverProfile();
    _checkActiveRide();
    _connectWebSocket();
    _initializeDriverLocation();
    _startNotificationPolling();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _initMarkerIcons() async {
    try {
      _driverMarkerIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(64, 64)),
        'assets/images/car_marker.png',
      );
    } catch (e) {
      addDebugMessage('⚠️ Car icon fallback: $e');
      _driverMarkerIcon = await MarkerFactory.driver;
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await DriverService.getDriverProfile(widget.token);
      if (mounted && profile != null) {
        setState(() {
          _driverProfile = profile;
          _isOnline = profile.isOnline;
        });
        if (_isOnline) {
          _startLocationTracking();
          _startRidePolling();
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _checkActiveRide() async {
    try {
      final activeRide = await DriverService.getActiveRide(widget.token);
      if (activeRide != null && mounted) {
        setState(() => _currentRide = activeRide);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _connectWebSocket() {
    WebSocketService.onForceLogout = _handleForceLogout;
    WebSocketService.connect(widget.userId, widget.username);
    _setupWebSocketListeners();
  }

  void _handleForceLogout() {
    if (!mounted) return;
    WebSocketService.disconnect();
    StorageService.clearAllData();
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
  }

  void _setupWebSocketListeners() {
    _rideEventsSub?.cancel();
    _rideEventsSub = WebSocketService.rideEvents.listen(
      (event) {
        final type = event['type'] ?? '';
        if (type == 'ride_available' && !_isPreviewOpen) {
          _handleNewRideRequest(event);
        } else if (type == 'ride_confirmed') {
          _handleRideConfirmed(event);
        } else if (type == 'ride_cancelled') {
          _handleRideCancelled(event);
        }
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
  }

  void _handleNewRideRequest(Map<String, dynamic> event) {
    if (_currentRide != null || _isPreviewOpen) return;

    final pickupLat = (event['pickupLat'] as num?)?.toDouble();
    final pickupLng = (event['pickupLng'] as num?)?.toDouble();
    if (pickupLat != null && pickupLng != null && _driverCurrentLocation != null) {
      final distance = _haversineKm(
        _driverCurrentLocation!,
        LatLng(pickupLat, pickupLng),
      );
      if (distance > 15.0) {
        addDebugMessage('🚫 Ride too far: ${distance.toStringAsFixed(1)}km > 15km');
        return;
      }
    }

    _playRideAlert();
    _showRidePreview(event);
  }

  double _haversineKm(LatLng a, LatLng b) {
    const r = 6371;
    final dLat = (b.latitude - a.latitude) * (3.141592653589793 / 180);
    final dLng = (b.longitude - a.longitude) * (3.141592653589793 / 180);
    final lat1 = a.latitude * (3.141592653589793 / 180);
    final lat2 = b.latitude * (3.141592653589793 / 180);
    final dHalf = dLat / 2;
    final lHalf = dLng / 2;
    final aa = math.sin(dHalf) * math.sin(dHalf) +
        math.sin(lHalf) * math.sin(lHalf) * math.cos(lat1) * math.cos(lat2);
    final cc = 2 * math.asin(math.sqrt(aa));
    return r * cc;
  }

  void _handleRideConfirmed(Map<String, dynamic> event) {
    if (!mounted) return;
    final rideId = event['rideId'];

    _stopRideAlert();

    if (rideId != null) {
      _loadRideDetails(rideId);
    }
  }

  void _handleRideCancelled(Map<String, dynamic> event) {
    if (!mounted) return;
    final rideId = event['rideId'];

    if (_currentRide?.id == rideId) {
      setState(() => _currentRide = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride has been cancelled'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _loadRideDetails(dynamic rideId) async {
    try {
      final ride = await RideService.getRideDetails(rideId, widget.token);
      if (mounted && ride != null) {
        setState(() => _currentRide = ride);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _playRideAlert() {
    _isAlertPlaying = true;
    try {
      _ringtonePlayer.play(
        ios: IosSounds.alarm,
        android: AndroidSounds.alarm,
        volume: 1.0,
      );
      Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 800], intensities: [0, 255, 0, 255, 0, 255]);
    } catch (e) {
      // Silent fail
    }

    _alertTimeoutTimer?.cancel();
    _alertTimeoutTimer = Timer(const Duration(seconds: 30), () {
      _stopRideAlert();
    });
  }

  void _stopRideAlert() {
    if (!_isAlertPlaying) return;
    _isAlertPlaying = false;
    try {
      _ringtonePlayer.stop();
      Vibration.cancel();
    } catch (e) {
      // Silent fail
    }
    _alertTimeoutTimer?.cancel();
  }

  void _showRidePreview(Map<String, dynamic> event) {
    _isPreviewOpen = true;
    _stopRideAlert();

    final rideData = {
      'rideId': event['rideId'],
      'riderId': event['riderId'],
      'riderName': event['riderName'] ?? 'Rider',
      'pickupAddress': event['pickupAddress'] ?? '',
      'dropoffAddress': event['dropoffAddress'] ?? '',
      'pickupLat': event['pickupLat'],
      'pickupLng': event['pickupLng'],
      'dropoffLat': event['dropoffLat'],
      'dropoffLng': event['dropoffLng'],
      'estimatedFare': event['estimatedFare'],
      'estimatedDistance': event['estimatedDistance'],
      'estimatedDuration': event['estimatedDuration'],
      'rideType': event['rideType'],
    };

    final pickupLat = (event['pickupLat'] as num?)?.toDouble() ?? 0.0;
    final pickupLng = (event['pickupLng'] as num?)?.toDouble() ?? 0.0;
    final dropoffLat = (event['dropoffLat'] as num?)?.toDouble() ?? 0.0;
    final dropoffLng = (event['dropoffLng'] as num?)?.toDouble() ?? 0.0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RidePreviewScreen(
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          dropoffLat: dropoffLat,
          dropoffLng: dropoffLng,
          pickupAddress: event['pickupAddress'] ?? '',
          dropoffAddress: event['dropoffAddress'] ?? '',
          estimatedFare: (event['estimatedFare'] as num?)?.toDouble(),
          driverMode: true,
          onAccept: () => _acceptRide(rideData),
          onIgnore: () {
            _isPreviewOpen = false;
          },
        ),
      ),
    ).then((_) {
      _isPreviewOpen = false;
    });
  }

  Future<void> _acceptRide(Map<String, dynamic> rideData) async {
    if (_isAcceptingRide) return;
    if (_currentRide != null) return;
    _isAcceptingRide = true;

    try {
      final rideId = rideData['rideId'];
      if (rideId == null) return;

      final ride = await RideService.acceptRide(rideId, widget.token);
      if (ride != null && mounted) {
        setState(() => _currentRide = ride);
        _stopRideAlert();
        Navigator.pushNamed(
          context,
          '/driver-navigation',
          arguments: {
            'rideId': ride.id,
            'pickupAddress': ride.pickupAddress,
            'pickupLat': ride.pickupLatitude,
            'pickupLng': ride.pickupLongitude,
            'dropoffAddress': ride.dropoffAddress,
            'dropoffLat': ride.dropoffLatitude,
            'dropoffLng': ride.dropoffLongitude,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept ride: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isAcceptingRide = false;
    }
  }

  Future<void> _initializeDriverLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showError('Please enable GPS/Location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showError('Location permission is required');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) _showError('Location permission denied. Please enable in settings.');
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _driverCurrentLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }

      if (_isOnline) {
        await DriverService.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          token: widget.token,
        );

        WebSocketService.sendRideMessage('driver_location', {
          'driverId': widget.userId,
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }
    } catch (e) {
      if (_locationRetryCount < 3) {
        _locationRetryCount++;
        Future.delayed(Duration(seconds: _locationRetryCount * 2), () {
          if (mounted) _initializeDriverLocation();
        });
      }
    }
  }

  void _startLocationTracking() {
    _stopLocationTracking();
    _startLocationBroadcastTimer();

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
        _driverCurrentLocation = newLocation;
        _lastHeading = position.heading;

        if (_isUpdatingLocation) return;
        if (DateTime.now().difference(_lastLocationUpdate).inSeconds < 5) return;
        _isUpdatingLocation = true;
        _lastLocationUpdate = DateTime.now();

        try {
          await DriverService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            token: widget.token,
          );

          WebSocketService.sendRideMessage('driver_location', {
            'driverId': widget.userId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
          });
        } finally {
          _isUpdatingLocation = false;
        }
      },
    );
  }

  void _stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _locationBroadcastTimer?.cancel();
  }

  void _startLocationBroadcastTimer() {
    _locationBroadcastTimer?.cancel();
    _locationBroadcastTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_driverCurrentLocation == null) return;
      WebSocketService.sendRideMessage('driver_location', {
        'driverId': widget.userId,
        'latitude': _driverCurrentLocation!.latitude,
        'longitude': _driverCurrentLocation!.longitude,
        'heading': _lastHeading,
      });
    });
  }

  void _startRidePolling() {
    _ridePollTimer?.cancel();
    _ridePollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchAvailableRides();
    });
  }

  void _stopRidePolling() {
    _ridePollTimer?.cancel();
  }

  Future<void> _fetchAvailableRides() async {
    if (_currentRide != null) return;
    try {
      final rides = await RideService.getAvailableRides(widget.token);
      if (!mounted) return;

      final newRideIds = rides.map((r) => r.id).toSet();
      final unseenIds = newRideIds.difference(_knownRideIds);

      setState(() {
        _availableRides = rides;
        _knownRideIds = newRideIds;
      });

      for (final ride in rides) {
        if (unseenIds.contains(ride.id) && !_isPreviewOpen) {
          _handleNewRideRequest({
            'rideId': ride.id,
            'riderId': ride.rider.id,
            'riderName': ride.rider.fullName,
            'pickupAddress': ride.pickupAddress,
            'dropoffAddress': ride.dropoffAddress,
            'pickupLat': ride.pickupLatitude,
            'pickupLng': ride.pickupLongitude,
            'dropoffLat': ride.dropoffLatitude,
            'dropoffLng': ride.dropoffLongitude,
            'estimatedFare': ride.estimatedFare,
            'estimatedDistance': ride.estimatedDistance,
            'estimatedDuration': ride.estimatedDuration,
            'rideType': ride.rideType,
          });
          break;
        }
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _startNotificationPolling() {
    _fetchUnreadCount();
    _notificationPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchUnreadCount();
    });
  }

  Future<void> _fetchUnreadCount() async {
    if (!mounted) return;
    try {
      final count = await NotificationService.getUnreadCount(widget.token);
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isLoading = true);

    try {
      final result = await DriverService.toggleOnlineStatus(widget.token);
      if (mounted) {
        setState(() {
          _isOnline = result;
          _isLoading = false;
        });

        if (_isOnline) {
          _startLocationTracking();
          _startRidePolling();
          _fetchAvailableRides();
        } else {
          _stopLocationTracking();
          _stopRidePolling();
          setState(() => _availableRides = []);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to update status');
      }
    }
  }

  void _onLogout() async {
    try {
      _stopLocationTracking();
      _stopRidePolling();
      _notificationPollTimer?.cancel();

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
        Navigator.pushNamedAndRemoveUntil(context, '/splash', (route) => false);
      }
    } catch (e) {
      // Silent fail
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildMap(),
          _buildOverlay(),
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              elevation: 2,
              onPressed: _recenterMap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 22),
            ),
          ),
          _buildTopBar(),
          if (_selectedIndex == 1) _buildAvailableRidesOverlay(),
          if (_selectedIndex == 2) _buildProfileOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      style: _mapStyle,
      onMapCreated: (controller) => _mapController = controller,
      initialCameraPosition: CameraPosition(
        target: _driverCurrentLocation ?? const LatLng(0, 0),
        zoom: 15,
      ),
      markers: {
        if (_driverCurrentLocation != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverCurrentLocation!,
            icon: _driverMarkerIcon,
            rotation: _lastHeading,
            anchor: const Offset(0.5, 0.5),
            flat: true,
          ),
      },
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildOverlay() {
    if (_selectedIndex != 0) return const SizedBox.shrink();
    if (_currentRide == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: _buildActiveRideCard(),
    );
  }

  Widget _buildActiveRideCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppSpacing.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Active Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              StatusBadge.active(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentRide!.pickupAddress,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _currentRide!.dropoffAddress,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PremiumButton(
                  label: 'Navigate',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/driver-navigation',
                      arguments: {
                        'rideId': _currentRide!.id,
                        'pickupAddress': _currentRide!.pickupAddress,
                        'pickupLat': _currentRide!.pickupLatitude,
                        'pickupLng': _currentRide!.pickupLongitude,
                        'dropoffAddress': _currentRide!.dropoffAddress,
                        'dropoffLat': _currentRide!.dropoffLatitude,
                        'dropoffLng': _currentRide!.dropoffLongitude,
                      },
                    );
                  },
                  variant: ButtonVariant.primary,
                  height: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: Row(
        children: [
          _buildFloatingButton(
            icon: Icons.menu_rounded,
            onPressed: _showMenuSheet,
            heroTag: 'menu',
          ),
          const Spacer(),
          _buildOnlineToggle(),
          const Spacer(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildFloatingButton(
                icon: Icons.notifications_outlined,
                onPressed: _showNotificationsSheet,
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
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isOnline ? AppColors.success : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isOnline ? [
            BoxShadow(
              color: AppColors.success.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _isOnline ? Colors.white : AppColors.textTertiary,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                color: _isOnline ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
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

  Widget _buildAvailableRidesOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        color: AppColors.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Available Rides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: _availableRides.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No rides available',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'New ride requests will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _availableRides.length,
                      itemBuilder: (context, index) {
                        final ride = _availableRides[index];
                        return _buildRideCard(ride);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ride.rider.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (ride.estimatedFare != null)
                Text(
                  '\$${ride.estimatedFare!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAddressRow(Icons.circle, AppColors.success, ride.pickupAddress),
          const SizedBox(height: 4),
          _buildAddressRow(Icons.location_on, AppColors.error, ride.dropoffAddress),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ride.estimatedDistance != null)
                _buildInfoChip(Icons.straighten, '${ride.estimatedDistance!.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              if (ride.estimatedDuration != null)
                _buildInfoChip(Icons.schedule, '${ride.estimatedDuration} min'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, Color color, String address) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverlay() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 0,
      right: 0,
      bottom: 80,
      child: Container(
        color: AppColors.surface,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.username.isNotEmpty
                              ? widget.username[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _driverProfile?.user.fullName ?? widget.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildProfileStat(
                icon: Icons.star,
                label: 'Rating',
                value: '${_driverProfile?.averageRating.toStringAsFixed(1) ?? "5.0"}',
                color: AppColors.warning,
              ),
              _buildProfileStat(
                icon: Icons.directions_car,
                label: 'Total Rides',
                value: '${_driverProfile?.totalRides ?? 0}',
                color: AppColors.primary,
              ),
              _buildProfileStat(
                icon: Icons.attach_money,
                label: 'Vehicle',
                value: _driverProfile?.vehicleModel ?? "N/A",
                color: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) _fetchAvailableRides();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Available',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet() {
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
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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

  void _recenterMap() {
    if (_driverCurrentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverCurrentLocation!, 15),
      );
    }
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
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined, size: 20),
                title: const Text('Debug'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DebugScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: const Text('Trip History'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripHistoryScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, size: 20),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        username: widget.username,
                        userId: widget.userId,
                        token: widget.token,
                      ),
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

  @override
  void dispose() {
    _positionStream?.cancel();
    _ridePollTimer?.cancel();
    _locationBroadcastTimer?.cancel();
    _notificationPollTimer?.cancel();
    _rideEventsSub?.cancel();
    _chatMessagesSub?.cancel();
    _alertTimeoutTimer?.cancel();
    _ringtonePlayer.stop();
    super.dispose();
  }
}
