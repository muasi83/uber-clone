import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/status_badge.dart';
import '../models/ride_model.dart';
import '../services/currency_service.dart';
import '../services/ride_service.dart';
import '../services/driver_service.dart';
import '../services/websocket_service.dart';
import '../services/storage_service.dart';
import '../screens/settings_screen.dart';
import '../screens/ride_preview_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/trip_history_screen.dart';
import '../utils/bearing_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';
import '../utils/address_utils.dart';
import '../services/recorded_screen_mixin.dart';
import '../models/scheduled_ride.dart';
import '../services/scheduled_ride_service.dart';

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

class _DriverHomeScreenState extends State<DriverHomeScreen> with RecordedScreenMixin<DriverHomeScreen> {
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

  bool _isAlertPlaying = false;
  bool _isPreviewOpen = false;
  Timer? _alertTimeoutTimer;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;
  StreamSubscription<Map<String, dynamic>>? _chatMessagesSub;

  bool _isUpdatingLocation = false;
  DateTime _lastLocationUpdate = DateTime.now().subtract(const Duration(seconds: 10));
  int _locationRetryCount = 0;
  LatLng? _animatedDriverPos;
  Timer? _driverAnimTimer;
  BitmapDescriptor _driverMarkerIcon = BitmapDescriptor.defaultMarker;

  bool _isAcceptingRide = false;
  String? _mapStyle;
  Set<int?> _knownRideIds = {};

  Map<String, dynamic>? _financialSummary;

