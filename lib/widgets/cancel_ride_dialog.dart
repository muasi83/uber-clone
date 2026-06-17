import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CancelRideResult {
  final String reason;
  final bool confirmed;

  CancelRideResult({required this.reason, required this.confirmed});
}

Future<CancelRideResult?> showCancelRideDialog(BuildContext context,
    {String title = 'Cancel Ride?', String message = 'Are you sure you want to cancel this ride?'}) async {
  final reasonController = TextEditingController();

  try {
    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'action': 'no'}),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'action': 'yes',
                'reason': reasonController.text.trim(),
              });
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == null || result['action'] != 'yes') return null;

    return CancelRideResult(
      confirmed: true,
      reason: result['reason'] ?? 'Rider cancelled ride',
    );
  } finally {
    reasonController.dispose();
  }
}
