import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../screens/debug_screen.dart';
import 'dart:math' as Math;

class RiderSearchingDriverScreen extends StatefulWidget {
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final String rideType;
  final double fare;
  final String token;
  final int userId;
  final String username;

  const RiderSearchingDriverScreen({
    Key? key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.rideType,
    required this.fare,
    required this.token,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  State<RiderSearchingDriverScreen> createState() =>
      _RiderSearchingDriverScreenState();
}

class _RiderSearchingDriverScreenState
    extends State<RiderSearchingDriverScreen>
    with TickerProviderStateMixin {
  late GoogleMapController mapController;
  Set<Marker> _markers = {};
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  Ride? _acceptedRide;
  bool _isSearching = true;
  int _searchDuration = 0;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🔍 SEARCHING FOR DRIVER');
    addDebugMessage('Ride Type: ${widget.rideType}');
    addDebugMessage('Fare: \$${widget.fare}');
    addDebugMessage('═══════════════════════════════════════');

    _initializeMap();

    // Pulse animation for pickup location
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Rotate animation for search indicator
    _rotateController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Simulate driver search (in real app, this would be WebSocket)
    _startSearching();

    // Update search duration every second
    _updateSearchDuration();
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
          title: 'Your Location',
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
          title: 'Destination',
          snippet: widget.dropoffLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );
  }

  void _updateSearchDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isSearching) {
        setState(() => _searchDuration++);
        _updateSearchDuration();
      }
    });
  }

void _startSearching() async {
  try {
    addDebugMessage('🚗 Requesting ride...');

    // ✅ NOW INCLUDES ALL 3 REQUIRED PARAMETERS
    final ride = await RideService.requestRide(
      pickupLat: widget.pickupLocation.latitude,
      pickupLng: widget.pickupLocation.longitude,
      pickupAddress: widget.pickupLocation.address,
      dropoffLat: widget.dropoffLocation.latitude,
      dropoffLng: widget.dropoffLocation.longitude,
      dropoffAddress: widget.dropoffLocation.address,
      rideType: widget.rideType,
      estimatedDistance: _calculateDistance(
        widget.pickupLocation.latitude,
        widget.pickupLocation.longitude,
        widget.dropoffLocation.latitude,
        widget.dropoffLocation.longitude,
      ),  // ✅ ADD THIS
      estimatedFare: widget.fare,  // ✅ ADD THIS (already have fare)
      estimatedDuration: _calculateDuration(widget.fare),  // ✅ ADD THIS
      token: widget.token,
    );

    if (ride != null) {
      addDebugMessage('✅ Ride created: ID ${ride.id}');
      setState(() {
        _acceptedRide = ride;
      });

      // Simulate driver acceptance after 3-5 seconds
      _simulateDriverAcceptance(ride.id!);
    } else {
      addDebugMessage('❌ Failed to create ride');
      if (mounted) {
        _showError('Failed to request ride. Please try again.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pop(context);
        });
      }
    }
  } catch (e) {
    addDebugMessage('❌ Error: $e');
    if (mounted) {
      _showError('Error requesting ride: $e');
    }
  }
}

/// Calculate distance using Haversine formula
double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
  const int R = 6371;
  final lat1Rad = _toRad(lat1);
  final lat2Rad = _toRad(lat2);
  final deltaLat = _toRad(lat2 - lat1);
  final deltaLng = _toRad(lng2 - lng1);
  
  final a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(lat1Rad) *
          Math.cos(lat2Rad) *
          Math.sin(deltaLng / 2) *
          Math.sin(deltaLng / 2);
  final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

double _toRad(double degree) => degree * (3.141592653589793 / 180);

