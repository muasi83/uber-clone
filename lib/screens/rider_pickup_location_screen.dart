import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:math' as Math;
import '../services/directions_service.dart';
import '../screens/debug_screen.dart';

class RideLocationPickerScreen extends StatefulWidget {
  const RideLocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<RideLocationPickerScreen> createState() => _RideLocationPickerScreenState();
}

class _RideLocationPickerScreenState extends State<RideLocationPickerScreen> {
  late GoogleMapController mapController;
  
  // Location data
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  
  // Map rendering
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Step state
  int _step = 0; // 0 = pickup, 1 = dropoff
  
  // Ride data
  double? _estimatedDistance;
  double? _estimatedFare;
  String _rideType = 'ECONOMY';
  int? _estimatedDuration;
  
  // Loading states
  bool _isLoadingPickupAddress = false;
  bool _isLoadingDropoffAddress = false;
  bool _isLoadingRoute = false;
  bool _isInitializingMap = true;
  String _initializationError = '';
  
  final TextEditingController _pickupSearchController = TextEditingController();
  final TextEditingController _dropoffSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  /// Initialize map with current location and check permissions
/// Initialize map with current location and check permissions
Future<void> _initializeMap() async {
  try {
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('📍 INITIALIZING MAP');
    addDebugMessage('🔑 Checking Google Maps API Key...');
    
    // ✅ CHECK LOCATION PERMISSION
    addDebugMessage('📍 Checking location permission...');
    LocationPermission permission = await Geolocator.checkPermission();
    addDebugMessage('Current permission status: $permission');
    
    if (permission == LocationPermission.denied) {
      addDebugMessage('⚠️ Permission denied - requesting from user...');
      permission = await Geolocator.requestPermission();
      addDebugMessage('Permission after request: $permission');
      
      if (permission == LocationPermission.denied) {
        addDebugMessage('❌ User denied location permission');
        setState(() {
          _isInitializingMap = false;
          _initializationError = 'Location permission required';
        });
        _showError('Location permission is required to use the map');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      addDebugMessage('❌ Location permission denied forever');
      setState(() {
        _isInitializingMap = false;
        _initializationError = 'Location permission denied forever';
      });
      _showError('Please enable location in app settings');
      return;
    }
    
    addDebugMessage('✅ Location permission granted');
    
    // ✅ GET CURRENT POSITION
    addDebugMessage('📍 Getting current position...');
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        addDebugMessage('⚠️ Location request timeout after 15 seconds');
        throw TimeoutException('Location timeout');
      },
    );
    
    addDebugMessage('✅ Position received:');
    addDebugMessage('   Latitude: ${position.latitude}');
    addDebugMessage('   Longitude: ${position.longitude}');
    addDebugMessage('   Accuracy: ${position.accuracy} meters');
    
    _currentLocation = LatLng(position.latitude, position.longitude);
    _pickupLocation = _currentLocation;
    
    // ✅ GET ADDRESS FOR CURRENT LOCATION
    addDebugMessage('📍 Getting address via reverse geocoding...');
    String? addressFromGeocoding;
    
    try {
      // ✅ HANDLE NULL GRACEFULLY
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          addDebugMessage('⚠️ Geocoding timeout');
          return []; // Return empty list instead of throwing
        },
      );
      
      if (placemarks != null && placemarks.isNotEmpty) {
        final place = placemarks.first;
        addressFromGeocoding = '${place.street ?? 'Unknown'}, ${place.locality ?? 'Unknown'}';
        addDebugMessage('✅ Address from geocoding: $addressFromGeocoding');
      } else {
        addDebugMessage('⚠️ No placemarks found from geocoding');
      }
    } catch (e) {
      addDebugMessage('⚠️ Reverse geocoding error: $e');
    }
    
    // ✅ USE GEOCODED ADDRESS OR FALL BACK TO COORDINATES
    _pickupAddress = addressFromGeocoding ?? 
        'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
    
    _pickupSearchController.text = _pickupAddress;
    addDebugMessage('📍 Final address: $_pickupAddress');
    
    if (mounted) {
      setState(() {
        _isInitializingMap = false;
        _updateMapMarkers();
      });
    }
    
    addDebugMessage('✅ Map initialization complete');
    addDebugMessage('═══════════════════════════════════════');
  } on TimeoutException catch (e) {
    addDebugMessage('❌ TIMEOUT ERROR: $e');
    if (mounted) {
      setState(() {
        _isInitializingMap = false;
        _initializationError = 'Location request timeout. Please check location permissions.';
      });
    }
    _showError('Failed to get location (timeout). Please try again.');
  } catch (e) {
    addDebugMessage('❌ ERROR INITIALIZING MAP: $e');
    addDebugMessage('Stack trace: $e');
    if (mounted) {
      setState(() {
        _isInitializingMap = false;
        _initializationError = 'Error: ${e.toString()}';
      });
    }
    _showError('Failed to initialize map: $e');
  }
}
  /// Called when map is created
  void _onMapCreated(GoogleMapController controller) {
    addDebugMessage('🗺️ GoogleMap widget created');
    mapController = controller;
    
    if (_pickupLocation != null) {
      addDebugMessage('📍 Animating camera to pickup location');
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
      );
    }
  }

  /// Called when camera moves (user drags map)
