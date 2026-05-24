import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../services/websocket_service.dart';
import '../screens/debug_screen.dart';

class RiderActiveRideScreen extends StatefulWidget {
  final int rideId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;

  const RiderActiveRideScreen({
    Key? key,
    required this.rideId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
  }) : super(key: key);

  @override
  State<RiderActiveRideScreen> createState() => _RiderActiveRideScreenState();
}

class _RiderActiveRideScreenState extends State<RiderActiveRideScreen> {
  late GoogleMapController mapController;
  LatLng? _driverLocation;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int _remainingMinutes = 0;

  @override
  void initState() {
    super.initState();
    _setupWebSocketListeners();
    _updateRoute();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 ACTIVE RIDE');
    addDebugMessage('Destination: ${widget.dropoffAddress}');
    addDebugMessage('═══════════════════════════════════════');
  }

  void _setupWebSocketListeners() {
    try {
      WebSocketService.driverLocationEvents.listen((event) {
        final lat = event['latitude'] as double?;
        final lng = event['longitude'] as double?;

        if (lat != null && lng != null && mounted) {
          setState(() {
            _driverLocation = LatLng(lat, lng);
            _updateMarkers();
            _updateRoute();
          });
        }
      });

      WebSocketService.rideEvents.listen((event) {
        if (event['type'] == 'ride_completed' && mounted) {
          Navigator.pushReplacementNamed(
            context,
            '/rider-completed',
            arguments: {
              'rideId': widget.rideId,
              'totalFare': event['payload']?['totalFare'],
              'distance': event['payload']?['distance'],
              'duration': event['payload']?['duration'],
            },
          );
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Current location (yellow)
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: const LatLng(0, 0), // TODO: Get actual current location
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueYellow,
        ),
      ),
    );

    // Driver (blue)
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

    // Destination (red)
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );

    setState(() {});
  }

  Future<void> _updateRoute() async {
    try {
      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'On the Way',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
          ),

          // Bottom card
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
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

                    // Destination
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Destination',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.dropoffAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ETA
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'ETA: $_remainingMinutes minutes',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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