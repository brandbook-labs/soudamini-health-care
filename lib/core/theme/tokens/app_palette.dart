import 'package:flutter/material.dart';

class AppPalette {
  // ===========================================================================
  // 0. SEED CONFIGURATION (CHANGE THESE ONLY)
  // ===========================================================================
  // This is the single field that controls the brand.
  // 🟢 Brand is now GREEN. To retune it, change ONLY this value.
  //    A few alternatives you can drop in:
  //      Color(0xFF16A34A) // vivid green   (current)
  //      Color(0xFF059669) // emerald (deeper, higher contrast on white)
  //      Color(0xFF15803D) // forest green
  static const Color _brandSeed = Color(0xFF16A34A);

  // We define seeds for semantic colors too, so their scales generate automatically.
  static const Color _neutralSeed = Color.fromARGB(255, 124, 124, 124); // Slate
  static const Color _tealSeed = Color(0xFF006C70);
  static const Color _successSeed = Color(0xFF2E7D32);
  static const Color _warningSeed = Color(0xFFFF8F00);
  static const Color _errorSeed = Color(0xFFD32F2F);

  // ===========================================================================
  // 1. BRAND COLORS (Jivan Green)
  // Generated dynamically from _brandSeed
  // ===========================================================================
  static Color get jivanBlue50 => _tint(_brandSeed, 0.95);
  static Color get jivanBlue100 => _tint(_brandSeed, 0.80);
  static Color get jivanBlue200 => _tint(_brandSeed, 0.60);
  static Color get jivanBlue300 => _tint(_brandSeed, 0.40);
  static Color get jivanBlue400 => _tint(_brandSeed, 0.20);
  static Color get jivanBlue500 => _brandSeed; // Main Brand Color
  static Color get jivanBlue600 => _shade(_brandSeed, 0.10);
  static Color get jivanBlue700 => _shade(_brandSeed, 0.30);
  static Color get jivanBlue800 => _shade(_brandSeed, 0.50);
  static Color get jivanBlue900 => _shade(_brandSeed, 0.70);

  // ===========================================================================
  // 2. NEUTRALS (Slate / Greys)
  // Generated dynamically from _neutralSeed
  // ===========================================================================
  static const Color neutralWhite = Color(0xFFFFFFFF);
  static Color get neutral50 => _tint(_neutralSeed, 0.95);
  static Color get neutral100 => _tint(_neutralSeed, 0.90);
  static Color get neutral200 => _tint(_neutralSeed, 0.80);
  static Color get neutral300 => _tint(_neutralSeed, 0.60);
  static Color get neutral400 => _tint(_neutralSeed, 0.40);
  static Color get neutral500 => _neutralSeed;
  static Color get neutral600 => _shade(_neutralSeed, 0.20);
  static Color get neutral700 => _shade(_neutralSeed, 0.40);
  static Color get neutral800 => _shade(_neutralSeed, 0.60);
  static Color get neutral900 => _shade(_neutralSeed, 0.80);
  static const Color neutralBlack = Color(0xFF111111);

  // ===========================================================================
  // 3. SECONDARY (Teal / Cyan)
  // Generated dynamically from _tealSeed
  // ===========================================================================
  static Color get teal50 => _tint(_tealSeed, 0.95);
  static Color get teal100 => _tint(_tealSeed, 0.80);
  static Color get teal200 => _tint(_tealSeed, 0.60);
  static Color get teal500 => _tealSeed;
  static Color get teal700 => _shade(_tealSeed, 0.30);

  // Keeping this manual as it's a specific highlight color
  static const Color cyan400 = Color(0xFF4CD9E0);

  // ===========================================================================
  // 4. SEMANTIC SCALES
  // Generated dynamically from their respective seeds
  // ===========================================================================

  // --- SUCCESS (Green) ---
  static Color get success50 => _tint(_successSeed, 0.95);
  static Color get success100 => _tint(_successSeed, 0.80);
  static Color get success200 => _tint(_successSeed, 0.60);
  static Color get success300 => _tint(_successSeed, 0.40);
  static Color get success500 => _successSeed;
  static Color get success700 => _shade(_successSeed, 0.30);

  // --- WARNING (Orange/Amber) ---
  static Color get warning50 => _tint(_warningSeed, 0.95);
  static Color get warning100 => _tint(_warningSeed, 0.80);
  static Color get warning200 => _tint(_warningSeed, 0.60);
  static Color get warning500 => _warningSeed;
  static Color get warning700 => _shade(_warningSeed, 0.30);

  // --- ERROR (Red) ---
  static Color get error50 => _tint(_errorSeed, 0.95);
  static Color get error100 => _tint(_errorSeed, 0.80);
  static Color get error200 => _tint(_errorSeed, 0.60);
  static Color get error500 => _errorSeed;
  static Color get error700 => _shade(_errorSeed, 0.30);

  // --- INFO (Brand) ---
  // References the Brand Colors directly (now green).
  static Color get info50 => jivanBlue50;
  static Color get info100 => jivanBlue100;
  static Color get info200 => jivanBlue200;
  static Color get info500 => jivanBlue500;

  // ===========================================================================
  // 5. GRADIENTS
  // ===========================================================================
  // Note: Gradients are not const because the colors inside are not const anymore
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [jivanBlue500, jivanBlue600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ===========================================================================
  // INTERNAL LOGIC (Color Mixing Helpers)
  // ===========================================================================

  /// Lightens the color by mixing it with White.
  /// [factor] 0.0 = Original Color, 1.0 = White
  static Color _tint(Color color, double factor) =>
      Color.lerp(color, Colors.white, factor)!;

  /// Darkens the color by mixing it with Black.
  /// [factor] 0.0 = Original Color, 1.0 = Black
  static Color _shade(Color color, double factor) =>
      Color.lerp(color, Colors.black, factor)!;
}
