import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // Font sizes
  static const double displayLarge = 32;
  static const double displayMedium = 28;
  static const double headlineLarge = 24;
  static const double headlineMedium = 20;
  static const double titleLarge = 18;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 10;

  // Font weights
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight regular = FontWeight.w400;

  // Line heights
  static const double tight = 1.2;
  static const double normal = 1.4;
  static const double relaxed = 1.6;

  // Letter spacing
  static const double tightSpacing = -0.3;
  static const double normalSpacing = 0.0;
  static const double wideSpacing = 0.5;

  static TextTheme get textTheme => GoogleFonts.getTextTheme(
        'Space Grotesk',
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: displayLarge,
            fontWeight: bold,
            letterSpacing: tightSpacing,
            height: tight,
          ),
          displayMedium: TextStyle(
            fontSize: displayMedium,
            fontWeight: bold,
            letterSpacing: tightSpacing,
            height: tight,
          ),
          headlineLarge: TextStyle(
            fontSize: headlineLarge,
            fontWeight: semiBold,
            letterSpacing: normalSpacing,
            height: tight,
          ),
          headlineMedium: TextStyle(
            fontSize: headlineMedium,
            fontWeight: semiBold,
            letterSpacing: normalSpacing,
            height: tight,
          ),
          titleLarge: TextStyle(
            fontSize: titleLarge,
            fontWeight: semiBold,
            letterSpacing: normalSpacing,
            height: normal,
          ),
          titleMedium: TextStyle(
            fontSize: titleMedium,
            fontWeight: medium,
            letterSpacing: normalSpacing,
            height: normal,
          ),
          titleSmall: TextStyle(
            fontSize: titleSmall,
            fontWeight: medium,
            letterSpacing: normalSpacing,
            height: normal,
          ),
          bodyLarge: TextStyle(
            fontSize: bodyLarge,
            fontWeight: regular,
            letterSpacing: normalSpacing,
            height: relaxed,
          ),
          bodyMedium: TextStyle(
            fontSize: bodyMedium,
            fontWeight: regular,
            letterSpacing: normalSpacing,
            height: relaxed,
          ),
          bodySmall: TextStyle(
            fontSize: bodySmall,
            fontWeight: regular,
            letterSpacing: normalSpacing,
            height: relaxed,
          ),
          labelLarge: TextStyle(
            fontSize: labelLarge,
            fontWeight: medium,
            letterSpacing: wideSpacing,
            height: normal,
          ),
          labelMedium: TextStyle(
            fontSize: labelMedium,
            fontWeight: medium,
            letterSpacing: wideSpacing,
            height: normal,
          ),
          labelSmall: TextStyle(
            fontSize: labelSmall,
            fontWeight: medium,
            letterSpacing: wideSpacing,
            height: normal,
          ),
        ),
      );

  static TextStyle get body => const TextStyle(
        fontSize: bodyMedium,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: relaxed,
      );

  static TextStyle get caption => const TextStyle(
        fontSize: bodySmall,
        fontWeight: regular,
        letterSpacing: normalSpacing,
        height: normal,
      );
}
