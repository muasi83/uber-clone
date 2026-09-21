import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../services/photo_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../utils/driver_card_data.dart';
import 'user_avatar.dart';

/// Shared rider-facing driver/vehicle card shown after a driver accepts.
///
/// Display-only: renders ETA header, driver photo/name/rating, vehicle
/// photo, plate pill, and Chat (working) + Call (disabled visual
/// placeholder) actions from already-available [DriverCardData].
/// No location, polling, navigation, or call logic lives here.
class DriverArrivingCard extends StatelessWidget {
  const DriverArrivingCard({
    super.key,
    required this.cardData,
    required this.etaText,
    required this.onChat,
    required this.unreadCount,
    this.onCall,
  });

  final DriverCardData cardData;
  final String etaText;
  final VoidCallback onChat;
  final int unreadCount;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final driverName = cardData.name ?? 'Driver';
    final vehicleLine = [
      if (cardData.vehicleColor != null) cardData.vehicleColor!,
      if (cardData.vehicleModel != null) cardData.vehicleModel!,
    ].join(' · ');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar: centered, subtle, with top padding so it never sticks.
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Header row: live ETA title.
        Text(
          etaText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(
                  photoUrl: PhotoService.resolvePhotoUrl(cardData.photoUrl),
                  displayName: driverName,
                  radius: 28,
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (cardData.vehicleNumber != null &&
                      cardData.vehicleNumber!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        cardData.vehicleNumber!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (vehicleLine.isNotEmpty) ...[
                    AppSpacing.gapXs,
                    Text(
                      vehicleLine,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  AppSpacing.gapXs,
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          driverName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (cardData.rating != null)
                        Text(
                          '  ★ ${cardData.rating!.toStringAsFixed(1)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            AppSpacing.hGapMd,
            _vehicleThumbnail(context, 72),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Semantics(
                    button: true,
                    label: 'Chat with driver',
                    child: InkWell(
                      onTap: onChat,
                      borderRadius: BorderRadius.circular(26),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Any pickup notes?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              button: true,
              label: 'Call driver',
              child: InkWell(
                onTap: onCall,
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vehicleThumbnail(BuildContext context, double size) {
    final url = PhotoService.resolvePhotoUrl(cardData.vehiclePhotoUrl);
    if (url == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(
          Icons.directions_car_rounded,
          color: AppColors.textTertiary,
          size: size * 0.55,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: AppColors.surfaceVariant,
            child: Icon(
              Icons.directions_car_rounded,
              color: AppColors.textTertiary,
              size: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}
