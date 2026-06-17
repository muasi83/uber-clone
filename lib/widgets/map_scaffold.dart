import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'bottom_sheet_handle.dart';

class MapScaffold extends StatelessWidget {
  final Widget map;
  final Widget? bottomSheet;
  final Widget? floatingActionButton;
  final Widget? appBar;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;

  const MapScaffold({
    super.key,
    required this.map,
    this.bottomSheet,
    this.floatingActionButton,
    this.appBar,
    this.extendBodyBehindAppBar = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar != null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: Stack(
        children: [
          map,
          if (bottomSheet != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: bottomSheet!,
            ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class MapBottomSheet extends StatelessWidget {
  final Widget child;
  final bool useDraggableScrollable;

  const MapBottomSheet({
    super.key,
    required this.child,
    this.useDraggableScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useDraggableScrollable) {
      return DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.bottomSheetTopRadius),
              ),
              boxShadow: AppSpacing.shadowXl,
            ),
            child: Column(
              children: [
                const BottomSheetHandle(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.bottomSheetTopRadius),
        ),
        boxShadow: AppSpacing.shadowXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
