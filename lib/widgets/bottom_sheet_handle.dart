import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomSheetHandle extends StatelessWidget {
  final Color? color;

  const BottomSheetHandle({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: color ?? AppColors.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
