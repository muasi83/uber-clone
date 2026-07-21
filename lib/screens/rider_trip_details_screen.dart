import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../services/directions_service.dart';
import '../services/currency_service.dart';
import '../screens/rider_searching_driver_screen.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../utils/marker_utils.dart';
import '../utils/map_style_loader.dart';
import '../utils/address_utils.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_card.dart';
import '../widgets/ride_type_selector.dart';
import '../models/location_model.dart';

class RiderTripDetailsScreen extends StatefulWidget {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double dropoffLat;
  final double dropoffLng;
  final String dropoffAddress;
  final double estimatedDistance;
  final int estimatedDuration;
  final String initialRideType;

  const RiderTripDetailsScreen({
    super.key,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    required this.estimatedDistance,
    required this.estimatedDuration,
    this.initialRideType = 'ECONOMY',
  });

  @override
  State<RiderTripDetailsScreen> createState() => _RiderTripDetailsScreenState();
}

class _RiderTripDetailsScreenState extends State<RiderTripDetailsScreen> {
  late String _selectedRideType;
  late double _selectedFare;
  String _selectedPaymentMethod = 'CASH';
  bool _isSubmitting = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  BitmapDescriptor _yellowPinMarker = BitmapDescriptor.defaultMarker;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _selectedRideType = widget.initialRideType;
    _selectedFare = RideTypeSelector.calculateFare(rideTypes, widget.initialRideType, widget.estimatedDistance);
    _initMarkers();

    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('💳 TRIP DETAILS');
    addDebugMessage(
        'Distance: ${widget.estimatedDistance.toStringAsFixed(2)} km');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _initMarkers() async {
    _yellowPinMarker = await getYellowPinMarker();
    _markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: 'Pickup: ${widget.pickupAddress}'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(widget.dropoffLat, widget.dropoffLng),
        icon: _yellowPinMarker,
        infoWindow: InfoWindow(title: 'Dropoff: ${widget.dropoffAddress}'),
      ),
    );
    _loadRoute();
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
  }

  Future<void> _loadRoute() async {
    try {
      final route = await DirectionsService.getDirections(
        origin: LatLng(widget.pickupLat, widget.pickupLng),
        destination: LatLng(widget.dropoffLat, widget.dropoffLng),
      );
      if (route != null && route.isSuccess && route.polylinePoints != null) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: route.polylinePoints!,
              color: AppColors.primary,
              width: 5,
              geodesic: true,
            ),
          );
        });
      }
    } catch (e) {
      addDebugMessage('Route load error: $e');
    }
  }

  Future<void> _submitRideRequest() async {
    if (_isSubmitting) return;

    try {
      setState(() => _isSubmitting = true);

      addDebugMessage('═══════════════════════════════════════');
      addDebugMessage('📤 SUBMITTING RIDE REQUEST');
      addDebugMessage('Type: $_selectedRideType');
      addDebugMessage('Payment: $_selectedPaymentMethod');
      addDebugMessage('═══════════════════════════════════════');

      final token = StorageService.getToken();
      if (token == null) {
        _showError('Authentication error');
        return;
      }

      final ride = await RideService.requestRide(
        pickupLat: widget.pickupLat,
        pickupLng: widget.pickupLng,
        pickupAddress: widget.pickupAddress,
        dropoffLat: widget.dropoffLat,
        dropoffLng: widget.dropoffLng,
        dropoffAddress: widget.dropoffAddress,
        rideType: _selectedRideType,
        paymentMethod: _selectedPaymentMethod,
        estimatedDistance: widget.estimatedDistance,
        estimatedFare: _selectedFare,
        estimatedDuration: widget.estimatedDuration,
        token: token,
      );

      if (ride != null && mounted) {
        addDebugMessage('✅ Ride created: ${ride.id}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RiderSearchingDriverScreen(
              rideId: ride.id!,
              pickupAddress: widget.pickupAddress,
              dropoffAddress: widget.dropoffAddress,
              estimatedFare: _selectedFare,
            ),
          ),
        );
      } else {
        _showError('Failed to request ride');
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: AppSpacing.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            AppSpacing.gapLg,
            _buildPaymentOption('WALLET', Icons.account_balance_wallet),
            _buildPaymentOption('CASH', Icons.money),
            _buildPaymentOption('CARD', Icons.credit_card),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(method),
      trailing: _selectedPaymentMethod == method
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        setState(() => _selectedPaymentMethod = method);
        Navigator.pop(context);
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Choose Ride',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map with route
            Container(
              height: 250,
              margin: AppSpacing.screenPadding,
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgRadius,
                color: AppColors.surfaceVariant,
                boxShadow: AppShadows.medium,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.lgRadius,
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        final bounds = LatLngBounds(
                          southwest: LatLng(
                            widget.pickupLat < widget.dropoffLat
                                ? widget.pickupLat - 0.01
                                : widget.dropoffLat - 0.01,
                            widget.pickupLng < widget.dropoffLng
                                ? widget.pickupLng - 0.01
                                : widget.dropoffLng - 0.01,
                          ),
                          northeast: LatLng(
                            widget.pickupLat > widget.dropoffLat
                                ? widget.pickupLat + 0.01
                                : widget.dropoffLat + 0.01,
                            widget.pickupLng > widget.dropoffLng
                                ? widget.pickupLng + 0.01
                                : widget.dropoffLng + 0.01,
                          ),
                        );
                        controller.moveCamera(
                            CameraUpdate.newLatLngBounds(bounds, 80));
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.pickupLat, widget.pickupLng),
                        zoom: 13,
                      ),
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                      style: _mapStyle,
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: Container(
                        padding: AppSpacing.chipPadding,
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius:
                              BorderRadius.circular(1000),
                          boxShadow: AppShadows.small,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.route,
                                size: 14, color: AppColors.primary),
                            AppSpacing.hGapXs,
                            Text(
                              '${widget.estimatedDistance.toStringAsFixed(1)} km · ${widget.estimatedDuration} min',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Address cards
            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                children: [
                  PremiumCard(
                    padding: AppSpacing.cardPaddingCompact,
                    shadows: AppShadows.small,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius:
                                AppRadius.smRadius,
                          ),
                          child: const Icon(Icons.location_on_outlined,
                              color: AppColors.success, size: 20),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pickup',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                widget.pickupAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                formatLatLng(widget.pickupLat, widget.pickupLng),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: List.generate(
                          3,
                          (i) => Container(
                                width: 2,
                                height: 4,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.outlineVariant,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              )),
                    ),
                  ),
                  PremiumCard(
                    padding: AppSpacing.cardPaddingCompact,
                    shadows: AppShadows.small,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius:
                                AppRadius.smRadius,
                          ),
                          child: const Icon(Icons.location_on,
                              color: AppColors.error, size: 20),
                        ),
                        AppSpacing.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dropoff',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              AppSpacing.gapXs,
                              Text(
                                widget.dropoffAddress,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                formatLatLng(widget.dropoffLat, widget.dropoffLng),
                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ride type selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select ride type',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapMd,
                  RideTypeSelector(
                    rideTypes: rideTypes,
                    selectedApiName: _selectedRideType,
                    onChanged: (type) {
                      setState(() {
                        _selectedRideType = type;
                        _selectedFare = RideTypeSelector.calculateFare(
                          rideTypes, type, widget.estimatedDistance,
                        );
                      });
                    },
                    distanceKm: widget.estimatedDistance,
                  ),
                ],
              ),
            ),
            AppSpacing.gapXxl,

            // Payment method
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapMd,
                  GestureDetector(
                    onTap: _showPaymentMethodSelector,
                    child: PremiumCard(
                      padding: AppSpacing.cardPaddingCompact,
                      shadows: AppShadows.small,
                      hasRipple: true,
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius:
                                  AppRadius.smRadius,
                            ),
                            child: Icon(
                              _selectedPaymentMethod == 'WALLET'
                                  ? Icons.account_balance_wallet
                                  : _selectedPaymentMethod == 'CASH'
                                      ? Icons.money
                                      : Icons.credit_card,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          AppSpacing.hGapMd,
                          Expanded(
                            child: Text(
                              _selectedPaymentMethod,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXxl,

            // Price breakdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PremiumCard(
                padding: AppSpacing.cardPadding,
                shadows: AppShadows.small,
                child: Column(
                  children: [
                    _priceRow('Base fare', CurrencyService.format(2.0)),
                    AppSpacing.gapMd,
                    _priceRow(
                      'Distance (${widget.estimatedDistance.toStringAsFixed(1)} km)',
                      '${CurrencyService.format(widget.estimatedDistance * (_selectedRideType == 'ECONOMY' ? 0.20 : 0.35))}',
                    ),
                    const Divider(height: 32, color: AppColors.outline),
                    _priceRow(
                      'Total',
                      '${CurrencyService.format(_selectedFare)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapXxl,

            // Confirm button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PremiumButton(
                label: _isSubmitting ? 'Requesting...' : 'Confirm Ride',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitRideRequest,
                icon: _isSubmitting ? null : Icons.check_circle_outline,
                variant: ButtonVariant.gradient,
                height: 60,
              ),
            ),
            AppSpacing.gapHuge,
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

}
