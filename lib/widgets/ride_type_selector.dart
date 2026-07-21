import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../services/currency_service.dart';
import '../theme/app_spacing.dart';

enum RideTypeSelectorVariant { card, chip }

class RideTypeSelector extends StatelessWidget {
  final List<RideType> rideTypes;
  final String selectedApiName;
  final ValueChanged<String> onChanged;
  final RideTypeSelectorVariant variant;
  final double? distanceKm;

  const RideTypeSelector({
    super.key,
    required this.rideTypes,
    required this.selectedApiName,
    required this.onChanged,
    this.variant = RideTypeSelectorVariant.card,
    this.distanceKm,
  });

  static String toApiName(String displayName) =>
      displayName.toUpperCase().replaceAll(' ', '_');

  static String toDisplayName(String apiName) {
    if (apiName.isEmpty) return apiName;
    final parts = apiName.split('_');
    return parts.map((p) => p[0] + p.substring(1).toLowerCase()).join(' ');
  }

  static double calculateFare(
    List<RideType> types, String apiName, double distanceKm,
  ) {
    for (final rt in types) {
      if (toApiName(rt.name) == apiName) {
        return rt.baseFare + distanceKm * rt.perKmRate;
      }
    }
    return 2.0 + distanceKm * 0.20;
  }

  static double getRatePerKm(List<RideType> types, String apiName) {
    for (final rt in types) {
      if (toApiName(rt.name) == apiName) {
        return rt.perKmRate;
      }
    }
    return 0.20;
  }

  static List<String> apiNames(List<RideType> types) =>
      types.map((rt) => toApiName(rt.name)).toList();

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      RideTypeSelectorVariant.card => _buildCardList(),
      RideTypeSelectorVariant.chip => _buildChipRow(),
    };
  }

  Widget _buildCardList() {
    return Column(
      children: rideTypes.map((rt) {
        final apiName = toApiName(rt.name);
        final isSelected = selectedApiName == apiName;
        final fare = distanceKm != null
            ? rt.baseFare + distanceKm! * rt.perKmRate
            : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GestureDetector(
            onTap: () => onChanged(apiName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : AppColors.surfaceVariant,
                borderRadius: AppRadius.mdRadius,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppShadows.medium : [],
              ),
              child: Padding(
                padding: AppSpacing.cardPadding,
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: AppRadius.mdRadius,
                      ),
                      child: Center(
                        child: Text(
                          rt.icon,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    AppSpacing.hGapLg,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rt.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rt.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${rt.perKmRate.toStringAsFixed(2)}/km',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (fare != null)
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                            child: Text(CurrencyService.format(fare)),
                          ),
                      ],
                    ),
                    if (isSelected) ...[
                      AppSpacing.hGapSm,
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.primaryLight,
                          size: 16,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipRow() {
    return Row(
      children: rideTypes.map((rt) {
        final apiName = toApiName(rt.name);
        final isSelected = selectedApiName == apiName;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => onChanged(apiName),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
                horizontal: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: AppRadius.smRadius,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.outline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rt.icon,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? AppColors.primaryLight : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    rt.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${rt.perKmRate.toStringAsFixed(2)}/km',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primaryLight.withValues(alpha: 0.8)
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
