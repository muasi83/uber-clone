import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Palette ─────────────────────────────────────────────────
  static const Color primary = Color(0xFF0E9F6E);
  static const Color primaryDark = Color(0xFF0B7D55);
  static const Color primaryLight = Color(0xFF34D399);

  static const Color dark = Color(0xFF1B1F24);
  static const Color darkLight = Color(0xFF2D3238);

  static const Color accent = Color(0xFFF5B942);
  static const Color accentDark = Color(0xFFD49A2E);
  static const Color accentLight = Color(0xFFFCD68A);

  static const Color brandSecondary = Color(0xFF8F7CC0);
  static const Color brandSecondaryLight = Color(0xFFB0A0D4);
  static const Color brandSecondaryDark = Color(0xFF6B5699);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF8F7CC0);
  static const Color infoContainer = Color(0xFFF0EBF8);

  // ── Neutrals ──────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color outline = Color(0xFFDEE2E6);
  static const Color outlineVariant = Color(0xFFCED4DA);

  // ── Text ──────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1B1F24);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnDark = Colors.white;

  // ── Dark Mode ─────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1B1F24);
  static const Color darkSurface = Color(0xFF2D3238);
  static const Color darkSurfaceVariant = Color(0xFF3D434A);
  static const Color darkOutline = Color(0xFF4D535A);

  // ── Map ───────────────────────────────────────────────────────────
  static const Color mapOverlay = Color(0x80000000);
  static const Color driverMarker = Color(0xFF8F7CC0);
  static const Color pickupMarker = Color(0xFF0E9F6E);
  static const Color dropoffMarker = Color(0xFFEF4444);
  static const Color mapRouteLine = Color(0xFF8F7CC0);

  // ── Ride Types ────────────────────────────────────────────────────
  static const List<Color> rideTypeColors = [
    Color(0xFF0E9F6E), // Economy  – Emerald
    Color(0xFF8F7CC0), // Comfort  – Purple
    Color(0xFFF5B942), // Luxury   – Gold
  ];

  // ── Avatar Colors ─────────────────────────────────────────────────
  static const List<Color> avatarColors = [
    Color(0xFF0E9F6E),
    Color(0xFF8F7CC0),
    Color(0xFF9C27B0),
    Color(0xFFF59E0B),
    Color(0xFFF5B942),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
    Color(0xFF795548),
  ];

  // ── Backward-compat aliases ───────────────────────────────────────
  static const Color primaryContainer = Color(0xFFD1FAE5);
  static const Color secondary = brandSecondary;
  static const Color secondaryLight = brandSecondaryLight;
  static const Color accentContainer = Color(0xFFFEF3C7);

  // ── Gradients ─────────────────────────────────────────────────────
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

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1B1F24), Color(0xFF121417)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [
      Color(0xFFF1F3F5),
      Color(0xFFF8F9FA),
      Color(0xFFF1F3F5),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
