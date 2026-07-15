import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class PaymentMethodsScreen extends StatefulWidget {
  final String token;
  const PaymentMethodsScreen({super.key, required this.token});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [
    {'type': 'Wallet', 'balance': '\$45.20', 'icon': Icons.account_balance_wallet_outlined, 'selected': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._methods.map((m) => _buildMethodCard(m)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your payment information is stored securely. We use token-based storage and never save full card details.',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(Map<String, dynamic> method) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(method['icon'] as IconData, color: AppColors.primary),
        ),
        title: Text(method['type'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(method['balance'] as String, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: method['selected'] == true
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.radio_button_unchecked, color: AppColors.textTertiary),
                onPressed: () {},
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}
