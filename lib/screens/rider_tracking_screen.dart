import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';

class RiderTrackingScreen extends StatefulWidget {
  final int rideId;
  final Map<String, dynamic> driverData;

  const RiderTrackingScreen({
    super.key,
    required this.rideId,
    required this.driverData,
  });

  @override
  State<RiderTrackingScreen> createState() => _RiderTrackingScreenState();
}

class _RiderTrackingScreenState extends State<RiderTrackingScreen> {
  late GoogleMapController mapController;
  LatLng? _driverLocation;
  LatLng? _pickupLocation;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _driverArrived = false;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
    _setupWebSocketListeners();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('👁️  TRACKING DRIVER');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  void _initializeTracking() {
    _driverLocation = LatLng(
      widget.driverData['currentLatitude'] as double? ?? 0,
      widget.driverData['currentLongitude'] as double? ?? 0,
    );

    _pickupLocation = LatLng(
      widget.driverData['pickupLatitude'] as double? ?? 0,
      widget.driverData['pickupLongitude'] as double? ?? 0,
    );

    _updateMarkers();
    _updateRoute();
  }

  void _setupWebSocketListeners() {
    try {
      WebSocketService.rideEvents.listen((event) {
        final type = event['type'] ?? '';

        if (type == 'driver_location') {
          final lat = event['latitude'] as double?;
          final lng = event['longitude'] as double?;

          if (lat != null && lng != null && mounted) {
            setState(() {
              _driverLocation = LatLng(lat, lng);
              _updateMarkers();
              _updateRoute();
              _fitBounds();
            });

            addDebugMessage('📍 Driver location updated: $lat, $lng');
          }
        } else if (type == 'driver_arrived' && mounted) {
          setState(() => _driverArrived = true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Your driver has arrived!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );

          addDebugMessage('✅ Driver arrived notification');
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error setting up listeners: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Pickup (green)
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

    // Driver (blue)
    if (_driverLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
          infoWindow: InfoWindow(
            title: widget.driverData['driverName'] as String? ?? 'Driver',
          ),
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

        setState(() {});
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'Driver on the Way',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _driverLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Top card - Driver info
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
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.driverData['driverName'] as String? ??
                                'Driver',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.driverData['vehicleColor'] as String? ?? 'Unknown'} ${widget.driverData['vehicleModel'] as String? ?? ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.driverData['licensePlate'] as String? ??
                                'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone,
                          color: Color(0xFF6366F1)),
                      onPressed: () {
                        // TODO: Implement call driver
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Call driver feature coming soon'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom card - Status
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status
                    Text(
                      _driverArrived
                          ? '✅ Driver has arrived!'
                          : '🚗 Driver is on the way',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _driverArrived ? Colors.green : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _driverArrived
                          ? 'Meet your driver at the pickup location'
                          : 'Driver is approaching your pickup location',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Progress indicator
                    if (!_driverArrived)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
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
    mapController.dispose();
    super.dispose();
  }
}