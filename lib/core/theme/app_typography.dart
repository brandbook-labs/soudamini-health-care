import 'package:flutter/material.dart';
import 'tokens/app_text_tokens.dart';

class AppTypography {
  /// Generates the complete Material 3 TextTheme.
  static TextTheme get(ColorScheme colors) {
    return TextTheme(
      // -----------------------------------------------------------------------
      // DISPLAY (Giant text, e.g., Onboarding Hero text, Big Stats)
      // -----------------------------------------------------------------------
      displayLarge: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.displayLg,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightTight,
        letterSpacing: AppTextTokens.spacingTight,
        color: colors.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.displayMd,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightTight,
        color: colors.onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.displaySm,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightNormal,
        color: colors.onSurface,
      ),

      // -----------------------------------------------------------------------
      // HEADLINE (Section headers, AppBars, Modal titles)
      // -----------------------------------------------------------------------
      headlineLarge: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.headlineLg,
        fontWeight: AppTextTokens.semiBold,
        height: AppTextTokens.heightNormal,
        color: colors.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.headlineMd,
        fontWeight: AppTextTokens.semiBold,
        height: AppTextTokens.heightNormal,
        color: colors.onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.headlineSm,
        fontWeight: AppTextTokens.semiBold,
        height: AppTextTokens.heightNormal,
        color: colors.onSurface,
      ),

      // -----------------------------------------------------------------------
      // TITLE (Card titles, List Tile titles)
      // -----------------------------------------------------------------------
      titleLarge: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.titleLg,
        fontWeight: AppTextTokens.medium,
        height: AppTextTokens.heightNormal,
        color: colors.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.titleMd,
        fontWeight: AppTextTokens.medium,
        height: AppTextTokens.heightNormal,
        letterSpacing: AppTextTokens.spacingWide,
        color: colors.onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.titleSm,
        fontWeight: AppTextTokens.medium,
        height: AppTextTokens.heightNormal,
        letterSpacing: AppTextTokens.spacingWide,
        color: colors.onSurface,
      ),

      // -----------------------------------------------------------------------
      // BODY (Paragraphs, descriptions, long text)
      // -----------------------------------------------------------------------
      bodyLarge: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.bodyLg,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightRelaxed,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.bodyMd,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightRelaxed,
        letterSpacing: 0.25,
        color: colors.onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.bodySm,
        fontWeight: AppTextTokens.regular,
        height: AppTextTokens.heightRelaxed,
        letterSpacing: 0.4,
        // 🔥 IMPROVEMENT: Use 'onSurfaceVariant' instead of opacity.
        // This ensures better contrast in Dark Mode automatically.
        color: colors.onSurfaceVariant,
      ),

      // -----------------------------------------------------------------------
      // LABEL (Buttons, Tabs, Chips, Captions)
      // -----------------------------------------------------------------------
      labelLarge: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.labelLg,
        fontWeight: AppTextTokens.medium,
        height: AppTextTokens.heightTight,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.labelMd,
        fontWeight: AppTextTokens.medium,
        height: AppTextTokens.heightTight,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTextTokens.fontFamily,
        fontSize: AppTextTokens.labelSm,
        fontWeight: AppTextTokens.bold,
        height: AppTextTokens.heightTight,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
    );
  }
}
