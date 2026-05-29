import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary — Red premium theme
  static const Color primary = Color(0xFFE53935);
  static const Color primaryDark = Color(0xFFC62828);
  static const Color primaryLight = Color(0xFFEF5350);
  static const Color accent = Color(0xFFFF1744);

  // Secondary
  static const Color secondary = Color(0xFF212121);
  static const Color secondaryLight = Color(0xFF616161);

  // Neutral
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFEEEEEE);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // Container variants
  static const Color primaryContainer = Color(0xFFFFEBEE);
  static const Color primaryContainerDark = Color(0xFFC62828);

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFE3F2FD);

  // Dark
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
  static const Color darkOutline = Color(0xFF424242);

  // Gradient helpers
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientH = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF212121), Color(0xFF000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Colors.grey.shade200,
      Colors.grey.shade100,
      Colors.grey.shade200,
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  // Ride type colors
  static const List<Color> rideTypeColors = [
    Color(0xFFE53935),
    Color(0xFF212121),
    Color(0xFF616161),
    Color(0xFFFFC107),
  ];
}
