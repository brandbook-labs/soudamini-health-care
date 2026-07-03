import 'package:flutter/material.dart';
import 'package:my_new_app/core/theme/tokens/app_radius.dart';
import 'package:my_new_app/core/theme/tokens/app_shadows.dart';
import 'package:my_new_app/core/theme/tokens/app_spacing.dart';
import '../theme/extensions/semantic_colors.dart';

// Exports allow you to import just this file to get everything
export '../theme/tokens/app_spacing.dart';
export '../theme/tokens/app_radius.dart';
export '../theme/tokens/app_shadows.dart';
export '../theme/tokens/app_palette.dart';

extension ThemeContext on BuildContext {
  // ===========================================================================
  // 1. THEME & COLOR SHORTCUTS
  // ===========================================================================
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
  TextTheme get text => theme.textTheme;
  SemanticColors get semantic =>
      theme.extension<SemanticColors>() ?? SemanticColors.light;
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// High-frequency Color Shortcuts (Optional but recommended)
  Color get primaryColor => colorScheme.primary;
  Color get onPrimary => colorScheme.onPrimary;
  Color get surface => colorScheme.surface;
  Color get onSurface => colorScheme.onSurface;

  // ===========================================================================
  // 2. SHADOW SHORTCUTS
  // ===========================================================================
  List<BoxShadow> get shadowSm =>
      isDarkMode ? AppShadows.darkMd : AppShadows.lightSm;
  List<BoxShadow> get shadowMd =>
      isDarkMode ? AppShadows.darkMd : AppShadows.lightMd;

  // ===========================================================================
  // 3. SCREEN & LAYOUT SHORTCUTS
  // ===========================================================================
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get width => mediaQuery.size.width;
  double get height => mediaQuery.size.height;
  EdgeInsets get padding => mediaQuery.padding; // Safe area padding

  /// KEYBOARD HANDLING
  void closeKeyboard() => FocusScope.of(this).unfocus();
  bool get isKeyboardOpen => mediaQuery.viewInsets.bottom > 0;

  // ===========================================================================
  // 4. RADIUS SHORTCUTS
  // ===========================================================================
  BorderRadius get roundedSm => AppRadius.small;
  BorderRadius get roundedMd => AppRadius.medium;
  BorderRadius get roundedLg => AppRadius.large;
  BorderRadius get roundedSheet => AppRadius.sheetTop;
  BorderRadius get roundedFull => BorderRadius.circular(AppRadius.full);

  double get radiusSm => AppRadius.sm;
  double get radiusMd => AppRadius.md;

  // ===========================================================================
  // 5. SPACING SHORTCUTS (SizedBox)
  // ===========================================================================
  SizedBox get gapXs => AppSpacing.gapXs;
  SizedBox get gapSm => AppSpacing.gapSm;
  SizedBox get gapMd => AppSpacing.gapMd;
  SizedBox get gapLg => AppSpacing.gapLg;
  SizedBox get gapXl => AppSpacing.gapXl;
  SizedBox get gapXxl => AppSpacing.gapXxl;

  // ===========================================================================
  // 6. SPACING CONSTANTS (Doubles for Padding)
  // ===========================================================================
  double get spaceXs => AppSpacing.xs;
  double get spaceSm => AppSpacing.sm;
  double get spaceMd => AppSpacing.md;
  double get spaceLg => AppSpacing.lg;
  double get spaceXl => AppSpacing.xl;
  double get spaceXxl => AppSpacing.xxl;

  // ===========================================================================
  // 7. TYPOGRAPHY SHORTCUTS (🔥🔥 THIS WAS MISSING)
  // ===========================================================================
  // Allows `context.headlineLg` instead of `context.text.headlineLarge`

  TextStyle? get displayLg => text.displayLarge;
  TextStyle? get displayMd => text.displayMedium;
  TextStyle? get displaySm => text.displaySmall;

  TextStyle? get headlineLg => text.headlineLarge;
  TextStyle? get headlineMd => text.headlineMedium;
  TextStyle? get headlineSm => text.headlineSmall;

  TextStyle? get titleLg => text.titleLarge;
  TextStyle? get titleMd => text.titleMedium;
  TextStyle? get titleSm => text.titleSmall;

  TextStyle? get bodyLg => text.bodyLarge;
  TextStyle? get bodyMd => text.bodyMedium;
  TextStyle? get bodySm => text.bodySmall;

  TextStyle? get labelLg => text.labelLarge;
  TextStyle? get labelMd => text.labelMedium;
  TextStyle? get labelSm => text.labelSmall;

  // ===========================================================================
  // 8. RESPONSIVE PERCENTAGES (🔥🔥 THIS WAS MISSING)
  // ===========================================================================
  // Usage: width: context.percentWidth(0.5) // 50% of screen width

  double percentWidth(double percent) => width * percent;
  double percentHeight(double percent) => height * percent;
}
