import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/status_badge.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/driver_service.dart';
import '../services/websocket_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../screens/settings_screen.dart';
import '../screens/debug_screen.dart';
import '../screens/ride_preview_screen.dart';

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
  final Map<int, RouteData> _routeCache = {};

  // LOCATION STREAM (replaces timer)
  StreamSubscription<Position>? _positionStream;
  LatLng? _driverCurrentLocation;
  double _lastHeading = 0;

  // 🔥 FIX: Ride polling fallback timer — NOT location, just ride fetching
  Timer? _ridePollTimer;

  // ALERT STATE
  bool _isAlertPlaying = false;
  bool _isDialogShowing = false;
  Timer? _alertTimeoutTimer;
  final FlutterRingtonePlayer _ringtonePlayer = FlutterRingtonePlayer();

  // Periodic location broadcast (every 10s) so riders can see driver on map
  Timer? _locationBroadcastTimer;

  // Map controller
  GoogleMapController? _mapController;

  // SIMULATION MODE — tap on map to move driver
  bool _simulationMode = false;
  LatLng? _simulatedLocation;
  LatLng? _lastSimulatedLocation;

  StreamSubscription<Map<String, dynamic>>? _rideEventsSub;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER HOME SCREEN LOADED');
    addDebugMessage('User: ${widget.username}');
    addDebugMessage('═══════════════════════════════════════');

    _loadDriverProfile();
    _checkActiveRide();
    _connectWebSocket();
    _initializeDriverLocation();
  }

  // ═════════════════════════════════════════════════════════════════
  // ACTIVE RIDE CHECK (Engagement Lock)
  // ═════════════════════════════════════════════════════════════════

  Future<void> _checkActiveRide() async {
    try {
      final activeRide = await DriverService.getActiveRide(widget.token);
      if (activeRide != null && mounted) {
        setState(() => _currentRide = activeRide);
        addDebugMessage('🚗 Found active ride: ${activeRide.id} — new ride notifications BLOCKED');
      } else {
        addDebugMessage('ℹ️ No active ride — ready for notifications');
      }
    } catch (e) {
      addDebugMessage('⚠️ Error checking active ride: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // LOCATION (one-time init fetch)
  // ═════════════════════════════════════════════════════════════════

  Future<void> _initializeDriverLocation() async {
    addDebugMessage('📍 Checking driver location...');

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      addDebugMessage('❌ Location services disabled');
      if (mounted) _showError('Please enable GPS/Location services to continue');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        addDebugMessage('❌ Location permission denied');
        if (mounted) _showError('Location permission is required for drivers');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      addDebugMessage('❌ Location permission denied forever');
      if (mounted) {
        _showError('Location permission denied. Please enable it in app settings.');
      }
      await Geolocator.openAppSettings();
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _driverCurrentLocation = LatLng(position.latitude, position.longitude);
      addDebugMessage('✅ Initial location: ${position.latitude}, ${position.longitude}');

      if (!_isOnline) {
        addDebugMessage('ℹ️ Offline — location saved locally, not broadcasting');
        return;
      }

      final success = await DriverService.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        token: widget.token,
      );

      if (success) {
        addDebugMessage('✅ Driver location registered on server');
      } else {
        addDebugMessage('⚠️ Failed to register location on server');
      }

      WebSocketService.sendRideMessage('driver_location', {
        'driverId': widget.userId,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });
    } catch (e) {
      addDebugMessage('❌ Error getting initial location: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // STREAM-BASED LOCATION TRACKING (50m distance filter)
  // ═════════════════════════════════════════════════════════════════

  void _startLocationTracking() {
    _stopLocationTracking();

    addDebugMessage('▶️ Starting location stream (50m filter)...');

    _startLocationBroadcastTimer();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        if (!mounted) return;

        final newLocation = LatLng(position.latitude, position.longitude);
        _driverCurrentLocation = newLocation;
        _lastHeading = position.heading;

        addDebugMessage(
          '📍 Driver moved 50m+ — ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        );

        try {
          final success = await DriverService.updateLocation(
            latitude: position.latitude,
            longitude: position.longitude,
            token: widget.token,
          );
          if (success) {
            addDebugMessage('✅ Server updated with new location');
          } else {
            addDebugMessage('⚠️ Server location update failed');
          }

          WebSocketService.sendRideMessage('driver_location', {
            'driverId': widget.userId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
          });
        } catch (e) {
          addDebugMessage('❌ Error sending location: $e');
        }

        if (_isOnline && _selectedIndex == 1) {
          addDebugMessage('🔄 Refreshing nearby rides due to location change');
          _loadAvailableRides();
        }
      },
      onError: (error) {
        addDebugMessage('❌ Location stream error: $error');
      },
      onDone: () {
        addDebugMessage('⏹️ Location stream closed');
      },
    );
  }

  void _stopLocationTracking() {
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
      addDebugMessage('⏹️ Location stream stopped');
    }
    _stopLocationBroadcastTimer();
  }

  /// Broadcast driver location via WebSocket every 10 seconds.
  /// This lets riders see the driver's car on their map even when stationary.
  void _startLocationBroadcastTimer() {
    _stopLocationBroadcastTimer();
    _locationBroadcastTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _broadcastLocationViaWebSocket();
    });
    addDebugMessage('▶️ Location broadcast timer started (10s)');
  }

  void _stopLocationBroadcastTimer() {
    _locationBroadcastTimer?.cancel();
    _locationBroadcastTimer = null;
  }

  void _broadcastLocationViaWebSocket() {
    if (_driverCurrentLocation == null || !_isOnline) return;
    WebSocketService.sendRideMessage('driver_location', {
      'driverId': widget.userId,
      'latitude': _driverCurrentLocation!.latitude,
      'longitude': _driverCurrentLocation!.longitude,
      'heading': _lastHeading,
    });
  }

  // ═════════════════════════════════════════════════════════════════
  // SIMULATION MODE — tap map to teleport driver for testing
  // ═════════════════════════════════════════════════════════════════

  void _toggleSimulationMode() {
    setState(() {
      _simulationMode = !_simulationMode;
      if (!_simulationMode) _simulatedLocation = null;
    });
    addDebugMessage('🎮 Simulation mode: ${_simulationMode ? 'ON' : 'OFF'}');

    if (_simulationMode) {
      _positionStream?.cancel();
      _positionStream = null;
      addDebugMessage('⏸️ Real GPS paused — broadcast timer keeps running');
    } else {
      if (_isOnline) {
        _startLocationTracking();
        addDebugMessage('▶️ Real GPS + broadcast resumed');
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    if (!_simulationMode) return;

    addDebugMessage('🎯 Simulated move → ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}');

    setState(() {
      _simulatedLocation = position;
      _driverCurrentLocation = position;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(position));

    DriverService.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      token: widget.token,
    );

    double? heading;
    if (_lastSimulatedLocation != null) {
      heading = _bearingBetween(_lastSimulatedLocation!, position);
    }
    _lastSimulatedLocation = position;

    WebSocketService.sendRideMessage('driver_location', {
      'driverId': widget.userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': heading,
    });

    addDebugMessage('✅ Simulated location sent to server + WebSocket broadcast');
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

  // ═════════════════════════════════════════════════════════════════
  // 🔥 FIX: RIDE POLLING FALLBACK (20s) — catches rides if WebSocket fails
  // ═════════════════════════════════════════════════════════════════

  void _startRidePolling() {
    _stopRidePolling();
    addDebugMessage('▶️ Starting ride poll fallback (10s)');

    _ridePollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted || !_isOnline || _currentRide != null) return;
      addDebugMessage('🔄 Poll fallback: fetching available rides');
      _loadAvailableRides();
    });
  }

  void _stopRidePolling() {
    _ridePollTimer?.cancel();
    _ridePollTimer = null;
    addDebugMessage('⏹️ Ride poll fallback stopped');
  }

  // ═════════════════════════════════════════════════════════════════
  // DISTANCE HELPER (15 KM FILTER)
  // ═════════════════════════════════════════════════════════════════

  double _calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000.0;
  }

  // ═════════════════════════════════════════════════════════════════
  // WEBSOCKET
  // ═════════════════════════════════════════════════════════════════

  void _connectWebSocket() {
    addDebugMessage('🔌 Connecting WebSocket for Driver...');
    WebSocketService.onForceLogout = _handleForceLogout;
    WebSocketService.connect(widget.userId, widget.username);
    _setupWebSocketListeners();
  }

  void _handleForceLogout() {
    if (!mounted) return;
    addDebugMessage('🚫 Force logout: signed in from another device');
    WebSocketService.disconnect();
    StorageService.clearAllData();
    Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed out: logged in from another device'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 🔥 FIX: Handle ALL ride event types, not just ride_available
  void _setupWebSocketListeners() {
    try {
      _rideEventsSub = WebSocketService.rideEvents.listen((event) {
        final type = event['type'] ?? 'unknown';
        final payload = event['payload'] ?? event;
        final rideId = payload['rideId'] ?? payload['id'];

        addDebugMessage('📨 WebSocket event received: $type | rideId: $rideId');

        switch (type) {
          case 'ride_available':
            addDebugMessage('📥 New ride request received via WebSocket');
            _handleRideAvailableEvent(event);
            break;

          // 🔥 FIX: Remove ride immediately when cancelled by rider
          case 'ride_cancelled':
            addDebugMessage('❌ Ride cancelled by rider: $rideId');
            if (rideId != null && mounted) {
              setState(() {
                _availableRides.removeWhere((r) => r.id.toString() == rideId.toString());
                _routeCache.remove(int.tryParse(rideId.toString()) ?? 0);
              });
              _showError('Ride $rideId was cancelled by rider');
            }
            break;

          // 🔥 FIX: Remove ride if another driver accepted it
          case 'ride_accepted':
            addDebugMessage('🤝 Ride accepted by another driver: $rideId');
            if (rideId != null && mounted) {
              setState(() {
                _availableRides.removeWhere((r) => r.id.toString() == rideId.toString());
                _routeCache.remove(int.tryParse(rideId.toString()) ?? 0);
              });
            }
            break;

          // 🔥 FIX: Remove ride if rider search timed out
          case 'search_timeout':
            addDebugMessage('⏱️ Search timeout for ride: $rideId');
            if (rideId != null && mounted) {
              setState(() {
                _availableRides.removeWhere((r) => r.id.toString() == rideId.toString());
                _routeCache.remove(int.tryParse(rideId.toString()) ?? 0);
              });
            }
            break;

          default:
            addDebugMessage('ℹ️ Unhandled WebSocket type: $type');
        }
      });
    } catch (e) {
      addDebugMessage('⚠️ WebSocket listener error: $e');
    }
  }

  /// Core logic: Online + Not Engaged + Within 15 KM → Loud Alert
  void _handleRideAvailableEvent(Map<String, dynamic> event) {
    if (!mounted) return;

    // 1. Must be ONLINE
    if (!_isOnline) {
      addDebugMessage('🔴 Driver is OFFLINE — ignoring ride');
      return;
    }

    // 2. Must NOT be already engaged
    if (_currentRide != null) {
      addDebugMessage('🚗 Driver already ENGAGED (ride ${_currentRide!.id}) — ignoring ride');
      return;
    }

    // 3. Must be WITHIN 15 KM
    final payload = event['payload'] ?? event;
    final pickupLat = payload['pickupLatitude'] ?? payload['pickupLat'];
    final pickupLng = payload['pickupLongitude'] ?? payload['pickupLng'];

    if (pickupLat != null && pickupLng != null && _driverCurrentLocation != null) {
      final distanceKm = _calculateDistanceKm(
        _driverCurrentLocation!.latitude,
        _driverCurrentLocation!.longitude,
        double.parse(pickupLat.toString()),
        double.parse(pickupLng.toString()),
      );

      if (distanceKm > 15.0) {
        addDebugMessage('📍 Ride too far: ${distanceKm.toStringAsFixed(1)} km > 15 km — ignoring');
        return;
      }
      addDebugMessage('📍 Ride within range: ${distanceKm.toStringAsFixed(1)} km ✅');
    } else if (_driverCurrentLocation == null) {
      addDebugMessage('⚠️ Driver location unknown — allowing notification anyway');
    }

    // 4. Block if dialog already showing
    if (_isDialogShowing) {
      addDebugMessage('🔇 Alert dialog already showing — ignoring duplicate');
      return;
    }

    // 5. Trigger LOUD alert + popup
    _playRideAlert();
    _showRideAlertDialog(event);

    // 6. Refresh list so it appears in Available tab
    _loadAvailableRides();
  }

  // ═════════════════════════════════════════════════════════════════
  // LOUD VOICE / RINGTONE ALERT
  // ═════════════════════════════════════════════════════════════════

  Future<void> _playRideAlert() async {
    if (_isAlertPlaying) return;
    _isAlertPlaying = true;

    try {
      // 🔥 FIX: Only play ringtone on real mobile devices (Android/iOS)
      // On Chrome/web/emulator, this plugin does nothing — skip it
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _ringtonePlayer.playAlarm(looping: true);
        addDebugMessage('🔔 Playing loud ride alert (alarm)');
      } else {
        addDebugMessage('ℹ️ Web/Chrome detected — skipping ringtone, using visual alert only');
      }

      // 🔥 FIX: Only vibrate on real mobile devices
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
          await Vibration.vibrate(pattern: [0, 800, 400, 800, 400, 800]);
          addDebugMessage('📳 Vibration started');
        }
      }
    } catch (e) {
      addDebugMessage('⚠️ Alert sound error: $e');
    }
  }

  void _stopRideAlert() {
    if (!_isAlertPlaying) return;
    _isAlertPlaying = false;

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        _ringtonePlayer.stop();
        Vibration.cancel();
      }
      addDebugMessage('🔕 Alert stopped');
    } catch (e) {
      addDebugMessage('⚠️ Stop alert error: $e');
    }
  }

  void _showRideAlertDialog(Map<String, dynamic> event) {
    if (_isDialogShowing) return;
    _isDialogShowing = true;

    final payload = event['payload'] ?? event;
    final rideId = payload['rideId'] ?? payload['id'];

    _alertTimeoutTimer?.cancel();
    _alertTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && Navigator.of(context).canPop()) {
        _stopRideAlert();
        _isDialogShowing = false;
        Navigator.of(context).pop();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.red, size: 32),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NEW RIDE AVAILABLE!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.local_taxi, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'A ride matching your location just arrived',
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'From:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  payload['pickupAddress'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'To:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  payload['dropoffAddress'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '\$${payload['estimatedFare']?.toString() ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _alertTimeoutTimer?.cancel();
                  _stopRideAlert();
                  _isDialogShowing = false;
                  Navigator.pop(dialogContext);
                  addDebugMessage('❌ Driver ignored ride $rideId');
                },
                child: const Text('IGNORE', style: TextStyle(color: Colors.grey)),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  _alertTimeoutTimer?.cancel();
                  _stopRideAlert();
                  _isDialogShowing = false;
                  await _openRidePreview(payload);
                },
                icon: const Icon(Icons.map, size: 18),
                label: const Text('VIEW ON MAP'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  _alertTimeoutTimer?.cancel();
                  _stopRideAlert();
                  _isDialogShowing = false;
                  Navigator.pop(dialogContext);
                  if (rideId != null) {
                    _acceptRide(int.parse(rideId.toString()));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.check, color: Colors.white),
                label: const Text(
                  'ACCEPT RIDE',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Future<void> _openRidePreview(Map<String, dynamic> payload) async {
    final pickupLat = (payload['pickupLatitude'] ?? payload['pickupLat'] ?? 0).toDouble();
    final pickupLng = (payload['pickupLongitude'] ?? payload['pickupLng'] ?? 0).toDouble();
    final dropoffLat = (payload['dropoffLatitude'] ?? payload['dropoffLat'] ?? 0).toDouble();
    final dropoffLng = (payload['dropoffLongitude'] ?? payload['dropoffLng'] ?? 0).toDouble();
    final fare = (payload['estimatedFare'] as num?)?.toDouble();

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RidePreviewScreen(
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            dropoffLat: dropoffLat,
            dropoffLng: dropoffLng,
            pickupAddress: payload['pickupAddress'] ?? 'Unknown',
            dropoffAddress: payload['dropoffAddress'] ?? 'Unknown',
            estimatedFare: fare,
          ),
        ),
      );
      // After returning from preview, re-show the alert if the ride is still available
      _isDialogShowing = false;
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // PROFILE & RIDES
  // ═════════════════════════════════════════════════════════════════

  Future<void> _loadDriverProfile() async {
    try {
      final profile = await DriverService.getDriverProfile(widget.token);
      if (profile != null) {
        setState(() => _driverProfile = profile);
        addDebugMessage('✅ Driver profile loaded');
      } else {
        addDebugMessage('⚠️ Driver profile is null');
        setState(() => _driverProfile = null);
      }
    } catch (e) {
      addDebugMessage('❌ Error loading driver profile: $e');
      setState(() => _driverProfile = null);
    }
  }

  Future<void> _loadAvailableRides() async {
    if (!_isOnline) {
      addDebugMessage('🔴 Driver is offline — clearing ride list');
      setState(() {
        _availableRides = [];
        _routeCache.clear();
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final rides = await RideService.getAvailableRides(widget.token);

      List<Ride> filteredRides = [];
      if (_driverCurrentLocation != null) {
        for (var ride in rides) {
          final distanceKm = _calculateDistanceKm(
            _driverCurrentLocation!.latitude,
            _driverCurrentLocation!.longitude,
            ride.pickupLatitude,
            ride.pickupLongitude,
          );
          if (distanceKm <= 15.0) {
            filteredRides.add(ride);
            addDebugMessage('✅ Ride ${ride.id} within ${distanceKm.toStringAsFixed(1)} km');
          } else {
            addDebugMessage('❌ Ride ${ride.id} too far: ${distanceKm.toStringAsFixed(1)} km');
          }
        }
      } else {
        addDebugMessage('⚠️ No driver location — cannot filter by distance');
        filteredRides = rides;
      }

      final existingIds = _availableRides.map((r) => r.id).toSet();
      final newRides = filteredRides.where((r) => !existingIds.contains(r.id)).toList();

      setState(() => _availableRides = filteredRides);
      addDebugMessage('✅ Showing ${filteredRides.length} nearby rides (${newRides.length} new)');

      // 🔔 Trigger alert for any NEW ride discovered via polling
      if (newRides.isNotEmpty && !_isAlertPlaying && !_isDialogShowing && _currentRide == null) {
        addDebugMessage('🔔 New ride from polling — triggering alert');
        _playRideAlert();
        _showRideAlertDialog({'payload': newRides.first.toJson()});
      }

      for (var ride in filteredRides) {
        try {
          final route = await DirectionsService.getDirections(
            origin: LatLng(ride.pickupLatitude, ride.pickupLongitude),
            destination: LatLng(ride.dropoffLatitude, ride.dropoffLongitude),
          );
          if (route != null && mounted) {
            setState(() {
              _routeCache[ride.id ?? 0] = RouteData(
                polylinePoints: route.polylinePoints,
                totalDistanceKm: route.distanceKm,
                totalDurationMinutes: route.durationMinutes,
              );
            });
          }
        } catch (e) {
          addDebugMessage('⚠️ Route preload error for ride ${ride.id}: $e');
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error loading rides: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // ONLINE / OFFLINE
  // ═════════════════════════════════════════════════════════════════

  Future<void> _toggleOnline() async {
    addDebugMessage('🔄 Toggling online status...');
    try {
      final result = await DriverService.toggleOnlineStatus(widget.token);
      if (result) {
        setState(() => _isOnline = !_isOnline);
        addDebugMessage('✅ Online status: $_isOnline');

        if (_isOnline) {
          WebSocketService.setOnline(widget.userId, widget.username);
          await _initializeDriverLocation();
          _startLocationTracking();
          _startRidePolling(); // 🔥 FIX: start fallback polling
          _loadAvailableRides();
        } else {
          WebSocketService.setOffline(widget.userId);
          _stopLocationTracking();
          _stopRidePolling(); // 🔥 FIX: stop fallback polling
          setState(() {
            _availableRides = [];
            _routeCache.clear();
          });
        }
      } else {
        _showError('Failed to toggle online status');
      }
    } catch (e) {
      addDebugMessage('❌ Exception: $e');
      _showError('Error: ${e.toString()}');
    }
  }

  // ═════════════════════════════════════════════════════════════════
  // ACCEPT RIDE
  // ═════════════════════════════════════════════════════════════════

  Future<void> _acceptRide(int rideId) async {
    _stopRideAlert();

    // Ensure we have driver location before accepting
    if (_driverCurrentLocation == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        _driverCurrentLocation = LatLng(pos.latitude, pos.longitude);
      } catch (_) {}
    }

    try {
      final ride = await RideService.acceptRide(rideId, widget.token);
      if (ride != null && mounted) {
        setState(() => _currentRide = ride);
        _availableRides.removeWhere((r) => r.id == rideId);

        if (mounted) {
          WebSocketService.sendRideMessage('ride_accepted', {
            'rideId': rideId,
            'driverName': _driverProfile?.user.fullName ?? widget.username,
            'driverId': widget.userId,
            'currentLatitude': _driverCurrentLocation?.latitude,
            'currentLongitude': _driverCurrentLocation?.longitude,
            'pickupLatitude': ride.pickupLatitude,
            'pickupLongitude': ride.pickupLongitude,
            'vehicleColor': _driverProfile?.vehicleColor ?? '',
            'vehicleModel': _driverProfile?.vehicleModel ?? '',
            'licensePlate': _driverProfile?.vehicleNumber ?? '',
          });

          Navigator.pushNamed(
            context,
            '/driver-navigation',
            arguments: {
              'rideId': rideId,
              'pickupAddress': ride.pickupAddress,
              'pickupLat': ride.pickupLatitude,
              'pickupLng': ride.pickupLongitude,
              'dropoffAddress': ride.dropoffAddress,
              'dropoffLat': ride.dropoffLatitude,
              'dropoffLng': ride.dropoffLongitude,
            },
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ride accepted!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error accepting ride: $e');
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // LOGOUT
  // ═════════════════════════════════════════════════════════════════

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              _showLoading('Logging out...');

              try {
                await http
                    .post(
                      Uri.parse('${StorageService.getServerUrl()}/api/users/${widget.userId}/logout'),
                      headers: {'Authorization': 'Bearer ${widget.token}'},
                    )
                    .timeout(const Duration(seconds: 10));
                addDebugMessage('✅ Server notified of logout');
              } catch (e) {
                addDebugMessage('⚠️ Server logout error (continuing anyway): $e');
              }

              try {
                WebSocketService.setOffline(widget.userId);
                WebSocketService.disconnect();
                addDebugMessage('✅ WebSocket disconnected');
              } catch (e) {
                addDebugMessage('⚠️ WebSocket disconnect error: $e');
              }

              try {
                await StorageService.clearToken();
                await StorageService.clearUserId();
                addDebugMessage('✅ Local storage cleared');
              } catch (e) {
                addDebugMessage('⚠️ Storage clear error: $e');
              }

              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLoading(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════
  // BUILD — PREMIUM UI/UX REDESIGN
  // ═════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildPremiumAppBar(),
      body: Stack(
        children: [
          _buildMapBackground(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: Stack(
              key: ValueKey('overlay_$_selectedIndex'),
              fit: StackFit.expand,
              children: [
                _buildBody(),
              ],
            ),
          ),
          _buildMapFabButtons(),
        ],
      ),
      bottomNavigationBar: _buildPremiumBottomNav(),
    );
  }

  PreferredSizeWidget _buildPremiumAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(Icons.directions_car, color: Colors.white, size: 20),
          ),
          AppSpacing.hGapMd,
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver Hub',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        GestureDetector(
          onTap: _toggleOnline,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _isOnline ? StatusBadge.online() : StatusBadge.offline(),
          ),
        ),
        AppSpacing.hGapSm,
        if (_isOnline)
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh rides',
            onPressed: _loadAvailableRides,
          ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SettingsScreen(username: widget.username)),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bug_report_outlined),
          tooltip: 'Debug Console',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DebugScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildPremiumBottomNav() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        if (index == 1) _loadAvailableRides();
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Available',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  Widget _buildMapBackground() {
    if (_driverCurrentLocation == null) {
      return Container(color: AppColors.background);
    }

    final markers = <Marker>{};

    if (_currentRide != null) {
      markers.addAll([
        Marker(
          markerId: const MarkerId('current_pickup'),
          position: LatLng(_currentRide!.pickupLatitude, _currentRide!.pickupLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: _currentRide!.pickupAddress),
        ),
        Marker(
          markerId: const MarkerId('current_dropoff'),
          position: LatLng(_currentRide!.dropoffLatitude, _currentRide!.dropoffLongitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: _currentRide!.dropoffAddress),
        ),
      ]);
    }

    if (_simulationMode && _simulatedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('simulated_driver'),
          position: _simulatedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: const InfoWindow(title: 'Simulated Location'),
        ),
      );
    }

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _driverCurrentLocation!,
            zoom: 14,
          ),
          onTap: _simulationMode ? _onMapTap : null,
          markers: markers,
          myLocationEnabled: !_simulationMode,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.bottomNavHeight + 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeOverlay();
      case 1:
        return _buildAvailableRidesOverlay();
      case 2:
        return _buildProfileOverlay();
      default:
        return _buildHomeOverlay();
    }
  }

  // ────────────────────────────────────────────────────────────────
  // HOME OVERLAY
  // ────────────────────────────────────────────────────────────────

  Widget _buildHomeOverlay() {
    return Positioned(
      key: const ValueKey('home_overlay'),
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _currentRide != null
                ? _buildCurrentRideCard()
                : _isOnline
                    ? _buildOnlineRequestList()
                    : _buildOfflineState(),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineState() {
    return Column(
      key: const ValueKey('offline'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumCard(
          padding: AppSpacing.cardPadding,
          shadows: AppSpacing.shadowLg,
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.textTertiary.withValues(alpha: 0.2), AppColors.outline.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: const Icon(Icons.power_settings_new, color: AppColors.textTertiary, size: 28),
              ),
              AppSpacing.gapMd,
              const Text(
                'You are offline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapXs,
              const Text(
                'Go online to start receiving ride requests',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AppSpacing.gapMd,
        if (_driverProfile != null)
          PremiumCard(
            padding: AppSpacing.cardPadding,
            shadows: AppSpacing.shadowMd,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Rating', _driverProfile!.averageRating.toStringAsFixed(1), Icons.star, AppColors.warning),
                _buildStatColumn('Rides', _driverProfile!.totalRides.toString(), Icons.trip_origin, AppColors.primary),
                _buildStatColumn('Earnings', '\$--', Icons.attach_money, AppColors.success),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color.withValues(alpha: 0.5), size: 18),
        AppSpacing.gapXs,
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildMapFabButtons() {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + AppSpacing.bottomNavHeight + 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_simulationMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SIM MODE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          FloatingActionButton.small(
            heroTag: 'simulate',
            onPressed: () {
              final wasOff = !_simulationMode;
              _toggleSimulationMode();
              if (wasOff) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap the map to place the driver'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            backgroundColor: _simulationMode ? Colors.amber : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.pin_drop,
              color: _simulationMode ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'online_toggle',
            onPressed: _toggleOnline,
            backgroundColor: _isOnline ? AppColors.success : AppColors.textTertiary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.power_settings_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentRideCard() {
    final ride = _currentRide!;
    return Column(
      key: const ValueKey('current_ride'),
      mainAxisSize: MainAxisSize.min,
      children: [
        PremiumCard(
          padding: AppSpacing.cardPadding,
          shadows: AppSpacing.shadowXl,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.navigation, color: Colors.white, size: 20),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Ride',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Ride #${ride.id}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge.arriving(),
                ],
              ),
              AppSpacing.gapLg,
              Container(
                padding: AppSpacing.chipPadding,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 14, color: AppColors.primary),
                    const SizedBox(width: 2),
                    Text(
                      ride.rider.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapMd,
              _buildAddressRow(Icons.trip_origin, ride.pickupAddress, AppColors.primary),
              AppSpacing.gapSm,
              _buildAddressRow(Icons.location_on, ride.dropoffAddress, AppColors.error),
              AppSpacing.gapLg,
              PremiumButton(
                label: 'Navigate to pickup',
                icon: Icons.navigation,
                variant: ButtonVariant.gradient,
                onPressed: () {
                  Navigator.pushNamed(context, '/driver-navigation', arguments: {
                    'rideId': ride.id,
                    'pickupAddress': ride.pickupAddress,
                    'pickupLat': ride.pickupLatitude,
                    'pickupLng': ride.pickupLongitude,
                    'dropoffAddress': ride.dropoffAddress,
                    'dropoffLat': ride.dropoffLatitude,
                    'dropoffLng': ride.dropoffLongitude,
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressRow(IconData icon, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────────
  // ONLINE RIDE REQUEST LIST
  // ────────────────────────────────────────────────────────────────

  Widget _buildOnlineRequestList() {
    return Column(
      key: const ValueKey('online_requests'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(_availableRides.length, (index) {
          final ride = _availableRides[index];
          final routeData = _routeCache[ride.id ?? 0];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _availableRides.length - 1 ? 0 : AppSpacing.md,
            ),
            child: _buildRideRequestCard(ride, routeData),
          );
        }),
        if (_availableRides.isEmpty && !_isLoading)
          PremiumCard(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: AppSpacing.lg),
            shadows: AppSpacing.shadowMd,
            child: Column(
              children: [
                Icon(
                  Icons.radio_button_unchecked,
                  size: 48,
                  color: AppColors.textTertiary.withValues(alpha: 0.4),
                ),
                AppSpacing.gapMd,
                const Text(
                  'No ride requests nearby',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                AppSpacing.gapXs,
                const Text(
                  'Within 15 km of your location',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          )
        else if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildRideRequestCard(Ride ride, RouteData? routeData) {
    return PremiumCard(
      padding: AppSpacing.cardPadding,
      shadows: AppSpacing.shadowLg,
      border: Border.all(color: AppColors.outline.withValues(alpha: 0.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: const Icon(Icons.directions_car, color: Colors.white, size: 22),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.rideType,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (routeData != null && routeData.totalDistanceKm != null)
                      Text(
                        '${routeData.totalDistanceKm!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Text(
                      '\$${ride.estimatedFare?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (routeData != null && routeData.totalDurationMinutes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${routeData.totalDurationMinutes} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          AppSpacing.gapMd,
          const Divider(height: 1),
          AppSpacing.gapMd,
          _buildAddressRow(Icons.trip_origin, ride.pickupAddress, AppColors.success),
          AppSpacing.gapSm,
          _buildAddressRow(Icons.location_on, ride.dropoffAddress, AppColors.error),
          AppSpacing.gapLg,
          PremiumButton(
            label: 'Accept Ride',
            icon: Icons.check_circle_outline,
            variant: ButtonVariant.gradient,
            onPressed: () => _acceptRide(ride.id ?? 0),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // AVAILABLE RIDES TAB
  // ────────────────────────────────────────────────────────────────

  Widget _buildAvailableRidesOverlay() {
    return Positioned(
      key: const ValueKey('available_overlay'),
      left: 0,
      right: 0,
      bottom: 0,
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
      child: !_isOnline
          ? Center(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                shadows: AppSpacing.shadowXl,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 56,
                      color: AppColors.textTertiary.withValues(alpha: 0.5),
                    ),
                    AppSpacing.gapMd,
                    const Text(
                      'You are offline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    const Text(
                      'Go online to see available rides near you',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapXl,
                    PremiumButton(
                      label: 'Go Online',
                      icon: Icons.power_settings_new,
                      variant: ButtonVariant.gradient,
                      height: 48,
                      width: 200,
                      onPressed: _toggleOnline,
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _availableRides.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadAvailableRides,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: PremiumCard(
                              padding: const EdgeInsets.all(AppSpacing.xxl),
                              shadows: AppSpacing.shadowXl,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_car_outlined,
                                    size: 56,
                                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                                  ),
                                  AppSpacing.gapMd,
                                  const Text(
                                    'No available rides nearby',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  AppSpacing.gapSm,
                                  const Text(
                                    'Within 15 km of your location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAvailableRides,
                      child: ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          0,
                          AppSpacing.lg,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        itemCount: _availableRides.length,
                        itemBuilder: (context, index) {
                          final ride = _availableRides[index];
                          final routeData = _routeCache[ride.id ?? 0];
                          return Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? AppSpacing.lg : 0,
                              bottom: index == _availableRides.length - 1
                                  ? 0
                                  : AppSpacing.md,
                            ),
                            child: _buildRideRequestCard(ride, routeData),
                          );
                        },
                      ),
                    ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // PROFILE TAB
  // ────────────────────────────────────────────────────────────────

  Widget _buildProfileOverlay() {
    return Positioned(
      key: const ValueKey('profile_overlay'),
      left: 0,
      right: 0,
      bottom: 0,
      top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
      child: _driverProfile == null
          ? Center(
              child: PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                shadows: AppSpacing.shadowXl,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      size: 56,
                      color: AppColors.warning.withValues(alpha: 0.7),
                    ),
                    AppSpacing.gapMd,
                    const Text(
                      'Driver Profile Not Found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.gapSm,
                    const Text(
                      'You need to register as a driver first',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.gapXl,
                    PremiumButton(
                      label: 'Retry',
                      icon: Icons.refresh,
                      variant: ButtonVariant.outline,
                      height: 48,
                      width: 160,
                      onPressed: _loadDriverProfile,
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [
                PremiumCard(
                  padding: AppSpacing.cardPadding,
                  shadows: AppSpacing.shadowLg,
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _driverProfile!.user.fullName.isNotEmpty
                                ? _driverProfile!.user.fullName[0].toUpperCase()
                                : 'D',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      AppSpacing.gapMd,
                      Text(
                        _driverProfile!.user.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapXs,
                      Text(
                        _driverProfile!.vehicleModel != null
                            ? '${_driverProfile!.vehicleModel} - ${_driverProfile!.vehicleColor}'
                            : 'Vehicle not set',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      AppSpacing.gapLg,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildProfileStat(Icons.star, _driverProfile!.averageRating.toStringAsFixed(1), 'Rating', AppColors.warning),
                          Container(width: 1, height: 40, color: AppColors.outline),
                          _buildProfileStat(Icons.trip_origin, _driverProfile!.totalRides.toString(), 'Rides', AppColors.primary),
                          Container(width: 1, height: 40, color: AppColors.outline),
                          _buildProfileStat(Icons.attach_money, '\$--', 'Earnings', AppColors.success),
                        ],
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapMd,
                PremiumCard(
                  padding: AppSpacing.cardPadding,
                  shadows: AppSpacing.shadowSm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.gapLg,
                      _buildProfileRow('License', _driverProfile!.licenseNumber ?? 'Not provided', Icons.credit_card),
                      const Divider(height: 1),
                      _buildProfileRow('Vehicle', '${_driverProfile!.vehicleModel ?? 'Unknown'} (${_driverProfile!.vehicleColor ?? 'Unknown'})', Icons.directions_car),
                      const Divider(height: 1),
                      _buildProfileRow('Vehicle Number', _driverProfile!.vehicleNumber ?? 'Not provided', Icons.tag),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProfileStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        AppSpacing.gapXs,
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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

  @override
  void dispose() {
    _alertTimeoutTimer?.cancel();
    _stopLocationTracking();
    _stopRidePolling();
    _stopRideAlert();
    _rideEventsSub?.cancel();
    WebSocketService.disconnect();
    super.dispose();
  }
}

class RouteData {
  final List<LatLng>? polylinePoints;
  final double? totalDistanceKm;
  final int? totalDurationMinutes;
  RouteData({this.polylinePoints, this.totalDistanceKm, this.totalDurationMinutes});
}