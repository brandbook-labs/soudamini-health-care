import 'package:flutter/material.dart';
import 'tokens/app_palette.dart';
import 'tokens/app_spacing.dart';
import 'tokens/app_radius.dart';
import 'extensions/semantic_colors.dart';
import 'app_typography.dart';

class AppTheme {
  // ===========================================================================
  // 1. ENTRY POINTS
  // ===========================================================================

  static ThemeData get light => _createTheme(
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    extension: SemanticColors.light,
  );

  static ThemeData get dark => _createTheme(
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    extension: SemanticColors.dark,
  );

  // ===========================================================================
  // 2. MASTER THEME BUILDER
  // ===========================================================================

  static ThemeData _createTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required ThemeExtension<SemanticColors> extension,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,

      // Core UI Colors
      // .neutral50 is now a getter, so no 'const' here
      scaffoldBackgroundColor: isDark
          ? AppPalette.neutralBlack
          : AppPalette.neutralWhite,

      // Typography
      textTheme: AppTypography.get(colorScheme),

      // Extensions
      extensions: [extension],

      // --- GLOBAL PAGE TRANSITIONS ---
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          // TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
        },
      ),

      // Component Themes
      appBarTheme: _appBarTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      outlinedButtonTheme: _outlinedButtonTheme(colorScheme),
      inputDecorationTheme: _inputDecorationTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      dividerTheme: _dividerTheme(colorScheme),

      iconTheme: IconThemeData(
        // .neutral100 is a getter
        color: isDark ? AppPalette.neutral100 : AppPalette.neutralBlack,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
    );
  }

  // ===========================================================================
  // 3. COLOR SCHEMES
  // Changed from 'static const' to 'static get' because AppPalette colors
  // are now generated at runtime.
  // ===========================================================================

  static ColorScheme get _lightColorScheme => ColorScheme.light(
    primary: AppPalette.jivanBlue600,
    onPrimary: Colors.white,
    primaryContainer: AppPalette.jivanBlue400,
    onPrimaryContainer: AppPalette.jivanBlue900,

    secondary: AppPalette.teal500,
    onSecondary: Colors.white,

    surface: AppPalette.neutralWhite,
    onSurface: AppPalette.neutralBlack,
    onSurfaceVariant: AppPalette.neutral700,

    error: AppPalette.error500,
    onError: Colors.white,

    outline: AppPalette.neutral400,
    outlineVariant: AppPalette.neutral200,
  );

  static ColorScheme get _darkColorScheme => ColorScheme.dark(
    primary: AppPalette.jivanBlue500,
    onPrimary: AppPalette.neutralWhite,
    primaryContainer: AppPalette.jivanBlue900,
    onPrimaryContainer: AppPalette.jivanBlue100,

    secondary: AppPalette.cyan400,
    onSecondary: AppPalette.neutral900,

    surface: AppPalette.neutral900,
    onSurface: AppPalette.neutral100,
    onSurfaceVariant: AppPalette.neutral400,

    error: AppPalette.error200,
    onError: AppPalette.neutral900,

    outline: AppPalette.neutral700,
    outlineVariant: AppPalette.neutral800,
  );

  // ===========================================================================
  // 4. COMPONENT STYLES
  // ===========================================================================

  static AppBarTheme _appBarTheme(ColorScheme colors) {
    return AppBarTheme(
      backgroundColor: colors.surface,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: colors.onSurface),
      actionsIconTheme: IconThemeData(color: colors.onSurface),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colors) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(ColorScheme colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.outline.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(ColorScheme colors) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.all(AppSpacing.md),
      hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.4)),
      labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
      border: const OutlineInputBorder(borderRadius: AppRadius.medium),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.medium,
        borderSide: BorderSide(color: colors.error),
      ),
    );
  }

  static CardThemeData _cardTheme(ColorScheme colors) {
    return CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: colors.outline.withValues(alpha: 0.1)),
      ),
    );
  }

  static DividerThemeData _dividerTheme(ColorScheme colors) {
    return DividerThemeData(
      color: colors.outline.withValues(alpha: 0.15),
      thickness: 1,
      space: AppSpacing.lg,
    );
  }
}
