import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

class CancelRideResult {
  final String reason;
  final bool confirmed;

  CancelRideResult({required this.reason, required this.confirmed});
}

Future<CancelRideResult?> showCancelRideDialog(BuildContext context,
    {String title = 'Cancel Ride?', String message = 'Are you sure you want to cancel this ride?'}) async {
  final reasonController = TextEditingController();
  final l10n = AppLocalizations.of(context);

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
              decoration: InputDecoration(
                hintText: l10n.reasonOptional,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'action': 'no'}),
            child: Text(l10n.no),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'action': 'yes',
                'reason': reasonController.text.trim(),
              });
            },
            child: Text(l10n.yesCancel, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (result == null || result['action'] != 'yes') return null;

    return CancelRideResult(
      confirmed: true,
      reason: result['reason'] ?? l10n.riderCancelledRide,
    );
  } finally {
    reasonController.dispose();
  }
}
