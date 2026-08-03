import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class DocumentStatusInfo {
  final String label;
  final Color color;
  final IconData icon;

  const DocumentStatusInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}

DocumentStatusInfo documentStatusInfo(String? status) {
  return switch (status) {
    'APPROVED' => const DocumentStatusInfo(
        label: 'Approved',
        color: AppColors.success,
        icon: Icons.check_circle,
      ),
    'PENDING' => const DocumentStatusInfo(
        label: 'Pending Review',
        color: AppColors.warning,
        icon: Icons.schedule,
      ),
    'REUPLOAD_REQUESTED' => const DocumentStatusInfo(
        label: 'Re-upload Requested',
        color: AppColors.info,
        icon: Icons.autorenew,
      ),
    'REJECTED' => const DocumentStatusInfo(
        label: 'Rejected',
        color: AppColors.error,
        icon: Icons.cancel,
      ),
    'EXPIRED' => const DocumentStatusInfo(
        label: 'Expired',
        color: AppColors.errorDark,
        icon: Icons.event_busy,
      ),
    _ => const DocumentStatusInfo(
        label: 'Unknown',
        color: AppColors.textTertiary,
        icon: Icons.help_outline,
      ),
  };
}

/// Consistent expiry-urgency color for a document expiry date.
///
/// Returns errorDark for expired, warning when within [soonDays] days,
/// and tertiary (neutral) otherwise. A null/unparsable date is neutral.
Color documentExpiryColor(DateTime? expiry, {DateTime? now, int soonDays = 31}) {
  if (expiry == null) return AppColors.textTertiary;
  final today = now ?? DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);
  final expiryStart = DateTime(expiry.year, expiry.month, expiry.day);
  if (!expiryStart.isAfter(todayStart)) return AppColors.errorDark;
  final soonLimit = todayStart.add(Duration(days: soonDays));
  if (expiryStart.isBefore(soonLimit)) return AppColors.warning;
  return AppColors.textTertiary;
}
