import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final ButtonVariant variant;
  final double height;
  final double borderRadius;
  final double? width;

  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.height = 56,
    this.borderRadius = 16,
    this.width,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isDisabled;

  Color get _bgColor {
    if (!_enabled) return Colors.grey.shade300;
    switch (widget.variant) {
      case ButtonVariant.primary:
        return AppColors.primary;
      case ButtonVariant.secondary:
        return AppColors.secondary;
      case ButtonVariant.gradient:
        return AppColors.primary;
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.text:
        return Colors.transparent;
      case ButtonVariant.success:
        return AppColors.success;
      case ButtonVariant.danger:
        return AppColors.error;
    }
  }

  Color get _fgColor {
    if (!_enabled) return Colors.grey;
    switch (widget.variant) {
      case ButtonVariant.outline:
      case ButtonVariant.text:
        return AppColors.primary;
      default:
        return Colors.white;
    }
  }

  BoxBorder? get _border {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(
        color: AppColors.primary.withValues(alpha: 0.3),
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow> get _shadow {
    if (!_enabled || widget.variant == ButtonVariant.text) return [];
    return [
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.35),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.15),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? () => setState(() => _isPressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: _border,
            boxShadow: _isPressed ? [] : _shadow,
            gradient: widget.variant == ButtonVariant.gradient && _enabled
                ? AppColors.primaryGradient
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_fgColor),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: _fgColor, size: 20),
                  AppSpacing.hGapSm,
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _fgColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return child;
  }
}

enum ButtonVariant { primary, secondary, gradient, outline, text, success, danger }