/// Called when camera moves (user drags map)
Future<void> _onCameraMove(CameraPosition position) async {
  if (_step == 0) {
    // ===== STEP 1: SELECTING PICKUP =====
    _pickupLocation = position.target;
    _updateMapMarkers();
    
    // Start loading address
    setState(() => _isLoadingPickupAddress = true);
    
    try {
      final placemarks = await placemarkFromCoordinates(
        position.target.latitude,
        position.target.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [], // Return empty list on timeout
      );
      
      if (placemarks != null && placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street ?? 'Unknown'}, ${place.locality ?? 'Unknown'}';
        
        if (mounted) {
          setState(() {
            _pickupAddress = address;
            _pickupSearchController.text = address;
            _isLoadingPickupAddress = false;
          });
        }
        
        addDebugMessage('📍 Pickup address updated: $address');
      } else {
        // Fallback to coordinates
        final fallbackAddress = 'Lat: ${position.target.latitude.toStringAsFixed(4)}, Lng: ${position.target.longitude.toStringAsFixed(4)}';
        if (mounted) {
          setState(() {
            _pickupAddress = fallbackAddress;
            _pickupSearchController.text = fallbackAddress;
            _isLoadingPickupAddress = false;
          });
        }
        addDebugMessage('⚠️ Using fallback address: $fallbackAddress');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPickupAddress = false);
      }
      addDebugMessage('⚠️ Address lookup failed: $e');
    }
    
  } else if (_step == 1) {
    // ===== STEP 2: SELECTING DROPOFF =====
    _dropoffLocation = position.target;
    _updateMapMarkers();
    
    // Start loading address
    setState(() => _isLoadingDropoffAddress = true);
    
    try {
      final placemarks = await placemarkFromCoordinates(
        position.target.latitude,
        position.target.longitude,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => [], // Return empty list on timeout
      );
      
      if (placemarks != null && placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = '${place.street ?? 'Unknown'}, ${place.locality ?? 'Unknown'}';
        
        if (mounted) {
          setState(() {
            _dropoffAddress = address;
            _dropoffSearchController.text = address;
            _isLoadingDropoffAddress = false;
          });
        }
        
        addDebugMessage('📍 Dropoff address updated: $address');
        
        // Calculate route immediately after address loads
        if (_dropoffLocation != null && !_isLoadingRoute) {
          await _calculateRealRoute();
        }
      } else {
        // Fallback to coordinates
        final fallbackAddress = 'Lat: ${position.target.latitude.toStringAsFixed(4)}, Lng: ${position.target.longitude.toStringAsFixed(4)}';
        if (mounted) {
          setState(() {
            _dropoffAddress = fallbackAddress;
            _dropoffSearchController.text = fallbackAddress;
            _isLoadingDropoffAddress = false;
          });
        }
        addDebugMessage('⚠️ Using fallback address: $fallbackAddress');
        
        // Still calculate route even with coordinates
        if (_dropoffLocation != null && !_isLoadingRoute) {
          await _calculateRealRoute();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDropoffAddress = false);
      }
      addDebugMessage('⚠️ Address lookup failed: $e');
    }
  }
}
  /// Update markers and polylines on map
  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();
    
    if (_step == 0) {
      // ===== STEP 1: SHOW PICKUP SELECTION =====
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
      // ===== STEP 2: SHOW PICKUP + DROPOFF =====
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
    }
    
    setState(() {});
  }

  /// ✅ CALCULATE REAL ROUTE USING GOOGLE DIRECTIONS API
  Future<void> _calculateRealRoute() async {
    if (_pickupLocation == null || _dropoffLocation == null) {
      addDebugMessage('⚠️ Missing locations for route calculation');
      return;
    }
    
    if (_isLoadingRoute) {
      addDebugMessage('⏳ Route calculation already in progress');
      return;
    }
    
    setState(() => _isLoadingRoute = true);
    
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('🔄 CALLING GOOGLE DIRECTIONS API');
      addDebugMessage('From: ${_pickupLocation!.latitude}, ${_pickupLocation!.longitude}');
      addDebugMessage('To: ${_dropoffLocation!.latitude}, ${_dropoffLocation!.longitude}');
      
      // Call Google Directions API
      final result = await DirectionsService.getDirections(
        origin: _pickupLocation!,
        destination: _dropoffLocation!,
      );

      if (!mounted) return;

      if (result == null || !result.isSuccess) {
        addDebugMessage('❌ Route calculation failed');
        setState(() => _isLoadingRoute = false);
        _showError('Could not calculate route. Please try again.');
        return;
      }

      // Extract data
      final double distanceKm = result.distanceKm!;
      final int durationMin = result.durationMinutes!;
      final List<LatLng> polylinePoints = result.polylinePoints!;

      // Calculate fare based on REAL distance
      final double fare = DirectionsService.calculateFare(
        distanceKm,
        _rideType,
      );

      // Draw polyline on map
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: const Color(0xFF6366F1),
          width: 5,
          geodesic: true,
        ),
      );

      if (mounted) {
        setState(() {
          _estimatedDistance = distanceKm;
          _estimatedFare = fare;
          _estimatedDuration = durationMin;
          _isLoadingRoute = false;
        });
      }

      addDebugMessage('✅ Route calculated successfully');
      addDebugMessage('Distance: ${distanceKm.toStringAsFixed(2)} km');
      addDebugMessage('Duration: $durationMin min');
      addDebugMessage('Fare: \$${fare.toStringAsFixed(2)}');
      addDebugMessage('Polyline points: ${polylinePoints.length}');
      addDebugMessage('═══════════════════════════════════════');

    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
      addDebugMessage('❌ Route calculation error: $e');
    }
  }

  /// Confirm pickup location and move to step 2
  void _confirmPickup() {
    if (_pickupLocation == null || _pickupAddress.isEmpty) {
      _showError('Please select a pickup location');
      return;
    }
    
    addDebugMessage('✅ Pickup confirmed: $_pickupAddress');
    
    setState(() {
      _step = 1;
      _estimatedDistance = null;
      _estimatedFare = null;
      _estimatedDuration = null;
      _dropoffLocation = null;
      _dropoffSearchController.clear();
      _updateMapMarkers();
    });
  }

  /// Go back from step 2 to step 1
  void _backToPickup() {
    addDebugMessage('⬅️ Going back to pickup selection');
    
    setState(() {
      _step = 0;
      _dropoffLocation = null;
      _dropoffSearchController.clear();
      _estimatedDistance = null;
      _estimatedFare = null;
      _estimatedDuration = null;
      _isLoadingRoute = false;
      _updateMapMarkers();
    });
  }

  /// Confirm dropoff and request ride
