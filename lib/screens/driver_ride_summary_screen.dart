import 'package:flutter/material.dart';
import '../models/ride_model.dart';
import '../services/currency_service.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../widgets/premium_button.dart';
import '../services/recorded_screen_mixin.dart';
import '../utils/address_utils.dart';

class DriverRideSummaryScreen extends StatefulWidget {
  final int rideId;

  const DriverRideSummaryScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<DriverRideSummaryScreen> createState() =>
      _DriverRideSummaryScreenState();
}

class _DriverRideSummaryScreenState extends State<DriverRideSummaryScreen> with RecordedScreenMixin<DriverRideSummaryScreen> {
  Ride? _ride;
  bool _isLoading = true;
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  bool _ratingSubmitted = false;

  @override
  void initState() {
    super.initState();
    recordEvent(
      eventName: 'EARNINGS_VIEWED',
      category: 'FRONTEND',
      summary: 'Driver viewed earnings summary',
    );
    _loadRideDetails();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('💰 EARNINGS SUMMARY');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
  }

  Future<void> _loadRideDetails() async {
    try {
      final token = StorageService.getToken();
      if (token == null) return;
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (mounted) {
        setState(() {
          _ride = ride;
          _isLoading = false;
        });
      }
    } catch (e) {
      addDebugMessage('❌ Error loading ride details: $e');
      if (mounted) setState(() => _isLoading = false);
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
      if (token == null) return;

      addDebugMessage('⭐ Submitting rating (driver->rider): $_rating');

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
        summary: 'Driver submitted rating for rider',
      );
      if (mounted) {
        setState(() => _ratingSubmitted = true);
      }
    } catch (e) {
      addDebugMessage('❌ Error submitting rating: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
        title: const Text(
          'Ride Summary',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppSpacing.gapXxl,
            Semantics(
              label: 'Ride completed successfully',
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successContainer,
                ),
                child: const Icon(
                  Icons.check,
                  size: 56,
                  color: AppColors.success,
                ),
              ),
            ),
            AppSpacing.gapXxl,
            const Text(
              'Ride Complete!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXxl,
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Container(
              width: double.infinity,
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.medium,
              ),
              child: Column(
                children: [
                  _buildAddressSection(),
                  const Divider(color: AppColors.outline),
                  _buildDetailRow('Distance', '${_ride?.estimatedDistance?.toStringAsFixed(1) ?? '0.0'} km'),
                  const Divider(color: AppColors.outline),
                  _buildDetailRow('Duration', '${_ride?.estimatedDuration ?? 0} minutes'),
                  const Divider(color: AppColors.outline),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          CurrencyService.format(_ride?.finalFare ?? _ride?.estimatedFare ?? 0),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.outline),
                  _buildDetailRow('Payment', 'PENDING'),
                  const Divider(color: AppColors.outline),
                  _buildDetailRow('Your Earnings', 
                    CurrencyService.format((_ride?.finalFare ?? _ride?.estimatedFare ?? 0) * 0.85),
                  ),
                  _buildDetailRow('Platform Fee', 
                    CurrencyService.format((_ride?.finalFare ?? _ride?.estimatedFare ?? 0) * 0.15),
                  ),
                ],
              ),
            ),
            AppSpacing.gapXxl,
            if (!_ratingSubmitted) ...[
              const Text(
                'Rate your rider',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.gapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setState(() => _rating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        i < _rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              AppSpacing.gapMd,
              TextField(
                controller: _feedbackController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Additional feedback (optional)',
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.md),
                ),
              ),
              AppSpacing.gapXxl,
              PremiumButton(
                label: _isSubmitting ? 'Submitting...' : 'Submit Rating',
                onPressed: _isSubmitting ? null : _submitRating,
                isLoading: _isSubmitting,
              ),
              AppSpacing.gapMd,
            ],
            if (_ratingSubmitted)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Rating submitted — thank you!',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            PremiumButton(
              label: 'Back to Home',
              onPressed: () {
                recordEvent(
                  eventName: 'BACK_TO_HOME',
                  category: 'FRONTEND',
                  summary: 'Driver navigated back to home',
                );
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/driver-home',
                  (route) => false,
                );
              },
              icon: Icons.home_outlined,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.pickupMarker,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2, height: 24,
                color: AppColors.outline,
              ),
              Container(
                width: 10, height: 10,
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