/// Calculate estimated duration based on fare
int _calculateDuration(double fare) {
  // Rough estimation: $2.84 ≈ 12 minutes
  // fare = $2 + (distance * rate)
  // Assume avg rate of $0.20/km and avg speed of 30km/h
  return ((fare - 2.0) / 0.20 / 30 * 60).toInt().clamp(5, 60);
}

  void _simulateDriverAcceptance(int rideId) {
    // In a real app, this would listen to WebSocket for driver acceptance
    // For now, we simulate acceptance after 5-8 seconds
    final delaySeconds = 5 + (DateTime.now().millisecond % 4);

    Future.delayed(Duration(seconds: delaySeconds), () {
      if (mounted && _isSearching) {
        addDebugMessage('🎉 Driver found and accepted!');
        setState(() => _isSearching = false);

        // Show driver info briefly
        _showDriverAcceptedDialog();
      }
    });
  }

  void _showDriverAcceptedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Driver Accepted!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_acceptedRide?.driver != null) ...[
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF6366F1),
                    child: Text(
                      _acceptedRide!.driver!.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    _acceptedRide!.driver!.fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '4.8 ⭐ • ${_acceptedRide!.rideType}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vehicle',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Toyota Camry',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'License Plate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ABC 1234',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _cancelRide() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Ride?'),
        content: const Text(
          'Are you sure you want to cancel this ride request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSearching) {
          _cancelRide();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Map
            GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
                mapController.animateCamera(
                  CameraUpdate.newLatLng(
                    LatLng(
                      widget.pickupLocation.latitude,
                      widget.pickupLocation.longitude,
                    ),
                  ),
                );
              },
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.pickupLocation.latitude,
                  widget.pickupLocation.longitude,
                ),
                zoom: 14,
              ),
              markers: _markers,
              compassEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),

            // Top Bar with Back Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black26,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: _cancelRide,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Searching Animation Overlay
            if (_isSearching)
              Positioned(
                top: MediaQuery.of(context).size.height / 2 - 50,
                left: MediaQuery.of(context).size.width / 2 - 50,
                child: Column(
                  children: [
                    // Pulsing circle
                    ScaleTransition(
                      scale: Tween(begin: 0.5, end: 1.5).animate(
                        CurvedAnimation(
                          parent: _pulseController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6366F1)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                    ),

                    // Center icon
                    Positioned(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF6366F1),
                        ),
                        child: RotationTransition(
                          turns: _rotateController,
                          child: const Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Sheet
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

                        const SizedBox(height: 20),

                        if (_isSearching) ...[
                          // Searching Status
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                const Text(
                                  'Finding a driver...',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Searching for ${_searchDuration}s',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    _buildDot(0),
                                    const SizedBox(width: 8),
                                    _buildDot(1),
                                    const SizedBox(width: 8),
                                    _buildDot(2),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else if (_acceptedRide != null) ...[
                          // Driver Accepted
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green.withValues(alpha: 0.2),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Driver Accepted',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Trip Details
                        _buildTripDetail(
                          icon: Icons.location_on,
                          label: 'Pickup',
                          value: widget.pickupLocation.address,
                          color: Colors.green,
                        ),

                        const SizedBox(height: 16),

                        _buildTripDetail(
                          icon: Icons.location_on,
                          label: 'Dropoff',
                          value: widget.dropoffLocation.address,
                          color: Colors.red,
                        ),

                        const SizedBox(height: 24),

                        // Ride Details Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              _buildRideInfo(
                                icon: Icons.directions_car,
                                label: 'Ride Type',
                                value: widget.rideType,
                              ),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.grey[300],
                              ),
                              _buildRideInfo(
                                icon: Icons.attach_money,
                                label: 'Est. Fare',
                                value: '\$${widget.fare.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        if (_isSearching)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _cancelRide,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Colors.red,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Cancel Ride',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final value = (_pulseController.value * 3 - index).abs() % 1.0;
        return Transform.scale(
          scale: 0.5 + (1 - value) * 0.5,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.3 + (1 - value) * 0.7),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripDetail({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF6366F1), size: 24),
        const SizedBox(height: 8),
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
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }
}