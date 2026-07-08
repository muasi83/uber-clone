import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class RideLocationPickerScreen extends StatefulWidget {
  const RideLocationPickerScreen({super.key});

  @override
  State<RideLocationPickerScreen> createState() => _RideLocationPickerScreenState();
}

class _RideLocationPickerScreenState extends State<RideLocationPickerScreen> {
  GoogleMapController? mapController;
  
  LatLng? _currentLocation;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;
  
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
    _loadMapStyle();
    _initYellowPin();
    _initializeMap();
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _initializeMap() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      _currentLocation = LatLng(position.latitude, position.longitude);
      _pickupLocation = _currentLocation;
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final pStreet = (place.street ?? '').trim();
        final pNeighborhood = (place.subLocality ?? '').trim();
        final pCity = (place.locality ?? '').trim();
        final pParts = <String>[
          if (pCity.isNotEmpty) pCity,
          if (pNeighborhood.isNotEmpty && pNeighborhood != pCity) pNeighborhood,
          if (pStreet.isNotEmpty && pStreet != pNeighborhood) pStreet,
        ];
        _pickupAddress = pParts.join(' - ');
        _pickupSearchController.text = _pickupAddress;
      }
      
      if (mounted) {
        setState(() {});
        await _updateMapMarkers();
      }
      
      addDebugMessage('✅ Map initialized at: $_pickupAddress');
    } catch (e) {
      addDebugMessage('❌ Error initializing map: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_pickupLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
      );
    }
  }

  Future<void> _onCameraMove(CameraPosition position) async {
    if (_step == 0) {
      // Selecting pickup
      _pickupLocation = position.target;
      await _updateMapMarkers();
      
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
      await _updateMapMarkers();
      
      try {
        final placemarks = await placemarkFromCoordinates(
          position.target.latitude,
          position.target.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final dStreet = (place.street ?? '').trim();
          final dNeighborhood = (place.subLocality ?? '').trim();
          final dCity = (place.locality ?? '').trim();
          final dParts = <String>[
            if (dCity.isNotEmpty) dCity,
            if (dNeighborhood.isNotEmpty && dNeighborhood != dCity) dNeighborhood,
            if (dStreet.isNotEmpty && dStreet != dNeighborhood) dStreet,
          ];
          _dropoffAddress = dParts.join(' - ');
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

  Future<void> _updateMapMarkers() async {
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
            icon: await MarkerFactory.userLocation,
          ),
        );
      }
      
    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: _yellowPinMarker,
        ),
      );
    }
    if (_dropoffLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: _dropoffLocation!,
          infoWindow: const InfoWindow(title: 'Dropoff Location'),
          icon: _yellowPinMarker,
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
          color: AppColors.primary,
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
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) * 
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _toRad(double degree) => degree * (math.pi / 180);

  void _confirmPickup() {
    if (_pickupLocation == null) {
      _showError('Please select a pickup location');
      return;
    }
    
    setState(() => _step = 1);
    addDebugMessage('✅ Pickup confirmed: $_pickupAddress');
  }

  Future<void> _backToPickup() async {
    setState(() {
      _step = 0;
      _dropoffLocation = null;
      _dropoffSearchController.clear();
      _estimatedDistance = null;
      _estimatedFare = null;
    });
    await _updateMapMarkers();
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

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // FULL SCREEN MAP
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? const LatLng(0, 0),
              zoom: 17,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            style: _mapStyle,
          ),
          
          // Center pin
          const Center(
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 56,
            ),
          ),
          
          // Top AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _stepDot(0),
                    const SizedBox(width: 6),
                    Text(
                      'Pickup',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _step == 0 ? AppColors.primary : AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 24, height: 2, color: _step >= 1 ? AppColors.primary : AppColors.outline),
                    const SizedBox(width: 8),
                    _stepDot(1),
                    const SizedBox(width: 6),
                    Text(
                      'Dropoff',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _step >= 1 ? AppColors.primary : AppColors.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: true,
            ),
          ),
          
          // Top search card
          Positioned(
            top: 88,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppSpacing.shadowLg,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pickup search
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _step == 0 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outline,
                      ),
                    ),
                    child: TextField(
                      controller: _pickupSearchController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Pickup location',
                        prefixIcon: Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.success,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                        hintStyle: TextStyle(color: AppColors.textTertiary),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_step == 1) ...[
                    const SizedBox(height: 8),
                    // Connecting line
                    Container(
                      height: 20,
                      width: 2,
                      color: AppColors.outline,
                      margin: const EdgeInsets.only(left: 14),
                    ),
                    const SizedBox(height: 8),
                    // Dropoff search
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _step == 1 ? AppColors.primary.withValues(alpha: 0.3) : AppColors.outline,
                        ),
                      ),
                      child: TextField(
                        controller: _dropoffSearchController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Dropoff location',
                          prefixIcon: Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColors.error,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          hintStyle: TextStyle(color: AppColors.textTertiary),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (_estimatedDistance != null && _estimatedFare != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_estimatedDistance!.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '\$',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Text(
                              _estimatedFare!.toStringAsFixed(2),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _rideTypeChip('ECONOMY', '\$0.20/km'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _rideTypeChip('LUXURY', '\$0.35/km'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // My location button
          Positioned(
            right: 16,
            bottom: 100,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppSpacing.shadowLg,
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location, color: AppColors.primary),
                onPressed: () {
                  if (_currentLocation != null) {
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentLocation!, 17),
                    );
                  }
                },
              ),
            ),
          ),
          
          // Bottom buttons
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: _step == 0
                ? PremiumButton(
                    label: 'Confirm Pickup',
                    icon: Icons.check_circle_outline,
                    onPressed: _confirmPickup,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PremiumButton(
                          label: 'Back',
                          variant: ButtonVariant.outline,
                          onPressed: _backToPickup,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PremiumButton(
                          label: 'Request Ride',
                          icon: Icons.rocket_launch_outlined,
                          onPressed: _confirmDropoff,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stepDot(int index) {
    final active = index <= _step;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.outline,
      ),
      child: Center(
        child: active
            ? const Icon(Icons.check, color: AppColors.primaryLight, size: 14)
            : Text(
                '${index + 1}',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _rideTypeChip(String type, String price) {
    final selected = _rideType == type;
    return GestureDetector(
      onTap: () => setState(() => _rideType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'ECONOMY' ? Icons.directions_car : Icons.diamond_outlined,
              size: 16,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: selected ? AppColors.primaryLight : AppColors.textPrimary,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 9,
                    color: selected ? AppColors.primaryLight.withValues(alpha: 0.8) : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupSearchController.dispose();
    _dropoffSearchController.dispose();
    mapController?.dispose();
    super.dispose();
  }
}
