import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppShadows {
  // Light Mode Shadows (Soft & Diffuse)
  static final List<BoxShadow> lightSm = [
    BoxShadow(
      color: AppPalette.neutralBlack.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static final List<BoxShadow> lightMd = [
    BoxShadow(
      color: AppPalette.neutralBlack.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // Dark Mode Shadows (Usually just borders or very subtle glows)
  // In Material 3 dark mode, we often rely on surface colors, not shadows.
  static final List<BoxShadow> darkMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}
