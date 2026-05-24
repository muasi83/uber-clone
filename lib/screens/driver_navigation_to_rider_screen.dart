import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/ride_service.dart';
import '../services/directions_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';

class DriverNavigationToRiderScreen extends StatefulWidget {
  final int rideId;
  final String pickupAddress;

  const DriverNavigationToRiderScreen({
    super.key,
    required this.rideId,
    required this.pickupAddress,
  });

  @override
  State<DriverNavigationToRiderScreen> createState() =>
      _DriverNavigationToRiderScreenState();
}

class _DriverNavigationToRiderScreenState
    extends State<DriverNavigationToRiderScreen> {
  late GoogleMapController mapController;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _locationTimer;
  bool _isArriving = false;
  int _remainingMinutes = 15;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 DRIVER NAVIGATION TO RIDER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _initializeNavigation() async {
    try {
      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _driverLocation = LatLng(position.latitude, position.longitude);

      // TODO: Get pickup location from ride details (should be passed in arguments)
      _pickupLocation = const LatLng(0, 0); // Placeholder

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

        final newLocation = LatLng(position.latitude, position.longitude);

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
            _driverLocation = newLocation;
            _updateMarkers();
            _updateRoute();
          });
        }

        addDebugMessage(
            '📍 Location updated: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        addDebugMessage('⚠️ Location update error: $e');
      }
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Driver location (blue)
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Pickup location (green)
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }

    setState(() {});
  }

  Future<void> _updateRoute() async {
    if (_driverLocation == null || _pickupLocation == null) return;

    try {
      final route = await DirectionsService.getDirections(
        origin: _driverLocation!,
        destination: _pickupLocation!,
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
    _fitBounds();
  }

  void _fitBounds() {
    if (_driverLocation == null || _pickupLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        _driverLocation!.latitude < _pickupLocation!.latitude
            ? _driverLocation!.latitude - 0.01
            : _pickupLocation!.latitude - 0.01,
        _driverLocation!.longitude < _pickupLocation!.longitude
            ? _driverLocation!.longitude - 0.01
            : _pickupLocation!.longitude - 0.01,
      ),
      northeast: LatLng(
        _driverLocation!.latitude > _pickupLocation!.latitude
            ? _driverLocation!.latitude + 0.01
            : _pickupLocation!.latitude + 0.01,
        _driverLocation!.longitude > _pickupLocation!.longitude
            ? _driverLocation!.longitude + 0.01
            : _pickupLocation!.longitude + 0.01,
      ),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  Future<void> _notifyArrival() async {
    try {
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
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/driver-active-ride',
              arguments: {
                'rideId': widget.rideId,
                'dropoffAddress': 'Destination',
              },
            );
          }
        });
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      if (mounted) {
        setState(() => _isArriving = false);
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
        title: const Text(
          'Navigate to Pickup',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Map
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
            myLocationButtonEnabled: true,
          ),

          // Bottom button
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isArriving ? null : _notifyArrival,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isArriving ? 'Notifying...' : 'I\'ve Arrived',
                  style: TextStyle(
                    color: _isArriving ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          // Top ETA card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ETA',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_remainingMinutes minutes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.pickupAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
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