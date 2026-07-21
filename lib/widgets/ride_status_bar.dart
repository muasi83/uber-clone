import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class RideStatusBar extends StatelessWidget {
  final String status;
  final String? subtitle;
  final Color? statusColor;
  final IconData? icon;
  final bool showPulse;

  const RideStatusBar({
    super.key,
    required this.status,
    this.subtitle,
    this.statusColor,
    this.icon,
    this.showPulse = false,
  });

  Color get _color => statusColor ?? AppColors.info;

  IconData get _icon => icon ?? Icons.info_outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: _color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          if (showPulse)
            SizedBox(
              width: 24,
              height: 24,
              child: _PulsingIcon(color: _color),
            )
          else
            Icon(_icon, size: 20, color: _color),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _color,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _color.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final Color color;

  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
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
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value * 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.navigation,
            size: 14,
            color: widget.color,
          ),
        );
      },
    );
  }
}
