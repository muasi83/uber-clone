import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/map_style_loader.dart';
import 'premium_button.dart';

enum LocationPickerMode { pickup, dropoff }

class LocationPickerScreen extends StatefulWidget {
  final LocationPickerMode mode;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.mode = LocationPickerMode.pickup,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(6.5244, 3.3792);
  String _address = '';
  bool _isLoadingLocation = true;
  bool _isLoadingAddress = false;
  Timer? _debounceTimer;

  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnim;

  Color get _pinColor => switch (widget.mode) {
        LocationPickerMode.pickup => AppColors.pickupMarker,
        LocationPickerMode.dropoff => AppColors.dropoffMarker,
      };

  String get _title => switch (widget.mode) {
        LocationPickerMode.pickup => 'Set pickup location',
        LocationPickerMode.dropoff => 'Set drop-off location',
      };

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    );

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _isLoadingLocation = false;
      _lookupAddress(_selectedLocation);
    } else {
      _initCurrentLocation();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _bounceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        setState(() {
          _selectedLocation = loc;
          _isLoadingLocation = false;
        });
        _bounceController.forward(from: 0);
        _lookupAddress(loc);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(loc, 16),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _lookupAddress(LatLng location) async {
    setState(() => _isLoadingAddress = true);
    try {
      final address = await LocationService.getFormattedAddress(
        location.latitude,
        location.longitude,
      );
      if (mounted) {
        setState(() {
          _address = address ?? '';
          _isLoadingAddress = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingAddress = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (!_isLoadingLocation) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 16),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    _selectedLocation = position.target;
  }

  void _onCameraIdle() {
    _bounceController.forward(from: 0);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _lookupAddress(_selectedLocation);
    });
  }

  void _onConfirm() {
    Navigator.of(context).pop({
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
      'address': _address,
    });
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        final loc = LatLng(pos.latitude, pos.longitude);
        _selectedLocation = loc;
        _lookupAddress(loc);
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(loc, 16),
        );
      }
    } catch (_) {}
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
              style: MapStyleLoader.cachedStyle,
            ),
          Center(
            child: AnimatedBuilder(
              animation: _bounceAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnim.value * 16),
                  child: child,
                );
              },
              child: SizedBox(
                width: 40,
                height: 72,
                child: CustomPaint(
                  painter: _LocationPinPainter(color: _pinColor),
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
                title: Text(
                  _title,
                  style: const TextStyle(color: AppColors.primary),
                ),
                centerTitle: true,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 220,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.surface,
              onPressed: _centerOnCurrentLocation,
              child: const Icon(
                Icons.my_location,
                color: AppColors.primary,
                size: 22,
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
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgRadius,
                ),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            widget.mode == LocationPickerMode.pickup
                                ? Icons.trip_origin
                                : Icons.location_on,
                            color: _pinColor,
                            size: 24,
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: _isLoadingAddress
                                ? const Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      AppSpacing.hGapSm,
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
                                      fontWeight: _address.isEmpty
                                          ? FontWeight.normal
                                          : FontWeight.w600,
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
                      AppSpacing.gapMd,
                      PremiumButton(
                        label: _address.isEmpty
                            ? 'Move the map'
                            : 'Confirm Location',
                        onPressed:
                            _address.isNotEmpty ? _onConfirm : null,
                        variant: ButtonVariant.gradient,
                        height: 52,
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

class _LocationPinPainter extends CustomPainter {
  final Color color;

  _LocationPinPainter({required this.color});

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
      ..color = color
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
