import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/glass_card.dart';
import 'dart:math' as math;
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/marker_factory.dart';

class RideMapScreen extends StatefulWidget {
  final bool isDriver;

  const RideMapScreen({
    super.key,
    this.isDriver = false,
  });

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  GoogleMapController? mapController;
  
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
  
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  bool isLoading = true;
  String rideType = 'ECONOMY';
  double? estimatedDistance;
  double? estimatedFare;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initYellowPin();
    _getCurrentLocation();
  }

  Future<void> _initYellowPin() async {
    _yellowPinMarker = await getYellowPinMarker();
  }

  Future<void> _getCurrentLocation() async {
    try {
      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📍 GETTING CURRENT LOCATION');
      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      
      currentLocation = LatLng(position.latitude, position.longitude);
      pickupLocation = currentLocation;
      
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final neighborhood = (place.subLocality ?? '').trim();
        final street = (place.street ?? '').trim();
        final locality = (place.locality ?? '').trim();
        final parts = <String>[
          if (neighborhood.isNotEmpty) neighborhood,
          if (street.isNotEmpty) street,
          if (locality.isNotEmpty) locality,
        ];
        pickupAddress = parts.join(' - ');
        addDebugMessage('✅ Address: $pickupAddress');
      }
      
      if (mounted) {
        setState(() => isLoading = false);
        await _updateMapMarkers();
      }
      
      addDebugMessage('═══════════════════════════════════════');
    } catch (e) {
      addDebugMessage('❌ Error getting location: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    mapController?.animateCamera(
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
    
    await _updateMapMarkers();
  }

  Future<void> _updateMapMarkers() async {
    markers.clear();
    polylines.clear();
    
    if (step == 1) {
      if (currentLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'Current Location'),
            icon: await MarkerFactory.userLocation,
          ),
        );
      }
      
      if (pickupLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupLocation!,
            infoWindow: const InfoWindow(title: 'Pickup Location (Moving)'),
            icon: _yellowPinMarker,
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
            icon: _yellowPinMarker,
          ),
        );
      }
      
      if (dropoffLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoffLocation!,
            infoWindow: const InfoWindow(title: 'Dropoff Location (Moving)'),
            icon: _yellowPinMarker,
          ),
        );
      }
      
      if (pickupLocation != null && dropoffLocation != null) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [pickupLocation!, dropoffLocation!],
            color: AppColors.primary,
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
    
    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
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

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
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
        final neighborhood = (place.subLocality ?? '').trim();
        final street = (place.street ?? '').trim();
        final locality = (place.locality ?? '').trim();
        final parts = <String>[
          if (neighborhood.isNotEmpty) neighborhood,
          if (street.isNotEmpty) street,
          if (locality.isNotEmpty) locality,
        ];
        pickupAddress = parts.join(' - ');
      }
    } catch (e) {
      pickupAddress = 'Pickup location';
    }
    
    setState(() => step = 2);
    await _updateMapMarkers();
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
        final street = (place.street ?? '').trim();
        final neighborhood = (place.subLocality ?? '').trim();
        final city = (place.locality ?? '').trim();
        final parts = <String>[
          if (city.isNotEmpty) city,
          if (neighborhood.isNotEmpty && neighborhood != city) neighborhood,
          if (street.isNotEmpty && street != neighborhood) street,
        ];
        dropoffAddress = parts.join(' - ');
      }
    } catch (e) {
      dropoffAddress = 'Dropoff location';
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
            backgroundColor: AppColors.success,
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
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  initialCameraPosition: CameraPosition(
                    target: pickupLocation ?? const LatLng(0, 0),
                    zoom: 17,
                  ),
                  markers: markers,
                  polylines: polylines,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  style: _mapStyle,
                ),
                
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
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stepDot(1, true),
                          const SizedBox(width: 6),
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 20, height: 1, color: AppColors.primary),
                          const SizedBox(width: 6),
                          _stepDot(2, step >= 2),
                          const SizedBox(width: 6),
                          Text(
                            'Dropoff',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: step >= 2 ? AppColors.primary : AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    centerTitle: true,
                  ),
                ),
                
                // Center pin
                const Center(
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
                
                // My location button
                Positioned(
                  right: 16,
                  bottom: 220,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppSpacing.shadowLg,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.my_location, color: AppColors.primary),
                      onPressed: () {
                        if (currentLocation != null) {
                          _animateToLocation(currentLocation!);
                        }
                      },
                    ),
                  ),
                ),
                
                // Bottom panel
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.all(20),
                    child: step == 1 ? _buildPickupPanel() : _buildDropoffPanel(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stepDot(int number, bool active) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.primary : AppColors.outline,
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPickupPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup Location',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pickupAddress ?? 'Move the map to set location',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PremiumButton(
          label: 'Confirm Pickup Location',
          icon: Icons.check_circle_outline,
          onPressed: _confirmPickup,
        ),
      ],
    );
  }

  Widget _buildDropoffPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pickup',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pickupAddress ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dropoff',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dropoffAddress ?? 'Move the map to set location',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _rideTypeOption('ECONOMY', '\$0.20/km', Icons.directions_car),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _rideTypeOption('LUXURY', '\$0.35/km', Icons.diamond_outlined),
            ),
          ],
        ),
        if (estimatedDistance != null && estimatedFare != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distance',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${estimatedDistance!.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Estimated Fare',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${estimatedFare!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PremiumButton(
                label: 'Back',
                variant: ButtonVariant.outline,
                onPressed: () => setState(() => step = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: PremiumButton(
                label: 'Confirm & Request Ride',
                icon: Icons.rocket_launch_outlined,
                onPressed: _confirmDropoff,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rideTypeOption(String type, String price, IconData icon) {
    final selected = rideType == type;
    return GestureDetector(
      onTap: () => setState(() => rideType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.outline,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 10,
                    color: selected ? Colors.white.withValues(alpha: 0.8) : AppColors.textTertiary,
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
    mapController?.dispose();
    super.dispose();
  }
}
