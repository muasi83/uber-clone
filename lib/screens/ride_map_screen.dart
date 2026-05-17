import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import 'dart:math' as Math;

class RideMapScreen extends StatefulWidget {
  final bool isDriver;

  const RideMapScreen({
    Key? key,
    this.isDriver = false,
  }) : super(key: key);

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  late GoogleMapController mapController;
  
  // Location data
  LatLng? pickupLocation;
  LatLng? dropoffLocation;
  LatLng? currentLocation;
  String? pickupAddress;
  String? dropoffAddress;
  
  // UI State
  int step = 1; // 1 = Select Pickup, 2 = Select Dropoff
  late Set<Marker> markers = {};
  late Set<Polyline> polylines = {};
  
  bool isLoading = true;
  String rideType = 'ECONOMY';
  double? estimatedDistance;
  double? estimatedFare;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📍 GETTING CURRENT LOCATION');
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      currentLocation = LatLng(position.latitude, position.longitude);
      pickupLocation = currentLocation;
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        pickupAddress = '${place.street}, ${place.locality}';
        addDebugMessage('✅ Address: $pickupAddress');
      }
      
      if (mounted) {
        setState(() => isLoading = false);
        _updateMapMarkers();
      }
      
      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Error getting location: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (pickupLocation != null) {
      _animateToLocation(pickupLocation!);
    }
  }

  void _animateToLocation(LatLng location) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(location, 17),
    );
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    LatLng newLocation = position.target;
    
    if (step == 1) {
      setState(() => pickupLocation = newLocation);
    } else if (step == 2) {
      setState(() => dropoffLocation = newLocation);
    }
    
    _updateMapMarkers();
  }

  void _updateMapMarkers() {
    markers.clear();
    polylines.clear();
    
    if (step == 1) {
      if (currentLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      if (pickupLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location (Moving)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    } else if (step == 2) {
      if (pickupLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location (Fixed)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      if (dropoffLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoffLocation!,
            infoWindow: const InfoWindow(title: 'Dropoff Location (Moving)'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
      
      if (pickupLocation != null && dropoffLocation != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [pickupLocation!, dropoffLocation!],
            color: const Color(0xFF6366F1),
            width: 5,
          ),
        );
        
        _calculateDistanceAndFare();
      }
    }
    
    setState(() {});
  }

  void _calculateDistanceAndFare() {
    if (pickupLocation == null || dropoffLocation == null) return;
    
    const int R = 6371;
    final lat1Rad = _toRad(pickupLocation!.latitude);
    final lat2Rad = _toRad(dropoffLocation!.latitude);
    final deltaLat = _toRad(dropoffLocation!.latitude - pickupLocation!.latitude);
    final deltaLng = _toRad(dropoffLocation!.longitude - pickupLocation!.longitude);
    
    final a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
        Math.cos(lat1Rad) *
            Math.cos(lat2Rad) *
            Math.sin(deltaLng / 2) *
            Math.sin(deltaLng / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    final distance = R * c;
    
    double ratePerKm = rideType == 'ECONOMY' ? 0.20 : 0.35;
    double fare = (distance * ratePerKm * 100).roundToDouble() / 100;
    
    setState(() {
      estimatedDistance = distance;
      estimatedFare = fare;
    });
    
    addDebugMessage('📏 Distance: ${distance.toStringAsFixed(2)} km');
    addDebugMessage('💰 Fare: \$$fare');
  }

  double _toRad(double degree) => degree * (3.141592653589793 / 180);

  Future<void> _confirmPickup() async {
    if (pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a pickup location')),
      );
      return;
    }
    
    try {
      final placemarks = await placemarkFromCoordinates(
        pickupLocation!.latitude,
        pickupLocation!.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        pickupAddress = '${place.street}, ${place.locality}';
      }
    } catch (e) {
      pickupAddress = 'Unknown Location';
    }
    
    setState(() => step = 2);
    _updateMapMarkers();
    _animateToLocation(pickupLocation!);
    
    addDebugMessage('✅ Pickup location confirmed: $pickupAddress');
  }

  Future<void> _confirmDropoff() async {
    if (dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a dropoff location')),
      );
      return;
    }
    
    try {
      final placemarks = await placemarkFromCoordinates(
        dropoffLocation!.latitude,
        dropoffLocation!.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        dropoffAddress = '${place.street}, ${place.locality}';
      }
    } catch (e) {
      dropoffAddress = 'Unknown Location';
    }
    
    addDebugMessage('✅ Dropoff location confirmed: $dropoffAddress');
    addDebugMessage('📏 Distance: ${estimatedDistance?.toStringAsFixed(2)} km');
    addDebugMessage('💰 Total Fare: \$$estimatedFare');
    
    await _requestRide();
  }
Future<void> _requestRide() async {
  if (pickupLocation == null || dropoffLocation == null || pickupAddress == null || dropoffAddress == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid locations')),
    );
    return;
  }
  
  setState(() => isLoading = true);
  
  try {
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🚗 REQUESTING RIDE');
    addDebugMessage('From: $pickupAddress');
    addDebugMessage('To: $dropoffAddress');
    addDebugMessage('Type: $rideType');
    addDebugMessage('Distance: ${estimatedDistance?.toStringAsFixed(2)} km');
    addDebugMessage('Fare: \$${estimatedFare?.toStringAsFixed(2)}');
    
    final token = StorageService.getToken();
    
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token not found')),
      );
      return;
    }
    
    // ✅ NOW INCLUDES ALL 3 REQUIRED PARAMETERS
    final ride = await RideService.requestRide(
      pickupLat: pickupLocation!.latitude,
      pickupLng: pickupLocation!.longitude,
      pickupAddress: pickupAddress!,
      dropoffLat: dropoffLocation!.latitude,
      dropoffLng: dropoffLocation!.longitude,
      dropoffAddress: dropoffAddress!,
      rideType: rideType,
      estimatedDistance: estimatedDistance ?? 0.0,      // ✅ ADD THIS
      estimatedFare: estimatedFare ?? 0.0,              // ✅ ADD THIS
      estimatedDuration: _calculateDuration(estimatedDistance ?? 0.0),  // ✅ ADD THIS
      token: token,
    );
    
    if (ride != null) {
      addDebugMessage('✅ Ride request successful!');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride requested! Waiting for driver...'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context, ride);
      }
    }
  } catch (e) {
    addDebugMessage('❌ Error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

/// Calculate estimated duration based on distance
int _calculateDuration(double distanceKm) {
  // Assume average speed of 30 km/h
  return ((distanceKm / 30) * 60).toInt();
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        title: Text(
          step == 1 ? 'Select Pickup Location' : 'Select Dropoff Location',
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: pickupLocation ?? const LatLng(37.4219983, -122.084),
                    zoom: 17,
                  ),
                  markers: markers,
                  polylines: polylines,
                  compassEnabled: true,
                  zoomControlsEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                
                if (step == 1)
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  )
                else
                  const Align(
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.location_on,
                      color: Colors.blue,
                      size: 40,
                    ),
                  ),
                
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Step $step/2',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          if (step == 1)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Move map to select pickup location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (pickupAddress != null)
                                  Text(
                                    pickupAddress!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Move map to select dropoff location',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (dropoffAddress != null)
                                  Text(
                                    dropoffAddress!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => rideType = 'ECONOMY'),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: rideType == 'ECONOMY'
                                                ? const Color(0xFF6366F1)
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Economy\n\$0.20/km',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: rideType == 'ECONOMY'
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => setState(() => rideType = 'LUXURY'),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: rideType == 'LUXURY'
                                                ? const Color(0xFF6366F1)
                                                : Colors.grey[200],
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Luxury\n\$0.35/km',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: rideType == 'LUXURY'
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                if (estimatedDistance != null && estimatedFare != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${estimatedDistance?.toStringAsFixed(2)} km',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '\$${estimatedFare?.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (step == 2)
                                OutlinedButton(
                                  onPressed: () => setState(() => step = 1),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  child: const Text('Back'),
                                ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: step == 1
                                      ? _confirmPickup
                                      : _confirmDropoff,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    step == 1
                                        ? 'Confirm Pickup'
                                        : 'Confirm & Request Ride',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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