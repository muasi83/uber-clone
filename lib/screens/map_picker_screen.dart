import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../services/storage_service.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(6.5244, 3.3792);
  String _address = '';
  bool _isLoadingLocation = true;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _isLoadingLocation = false;
      _lookupAddress(_selectedLocation);
    } else {
      _initCurrentLocation();
    }
  }

  Future<void> _initCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(pos.latitude, pos.longitude);
          _isLoadingLocation = false;
        });
        _lookupAddress(_selectedLocation);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_selectedLocation, 16),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _lookupAddress(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    try {
      final token = StorageService.getToken();
      final url = '${StorageService.getServerUrl()}/api/routes/geocode?lat=${location.latitude}&lng=${location.longitude}';
      final headers = <String, String>{
        'ngrok-skip-browser-warning': 'true',
      };
      if (token != null && token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final formatted = json['formattedAddress'] as String?;
        final street = json['street'] as String?;
        final district = json['district'] as String?;
        final city = json['city'] as String?;
        final parts = <String>[
          if (street != null && street.isNotEmpty) street,
          if (district != null && district.isNotEmpty) district,
          if (city != null && city.isNotEmpty) city,
        ];
        if (mounted) {
          setState(() {
            _address = formatted ?? parts.join(', ');
            _isLoadingAddress = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingAddress = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoadingLocation) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 16),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedLocation = position.target;
  }

  Future<void> _onCameraIdle() async {
    await _lookupAddress(_selectedLocation);
  }

  void _onConfirm() {
    Navigator.of(context).pop({
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
      'address': _address,
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              onCameraMove: _onCameraMove,
              onCameraIdle: _onCameraIdle,
              initialCameraPosition: CameraPosition(
                target: _selectedLocation,
                zoom: 16,
              ),
              compassEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: SizedBox(
                width: 40,
                height: 72,
                child: CustomPaint(
                  painter: _MapCenterPinPainter(),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: const Text(
                  'Pick a location',
                  style: TextStyle(color: AppColors.primary),
                ),
                centerTitle: true,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _isLoadingAddress
                                ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Finding address...',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    _address.isEmpty
                                        ? 'Move the map to select location'
                                        : _address,
                                    style: TextStyle(
                                      fontSize: _address.isEmpty ? 14 : 16,
                                      fontWeight:
                                          _address.isEmpty ? FontWeight.normal : FontWeight.w600,
                                      color: _address.isEmpty
                                          ? AppColors.textTertiary
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _address.isNotEmpty ? _onConfirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Confirm Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
}

class _MapCenterPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 6;
    final topY = 20.0;

    final stickPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(centerX, bottomY - 4),
      Offset(centerX, topY + 2),
      stickPaint,
    );

    final tipPaint = Paint()
      ..color = AppColors.pickupMarker
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, topY), 6, tipPaint);

    final centerPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, topY), 2.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
