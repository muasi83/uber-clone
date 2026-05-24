import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/ride_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';

class DriverActiveRideScreen extends StatefulWidget {
  final int rideId;
  final String dropoffAddress;

  const DriverActiveRideScreen({
    Key? key,
    required this.rideId,
    required this.dropoffAddress,
  }) : super(key: key);

  @override
  State<DriverActiveRideScreen> createState() =>
      _DriverActiveRideScreenState();
}

class _DriverActiveRideScreenState extends State<DriverActiveRideScreen> {
  late GoogleMapController mapController;
  LatLng? _driverLocation;
  LatLng? _destinationLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  bool _rideStarted = false;
  bool _isCompleting = false;
  int _remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    _initializeRide();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 ACTIVE RIDE - HEADING TO DESTINATION');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _initializeRide() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _driverLocation = LatLng(position.latitude, position.longitude);
      _destinationLocation = const LatLng(0, 0); // TODO: Get from ride data

      _updateMarkers();
      _updateRoute();
      _startLocationUpdates();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      addDebugMessage('❌ Init error: $e');
    }
  }

  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final token = StorageService.getToken();
        if (token != null) {
          await RideService.updateDriverLocation(
            rideId: widget.rideId,
            latitude: position.latitude,
            longitude: position.longitude,
            token: token,
          );
        }

        if (mounted) {
          setState(() {
            _driverLocation = LatLng(position.latitude, position.longitude);
            _updateMarkers();
            _updateRoute();
          });
        }
      } catch (e) {
        addDebugMessage('⚠️ Location update error: $e');
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();

    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
        ),
      );
    }

    if (_destinationLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    setState(() {});
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null || _destinationLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _destinationLocation!,
      );

      if (route != null && route.isSuccess && mounted) {
        _polylines.clear();

        if (route.polylinePoints != null &&
            route.polylinePoints!.isNotEmpty) {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: Colors.blue,
              width: 5,
              geodesic: true,
            ),
          );
        }

        setState(() {
          _remainingMinutes = route.durationMinutes ?? 0;
        });
      }
    } catch (e) {
      addDebugMessage('⚠️ Route error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _startRide() async {
    try {
      setState(() => _rideStarted = true);

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.startRide(widget.rideId, token);
      }

      addDebugMessage('✅ Ride started');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride started!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _rideStarted = false);
      }
    }
  }

  Future<void> _completeRide() async {
    try {
      setState(() => _isCompleting = true);

      final token = StorageService.getToken();
      if (token != null) {
        await RideService.completeRide(widget.rideId, token);
      }

      _locationTimer?.cancel();

      addDebugMessage('✅ Ride completed');

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/driver-summary',
          arguments: {
            'rideId': widget.rideId,
          },
        );
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isCompleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Text(
          _rideStarted ? 'On the Way' : 'Ready to Start',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              children: [
                if (_rideStarted)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCompleting ? null : _completeRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isCompleting ? 'Completing...' : 'Complete Ride',
                        style: TextStyle(
                          color: _isCompleting ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _startRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
    _locationTimer?.cancel();
    mapController.dispose();
    super.dispose();
  }
}