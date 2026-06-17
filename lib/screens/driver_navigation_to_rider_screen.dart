import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/ride_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class DriverNavigationToRiderScreen extends StatefulWidget {
  final int rideId;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final String dropoffAddress;
  final double dropoffLat;
  final double dropoffLng;

  const DriverNavigationToRiderScreen({
    super.key,
    required this.rideId,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffAddress,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  @override
  State<DriverNavigationToRiderScreen> createState() =>
      _DriverNavigationToRiderScreenState();
}

class _DriverNavigationToRiderScreenState
    extends State<DriverNavigationToRiderScreen> {
  GoogleMapController? mapController;
  LatLng? _driverLocation;
  late final LatLng _pickupLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;
  bool _isArriving = false;
  int _remainingMinutes = 15;
  double? _distanceKm;

  StreamSubscription<Position>? _positionStream;
  int? _otherUserId;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();

    _pickupLocation = LatLng(widget.pickupLat, widget.pickupLng);

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER NAVIGATION TO RIDER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('Pickup: ${widget.pickupLat}, ${widget.pickupLng}');
    addDebugMessage('Address: ${widget.pickupAddress}');
    addDebugMessage('═══════════════════════════════════════');

    _initYellowPin();
    _initializeNavigation();
    _fetchChatPartnerId();
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initializeNavigation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _driverLocation = LatLng(position.latitude, position.longitude);
      addDebugMessage('✅ Driver location: ${position.latitude}, ${position.longitude}');

      _updateMarkers();
      _updateRoute();
      _startLocationStream();

      if (mounted) setState(() {});
    } catch (e) {
      addDebugMessage('❌ Init error: $e');
    }
  }

  void _startLocationStream() {
    _stopLocationStream();

    addDebugMessage('▶️ Starting navigation location stream (50m filter)');

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
        _driverLocation = newLocation;

        addDebugMessage(
          '📍 Driver moved 50m+ — ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
        );

        try {
          final token = StorageService.getToken();
          if (token != null) {
            await RideService.updateDriverLocation(
              rideId: widget.rideId,
              latitude: position.latitude,
              longitude: position.longitude,
              token: token,
            );
            addDebugMessage('✅ Rider notified of driver location via REST');
          }

          WebSocketService.sendRideMessage('driver_location', {
            'driverId': StorageService.getUserId(),
            'rideId': widget.rideId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'heading': position.heading,
          });
          addDebugMessage('✅ Rider notified of driver location via WebSocket');
        } catch (e) {
          addDebugMessage('⚠️ Failed to update rider location: $e');
        }

        if (mounted) {
          _updateMarkers();
          _updateRoute();
          setState(() {});
        }
      },
      onError: (error) {
        addDebugMessage('❌ Navigation stream error: $error');
      },
      onDone: () {
        addDebugMessage('⏹️ Navigation stream closed');
      },
    );
  }

  void _stopLocationStream() {
    if (_positionStream != null) {
      _positionStream!.cancel();
      _positionStream = null;
      addDebugMessage('⏹️ Navigation location stream stopped');
    }
  }

  Future<void> _updateMarkers() async {
    _markers.clear();

    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: await MarkerFactory.driver,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLocation,
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress}'),
      ),
    );

    if (mounted) setState(() {});
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _pickupLocation,
      );

      if (route != null && route.isSuccess && mounted) {
        _polylines.clear();

        if (route.polylinePoints != null && route.polylinePoints!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.mapRouteLine,
              width: 5,
              geodesic: true,
            ),
          );
        }

        setState(() {
          _remainingMinutes = route.durationMinutes ?? 0;
          _distanceKm = route.distanceKm;
        });

        addDebugMessage(
          '✅ Route updated — ${route.distanceKm?.toStringAsFixed(1)} km, $_remainingMinutes min',
        );
      }
    } catch (e) {
      addDebugMessage('⚠️ Route error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_driverLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _pickupLocation.latitude
            ? _driverLocation!.latitude - 0.01
            : _pickupLocation.latitude - 0.01,
        _driverLocation!.longitude < _pickupLocation.longitude
            ? _driverLocation!.longitude - 0.01
            : _pickupLocation.longitude - 0.01,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _pickupLocation.latitude
            ? _driverLocation!.latitude + 0.01
            : _pickupLocation.latitude + 0.01,
        _driverLocation!.longitude > _pickupLocation.longitude
            ? _driverLocation!.longitude + 0.01
            : _pickupLocation.longitude + 0.01,
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _notifyArrival() async {
    try {
      _stopLocationStream();
      setState(() => _isArriving = true);

      addDebugMessage('📍 Notifying driver arrival...');

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.driverArrived(widget.rideId, token);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rider notified!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Verify ride is still active before navigating
        if (token != null) {
          final ride = await RideService.getRideDetails(widget.rideId, token);
          if (ride != null && ride.status != 'CANCELLED' && ride.status != 'COMPLETED' && mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/driver-active-ride',
              arguments: {
                'rideId': widget.rideId,
                'dropoffAddress': widget.dropoffAddress,
                'dropoffLat': widget.dropoffLat,
                'dropoffLng': widget.dropoffLng,
              },
            );
          } else if (mounted) {
            addDebugMessage('⚠️ Ride was ${ride?.status} — returning to home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride was cancelled'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.pushNamedAndRemoveUntil(context, '/driver-home', (route) => false);
          }
        } else if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/driver-active-ride',
            arguments: {
              'rideId': widget.rideId,
              'dropoffAddress': widget.dropoffAddress,
              'dropoffLat': widget.dropoffLat,
              'dropoffLng': widget.dropoffLng,
            },
          );
        }
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isArriving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _openGoogleMaps() {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${widget.pickupLat},${widget.pickupLng}'
      '&travelmode=driving',
    );
    _launchUrl(uri);
  }

  Future<void> _launchUrl(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        addDebugMessage('Google Maps opened: $uri');
      } else {
        await Clipboard.setData(ClipboardData(text: uri.toString()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Maps — link copied to clipboard'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        addDebugMessage('Could not launch, copied URL instead: $uri');
      }
    } catch (e) {
      addDebugMessage('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Navigate to Rider',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                tooltip: 'Chat with Rider',
                onPressed: _openChat,
              ),
              _buildUnreadBadge(),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: true,
            style: _mapStyle,
          ),
          if (_isArriving)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isArriving ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  color: AppColors.mapOverlay,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 80),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'You have arrived!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Rider has been notified',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusXxl),
                  topRight: Radius.circular(AppSpacing.radiusXxl),
                ),
                boxShadow: AppSpacing.shadowXl,
              ),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.error, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pickup Location',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.pickupAddress,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: AppColors.outline),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$_remainingMinutes min remaining',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_distanceKm != null)
                        Text(
                          '${_distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PremiumButton(
                    label: _isArriving ? 'Notifying...' : "I've Arrived",
                    icon: _isArriving ? Icons.hourglass_empty : Icons.check_circle,
                    onPressed: _isArriving ? null : _notifyArrival,
                    variant: ButtonVariant.gradient,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openGoogleMaps,
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('Open Google Maps'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _fetchChatPartnerId() async {
    final token = StorageService.getToken();
    if (token == null) return;
    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride != null && mounted) {
        _otherUserId = ride.rider.id;
      }
    } catch (_) {}
  }

  Widget _buildUnreadBadge() {
    if (_otherUserId == null) return const SizedBox.shrink();
    final count = WebSocketService.unreadCounts[_otherUserId!] ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Positioned(
      right: 2,
      top: 2,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 9 ? '9+' : '$count',
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _openChat() async {
    final token = StorageService.getToken();
    final currentUserId = StorageService.getUserId();
    final currentUsername = StorageService.getUsername();
    if (token == null || currentUserId == null || currentUsername == null) return;

    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null) return;

      final otherUser = ride.rider;
      if (otherUser.id == null) return;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              receiverId: otherUser.id!,
              receiverName: otherUser.fullName,
              token: token,
            ),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Chat error: $e');
    }
  }

  @override
  void dispose() {
    _stopLocationStream();
    mapController?.dispose();
    super.dispose();
  }
}
