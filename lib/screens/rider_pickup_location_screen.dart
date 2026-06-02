import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../screens/rider_dropoff_location_screen.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../widgets/glass_card.dart';

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
        } catch (e) {
          if (!_loggedGeocodingErrorOnce) {
            _loggedGeocodingErrorOnce = true;
            if (kDebugMode) {
              debugPrint(
                  '⚠️ Reverse geocoding failed once (will fallback to Lat/Lng). Error: $e');
            }
          }

          if (!mounted) return;

          setState(() {
            _pickupAddress = address;
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

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Set Pickup Location',
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
            ),
          ),

          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 48,
                ),
                SizedBox(height: 60),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassCard(
              borderRadius: AppSpacing.radiusXxl,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  if (_isLoadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        AppSpacing.hGapMd,
                        Text(
                          'Finding address...',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    )
                  else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Text(
                            _pickupAddress.isEmpty
                                ? 'Tap map to set pickup'
                                : _pickupAddress,
                            style: TextStyle(
                              fontSize: _pickupAddress.isEmpty ? 15 : 18,
                              fontWeight: FontWeight.bold,
                              color: _pickupAddress.isEmpty
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  AppSpacing.gapLg,
                  PremiumButton(
                    label: 'Confirm Pickup',
                    onPressed: _confirmPickup,
                    variant: ButtonVariant.gradient,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: AppSpacing.lg,
            bottom: MediaQuery.of(context).padding.bottom + 180,
            child: FloatingActionButton.small(
              heroTag: 'centerPickupMap',
              onPressed: () {
                if (_pickupLocation != null && mapController != null) {
                  mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_pickupLocation!, 17),
                  );
                }
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: AppColors.primary),
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
