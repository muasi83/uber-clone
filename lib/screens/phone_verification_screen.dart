import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyYourPhone), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone_android_outlined, size: 80, color: AppColors.primary),
            AppSpacing.gapXl,
            Text(
              l10n.verifyYourPhone,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            AppSpacing.gapMd,
            const Text(
              'Enter the 6-digit code sent to your phone number',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            AppSpacing.gapXl,
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: AppColors.textTertiary),
                border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w600),
            ),
            AppSpacing.gapXl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
                ),
                child: Text(l10n.verify, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            AppSpacing.gapMd,
            TextButton(
              onPressed: () {},
              child: Text(l10n.resendCode, style: const TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
