import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Your ThemeContext

class JivanShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  /// 1. Standard Rectangular Shimmer
  const JivanShimmer({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  /// 2. Circular Shimmer (Perfect for Avatars)
  factory JivanShimmer.circular({
    required double size,
    EdgeInsetsGeometry? margin,
  }) {
    return JivanShimmer(
      width: size,
      height: size,
      shape: BoxShape.circle,
      margin: margin,
    );
  }

  /// 3. Text Placeholder (Rounded ends, like a line of text)
  factory JivanShimmer.text({
    required double width,
    double height = 16,
    EdgeInsetsGeometry? margin,
  }) {
    return JivanShimmer(
      width: width,
      height: height,
      borderRadius: 4, // Soft edges for text lines
      margin: margin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    // --- COLOR LOGIC ---
    // Light Mode: Subtle Light Grey -> White
    // Dark Mode: Dark Grey -> Slightly Lighter Grey
    final baseColor = isDark
        ? context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
        : Colors.grey.shade300;

    final highlightColor = isDark
        ? context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
        : Colors.grey.shade100;

    return Container(
      margin: margin,
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: baseColor, // The mask color
            shape: shape,
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(
                    borderRadius ?? AppRadius.medium.topLeft.x,
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
