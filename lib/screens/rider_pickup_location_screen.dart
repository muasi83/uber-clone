import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/directions_service.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../screens/debug_screen.dart';

class RiderPickupLocationScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const RiderPickupLocationScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<RiderPickupLocationScreen> createState() =>
      _RiderPickupLocationScreenState();
}

class _RiderPickupLocationScreenState extends State<RiderPickupLocationScreen> {
  GoogleMapController? mapController;

  LatLng? _pickupLocation;
  String _pickupAddress = '';
  final Set<Marker> _markers = {};

  bool _isLoadingAddress = false;
  Timer? _addressLookupTimer;

  // ✅ Prevent spam lookups
  LatLng? _lastLookupCenter;
  bool _loggedGeocodingErrorOnce = false;

  @override
  void initState() {
    super.initState();

    _pickupLocation = LatLng(widget.initialLat, widget.initialLng);

    _lookupAddress(_pickupLocation!);
    _updateMarkers();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
    );
  }

  Future<void> _onCameraIdle() async {
    try {
      if (mapController == null) return;

      final position = await mapController!.getVisibleRegion();

      final center = LatLng(
        (position.northeast.latitude + position.southwest.latitude) / 2,
        (position.northeast.longitude + position.southwest.longitude) / 2,
      );

      // ✅ Ignore tiny movements to avoid repeated reverse-geocoding spam
      if (_lastLookupCenter != null) {
        final dLat = (center.latitude - _lastLookupCenter!.latitude).abs();
        final dLng = (center.longitude - _lastLookupCenter!.longitude).abs();
        if (dLat < 0.00005 && dLng < 0.00005) {
          return;
        }
      }

      _lastLookupCenter = center;

      _pickupLocation = center;

      _updateMarkers();

      _lookupAddress(center);
    } catch (e) {
      // Don't use addDebugMessage here (async spam can cause ancestor issues)
      if (kDebugMode) debugPrint('⚠️ Camera idle error: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    if (_pickupLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLocation!,
          infoWindow: const InfoWindow(
            title: 'Pickup Location',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _lookupAddress(LatLng location) async {
    _addressLookupTimer?.cancel();

    _addressLookupTimer = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) return;

        setState(() {
          _isLoadingAddress = true;
        });

        // ✅ Always have a safe fallback
        String address =
            'Lat: ${location.latitude.toStringAsFixed(4)}, '
            'Lng: ${location.longitude.toStringAsFixed(4)}';

        try {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => <Placemark>[],
          );

          if (!mounted) return;

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;

            final street = (place.street ?? '').trim();
            final locality = (place.locality ?? '').trim();
            final administrativeArea = (place.administrativeArea ?? '').trim();
            final country = (place.country ?? '').trim();

            final parts = [
              if (street.isNotEmpty) street,
              if (locality.isNotEmpty) locality,
              if (administrativeArea.isNotEmpty) administrativeArea,
              if (country.isNotEmpty) country,
            ];

            final formatted = parts.join(', ').trim();
            if (formatted.isNotEmpty) {
              address = formatted;
            }
          }

          if (!mounted) return;

          setState(() {
            _pickupAddress = address;
            _isLoadingAddress = false;
          });

          // ✅ log only when meaningful (not spam)
          // addDebugMessage('📍 Pickup address: $address');
        } catch (e) {
          // ✅ This is where "Unexpected null value" happens sometimes.
          // Avoid spamming terminal/logs.
          if (!_loggedGeocodingErrorOnce) {
            _loggedGeocodingErrorOnce = true;
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Reverse geocoding failed once (will fallback to Lat/Lng). Error: $e');
            }
          }

          if (!mounted) return;

          setState(() {
            _pickupAddress = address; // fallback
            _isLoadingAddress = false;
          });
        }
      },
    );
  }

  void _confirmPickup() {
    if (_pickupLocation == null || _pickupAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a pickup location',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    addDebugMessage(
      '✅ Pickup confirmed: $_pickupAddress',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderDropoffLocationScreen(
          pickupLat: _pickupLocation!.latitude,
          pickupLng: _pickupLocation!.longitude,
          pickupAddress: _pickupAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            onCameraIdle: _onCameraIdle,
            initialCameraPosition: CameraPosition(
              target: _pickupLocation ?? const LatLng(0, 0),
              zoom: 17,
            ),
            markers: _markers,
            compassEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Center pin
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.2,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.black,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),

          // Address card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.1,
                    ),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup address',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pickupAddress.isEmpty
                              ? 'Select location'
                              : _pickupAddress,
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
                  if (!_isLoadingAddress && _pickupAddress.isNotEmpty)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                  if (_isLoadingAddress)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmPickup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFFD4AF37,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                ),
                child: const Text(
                  'Confirm point',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
    _addressLookupTimer?.cancel();

    mapController?.dispose();

    super.dispose();
  }
}