/// Confirm dropoff and request ride
Future<void> _confirmDropoff() async {
  if (_dropoffLocation == null || _dropoffAddress.isEmpty) {
    _showError('Please select a dropoff location');
    return;
  }
  
  if (_estimatedDistance == null || _estimatedFare == null) {
    _showError('Please wait for route calculation to complete');
    return;
  }
  
  // ✅ CALCULATE DURATION IF NOT ALREADY SET
  final duration = _estimatedDuration ?? _calculateDuration(_estimatedDistance!);
  
  addDebugMessage('═══════════════════════════════════════');
  addDebugMessage('✅ RIDE CONFIRMED BY RIDER');
  addDebugMessage('From: $_pickupAddress');
  addDebugMessage('To: $_dropoffAddress');
  addDebugMessage('Distance: ${_estimatedDistance?.toStringAsFixed(2)} km (ACTUAL)');
  addDebugMessage('Duration: $duration min');
  addDebugMessage('Type: $_rideType');
  addDebugMessage('Fare: \$${_estimatedFare?.toStringAsFixed(2)} (BASED ON REAL ROUTE)');
  addDebugMessage('═══════════════════════════════════════');
  
  // Return ride details to caller
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
    'estimatedDuration': duration,  // ✅ USE CALCULATED DURATION
  });
}

