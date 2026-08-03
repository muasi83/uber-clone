import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DriverVerificationInfo {
  final String label;
  final Color color;
  final IconData icon;

  const DriverVerificationInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

DriverVerificationInfo driverVerificationInfo(String? status) {
  return switch (status) {
    'APPROVED' => const DriverVerificationInfo(
        label: 'Approved',
        color: AppColors.success,
        icon: Icons.verified,
      ),
    'PENDING' => const DriverVerificationInfo(
        label: 'Pending Review',
        color: AppColors.warning,
        icon: Icons.schedule,
      ),
    'REJECTED' => const DriverVerificationInfo(
        label: 'Rejected',
        color: AppColors.error,
        icon: Icons.cancel_outlined,
      ),
    _ => const DriverVerificationInfo(
        label: 'Draft',
        color: AppColors.textTertiary,
        icon: Icons.edit_outlined,
      ),
  };
}
