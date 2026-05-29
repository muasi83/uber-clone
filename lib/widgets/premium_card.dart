import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final EdgeInsets? margin;
  final bool hasRipple;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius,
    this.shadows,
    this.color,
    this.gradient,
    this.border,
    this.margin,
    this.hasRipple = true,
  });

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        border: border,
        boxShadow: shadows ?? AppSpacing.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius ?? 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
          splashColor: hasRipple
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          highlightColor: hasRipple
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          child: Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return card;
    }
    return card;
  }
}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const PressableCard({
    super.key,
    required this.child,
    required this.onTap,
    this.padding,
    this.borderRadius,
  });

  @override
  State<PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<PressableCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: PremiumCard(
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          child: widget.child,
        ),
      ),
    );
  }
}
