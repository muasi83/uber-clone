import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';

class PaymentDialogResult {
  final bool confirmed;
  final String? reason;

  PaymentDialogResult({required this.confirmed, this.reason});
}

Future<PaymentDialogResult?> showPaymentDialog(
  BuildContext context, {
  required double amount,
  String title = 'Payment',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          Icon(Icons.account_balance_wallet, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Your trip has been completed.'),
          const SizedBox(height: 16),
          Text(
            CurrencyService.format(amount),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Total Fare',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Pay Now'),
        ),
      ],
    ),
  );

  if (result == null || !result) return null;
  return PaymentDialogResult(confirmed: true);
}
