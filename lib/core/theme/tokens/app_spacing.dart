import 'package:flutter/material.dart';

class AppSpacing {
  // Prevents using raw numbers like "8.0" in code

  // --- INSETS (Padding/Margins) ---
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0; // Standard component padding
  static const double lg = 24.0; // Section padding
  static const double xl = 32.0; // Screen edges
  static const double xxl = 48.0;

  // --- GAPS (For Rows/Columns) ---
  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);
  static const SizedBox gapXxl = SizedBox(width: xxl, height: xxl);
}
