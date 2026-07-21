import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DriverInfoCard extends StatelessWidget {
  final String driverName;
  final double? rating;
  final String? vehicleInfo;
  final String? licensePlate;
  final VoidCallback? onChatTap;
  final int unreadCount;

  const DriverInfoCard({
    super.key,
    required this.driverName,
    this.rating,
    this.vehicleInfo,
    this.licensePlate,
    this.onChatTap,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              driverName.isNotEmpty ? driverName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                driverName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (vehicleInfo != null) ...[
                const SizedBox(height: 2),
                Text(
                  vehicleInfo!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (rating != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating!.round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: AppColors.warning,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        if (onChatTap != null)
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onChatTap,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(10),
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
