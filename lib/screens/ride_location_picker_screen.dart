import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as Math;
import '../screens/debug_screen.dart';

class RideLocationPickerScreen extends StatefulWidget {
  const RideLocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<RideLocationPickerScreen> createState() => _RideLocationPickerScreenState();
}

class _RideLocationPickerScreenState extends State<RideLocationPickerScreen> {
  late GoogleMapController mapController;
  
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  int _step = 0; // 0 = pickup, 1 = dropoff
  double? _estimatedDistance;
  double? _estimatedFare;
  String _rideType = 'ECONOMY';
  bool _isLoadingRoute = false;
  
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropoffSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentLocation = LatLng(position.latitude, position.longitude);
      _pickupLocation = _currentLocation;
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _pickupAddress = '${place.street}, ${place.locality}';
        _pickupSearchController.text = _pickupAddress;
      }
      
      if (mounted) {
        setState(() {
          _updateMapMarkers();
        });
      }
      
      addDebugMessage('✅ Map initialized at: $_pickupAddress');
    } catch (e) {
      addDebugMessage('❌ Error initializing map: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_pickupLocation != null) {
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
      );
    }
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    if (_step == 0) {
      // Selecting pickup
      _pickupLocation = position.target;
      _updateMapMarkers();
      
      try {
        final placemarks = await placemarkFromCoordinates(
          position.target.latitude,
          position.target.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _pickupAddress = '${place.street}, ${place.locality}';
          if (mounted) {
            setState(() {
              _pickupSearchController.text = _pickupAddress;
            });
          }
        }
      } catch (e) {
        addDebugMessage('Error: $e');
      }
    } else if (_step == 1) {
      // Selecting dropoff
      _dropoffLocation = position.target;
      _updateMapMarkers();
      
      try {
        final placemarks = await placemarkFromCoordinates(
          position.target.latitude,
          position.target.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _dropoffAddress = '${place.street}, ${place.locality}';
          if (mounted) {
            setState(() {
              _dropoffSearchController.text = _dropoffAddress;
            });
          }
        }
      } catch (e) {
        addDebugMessage('Error: $e');
      }
    }
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();
    
    if (_step == 0) {
      // Show pickup selection
      if (_currentLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: _currentLocation!,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
    } else if (_step == 1) {
      // Show both pickup and dropoff
      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      if (_dropoffLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: _dropoffLocation!,
            infoWindow: const InfoWindow(title: 'Dropoff Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
      
      // Draw route if both locations selected
      if (_pickupLocation != null && _dropoffLocation != null) {
        _calculateRouteAndFare();
      }
    }
    
    setState(() {});
  }

  Future<void> _calculateRouteAndFare() async {
    if (_isLoadingRoute) return;
    
    setState(() => _isLoadingRoute = true);
    
    try {
      addDebugMessage('🔄 Calculating route...');
      
      // Calculate simple distance
      final distance = _calculateDistance(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _dropoffLocation!.latitude,
        _dropoffLocation!.longitude,
      );
      
      // Draw line between pickup and dropoff
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_pickupLocation!, _dropoffLocation!],
          color: const Color(0xFF6366F1),
          width: 5,
          geodesic: true,
        ),
      );
      
      // Calculate fare based on distance
      double ratePerKm = _rideType == 'ECONOMY' ? 0.20 : 0.35;
      double baseFare = 2.0;
      double fare = baseFare + (distance * ratePerKm);
      fare = (fare * 100).roundToDouble() / 100;
      
      if (mounted) {
        setState(() {
          _estimatedDistance = distance;
          _estimatedFare = fare;
        });
      }
      
      addDebugMessage('📏 Distance: ${distance.toStringAsFixed(2)} km');
      addDebugMessage('💰 Fare: \$$fare');
      
    } catch (e) {
      addDebugMessage('❌ Error calculating route: $e');
    } finally {
      setState(() => _isLoadingRoute = false);
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(_toRad(lat1)) * Math.cos(_toRad(lat2)) * 
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) => degree * (Math.pi / 180);

  void _confirmPickup() {
    if (_pickupLocation == null) {
      _showError('Please select a pickup location');
      return;
    }
    
    setState(() => _step = 1);
    addDebugMessage('✅ Pickup confirmed: $_pickupAddress');
  }

  void _backToPickup() {
    setState(() {
      _step = 0;
      _dropoffLocation = null;
      _dropoffSearchController.clear();
      _estimatedDistance = null;
      _estimatedFare = null;
      _updateMapMarkers();
    });
  }

  Future<void> _confirmDropoff() async {
    if (_dropoffLocation == null) {
      _showError('Please select a dropoff location');
      return;
    }
    
    if (_estimatedDistance == null || _estimatedFare == null) {
      _showError('Error calculating fare');
      return;
    }
    
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ RIDE DETAILS CONFIRMED');
    addDebugMessage('From: $_pickupAddress');
    addDebugMessage('To: $_dropoffAddress');
    addDebugMessage('Distance: ${_estimatedDistance?.toStringAsFixed(2)} km');
    addDebugMessage('Type: $_rideType');
    addDebugMessage('Fare: \$$_estimatedFare');
    addDebugMessage('═══════════════════════════════════════');
    
    // Return the ride details to the caller
    Navigator.pop(context, {
      'pickupLat': _pickupLocation!.latitude,
      'pickupLng': _pickupLocation!.longitude,
      'pickupAddress': _pickupAddress,
      'dropoffLat': _dropoffLocation!.latitude,
      'dropoffLng': _dropoffLocation!.longitude,
      'dropoffAddress': _dropoffAddress,
      'rideType': _rideType,
      'estimatedDistance': _estimatedDistance,
      'estimatedFare': _estimatedFare,
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Text(
          _step == 0 ? 'Select Pickup Location' : 'Select Dropoff Location',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ✅ FULL SCREEN MAP
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? const LatLng(37.4219983, -122.084),
              zoom: 17,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          // ✅ CENTER PIN
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 60,
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
          
          // ✅ TOP SEARCH CARD
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator
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
                        'Step ${_step + 1}/2',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Pickup field (always visible)
                    TextField(
                      controller: _pickupSearchController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Pickup Location',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Dropoff field (visible only in step 1)
                    if (_step == 1)
                      Column(
                        children: [
                          TextField(
                            controller: _dropoffSearchController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Dropoff Location',
                              prefixIcon: const Icon(Icons.location_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Ride type selection
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _rideType = 'ECONOMY'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _rideType == 'ECONOMY'
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Economy',
                                          style: TextStyle(
                                            color: _rideType == 'ECONOMY'
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '\$0.20/km',
                                          style: TextStyle(
                                            color: _rideType == 'ECONOMY'
                                                ? Colors.white
                                                : Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _rideType = 'LUXURY'),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _rideType == 'LUXURY'
                                          ? const Color(0xFF6366F1)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Luxury',
                                          style: TextStyle(
                                            color: _rideType == 'LUXURY'
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '\$0.35/km',
                                          style: TextStyle(
                                            color: _rideType == 'LUXURY'
                                                ? Colors.white
                                                : Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Fare estimate
                          if (_estimatedDistance != null && _estimatedFare != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distance',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '${_estimatedDistance?.toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Estimated Fare',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      Text(
                                        '\$${_estimatedFare?.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ BOTTOM BUTTONS
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                if (_step == 1)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _backToPickup,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                if (_step == 1)
                  const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _step == 0 ? _confirmPickup : _confirmDropoff,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _step == 0 ? 'Confirm Pickup' : 'Request Ride',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
    _pickupSearchController.dispose();
    _dropoffSearchController.dispose();
    mapController.dispose();
    super.dispose();
  }
}