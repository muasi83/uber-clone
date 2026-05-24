import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../screens/debug_screen.dart';

class RiderRoutePreviewScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double estimatedDistance;
  final double estimatedFare;
  final int estimatedDuration;
  final String rideType;

  const RiderRoutePreviewScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.estimatedDistance,
    required this.estimatedFare,
    required this.estimatedDuration,
    required this.rideType,
  });

  @override
  State<RiderRoutePreviewScreen> createState() =>
      _RiderRoutePreviewScreenState();
}

class _RiderRoutePreviewScreenState extends State<RiderRoutePreviewScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeRoute();
  }

  Future<void> _initializeRoute() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🗺️  ROUTE PREVIEW INITIALIZING');
      addDebugMessage('From: ${widget.pickupAddress}');
      addDebugMessage('To: ${widget.dropoffAddress}');

      // Get real route
      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
      );

      if (!mounted) return;

      if (route == null || !route.isSuccess) {
        setState(() {
          _error = 'Could not load route';
          _isLoading = false;
        });
        addDebugMessage('❌ Route fetch failed');
        return;
      }

      // Add markers
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(widget.pickupLat, widget.pickupLng),
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(widget.dropoffLat, widget.dropoffLng),
          infoWindow: const InfoWindow(title: 'Dropoff'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      // Add polyline
         // Add polyline
      if (route.polylinePoints != null && route.polylinePoints!.isNotEmpty) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: route.polylinePoints!,
            color: Colors.blue,
            width: 5,
            geodesic: true,
            patterns: [
              PatternItem.dash(30),
              PatternItem.gap(20),
            ],
          ),
        );
        addDebugMessage(
            '✅ Route loaded with ${route.polylinePoints!.length} points');
      }

      setState(() => _isLoading = false);

      // Animate to show both
      _fitBounds();

      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Route error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error loading route: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.pickupLat < widget.dropoffLat
            ? widget.pickupLat - 0.01
            : widget.dropoffLat - 0.01,
        widget.pickupLng < widget.dropoffLng
            ? widget.pickupLng - 0.01
            : widget.dropoffLng - 0.01,
      ),
      northeast: LatLng(
        widget.pickupLat > widget.dropoffLat
            ? widget.pickupLat + 0.01
            : widget.dropoffLat + 0.01,
        widget.pickupLng > widget.dropoffLng
            ? widget.pickupLng + 0.01
            : widget.dropoffLng + 0.01,
      ),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: const Text(
          'Route Preview',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
            myLocationButtonEnabled: false,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // Error overlay
          if (_error != null)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _error = null);
                            _initializeRoute();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

                    // Pickup
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'From',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.pickupAddress,
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
                    const SizedBox(height: 12),

                    // Dropoff
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
                                'To',
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

                    // Route details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailItem(
                            icon: Icons.straighten,
                            label: 'Distance',
                            value:
                                '${widget.estimatedDistance.toStringAsFixed(2)} km',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.blue[200],
                          ),
                          _buildDetailItem(
                            icon: Icons.access_time,
                            label: 'Duration',
                            value: '${widget.estimatedDuration} min',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF6366F1),
                                width: 2,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Change Route',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.pop(context, {
                                      'routeConfirmed': true,
                                      'pickupLat': widget.pickupLat,
                                      'pickupLng': widget.pickupLng,
                                      'pickupAddress':
                                          widget.pickupAddress,
                                      'dropoffLat': widget.dropoffLat,
                                      'dropoffLng': widget.dropoffLng,
                                      'dropoffAddress':
                                          widget.dropoffAddress,
                                      'estimatedDistance':
                                          widget.estimatedDistance,
                                      'estimatedFare': widget.estimatedFare,
                                      'estimatedDuration':
                                          widget.estimatedDuration,
                                      'rideType': widget.rideType,
                                    }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              disabledBackgroundColor: Colors.grey[300],
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isLoading ? 'Loading...' : 'Confirm Route',
                              style: TextStyle(
                                color: _isLoading
                                    ? Colors.grey
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blue,
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