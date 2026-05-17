import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../screens/debug_screen.dart';

class RiderConfirmationScreen extends StatefulWidget {
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final Function(String rideType) onConfirmRide;

  const RiderConfirmationScreen({
    Key? key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.onConfirmRide,
  }) : super(key: key);

  @override
  State<RiderConfirmationScreen> createState() =>
      _RiderConfirmationScreenState();
}

class _RiderConfirmationScreenState extends State<RiderConfirmationScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  String _selectedRideType = 'Economy';
  double _distance = 0.0;
  Map<String, double> _fares = {};
  bool _mapCreated = false;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ CONFIRMATION SCREEN LOADED');
    addDebugMessage('Pickup: ${widget.pickupLocation.address}');
    addDebugMessage('Dropoff: ${widget.dropoffLocation.address}');
    addDebugMessage('═══════════════════════════════════════');

    _calculateDistance();
    _calculateFares();
    _initializeMap();
  }

  void _calculateDistance() {
    try {
      _distance = LocationService.calculateDistance(
        widget.pickupLocation.latitude,
        widget.pickupLocation.longitude,
        widget.dropoffLocation.latitude,
        widget.dropoffLocation.longitude,
      );

      addDebugMessage('📏 Distance calculated: ${_distance.toStringAsFixed(2)} km');
    } catch (e) {
      addDebugMessage('❌ Error calculating distance: $e');
      _distance = 0.0;
    }
  }

  void _calculateFares() {
    try {
      setState(() {
        _fares = {};
        for (var rideType in rideTypes) {
          final fare =
              LocationService.calculateFare(_distance, rideType);
          _fares[rideType.name] = fare;

          addDebugMessage(
              '💵 ${rideType.name}: \$${fare.toStringAsFixed(2)}');
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error calculating fares: $e');
    }
  }

  void _initializeMap() {
    // Pickup marker (GREEN)
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.pickupLocation.latitude,
          widget.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.pickupLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    );

    // Dropoff marker (RED)
    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.dropoffLocation.latitude,
          widget.dropoffLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: widget.dropoffLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );

    // Polyline between pickup and dropoff
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            widget.pickupLocation.latitude,
            widget.pickupLocation.longitude,
          ),
          LatLng(
            widget.dropoffLocation.latitude,
            widget.dropoffLocation.longitude,
          ),
        ],
        color: const Color(0xFF6366F1),
        width: 5,
        geodesic: true,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    setState(() => _mapCreated = true);
    _fitBounds();
  }

  void _fitBounds() {
    final double minLat = widget.pickupLocation.latitude <
            widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;

    final double maxLat = widget.pickupLocation.latitude >
            widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;

    final double minLng = widget.pickupLocation.longitude <
            widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final double maxLng = widget.pickupLocation.longitude >
            widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  void _confirmRide() {
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🎉 RIDE CONFIRMED');
    addDebugMessage('Ride Type: $_selectedRideType');
    addDebugMessage('Fare: \$${_fares[_selectedRideType]}');
    addDebugMessage('Distance: ${_distance.toStringAsFixed(2)} km');
    addDebugMessage('═══════════════════════════════════════');

    widget.onConfirmRide(_selectedRideType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm Your Ride',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.pickupLocation.latitude,
                widget.pickupLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Bottom Sheet with Options
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
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
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

                      // Trip Summary
                      _buildTripSummary(),

                      const SizedBox(height: 24),

                      // Ride Type Selection
                      const Text(
                        'Select Ride Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...rideTypes.map((rideType) {
                        final fare = _fares[rideType.name] ?? 0.0;
                        final isSelected = _selectedRideType == rideType.name;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRideTypeCard(
                            rideType: rideType,
                            fare: fare,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _selectedRideType = rideType.name);
                              addDebugMessage(
                                  '✅ Selected: ${rideType.name}');
                            },
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 24),

                      // Confirm Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _confirmRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Confirm ${_selectedRideType} - \$${_fares[_selectedRideType]?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info Text
                      Center(
                        child: Text(
                          'You will be matched with a nearby driver',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pickup
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pickupLocation.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

          // Divider with dashed line
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              height: 24,
              width: 1,
              color: Colors.grey[300],
            ),
          ),

          const SizedBox(height: 16),

          // Dropoff
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dropoff',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dropoffLocation.address,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
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

          // Distance and Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryMetric(
                icon: Icons.straighten,
                label: 'Distance',
                value: '${_distance.toStringAsFixed(1)} km',
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildSummaryMetric(
                icon: Icons.access_time,
                label: 'Est. Time',
                value: '${(_distance * 1.5).toStringAsFixed(0)} min',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeCard({
    required RideType rideType,
    required double fare,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withValues(alpha: 0.1)
              : Colors.grey[50],
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: Center(
                child: Text(
                  rideType.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rideType.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    rideType.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Selected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            // Checkmark
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  Icons.check_circle,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}