  List<ScheduledRide> _pendingScheduledRides = [];
  List<ScheduledRide> _driverScheduledRides = [];
  Timer? _scheduledRidePollTimer;
  final Set<int> _scheduledRideLoadingIds = {};

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initMarkerIcons();
    _loadDriverProfile();
    _checkActiveRide();
    _connectWebSocket();
    _fetchScheduledRides();
    _initializeDriverLocation();
    recordEvent(
      eventName: 'DRIVER_HOME_OPENED',
      category: 'FRONTEND',
      summary: 'Driver home screen opened',
    );
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
    _loadFinancialSummary();
  }

  Future<void> _loadFinancialSummary() async {
    try {
      final summary = await DriverService.getFinancialSummary(widget.token);
      if (mounted) {
        setState(() => _financialSummary = summary);
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

  void _handleForceLogout() async {
    if (!mounted) return;
    WebSocketService.disconnect();
    await StorageService.clearAllData();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
    }
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
        } else if (type == 'scheduled_ride_removed') {
          final removedId = event['rideId'] as int?;
          if (removedId != null && mounted) {
            setState(() {
              _pendingScheduledRides.removeWhere((r) => r.id == removedId);
            });
          }
        } else if (type == 'scheduled_ride_30min_reminder') {
          final payload = event['payload'] as Map<String, dynamic>?;
          final pickup = payload?['pickupAddress'] as String? ?? '';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.notifications, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Scheduled ride in 30 min: $pickup')),
                  ],
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (type == 'scheduled_ride_unassigned') {
          final unassignedId = event['rideId'] as int?;
          if (unassignedId != null && mounted) {
            setState(() {
              _driverScheduledRides.removeWhere((r) => r.id == unassignedId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Scheduled ride was cancelled'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else if (type == 'scheduled_ride_available') {
          final payload = event['payload'] as Map<String, dynamic>?;
          if (payload != null && mounted) {
            final ride = ScheduledRide.fromJson(payload);
            setState(() {
              _driverScheduledRides.removeWhere((r) => r.id == ride.id);
              if (!_pendingScheduledRides.any((r) => r.id == ride.id)) {
                _pendingScheduledRides.add(ride);
              }
            });
          }
        } else if (type == 'scheduled_ride_cancelled') {
          final cancelledId = event['rideId'] as int?;
          if (cancelledId != null && mounted) {
            setState(() {
              _driverScheduledRides.removeWhere((r) => r.id == cancelledId);
              _pendingScheduledRides.removeWhere((r) => r.id == cancelledId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A scheduled ride was cancelled by the rider'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
        } else if (type == 'scheduled_ride_expired') {
          final expiredId = event['rideId'] as int?;
          if (expiredId != null && mounted) {
            setState(() {
              _driverScheduledRides.removeWhere((r) => r.id == expiredId);
              _pendingScheduledRides.removeWhere((r) => r.id == expiredId);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('A scheduled ride has expired'),
                backgroundColor: AppColors.warning,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 4),
              ),
            );
          }
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
              borderRadius: AppRadius.smRadius,
            ),
          ),
        );
      },
    );
  }

  void _handleNewRideRequest(Map<String, dynamic> event) {
    if (!mounted || _currentRide != null || _isPreviewOpen) return;

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
      recordEvent(
        eventName: 'DRIVER_RIDE_CANCELLED',
        category: 'BUSINESS',
        summary: 'Ride cancelled by passenger',
        extraDetails: {'rideId': rideId},
      );
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
        looping: true,
        asAlarm: true,
      );
      Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 800], intensities: [0, 255, 0, 255, 0, 255]);
    } catch (e) {
      addDebugMessage('❌ Ride alert error: $e');
    }

    _alertTimeoutTimer?.cancel();
    _alertTimeoutTimer = Timer(const Duration(seconds: 30), () {
      addDebugMessage('⏱️ Ride alert timed out after 30s');
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
      addDebugMessage('❌ Stop ride alert error: $e');
    }
    _alertTimeoutTimer?.cancel();
  }

  void _showRidePreview(Map<String, dynamic> event) {
    _isPreviewOpen = true;
    // Alarm keeps playing — driver must accept, ignore, or let 30s timeout stop it

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
            _stopRideAlert();
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

      recordEvent(
        eventName: 'DRIVER_ACCEPTED_RIDE',
        category: 'BUSINESS',
        summary: 'Driver accepted ride',
        extraDetails: {'rideId': rideId},
      );

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
        recordEvent(
          eventName: 'DRIVER_ACCEPT_RIDE_FAILED',
          category: 'BUSINESS',
          summary: 'Failed to accept ride',
          extraDetails: {'rideId': rideData['rideId'], 'error': e.toString()},
        );
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
        _startDriverMarkerAnimation(newLocation);

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

  void _startDriverMarkerAnimation(LatLng target) {
    _driverAnimTimer?.cancel();
    final origin = _animatedDriverPos ?? _driverCurrentLocation ?? target;

    const steps = 30;
    var step = 0;

    _driverAnimTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      step++;
      final t = step / steps;
      final eased = 1.0 - math.pow(1.0 - t, 3).toDouble();

      _animatedDriverPos = LatLng(
        origin.latitude + (target.latitude - origin.latitude) * eased,
        origin.longitude + (target.longitude - origin.longitude) * eased,
      );

      if (mounted) setState(() {});

      if (step >= steps) {
        _driverAnimTimer?.cancel();
        _driverAnimTimer = null;
        _animatedDriverPos = null;
        if (mounted) setState(() {});
      }
    });
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

  Future<void> _toggleOnlineStatus() async {
    setState(() => _isLoading = true);
    final isGoingOnline = !_isOnline;

    try {
      final result = await DriverService.toggleOnlineStatus(widget.token);
      if (mounted) {
        setState(() {
          _isOnline = result;
          _isLoading = false;
        });

        recordEvent(
          eventName: isGoingOnline ? 'DRIVER_WENT_ONLINE' : 'DRIVER_WENT_OFFLINE',
          category: 'BUSINESS',
          summary: isGoingOnline ? 'Driver went online' : 'Driver went offline',
        );

        if (_isOnline) {
          _startLocationTracking();
          _startRidePolling();
          _fetchAvailableRides();
          _fetchScheduledRides();
          _startScheduledRidePolling();
        } else {
          _stopLocationTracking();
          _stopRidePolling();
          _stopScheduledRidePolling();
          setState(() {
            _availableRides = [];
            _pendingScheduledRides = [];
            _driverScheduledRides = [];
          });
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
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smRadius),
        margin: AppSpacing.cardPadding,
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
          PositionedDirectional(
            end: 16,
            bottom: 120,
            child:             Semantics(
              button: true,
              label: 'Recenter map',
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.9),
                elevation: 2,
                onPressed: _recenterMap,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdRadius,
                ),
                child: const Icon(Icons.my_location, color: AppColors.primary, size: 22),
              ),
            ),
          ),
          _buildTopBar(),
          if (_isOnline && _selectedIndex == 0 && _currentRide == null)
            _buildEarningsCard(),
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
            position: _animatedDriverPos ?? _driverCurrentLocation!,
            icon: _driverMarkerIcon,
            rotation: normalizeCarHeading(_lastHeading % 360),
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
    final ride = _currentRide!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        boxShadow: AppShadows.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Active Ride',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              StatusBadge.active(),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  ride.rider.fullName.isNotEmpty
                      ? ride.rider.fullName[0].toUpperCase()
                      : 'R',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.rider.fullName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.outline,
                        ),
                      ),
                      Container(
                        width: 11,
                        height: 11,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatLatLng(ride.pickupLatitude, ride.pickupLongitude),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        ride.dropoffAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatLatLng(ride.dropoffLatitude, ride.dropoffLongitude),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Pickup ETA: -- min',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PremiumButton(
            label: 'Navigate',
            icon: Icons.navigation,
            onPressed: () {
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
            },
            variant: ButtonVariant.primary,
            height: 50,
            borderRadius: 14,
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
          Semantics(
            button: true,
            label: 'Menu',
            child: _buildFloatingButton(
              icon: Icons.menu_rounded,
              onPressed: _showMenuSheet,
              heroTag: 'menu',
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: 'Toggle online status',
            child: _buildOnlineToggle(),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle() {
    return GestureDetector(
      onTap: _isLoading ? null : _toggleOnlineStatus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: _isOnline ? AppColors.success : AppColors.dark,
          borderRadius: BorderRadius.circular(100),
          boxShadow: _isOnline ? AppShadows.large : AppShadows.medium,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            else
              _isOnline
                  ? const _PulsingDot(color: Colors.white, size: 14)
                  : Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.textTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isOnline ? 'Go Offline' : 'Go Online',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 0.3,
                  ),
                ),
                if (_isOnline)
                  Text(
                    _availableRides.isEmpty
                        ? 'No nearby rides'
                        : '${_availableRides.length} ride${_availableRides.length == 1 ? '' : 's'} nearby',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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
      backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.9),
      elevation: 2,
      onPressed: onPressed,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdRadius,
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
  }

  Widget _buildAvailableRidesOverlay() {
    final hasAvailable = _availableRides.isNotEmpty;
    final hasPendingScheduled = _pendingScheduledRides.isNotEmpty;
    final hasDriverScheduled = _driverScheduledRides.isNotEmpty;
    final isEmpty = !hasAvailable && !hasPendingScheduled && !hasDriverScheduled;

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
            Padding(
              padding: AppSpacing.cardPadding,
              child: Text(
                'Available Rides',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rides available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'New ride requests will appear here',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        if (hasAvailable) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Text(
                              'Available Now',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          ..._availableRides.map((ride) => _buildRideCard(ride)),
                        ],
                        if (hasPendingScheduled) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              'Scheduled Rides',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          ..._pendingScheduledRides.map((ride) => _buildScheduledRideCard(ride)),
                        ],
                        if (hasDriverScheduled) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text(
                              'My Upcoming',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          ..._driverScheduledRides.map((ride) => _buildDriverScheduledRideCard(ride)),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    final fs = _financialSummary;
    final totalGross = (fs?['totalGross'] as num?) ?? 0;
    final platformFees = (fs?['platformFeesGenerated'] as num?) ?? 0;
    final amountSettled = (fs?['amountSettled'] as num?) ?? 0;
    final outstanding = (fs?['outstandingBalance'] as num?) ?? 0;
    final lastDate = fs?['lastSettlementDate'] as String?;

    return PositionedDirectional(
      top: MediaQuery.of(context).padding.top + 80,
      start: 16,
      child: GestureDetector(
        onTap: () => _showFinancialDetails(totalGross, platformFees, amountSettled, outstanding, lastDate),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppShadows.medium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.trending_up, size: 16, color: AppColors.success),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyService.format(totalGross),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    "Today's earnings",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFinancialDetails(num totalGross, num platformFees, num amountSettled, num outstanding, String? lastDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Financial Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            _finRow('Lifetime Earnings', CurrencyService.format(totalGross), AppColors.success),
            _finRow('Platform Fees (15%)', CurrencyService.format(platformFees), AppColors.primary),
            _finRow('Amount Settled', CurrencyService.format(amountSettled), AppColors.info),
            const Divider(height: 24, color: AppColors.outline),
            _finRow('Outstanding Balance', CurrencyService.format(outstanding),
              outstanding > 0 ? AppColors.warning : AppColors.success),
            if (lastDate != null) ...[
              const SizedBox(height: 8),
              Text('Last Settlement: ${_formatDate(lastDate)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _finRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildRideCard(Ride ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlRadius,
        border: Border.all(color: AppColors.outline),
        boxShadow: AppShadows.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  ride.rider.fullName.isNotEmpty
                      ? ride.rider.fullName[0].toUpperCase()
                      : 'R',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.rider.fullName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              if (ride.estimatedFare != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    CurrencyService.format(ride.estimatedFare!),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: AppColors.outline,
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.pickupAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatLatLng(ride.pickupLatitude, ride.pickupLongitude),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        ride.dropoffAddress,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatLatLng(ride.dropoffLatitude, ride.dropoffLongitude),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (ride.estimatedDistance != null)
                _buildInfoChip(Icons.straighten, '${ride.estimatedDistance!.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              if (ride.estimatedDuration != null)
                _buildInfoChip(Icons.schedule, '${ride.estimatedDuration} min'),
              const Spacer(),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _showRidePreview({
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
                  }),
                  icon: const Icon(Icons.assignment_turned_in, size: 18),
                  label: const Text('View', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchScheduledRides() async {
    if (!_isOnline) return;
    if (_driverCurrentLocation == null) return;
    try {
      final pending = await ScheduledRideService.getNearby(
        lat: _driverCurrentLocation!.latitude,
        lng: _driverCurrentLocation!.longitude,
        token: widget.token,
      );
      final driverUpcoming = await ScheduledRideService.getDriverUpcoming(widget.token);
      if (mounted) {
        setState(() {
          _pendingScheduledRides = pending;
          _driverScheduledRides = driverUpcoming;
        });
      }
    } catch (e) {
      addDebugMessage('Error fetching scheduled rides: $e');
    }
  }

  void _startScheduledRidePolling() {
    _scheduledRidePollTimer?.cancel();
    _scheduledRidePollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchScheduledRides();
    });
  }

  void _stopScheduledRidePolling() {
    _scheduledRidePollTimer?.cancel();
  }

  Widget _buildScheduledRideCard(ScheduledRide ride) {
    final dateStr = DateFormat('MMM dd, yyyy – HH:mm').format(ride.scheduledAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.warning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
              if (ride.estimatedFare != null)
                Text(
                  CurrencyService.format(ride.estimatedFare!),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAddressRow(Icons.circle, AppColors.success, ride.pickupAddress,
              lat: ride.pickupLatitude, lng: ride.pickupLongitude),
          const SizedBox(height: 4),
          _buildAddressRow(Icons.location_on, AppColors.error, ride.dropoffAddress,
              lat: ride.dropoffLatitude, lng: ride.dropoffLongitude),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ride.estimatedDistance != null)
                _buildInfoChip(Icons.straighten, '${ride.estimatedDistance!.toStringAsFixed(1)} km'),
              const SizedBox(width: 8),
              if (ride.estimatedDuration != null)
                _buildInfoChip(Icons.schedule, '${ride.estimatedDuration} min'),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: ride.id != null && _scheduledRideLoadingIds.contains(ride.id) ? null : () => _acceptScheduledRide(ride),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smRadius,
                    ),
                  ),
                  child: _scheduledRideLoadingIds.contains(ride.id)
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary))
                    : const Text('Accept', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverScheduledRideCard(ScheduledRide ride) {
    final dateStr = DateFormat('MMM dd, yyyy – HH:mm').format(ride.scheduledAt);
    final timeLeft = ride.scheduledAt.difference(DateTime.now());
    final timeLeftStr = timeLeft.inMinutes > 60
        ? '${timeLeft.inHours}h ${timeLeft.inMinutes.remainder(60)}m'
        : '${timeLeft.inMinutes}m';

    Color statusColor;
    switch (ride.status) {
      case 'ASSIGNED':
        statusColor = AppColors.info;
        break;
      case 'DRIVER_ARRIVED':
        statusColor = AppColors.success;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdRadius,
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smRadius,
                ),
                child: Text(
                  ride.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              ),
              const Spacer(),
              Text(
                timeLeftStr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: timeLeft.inMinutes < 10 ? AppColors.error : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAddressRow(Icons.circle, AppColors.success, ride.pickupAddress,
              lat: ride.pickupLatitude, lng: ride.pickupLongitude),
          const SizedBox(height: 4),
          _buildAddressRow(Icons.location_on, AppColors.error, ride.dropoffAddress,
              lat: ride.dropoffLatitude, lng: ride.dropoffLongitude),
          const SizedBox(height: 12),
          Row(
            children: [
              if (ride.estimatedFare != null)
                Text(
                  CurrencyService.format(ride.estimatedFare!),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
              const Spacer(),
              if (ride.isAssigned) ...[
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: ride.id != null && _scheduledRideLoadingIds.contains(ride.id) ? null : () => _unassignScheduledRide(ride),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smRadius,
                      ),
                    ),
                    child: _scheduledRideLoadingIds.contains(ride.id)
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error))
                      : const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: ride.id != null && _scheduledRideLoadingIds.contains(ride.id) ? null : () => _markArrivedForScheduledRide(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smRadius,
                      ),
                    ),
                    child: _scheduledRideLoadingIds.contains(ride.id)
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary))
                      : const Text('Arrived', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ],
              if (ride.isDriverArrived)
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: ride.id != null && _scheduledRideLoadingIds.contains(ride.id) ? null : () => _showPickupCodeDialog(ride),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.smRadius,
                      ),
                    ),
                    child: _scheduledRideLoadingIds.contains(ride.id)
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary))
                      : const Text('Verify Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptScheduledRide(ScheduledRide ride) async {
    if (ride.id == null) return;
    if (_scheduledRideLoadingIds.contains(ride.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Scheduled Ride'),
        content: Text('Accept ride scheduled for ${
          DateFormat('MMM dd, HH:mm').format(ride.scheduledAt)
        }?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ignore')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _scheduledRideLoadingIds.add(ride.id!));
    try {
      final result = await ScheduledRideService.assign(ride.id!, widget.token);
      if (mounted && result != null) {
        setState(() {
          _pendingScheduledRides.removeWhere((r) => r.id == ride.id);
          _driverScheduledRides.add(result);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scheduled ride accepted — ${ride.pickupAddress}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scheduledRideLoadingIds.remove(ride.id!));
    }
  }

  Future<void> _unassignScheduledRide(ScheduledRide ride) async {
    if (ride.id == null) return;
    if (_scheduledRideLoadingIds.contains(ride.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Scheduled Ride'),
        content: const Text('Release this ride so other drivers can accept it?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Release', style: TextStyle(color: AppColors.textOnPrimary)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _scheduledRideLoadingIds.add(ride.id!));
    try {
      final result = await ScheduledRideService.unassign(ride.id!, widget.token);
      if (mounted && result != null) {
        setState(() {
          _driverScheduledRides.removeWhere((r) => r.id == ride.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scheduled ride released'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scheduledRideLoadingIds.remove(ride.id!));
    }
  }

  Future<void> _markArrivedForScheduledRide(ScheduledRide ride) async {
    if (ride.id == null) return;
    if (_scheduledRideLoadingIds.contains(ride.id)) return;
    setState(() => _scheduledRideLoadingIds.add(ride.id!));
    try {
      final result = await ScheduledRideService.markArrived(ride.id!, widget.token);
      if (mounted && result != null) {
        setState(() {
          final idx = _driverScheduledRides.indexWhere((r) => r.id == ride.id);
          if (idx >= 0) _driverScheduledRides[idx] = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as arrived — ask rider for pickup code'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _scheduledRideLoadingIds.remove(ride.id!));
    }
  }

  void _showPickupCodeDialog(ScheduledRide ride) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Pickup Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ask the rider for the 6-digit pickup code'),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 6, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                counterText: '',
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.length != 6) return;
              Navigator.pop(ctx);
              await _verifyAndStartRide(ride, code);
            },
            child: const Text('Verify & Start'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAndStartRide(ScheduledRide ride, String code) async {
    if (ride.id == null) return;
    if (_scheduledRideLoadingIds.contains(ride.id)) return;
    setState(() => _scheduledRideLoadingIds.add(ride.id!));
    try {
      final valid = await ScheduledRideService.verifyCode(ride.id!, code, widget.token);
      if (!mounted) return;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code — please try again'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final result = await ScheduledRideService.start(ride.id!, widget.token);
      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started — navigating to trip'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamed(context, '/driver-navigation', arguments: {
          'rideId': ride.id,
          'pickupAddress': ride.pickupAddress,
          'pickupLat': ride.pickupLatitude,
          'pickupLng': ride.pickupLongitude,
          'dropoffAddress': ride.dropoffAddress,
          'dropoffLat': ride.dropoffLatitude,
          'dropoffLng': ride.dropoffLongitude,
        });
      }
    } finally {
      if (mounted) setState(() => _scheduledRideLoadingIds.remove(ride.id!));
    }
  }

  Widget _buildAddressRow(IconData icon, Color color, String address,
      {double? lat, double? lng}) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (lat != null && lng != null)
                Text(
                  formatLatLng(lat, lng),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10, color: AppColors.textTertiary),
                ),
            ],
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
        borderRadius: AppRadius.smRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
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
          padding: AppSpacing.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _driverProfile?.user.fullName ?? widget.username,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdRadius,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    return NavigationBar(
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
                onTap: _onLogout,
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
    _rideEventsSub?.cancel();
    _chatMessagesSub?.cancel();
    _alertTimeoutTimer?.cancel();
    _driverAnimTimer?.cancel();
    _scheduledRidePollTimer?.cancel();
    try { _ringtonePlayer.stop(); } catch (_) {}
    super.dispose();
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _PulsingDot({required this.color, this.size = 12});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * (1.0 - _controller.value)),
                blurRadius: 2 + _controller.value * 6,
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
        );
      },
    );
  }
}
