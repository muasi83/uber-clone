import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';

class RiderConfirmationScreen extends StatefulWidget {
  final LocationData pickupLocation;
  final LocationData dropoffLocation;
  final Function(String rideType) onConfirmRide;

  const RiderConfirmationScreen({
    super.key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.onConfirmRide,
  });

  @override
  State<RiderConfirmationScreen> createState() =>
      _RiderConfirmationScreenState();
}

class _RiderConfirmationScreenState extends State<RiderConfirmationScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _selectedRideType = 'Economy';
  double _distance = 0.0;
  Map<String, double> _fares = {};
  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ CONFIRMATION SCREEN LOADED');
    addDebugMessage('Pickup: ${widget.pickupLocation.address}');
    addDebugMessage('Dropoff: ${widget.dropoffLocation.address}');
    addDebugMessage('═══════════════════════════════════════');

    _calculateDistance();
    _calculateFares();
    _initializeMap();
  }

  void _calculateDistance() {
    try {
      _distance = LocationService.calculateDistance(
        widget.pickupLocation.latitude,
        widget.pickupLocation.longitude,
        widget.dropoffLocation.latitude,
        widget.dropoffLocation.longitude,
      );

      addDebugMessage('📏 Distance calculated: ${_distance.toStringAsFixed(2)} km');
    } catch (e) {
      addDebugMessage('❌ Error calculating distance: $e');
      _distance = 0.0;
    }
  }

  void _calculateFares() {
    try {
      setState(() {
        _fares = {};
        for (var rideType in rideTypes) {
          final fare =
              LocationService.calculateFare(_distance, rideType);
          _fares[rideType.name] = fare;

          addDebugMessage(
              '💵 ${rideType.name}: \$${fare.toStringAsFixed(2)}');
        }
      });
    } catch (e) {
      addDebugMessage('❌ Error calculating fares: $e');
    }
  }

  void _initializeMap() {
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(
          widget.pickupLocation.latitude,
          widget.pickupLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.pickupLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        ),
      ),
    );

    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(
          widget.dropoffLocation.latitude,
          widget.dropoffLocation.longitude,
        ),
        infoWindow: InfoWindow(
          title: 'Dropoff Location',
          snippet: widget.dropoffLocation.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
      ),
    );

    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(
            widget.pickupLocation.latitude,
            widget.pickupLocation.longitude,
          ),
          LatLng(
            widget.dropoffLocation.latitude,
            widget.dropoffLocation.longitude,
          ),
        ],
        color: AppColors.primary,
        width: 5,
        geodesic: true,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    final double minLat = widget.pickupLocation.latitude <
            widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;

    final double maxLat = widget.pickupLocation.latitude >
            widget.dropoffLocation.latitude
        ? widget.pickupLocation.latitude
        : widget.dropoffLocation.latitude;

    final double minLng = widget.pickupLocation.longitude <
            widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final double maxLng = widget.pickupLocation.longitude >
            widget.dropoffLocation.longitude
        ? widget.pickupLocation.longitude
        : widget.dropoffLocation.longitude;

    final LatLngBounds bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 150),
    );
  }

  void _confirmRide() {
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('🎉 RIDE CONFIRMED');
    addDebugMessage('Ride Type: $_selectedRideType');
    addDebugMessage('Fare: \$${_fares[_selectedRideType]}');
    addDebugMessage('Distance: ${_distance.toStringAsFixed(2)} km');
    addDebugMessage('═══════════════════════════════════════');

    widget.onConfirmRide(_selectedRideType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.pickupLocation.latitude,
                widget.pickupLocation.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            compassEnabled: true,
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildPremiumAppBar(),
          ),
          Positioned(
            top: screenHeight * 0.40,
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAppBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Material(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Confirm Ride',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXxl),
        ),
        boxShadow: AppSpacing.shadowXl,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDragHandle(),
            AppSpacing.gapLg,
            _buildTripCard(),
            AppSpacing.gapXxl,
            _buildSectionTitle('Select Ride Type'),
            AppSpacing.gapMd,
            _buildRideTypeSelector(),
            AppSpacing.gapXxl,
            _buildSectionTitle('Price Breakdown'),
            AppSpacing.gapSm,
            _buildPriceBreakdown(),
            AppSpacing.gapXxl,
            PremiumButton(
              label: 'Confirm Ride',
              icon: Icons.check_circle_outline,
              onPressed: _confirmRide,
              variant: ButtonVariant.gradient,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTripCard() {
    final eta = '${(_distance * 1.5).toStringAsFixed(0)} min';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          _buildLocationRow(
            icon: Icons.circle,
            iconColor: AppColors.success,
            label: 'Pickup',
            address: widget.pickupLocation.address,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SizedBox(
              height: 28,
              child: CustomPaint(
                size: const Size(2, 28),
                painter: _DottedLinePainter(color: AppColors.outlineVariant),
              ),
            ),
          ),
          _buildLocationRow(
            icon: Icons.location_on,
            iconColor: AppColors.error,
            label: 'Dropoff',
            address: widget.dropoffLocation.address,
          ),
          const Divider(height: 24, color: AppColors.outline),
          Row(
            children: [
              _buildMetricChip(Icons.straighten, 'Distance',
                  '${_distance.toStringAsFixed(1)} km'),
              const SizedBox(width: 12),
              _buildMetricChip(Icons.access_time, 'Est. Time', eta),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textTertiary, size: 16),
            AppSpacing.hGapSm,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeSelector() {
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: rideTypes.length,
        separatorBuilder: (_, __) => AppSpacing.hGapMd,
        itemBuilder: (context, index) {
          final rideType = rideTypes[index];
          final fare = _fares[rideType.name] ?? 0.0;
          final isSelected = _selectedRideType == rideType.name;
          final eta = '${(_distance * 1.5).toStringAsFixed(0)} min';

          return GestureDetector(
            onTap: () {
              setState(() => _selectedRideType = rideType.name);
              addDebugMessage('✅ Selected: ${rideType.name}');
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 100,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(rideType.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    rideType.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${fare.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    eta,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    final selected = rideTypes.firstWhere(
      (rt) => rt.name == _selectedRideType,
      orElse: () => rideTypes.first,
    );
    final total = _fares[_selectedRideType] ?? 0.0;
    final distanceCharge = _distance * selected.perKmRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          _buildPriceRow('Base fare',
              '\$${selected.baseFare.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _buildPriceRow(
            'Distance (${_distance.toStringAsFixed(1)} km × \$${selected.perKmRate.toStringAsFixed(2)}/km)',
            '\$${distanceCharge.toStringAsFixed(2)}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.outline),
          ),
          _buildPriceRow(
            'Total',
            '\$${total.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashWidth).clamp(0, size.height)),
        paint,
      );
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
