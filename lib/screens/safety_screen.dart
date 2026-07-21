import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSafetyCard(
            icon: Icons.share_location_outlined,
            title: 'Share My Trip',
            subtitle: 'Share your ride status with trusted contacts',
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
          _buildSafetyCard(
            icon: Icons.sos_outlined,
            title: 'SOS Emergency',
            subtitle: 'Quick access to emergency services',
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () {},
          ),
          _buildSafetyCard(
            icon: Icons.verified_user_outlined,
            title: 'Driver Verification',
            subtitle: 'Learn how we verify our drivers',
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () {},
          ),
          _buildSafetyCard(
            icon: Icons.contact_support_outlined,
            title: 'Safety Tips',
            subtitle: 'Guidelines for a safe ride experience',
            trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            onTap: () {},
          ),
          AppSpacing.gapXl,
          Container(
            padding: AppSpacing.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: AppRadius.mdRadius,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.warning, size: 24),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    'In case of emergency, call 911 or use the SOS button above.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.successContainer,
            borderRadius: AppRadius.smRadius,
          ),
          child: Icon(icon, color: AppColors.success),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
