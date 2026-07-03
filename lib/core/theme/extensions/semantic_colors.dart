import 'package:flutter/material.dart';
import '../tokens/app_palette.dart';

@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color success;
  final Color onSuccess; // Text color on top of success background

  final Color warning;
  final Color onWarning;

  final Color info;
  final Color onInfo;

  final Color error;
  final Color onError;

  final LinearGradient primaryGradient;

  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.info,
    required this.onInfo,
    required this.error,
    required this.onError,
    required this.primaryGradient,
  });

  @override
  SemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? info,
    Color? onInfo,
    Color? error,
    Color? onError,
    LinearGradient? primaryGradient,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      error: error ?? this.error,
      onError: onError ?? this.onError,
      primaryGradient: primaryGradient ?? this.primaryGradient,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;

    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      error: Color.lerp(error, other.error, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      // Cast is safe here because we know we are lerping gradients
      primaryGradient:
          Gradient.lerp(primaryGradient, other.primaryGradient, t)!
              as LinearGradient,
    );
  }

  // ===========================================================================
  // THEME MAPPINGS
  // Changed from 'static const' to 'static get' to support dynamic AppPalette
  // ===========================================================================

  static SemanticColors get light => SemanticColors(
    // Success: Rich Green
    success: AppPalette.success500,
    onSuccess: Colors.white,

    // Warning: Rich Orange
    warning: AppPalette.warning500,
    onWarning: Colors.white,

    // Info: Brand Blue
    info: AppPalette.info500,
    onInfo: Colors.white,

    // Error: Rich Red
    error: AppPalette.error500,
    onError: Colors.white,

    primaryGradient: AppPalette.primaryGradient,
  );

  static SemanticColors get dark => SemanticColors(
    // Dark Mode Rule: Use PASTEL (200-300) colors for visibility

    // Success: Pastel Green
    success: AppPalette.success300,
    onSuccess: AppPalette.neutral900,

    // Warning: Pastel Orange
    warning: AppPalette.warning200,
    onWarning: AppPalette.neutral900,

    // Info: Pastel Blue
    info: AppPalette.info200,
    onInfo: AppPalette.neutral900,

    // Error: Pastel Red
    error: AppPalette.error200,
    onError: AppPalette.neutral900,

    // Dark gradient
    // Removed 'const' keyword because AppPalette colors are runtime getters
    primaryGradient: LinearGradient(
      colors: [AppPalette.jivanBlue600, AppPalette.jivanBlue800],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
