import 'package:flutter/material.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';
import '../screens/chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/premium_button.dart';

class RiderRideCompletedScreen extends StatefulWidget {
  final int rideId;
  final double? totalFare;
  final double? distance;
  final int? duration;

  const RiderRideCompletedScreen({
    super.key,
    required this.rideId,
    this.totalFare,
    this.distance,
    this.duration,
  });

  @override
  State<RiderRideCompletedScreen> createState() =>
      _RiderRideCompletedScreenState();
}

class _RiderRideCompletedScreenState extends State<RiderRideCompletedScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    addDebugMessage('═══════════════════════════════════════');
    addDebugMessage('✅ RIDE COMPLETED');
    addDebugMessage('Ride ID: ${widget.rideId}');
    addDebugMessage('═══════════════════════════════════════');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary),
            tooltip: 'Chat with Driver',
            onPressed: _openChat,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.xxxl + AppSpacing.giant, AppSpacing.xxl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
            AppSpacing.gapXxl,
            const Text(
              'Trip Completed!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXxxl,
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                side: const BorderSide(color: AppColors.outline),
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Distance',
                      '${widget.distance?.toStringAsFixed(2) ?? '0.00'} km',
                    ),
                    const Divider(height: 1, color: AppColors.outline),
                    _buildSummaryRow(
                      'Duration',
                      '${widget.duration ?? 0} min',
                    ),
                    const Divider(height: 1, color: AppColors.outline),
                    _buildSummaryRow(
                      'Total Fare',
                      '\$${widget.totalFare?.toStringAsFixed(2) ?? '0.00'}',
                      isPrice: true,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.gapXxxl,
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
            Row(
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
            AppSpacing.gapXxl,
            const Align(
              alignment: Alignment.centerLeft,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.lg),
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
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/rider-home',
      (route) => false,
    );
  }

  Future<void> _openChat() async {
    final token = StorageService.getToken();
    final currentUserId = StorageService.getUserId();
    final currentUsername = StorageService.getUsername();
    if (token == null || currentUserId == null || currentUsername == null) return;

    try {
      final ride = await RideService.getRideDetails(widget.rideId, token);
      if (ride == null || ride.driver == null || ride.driver!.id == null) return;

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              currentUserId: currentUserId,
              currentUsername: currentUsername,
              receiverId: ride.driver!.id!,
              receiverName: ride.driver!.fullName,
              token: token,
            ),
          ),
        );
      }
    } catch (e) {
      addDebugMessage('❌ Chat error: $e');
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
