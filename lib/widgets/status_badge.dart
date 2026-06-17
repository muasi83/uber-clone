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
      isAnimated: true,
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
      isAnimated: true,
    );
  }

  factory StatusBadge.active() {
    return const StatusBadge(
      label: 'Active',
      color: AppColors.primary,
      icon: Icons.play_circle_outline,
      isAnimated: true,
    );
  }

  factory StatusBadge.completed() {
    return const StatusBadge(
      label: 'Completed',
      color: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  factory StatusBadge.cancelled() {
    return const StatusBadge(
      label: 'Cancelled',
      color: AppColors.error,
      icon: Icons.cancel_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.success;

    if (isAnimated) {
      return _AnimatedBadge(
        label: label,
        color: badgeColor,
        icon: icon,
      );
    }

    return _StaticBadge(
      label: label,
      color: badgeColor,
      icon: icon,
    );
  }
}

class _StaticBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StaticBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.chipPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            AppSpacing.hGapXs,
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBadge extends StatefulWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _AnimatedBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  State<_AnimatedBadge> createState() => _AnimatedBadgeState();
}

class _AnimatedBadgeState extends State<_AnimatedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: AppSpacing.chipPadding,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1 * _pulseAnimation.value),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: widget.color),
                AppSpacing.hGapXs,
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
