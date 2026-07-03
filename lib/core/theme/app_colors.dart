import 'package:flutter/material.dart';

class AppColors {
  // --- RAW PALETTE (Private) ---
  // Only edit these when your brand guidelines change
  static const Color _brandBlue = Color.fromARGB(255, 7, 78, 231);
  static const Color _brandBlueDark = Color.fromARGB(255, 4, 61, 231);
  static const Color _secondaryTeal = Color(0xFF006C70);
  static const Color _secondaryCyan = Color(0xFF4CD9E0);

  // Backgrounds
  static const Color _lightBg = Color(0xFFF8FAFC);
  static const Color _darkBg = Color.fromARGB(255, 14, 14, 14);

  // Cards / Surfaces
  static const Color _lightSurface = Colors.white;
  static const Color _darkSurface = Color.fromARGB(255, 25, 25, 25);

  // Semantic Errors
  static const Color _errorLight = Color(0xFFBA1A1A);
  static const Color _errorDark = Color(0xFFFFB4AB);

  // --- SEMANTIC GETTERS (Public) ---
  // Use these in your Theme configuration

  static const Color primaryLight = _brandBlue;
  static const Color primaryDark = _brandBlueDark;

  static const Color secondaryLight = _secondaryTeal;
  static const Color secondaryDark = _secondaryCyan;

  static const Color backgroundLight = _lightBg;
  static const Color backgroundDark = _darkBg;

  static const Color surfaceLight = _lightSurface;
  static const Color surfaceDark = _darkSurface;

  static const Color errorLight = _errorLight;
  static const Color errorDark = _errorDark;
}
