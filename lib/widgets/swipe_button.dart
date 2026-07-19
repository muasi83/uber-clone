import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class SwipeButton extends StatefulWidget {
  final String label;
  final String? processingLabel;
  final VoidCallback? onConfirmed;
  final bool isDisabled;
  final IconData icon;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;

  const SwipeButton({
    super.key,
    required this.label,
    this.processingLabel,
    this.onConfirmed,
    this.isDisabled = false,
    this.icon = Icons.arrow_forward_ios,
    this.backgroundColor,
    this.height = 56,
    this.borderRadius = 16,
  });

  @override
  State<SwipeButton> createState() => _SwipeButtonState();
}

class _SwipeButtonState extends State<SwipeButton> {
  double _dragPercent = 0.0;
  bool _isCompleted = false;
  bool _isProcessing = false;
  bool _isDragging = false;

  static const double _thumbSize = 44.0;
  static const double _thumbMargin = 2.0;
  static const double _threshold = 0.75;

  @override
  void didUpdateWidget(SwipeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDisabled && !widget.isDisabled && _isCompleted) {
      _reset();
    }
  }

  bool get _interactive =>
      widget.onConfirmed != null && !widget.isDisabled && !_isCompleted;

  bool get _showActive =>
      widget.onConfirmed != null && !widget.isDisabled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - _thumbSize - _thumbMargin * 2;
        final Color baseColor = widget.backgroundColor ?? AppColors.primary;
        final Color fillColor = baseColor.withValues(alpha: 0.85);

        return GestureDetector(
          onHorizontalDragStart: _interactive
              ? (_) {
                  HapticFeedback.lightImpact();
                  setState(() => _isDragging = true);
                }
              : null,
          onHorizontalDragUpdate: _interactive
              ? (details) {
                  setState(() {
                    _dragPercent =
                        (_dragPercent + details.delta.dx / maxDrag).clamp(0.0, 1.0);
                  });
                }
              : null,
          onHorizontalDragEnd: _interactive
              ? (_) {
                  _isDragging = false;
                  if (_dragPercent >= _threshold) {
                    _confirm();
                  } else {
                    setState(() => _dragPercent = 0.0);
                  }
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: widget.height,
            decoration: BoxDecoration(
              color: _showActive ? baseColor : AppColors.outline,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AnimatedFractionallySizedBox(
                  duration: Duration(milliseconds: _isDragging ? 0 : 300),
                  curve: Curves.easeOut,
                  alignment: Alignment.centerLeft,
                  widthFactor: _showActive ? _dragPercent : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    _isProcessing
                        ? (widget.processingLabel ?? widget.label)
                        : widget.label,
                    style: TextStyle(
                      color: _showActive
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: Duration(milliseconds: _isDragging ? 0 : 300),
                  curve: Curves.easeOut,
                  left: _thumbLeft(constraints.maxWidth),
                  top: (widget.height - _thumbSize) / 2,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: _showActive
                          ? Colors.white
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(_thumbSize / 2),
                      boxShadow: _showActive
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _isProcessing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: baseColor,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              size: 18,
                              color: _showActive ? baseColor : AppColors.textTertiary,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _thumbLeft(double totalWidth) {
    if (_isCompleted) return totalWidth - _thumbSize - _thumbMargin;
    return _thumbMargin +
        _dragPercent * (totalWidth - _thumbSize - _thumbMargin * 2);
  }

  void _confirm() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isCompleted = true;
      _isProcessing = true;
      _dragPercent = 1.0;
    });
    widget.onConfirmed?.call();
  }

  void _reset() {
    setState(() {
      _isCompleted = false;
      _isProcessing = false;
      _dragPercent = 0.0;
    });
  }
}
