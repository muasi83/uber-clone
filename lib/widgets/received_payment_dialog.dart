import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/currency_service.dart';
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
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Icon(Icons.payments, size: 48, color: AppColors.success),
            const SizedBox(height: 12),
            Text(l10n.paymentReceived, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyService.format(amount),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.didYouReceiveThisPayment),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: l10n.reasonRequiredIfNo,
                border: const OutlineInputBorder(),
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
                  SnackBar(
                    content: Text(l10n.pleaseProvideAReason),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, {'received': false, 'reason': reason});
            },
            child: Text(l10n.noIDidnt, style: const TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, {'received': true}),
            child: Text(l10n.yesReceived),
          ),
        ],
      );
      },
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
