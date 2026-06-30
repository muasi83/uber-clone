import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ReceivedPaymentResult {
  final bool received;
  final String? reason;

  ReceivedPaymentResult({required this.received, this.reason});
}

Future<ReceivedPaymentResult?> showReceivedPaymentDialog(
  BuildContext context, {
  required double amount,
}) async {
  final reasonController = TextEditingController();

  try {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.payments, size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            const Text('Payment Received?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Did you receive this payment?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (required if No)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, {'received': false, 'reason': reason});
            },
            child: const Text("No, I didn't", style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, {'received': true}),
            child: const Text('Yes, Received'),
          ),
        ],
      ),
    );

    if (result == null) return null;
    return ReceivedPaymentResult(
      received: result['received'] as bool,
      reason: result['reason'] as String?,
    );
  } finally {
    reasonController.dispose();
  }
}
