import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride_model.dart';
import '../services/ride_service.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';
import '../services/recorded_screen_mixin.dart';
import '../utils/address_utils.dart';
import '../utils/map_style_loader.dart';

class RiderRideCompletedScreen extends StatefulWidget {
  final int rideId;
  final double? totalFare;
  final double? distance;
  final int? duration;
  final String paymentStatus;

  const RiderRideCompletedScreen({
    super.key,
    required this.rideId,
    this.totalFare,
    this.distance,
    this.duration,
    this.paymentStatus = 'COMPLETED',
  });

  @override
  State<RiderRideCompletedScreen> createState() =>
      _RiderRideCompletedScreenState();
}

class _RiderRideCompletedScreenState extends State<RiderRideCompletedScreen> with RecordedScreenMixin<RiderRideCompletedScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  Ride? _ride;

  double _tipAmount = 0;
  final List<double> _quickTips = [1.0, 2.0, 5.0];

  String? _mapStyle;
  final Set<Marker> _routeMarkers = {};
  final Set<Polyline> _routePolylines = {};

  @override
  void initState() {
    super.initState();
    recordEvent(
      eventName: 'RIDE_COMPLETED_VIEWED',
      category: 'FRONTEND',
      summary: 'Rider viewed completed ride screen',
    );
    _loadRideDetails();
    _loadMapStyle();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ RIDE COMPLETED');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await MapStyleLoader.load();
    if (mounted) setState(() {});
  }

  void _setupRouteMap() {
    if (_ride == null) return;
    _routeMarkers.addAll([
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(_ride!.pickupLatitude, _ride!.pickupLongitude),
        infoWindow: InfoWindow(title: _ride!.pickupAddress),
      ),
      Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(_ride!.dropoffLatitude, _ride!.dropoffLongitude),
        infoWindow: InfoWindow(title: _ride!.dropoffAddress),
      ),
    ]);
    _routePolylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(_ride!.pickupLatitude, _ride!.pickupLongitude),
          LatLng(_ride!.dropoffLatitude, _ride!.dropoffLongitude),
        ],
        color: AppColors.primary,
        width: 4,
      ),
    );
  }

  Future<void> _loadRideDetails() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (mounted) {
        setState(() {
          _ride = ride;
          _setupRouteMap();
        });
      }
    } catch (e) {
      addDebugMessage('❌ Error loading ride details: $e');
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final token = StorageService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication error'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      addDebugMessage('⭐ Submitting rating: $_rating');
      addDebugMessage('Feedback: ${_feedbackController.text}');

      await RideService.submitRating(
        rideId: widget.rideId,
        rating: _rating,
        feedback: _feedbackController.text,
        token: token,
      );

      addDebugMessage('✅ Rating submitted');
      recordEvent(
        eventName: 'RATING_SUBMITTED',
        category: 'FRONTEND',
        summary: 'Rider submitted rating for driver',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for rating!'),
            backgroundColor: AppColors.success,
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/rider-home',
              (route) => false,
            );
          }
        });
      }
    } catch (e) {
      addDebugMessage('❌ Error: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxxl + AppSpacing.giant, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              label: 'Trip completed successfully',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(1000),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
            ),
            AppSpacing.gapXxl,
            Semantics(
              label: 'Trip completed',
              child: const Text(
                'Trip Completed!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            AppSpacing.gapXxl,

            if (_ride?.driver != null)
              Semantics(
                label: 'Driver information',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgRadius,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: Text(
                            (_ride!.driver!.fullName.isNotEmpty
                                ? _ride!.driver!.fullName[0].toUpperCase()
                                : 'D'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ride!.driver!.fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (_ride!.driverAverageRating != null)
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      _ride!.driverAverageRating!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            AppSpacing.gapLg,

            Semantics(
              label: 'Trip summary',
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.lgRadius,
                  side: const BorderSide(color: AppColors.outline),
                ),
                child: Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    children: [
                      _buildAddressSection(),
                      const Divider(height: 1, color: AppColors.outline),
                      _buildSummaryRow(
                        'Distance',
                        '${_ride?.estimatedDistance?.toStringAsFixed(2) ?? widget.distance?.toStringAsFixed(2) ?? '0.00'} km',
                      ),
                      const Divider(height: 1, color: AppColors.outline),
                      _buildSummaryRow(
                        'Duration',
                        '${_ride?.estimatedDuration ?? widget.duration ?? 0} min',
                      ),
                      const Divider(height: 1, color: AppColors.outline),
                      _buildSummaryRow(
                        'Total Fare',
                        '${CurrencyService.format(_ride?.finalFare ?? _ride?.estimatedFare ?? widget.totalFare ?? 0)}',
                        isPrice: true,
                      ),
                      if (_tipAmount > 0) ...[
                        const Divider(height: 1, color: AppColors.outline),
                        _buildSummaryRow(
                          'Tip',
                          '${CurrencyService.format(_tipAmount)}',
                          isPrice: true,
                        ),
                      ],
                      const Divider(height: 1, color: AppColors.outline),
                      _buildSummaryRow(
                        'Payment',
                        widget.paymentStatus,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppSpacing.gapXxl,

            if (_ride != null)
              Semantics(
                label: 'Route map',
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.lgRadius,
                    side: const BorderSide(color: AppColors.outline),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
                    height: 140,
                    child: _mapStyle != null
                        ? GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                (_ride!.pickupLatitude + _ride!.dropoffLatitude) / 2,
                                (_ride!.pickupLongitude + _ride!.dropoffLongitude) / 2,
                              ),
                              zoom: 12,
                            ),
                            markers: _routeMarkers,
                            polylines: _routePolylines,
                            style: _mapStyle,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            myLocationEnabled: false,

                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            AppSpacing.gapXxl,

            Semantics(
              label: 'Add a tip',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a tip',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppSpacing.gapMd,
                  Row(
                    children: _quickTips.map((amount) {
                      final selected = _tipAmount == amount;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            end: amount != _quickTips.last ? 8 : 0,
                          ),
                          child: Semantics(
                            label: selected ? 'Selected tip ${CurrencyService.format(amount)}' : 'Tip ${CurrencyService.format(amount)}',
                            child: GestureDetector(
                              onTap: () => setState(() => _tipAmount = selected ? 0 : amount),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : AppColors.surfaceVariant,
                                  borderRadius: AppRadius.mdRadius,
                                  border: Border.all(
                                    color: selected ? AppColors.primary : AppColors.outline,
                                  ),
                                ),
                                child: Text(
                                  '${CurrencyService.format(amount)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: selected ? AppColors.primaryLight : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (_tipAmount > 0) ...[
                    AppSpacing.gapSm,
                    Semantics(
                      label: 'Remove tip',
                      child: GestureDetector(
                        onTap: () => setState(() => _tipAmount = 0),
                        child: const Text(
                          'Remove tip',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            AppSpacing.gapXxl,

            Semantics(
              label: 'Rate your driver',
              child: Column(
                children: [
                  const Text(
                    'Rate your driver',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.gapLg,
                  Semantics(
                    label: 'Rating stars, $_rating out of 5',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => setState(() => _rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              index < _rating ? Icons.star : Icons.star_border,
                              color: AppColors.warning,
                              size: 42,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXxl,
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'Additional feedback (optional)',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
              ),
            ),
            AppSpacing.gapSm,
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: AppSpacing.cardPadding,
              ),
            ),
            AppSpacing.gapXxl,
            PremiumButton(
              label: _isSubmitting ? 'Submitting...' : 'Submit Rating',
              onPressed: _isSubmitting ? null : _submitRating,
              isLoading: _isSubmitting,
            ),
            AppSpacing.gapMd,
            TextButton(
              onPressed: _skipRating,
              child: const Text(
                'Skip rating',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection() {
    final pickup = _ride?.pickupAddress ?? '';
    final dropoff = _ride?.dropoffAddress ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.pickupMarker,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 24,
                    color: AppColors.outline,
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.dropoffMarker,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      formatLatLng(
                          _ride?.pickupLatitude ?? 0, _ride?.pickupLongitude ?? 0),
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                    AppSpacing.gapLg,
                    Text(
                      dropoff,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      formatLatLng(
                          _ride?.dropoffLatitude ?? 0, _ride?.dropoffLongitude ?? 0),
                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPrice ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _skipRating() {
    recordEvent(
      eventName: 'SKIP_RATING',
      category: 'FRONTEND',
      summary: 'Rider skipped rating',
    );
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/rider-home',
      (route) => false,
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
