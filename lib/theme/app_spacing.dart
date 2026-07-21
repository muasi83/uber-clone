import 'package:flutter/material.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

class AppSpacing {
  AppSpacing._();

  // Base unit: 4px scale — only 4, 8, 12, 16, 24, 32, 48
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Standardized padding
  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets screenPaddingH = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets screenPaddingV = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(md);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    vertical: 14,
    horizontal: xl,
  );

  // Standardized gaps
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);
  static const SizedBox gapMd = SizedBox(height: md, width: md);
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
  static const SizedBox gapXxl = SizedBox(height: xxl, width: xxl);
  static const SizedBox gapXxxl = SizedBox(height: xxxl, width: xxxl);

  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
  static const SizedBox hGapXl = SizedBox(width: xl);
  static const SizedBox hGapXxl = SizedBox(width: xxl);

  // ── Backward-compat radius aliases ────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = AppRadius.sm;
  static const double radiusMd = AppRadius.md;
  static const double radiusLg = AppRadius.lg;
  static const double radiusXl = AppRadius.xl;
  static const double radiusXxl = AppRadius.xl;
  static const double radiusFull = 1000;
  static const double bottomSheetTopRadius = AppRadius.sheet;
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 6,
  );

  // ── Backward-compat shadow aliases ────────────────────────────────
  static List<BoxShadow> get shadowSm => AppShadows.small;
  static List<BoxShadow> get shadowMd => AppShadows.medium;
  static List<BoxShadow> get shadowLg => AppShadows.large;
  static List<BoxShadow> get shadowXl => AppShadows.large;

  // ── Backward-compat spacing aliases ───────────────────────────────
  static const SizedBox gapHuge = SizedBox(height: xxxl, width: xxxl);
  static const double giant = xxxl;
  static const double colossal = xxxl;

  // Layout
  static const double maxContentWidth = 400;
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double mapMinHeight = 250;
  static const double driverCardHeight = 120;
}