/// Calculate duration based on distance
int _calculateDuration(double distanceKm) {
  // Assume average speed of 30 km/h
  final minutes = ((distanceKm / 30) * 60).toInt();
  return minutes < 1 ? 1 : minutes; // Minimum 1 minute
}
  /// Handle ride type change and recalculate fare
  Future<void> _onRideTypeChanged(String newType) async {
    setState(() => _rideType = newType);
    
    // Recalculate fare with new ride type
    if (_estimatedDistance != null) {
      final newFare = DirectionsService.calculateFare(
        _estimatedDistance!,
        _rideType,
      );
      
      setState(() => _estimatedFare = newFare);
      
      addDebugMessage('💱 Ride type changed to: $newType');
      addDebugMessage('New fare: \$${newFare.toStringAsFixed(2)}');
    }
  }

  /// Show error message
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        title: Text(
          _step == 0 ? 'Select Pickup Location' : 'Select Dropoff Location',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitializingMap
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Initializing map...',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Getting your location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : _initializationError.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Failed to Initialize Map',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _initializationError,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isInitializingMap = true;
                            _initializationError = '';
                          });
                          _initializeMap();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // ===== FULL SCREEN MAP =====
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
                    
                    // ===== CENTER PIN =====
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                    
                    // ===== TOP CARD WITH LOCATION DETAILS =====
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
                              // Step Indicator
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
                              
                              // ===== STEP 1: PICKUP SELECTION =====
                              if (_step == 0) ...[
                                TextField(
                                  controller: _pickupSearchController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Pickup Location',
                                    prefixIcon: const Icon(Icons.location_on_outlined),
                                    suffixIcon: _isLoadingPickupAddress
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                              ]
                              
                              // ===== STEP 2: DROPOFF SELECTION =====
                              else ...[
                                // Pickup address (locked)
                                TextField(
                                  controller: _pickupSearchController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'From (Pickup)',
                                    prefixIcon: const Icon(Icons.location_on_outlined,
                                        color: Colors.green),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Dropoff address
                                TextField(
                                  controller: _dropoffSearchController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'To (Dropoff)',
                                    prefixIcon: const Icon(Icons.location_on,
                                        color: Colors.red),
                                    suffixIcon: _isLoadingDropoffAddress
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Padding(
                                              padding: EdgeInsets.all(10),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Route calculation indicator
                                if (_isLoadingRoute)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue),
                                    ),
                                    child: Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          '🔄 Calculating route...',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                
                                // Distance and fare display
                                else if (_estimatedDistance != null && _estimatedFare != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF6366F1),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
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
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Duration',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  '$_estimatedDuration min',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Fare',
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
                                        const SizedBox(height: 12),
                                        // Ride type selection
                                        Row(
                                          children: [
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _onRideTypeChanged('ECONOMY'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _rideType == 'ECONOMY'
                                                        ? const Color(0xFF6366F1)
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(8),
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
                                                onTap: () =>
                                                    _onRideTypeChanged('LUXURY'),
                                                child: Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _rideType == 'LUXURY'
                                                        ? const Color(0xFF6366F1)
                                                        : Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(8),
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
                                      ],
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    // ===== BOTTOM ACTION BUTTONS =====
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Back button (step 2 only)
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
                          if (_step == 1) const SizedBox(width: 12),
                          
                          // Confirm button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _step == 0
                                  ? _confirmPickup
                                  : (_isLoadingRoute ||
                                          _estimatedDistance == null ||
                                          _estimatedFare == null)
                                      ? null
                                      : _confirmDropoff,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                _step == 0
                                    ? 'Confirm Pickup'
                                    : _isLoadingRoute
                                        ? 'Calculating...'
                                        : 'Request Ride',
                                style: TextStyle(
                                  color: _step == 0 ||
                                          (!_isLoadingRoute &&
                                              _estimatedDistance != null &&
                                              _estimatedFare != null)
                                      ? Colors.white
                                      : Colors.grey,
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