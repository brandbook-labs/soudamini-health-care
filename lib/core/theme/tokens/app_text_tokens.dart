import 'package:flutter/material.dart';

class AppTextTokens {
  // --- 1. FONT FAMILY ---
  static const String fontFamily = 'Inter';
  // static const String secondaryFontFamily = 'Merriweather'; // Example if you mix fonts

  // --- 2. FONT WEIGHTS ---
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w900;

  // --- 3. FONT SIZES (Material 3 Scale) ---
  static const double displayLg = 57.0;
  static const double displayMd = 45.0;
  static const double displaySm = 36.0;

  static const double headlineLg = 32.0;
  static const double headlineMd = 28.0;
  static const double headlineSm = 24.0;

  static const double titleLg = 22.0;
  static const double titleMd = 17.0;
  static const double titleSm = 14.0;

  static const double bodyLg = 16.0;
  static const double bodyMd = 14.0;
  static const double bodySm = 12.0;

  static const double labelLg = 14.0;
  static const double labelMd = 12.0;
  static const double labelSm = 11.0;

  // --- 4. LINE HEIGHTS (Multipliers) ---
  // Controls vertical breathing room. 1.0 = tight, 1.5 = readable paragraph
  static const double heightTight = 1.0;
  static const double heightNormal = 1.2;
  static const double heightRelaxed = 1.5; // Good for long body text

  // --- 5. LETTER SPACING ---
  static const double spacingTight = -0.5;
  static const double spacingNormal = 0.0;
  static const double spacingWide = 0.15;
  static const double spacingWidest = 0.5;
}
