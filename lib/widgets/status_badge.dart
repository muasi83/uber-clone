import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final bool isAnimated;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.isAnimated = false,
  });

  factory StatusBadge.online() {
    return const StatusBadge(
      label: 'Online',
      color: AppColors.success,
      icon: Icons.check_circle,
    );
  }

  factory StatusBadge.offline() {
    return const StatusBadge(
      label: 'Offline',
      color: AppColors.textTertiary,
      icon: Icons.circle,
    );
  }

  factory StatusBadge.confirmed() {
    return const StatusBadge(
      label: 'Confirmed',
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  factory StatusBadge.pending() {
    return const StatusBadge(
      label: 'Pending',
      color: AppColors.warning,
      icon: Icons.schedule,
    );
  }

  factory StatusBadge.arriving() {
    return const StatusBadge(
      label: 'Arriving',
      color: AppColors.info,
      icon: Icons.navigation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: (color ?? AppColors.success).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: (color ?? AppColors.success).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color ?? AppColors.success),
            AppSpacing.hGapXs,
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
