import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/directions_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';

class RidePreviewScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String pickupAddress;
  final String dropoffAddress;
  final double? estimatedFare;

  const RidePreviewScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.pickupAddress,
    required this.dropoffAddress,
    this.estimatedFare,
  });

  @override
  State<RidePreviewScreen> createState() => _RidePreviewScreenState();
}

class _RidePreviewScreenState extends State<RidePreviewScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _autoDismissTimer;
  int _phase = 0; // 0=pickup zoom, 1=dropoff zoom, 2=full route

  @override
  void initState() {
    super.initState();
    addDebugMessage('RidePreviewScreen opened');
    _addMarkers();
    _startPreviewSequence();
    _autoDismissTimer = Timer(const Duration(seconds: 6), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _addMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress}'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Dropoff: ${widget.dropoffAddress}'),
      ),
    );
  }

  Future<void> _startPreviewSequence() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Phase 1: Zoom to pickup point (2-2.5 seconds)
    setState(() => _phase = 0);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.pickupLat, widget.pickupLng),
        16,
      ),
    );
    addDebugMessage('Phase 1: Zooming to pickup');

    await Future.delayed(const Duration(milliseconds: 2300));

    // Phase 2: Zoom to dropoff point (2-2.5 seconds)
    setState(() => _phase = 1);
    _mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.dropoffLat, widget.dropoffLng),
        16,
      ),
    );
    addDebugMessage('Phase 2: Zooming to dropoff');

    await Future.delayed(const Duration(milliseconds: 2300));

    // Phase 3: Show complete route with both points
    setState(() => _phase = 2);
    await _loadRoute();
    _fitBothPoints();
    addDebugMessage('Phase 3: Showing full route');
  }

  Future<void> _loadRoute() async {
    try {
      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
      );

      if (route != null && route.isSuccess && route.polylinePoints != null) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.primary,
              width: 5,
              geodesic: true,
            ),
          );
        });
      }
    } catch (e) {
      addDebugMessage('Route load error: $e');
    }
  }

  void _fitBothPoints() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.pickupLat < widget.dropoffLat ? widget.pickupLat - 0.01 : widget.dropoffLat - 0.01,
        widget.pickupLng < widget.dropoffLng ? widget.pickupLng - 0.01 : widget.dropoffLng - 0.01,
      ),
      northeast: LatLng(
        widget.pickupLat > widget.dropoffLat ? widget.pickupLat + 0.01 : widget.dropoffLat + 0.01,
        widget.pickupLng > widget.dropoffLng ? widget.pickupLng + 0.01 : widget.dropoffLng + 0.01,
      ),
    );
    _mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.moveCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(widget.pickupLat, widget.pickupLng),
        13,
      ),
    );
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Trip Preview'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Auto-closes in 6s',
                style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7)),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.pickupLat, widget.pickupLng),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pickupAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.dropoffAddress,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (widget.estimatedFare != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.attach_money, size: 16, color: AppColors.primary),
                        Text(
                          '\$${widget.estimatedFare!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Return to Offer', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _phase == 0 ? 'Showing pickup point...' :
                    _phase == 1 ? 'Showing dropoff point...' :
                    'Showing complete route',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
