import 'package:flutter/material.dart';
import '../services/ride_service.dart';
import '../services/storage_service.dart';
import '../screens/debug_screen.dart';

class RiderRideCompletedScreen extends StatefulWidget {
  final int rideId;
  final double? totalFare;
  final double? distance;
  final int? duration;

  const RiderRideCompletedScreen({
    Key? key,
    required this.rideId,
    this.totalFare,
    this.distance,
    this.duration,
  }) : super(key: key);

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
          backgroundColor: Colors.orange,
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
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.green,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Success icon
            Center(
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Trip Completed!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Trip summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Distance',
                      '${widget.distance?.toStringAsFixed(2) ?? '0.00'} km',
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Duration',
                      '${widget.duration ?? 0} minutes',
                    ),
                    const Divider(),
                    _buildSummaryRow(
                      'Total Fare',
                      '\$${widget.totalFare?.toStringAsFixed(2) ?? '0.00'}',
                      isPrice: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            Text(
              'Rate your driver',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Feedback
            Text(
              'Additional Feedback (Optional)',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Rating',
                  style: TextStyle(
                    color: _isSubmitting ? Colors.grey : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isPrice ? const Color(0xFF6366F1) : Colors.black,
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