import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import '../services/directions_service.dart';
import '../screens/debug_screen.dart';

class RideLocationPickerScreen extends StatefulWidget {
  const RideLocationPickerScreen({Key? key}) : super(key: key);

  @override
  State<RideLocationPickerScreen> createState() =>
      _RideLocationPickerScreenState();
}

class _RideLocationPickerScreenState extends State<RideLocationPickerScreen>
    with TickerProviderStateMixin {
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

  // Step state (0 = pickup, 1 = dropoff)
  int _step = 0;

  // Ride data
  double? _estimatedDistance;
  double? _estimatedFare;
  String _rideType = 'ECONOMY';
  int? _estimatedDuration;

  // Loading states
  bool _isLoadingAddress = false;
  bool _isLoadingRoute = false;
  bool _isInitializingMap = true;
  String _initializationError = '';

  // Animation controller
  late AnimationController _bottomSheetAnimationController;
  late Animation<Offset> _bottomSheetAnimation;

  // Debounce timer for address lookup
  Timer? _addressLookupTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeMap();
  }

  void _setupAnimations() {
    _bottomSheetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _bottomSheetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bottomSheetAnimationController,
      curve: Curves.easeOut,
    ));

    _bottomSheetAnimationController.forward();
  }

  Future<void> _initializeMap() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📍 INITIALIZING LOCATION PICKER MAP');

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isInitializingMap = false;
          _initializationError = 'Location permission required';
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      _currentLocation = LatLng(position.latitude, position.longitude);
      _pickupLocation = _currentLocation;

      // Get address
      String? addressFromGeocoding;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 8), onTimeout: () => []);

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          addressFromGeocoding =
              '${place.street ?? ''}, ${place.locality ?? ''}'
                  .replaceAll(RegExp(r',\s*$'), '');
        }
      } catch (e) {
        addDebugMessage('⚠️ Geocoding error: $e');
      }

      _pickupAddress = addressFromGeocoding ??
          'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';

      addDebugMessage('✅ Map initialized at: $_pickupAddress');
      addDebugMessage('═══════════════════════════════════════');

      if (mounted) {
        setState(() {
          _isInitializingMap = false;
          _updateMapMarkers();
        });
      }
    } catch (e) {
      addDebugMessage('❌ INIT ERROR: $e');
      if (mounted) {
        setState(() {
          _isInitializingMap = false;
          _initializationError = 'Failed to initialize map: $e';
        });
      }
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

  Future<void> _onCameraIdle() async {
    final position = await mapController.getVisibleRegion();
    final center = LatLng(
      (position.northeast.latitude + position.southwest.latitude) / 2,
      (position.northeast.longitude + position.southwest.longitude) / 2,
    );

    if (_step == 0) {
      _pickupLocation = center;
      _updateMapMarkers();
      _lookupAddress(center, isPickup: true);
    } else {
      _dropoffLocation = center;
      _updateMapMarkers();
      _lookupAddress(center, isPickup: false);
    }
  }

  Future<void> _lookupAddress(LatLng location, {required bool isPickup}) async {
    // Cancel previous timer
    _addressLookupTimer?.cancel();

    // Debounce address lookup
    _addressLookupTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      setState(() => _isLoadingAddress = true);

      try {
        final placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        ).timeout(const Duration(seconds: 5), onTimeout: () => []);

        if (!mounted) return;

        String address;
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = '${place.street ?? ''}, ${place.locality ?? ''}'
              .replaceAll(RegExp(r',\s*$'), '');
        } else {
          address = 'Lat: ${location.latitude.toStringAsFixed(4)}, '
              'Lng: ${location.longitude.toStringAsFixed(4)}';
        }

        setState(() {
          if (isPickup) {
            _pickupAddress = address;
          } else {
            _dropoffAddress = address;

            // Auto-calculate route when dropoff address is ready
            if (_dropoffLocation != null && !_isLoadingRoute) {
              _calculateRoute();
            }
          }
          _isLoadingAddress = false;
        });

        addDebugMessage(
            '📍 ${isPickup ? 'Pickup' : 'Dropoff'} address: $address');
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingAddress = false);
        }
        addDebugMessage('⚠️ Address lookup error: $e');
      }
    });
  }

  Future<void> _calculateRoute() async {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    if (_isLoadingRoute) return;

    setState(() => _isLoadingRoute = true);

    try {
      addDebugMessage('🔄 Calculating route...');

      final result = await DirectionsService.getDirections(
        origin: _pickupLocation!,
        destination: _dropoffLocation!,
      );

      if (!mounted) return;

      if (result == null || !result.isSuccess) {
        setState(() => _isLoadingRoute = false);
        _showError('Could not calculate route');
        return;
      }

      final distanceKm = result.distanceKm!;
      final durationMin = result.durationMinutes!;
      final polylinePoints = result.polylinePoints!;

      final fare =
          DirectionsService.calculateFare(distanceKm, _rideType);

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

      setState(() {
        _estimatedDistance = distanceKm;
        _estimatedFare = fare;
        _estimatedDuration = durationMin;
        _isLoadingRoute = false;
      });

      // Animate to show both points
      _fitBoundsBetweenLocations();

      addDebugMessage('✅ Route calculated: ${distanceKm.toStringAsFixed(2)} km');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
      addDebugMessage('❌ Route calculation error: $e');
    }
  }

  void _fitBoundsBetweenLocations() {
    if (_pickupLocation == null || _dropoffLocation == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        (_pickupLocation!.latitude < _dropoffLocation!.latitude
                ? _pickupLocation!.latitude
                : _dropoffLocation!.latitude) -
            0.01,
        (_pickupLocation!.longitude < _dropoffLocation!.longitude
                ? _pickupLocation!.longitude
                : _dropoffLocation!.longitude) -
            0.01,
      ),
      northeast: LatLng(
        (_pickupLocation!.latitude > _dropoffLocation!.latitude
                ? _pickupLocation!.latitude
                : _dropoffLocation!.latitude) +
            0.01,
        (_pickupLocation!.longitude > _dropoffLocation!.longitude
                ? _pickupLocation!.longitude
                : _dropoffLocation!.longitude) +
            0.01,
      ),
    );

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 150));
  }

  void _updateMapMarkers() {
    _markers.clear();

    if (_step == 0) {
      // Pickup step - only show current location
      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    } else {
      // Dropoff step - show both
      if (_pickupLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      if (_dropoffLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: _dropoffLocation!,
            infoWindow: const InfoWindow(title: 'Dropoff'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    setState(() {});
  }

  void _confirmPickup() {
    if (_pickupLocation == null || _pickupAddress.isEmpty) {
      _showError('Please select a pickup location');
      return;
    }

    addDebugMessage('✅ Pickup confirmed: $_pickupAddress');

    setState(() {
      _step = 1;
      _dropoffLocation = null;
      _dropoffAddress = '';
      _estimatedDistance = null;
      _estimatedFare = null;
      _estimatedDuration = null;
      _polylines.clear();
      _updateMapMarkers();
    });

    // Animate to dropoff step
    _bottomSheetAnimationController.reset();
    _bottomSheetAnimationController.forward();
  }

  void _backToPickup() {
    setState(() {
      _step = 0;
      _dropoffLocation = null;
      _dropoffAddress = '';
      _estimatedDistance = null;
      _estimatedFare = null;
      _estimatedDuration = null;
      _polylines.clear();
      _updateMapMarkers();
    });

    _bottomSheetAnimationController.reset();
    _bottomSheetAnimationController.forward();
  }

  Future<void> _confirmDropoff() async {
    if (_dropoffLocation == null || _dropoffAddress.isEmpty) {
      _showError('Please select a dropoff location');
      return;
    }

    if (_estimatedDistance == null || _estimatedFare == null) {
      _showError('Calculating route...');
      return;
    }

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ RIDE CONFIRMED');
    addDebugMessage('From: $_pickupAddress');
    addDebugMessage('To: $_dropoffAddress');
    addDebugMessage('Distance: ${_estimatedDistance?.toStringAsFixed(2)} km');
    addDebugMessage('Duration: $_estimatedDuration min');
    addDebugMessage('Type: $_rideType');
    addDebugMessage('Fare: \$${_estimatedFare?.toStringAsFixed(2)}');
    addDebugMessage('═══════════════════════════════════════');

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
      'estimatedDuration': _estimatedDuration,
    });
  }

  void _onRideTypeChanged(String newType) {
    if (_estimatedDistance != null) {
      final newFare =
          DirectionsService.calculateFare(_estimatedDistance!, newType);

      setState(() {
        _rideType = newType;
        _estimatedFare = newFare;
      });

      addDebugMessage('💱 Ride type: $newType - \$${newFare.toStringAsFixed(2)}');
    }
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
          _step == 0 ? 'Select Pickup' : 'Select Dropoff',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isInitializingMap
          ? _buildLoadingScreen()
          : _initializationError.isNotEmpty
              ? _buildErrorScreen()
              : _buildMapScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
          ),
          const SizedBox(height: 20),
          Text(
            'Getting your location...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _initializationError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
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
    );
  }

  Widget _buildMapScreen() {
    return Stack(
      children: [
        // Map
        GoogleMap(
          onMapCreated: _onMapCreated,
          onCameraIdle: _onCameraIdle,
          initialCameraPosition: CameraPosition(
            target: _pickupLocation ?? const LatLng(40.7128, -74.0060),
            zoom: 17,
          ),
          markers: _markers,
          polylines: _polylines,
          compassEnabled: true,
          zoomControlsEnabled: true,
          myLocationButtonEnabled: true,
        ),

        // Center pin (pickup step only)
        if (_step == 0)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),

        // Bottom sheet
        SlideTransition(
          position: _bottomSheetAnimation,
          child: _buildBottomSheet(),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return Positioned(
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
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 20),

                // Step indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                const SizedBox(height: 16),

                if (_step == 0)
                  _buildPickupSheet()
                else
                  _buildDropoffSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickupSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pickup Location',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pickupAddress,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isLoadingAddress)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[400]!,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!_isLoadingAddress)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmPickup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Pickup',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropoffSheet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pickup (locked)
        Text(
          'From (Pickup)',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Colors.green, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _pickupAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Dropoff
        Text(
          'To (Dropoff)',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dropoffAddress.isEmpty
                          ? 'Select dropoff location'
                          : _dropoffAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _dropoffAddress.isEmpty
                            ? Colors.grey[400]
                            : Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isLoadingAddress)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[400]!,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (_dropoffAddress.isNotEmpty && !_isLoadingAddress)
                const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Route info
        if (_isLoadingRoute)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Calculating route...',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else if (_estimatedDistance != null && _estimatedFare != null)
          _buildRouteInfo(),

        const SizedBox(height: 20),

        // Buttons
        Row(
          children: [
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
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoadingRoute ||
                        _estimatedDistance == null ||
                        _estimatedFare == null
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
                  _isLoadingRoute ? 'Calculating...' : 'Request Ride',
                  style: TextStyle(
                    color: _isLoadingRoute ||
                            _estimatedDistance == null ||
                            _estimatedFare == null
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
    );
  }

  Widget _buildRouteInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border.all(color: const Color(0xFF6366F1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Distance, Duration, Fare row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${_estimatedDistance?.toStringAsFixed(2)} km',
                  ),
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'Duration',
                    value: '$_estimatedDuration min',
                  ),
                  _buildInfoItem(
                    icon: Icons.local_taxi,
                    label: 'Fare',
                    value: '\$${_estimatedFare?.toStringAsFixed(2)}',
                    isPrice: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ride type selector
              Row(
                children: [
                  Expanded(
                    child: _buildRideTypeButton(
                      'ECONOMY',
                      '\$0.20/km',
                      _rideType == 'ECONOMY',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRideTypeButton(
                      'LUXURY',
                      '\$0.35/km',
                      _rideType == 'LUXURY',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isPrice ? const Color(0xFF6366F1) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideTypeButton(
    String type,
    String price,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => _onRideTypeChanged(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressLookupTimer?.cancel();
    _bottomSheetAnimationController.dispose();
    mapController.dispose();
    super.dispose();
  }
}