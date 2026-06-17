import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Core 4-color palette ──────────────────────────────────────────
  static const Color primary = Color(0xFF9DBB2D);
  static const Color primaryDark = Color(0xFF7A9424);
  static const Color primaryLight = Color(0xFFB8D460);

  static const Color secondary = Color(0xFF8F7CC0);
  static const Color secondaryLight = Color(0xFFB0A0D4);
  static const Color secondaryDark = Color(0xFF6B5699);

  static const Color accent = Color(0xFFD58E7D);
  static const Color accentLight = Color(0xFFE8C0B0);
  static const Color accentDark = Color(0xFFC07060);

  static const Color error = Color(0xFFC8101E);
  static const Color errorDark = Color(0xFFA00A14);
  static const Color errorLight = Color(0xFFE04040);

  // ── Neutral warm tones ───────────────────────────────────────────
  static const Color background = Color(0xFFFAF6F4);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5EDE8);
  static const Color outline = Color(0xFFE8DDD8);
  static const Color outlineVariant = Color(0xFFD6C8C0);

  // ── Text ─────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF2D1F1C);
  static const Color textSecondary = Color(0xFF7A6B66);
  static const Color textTertiary = Color(0xFFA89790);
  static const Color textOnPrimary = Color(0xFF2D1F1C);
  static const Color textOnDark = Colors.white;

  // ── Container / Surface variants ─────────────────────────────────
  static const Color primaryContainer = Color(0xFFF0F7E0);
  static const Color primaryContainerDark = Color(0xFF7A9424);
  static const Color secondaryContainer = Color(0xFFF0EBF8);
  static const Color accentContainer = Color(0xFFFFF0EB);

  // ── Semantic ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF9DBB2D);
  static const Color successContainer = Color(0xFFF0F7E0);
  static const Color warning = Color(0xFFE8943C);
  static const Color warningContainer = Color(0xFFFEF0E0);
  static const Color errorContainer = Color(0xFFFDEEEE);
  static const Color info = Color(0xFF8F7CC0);
  static const Color infoContainer = Color(0xFFF0EBF8);

  // ── Dark mode ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1A1423);
  static const Color darkSurface = Color(0xFF241D2E);
  static const Color darkSurfaceVariant = Color(0xFF322A3C);
  static const Color darkOutline = Color(0xFF4A4254);

  // ── Map-specific ─────────────────────────────────────────────────
  static const Color mapOverlay = Color(0x80000000);
  static const Color driverMarker = Color(0xFF8F7CC0);
  static const Color pickupMarker = Color(0xFF9DBB2D);
  static const Color dropoffMarker = Color(0xFFC8101E);
  static const Color mapRouteLine = Color(0xFF8F7CC0);

  // ── Gradient helpers ─────────────────────────────────────────────
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
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [accent, error],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF2D1F1C), Color(0xFF1A1423)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFF0EBF0),
      Color(0xFFF8F4F8),
      Color(0xFFF0EBF0),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Ride type colors ─────────────────────────────────────────────
  static const List<Color> rideTypeColors = [
    Color(0xFF9DBB2D), // Economy  – Green
    Color(0xFF8F7CC0), // Comfort  – Purple
    Color(0xFFD58E7D), // Luxury   – Peach
  ];

  // ── Avatar colors ────────────────────────────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFF9DBB2D),
    Color(0xFF8F7CC0),
    Color(0xFF9C27B0),
    Color(0xFFE8943C),
    Color(0xFFD58E7D),
    Color(0xFFC8101E),
    Color(0xFF00BCD4),
    Color(0xFF795548),
  ];
}
