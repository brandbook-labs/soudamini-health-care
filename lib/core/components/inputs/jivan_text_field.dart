import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for TextInputType
import 'package:my_new_app/core/utils/theme_utils.dart'; // Your ThemeContext extension

class JivanTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextAlign textAlign;
  final bool autoFocus;
  final bool obscureText;
  final Widget? suffixIcon;

  const JivanTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.autoFocus = false,
    this.textAlign = TextAlign.start,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Theme Logic using Context Extension
    final isDark = context.isDarkMode;

    // Border Color logic
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade300;

    // Fill Color logic
    final fillColor = isDark ? context.colorScheme.surface : Colors.white;

    // Placeholder Color logic
    final placeholderColor = isDark
        ? Colors.grey.shade700
        : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          onTap: onTap,
          autofocus: autoFocus,
          textAlign: textAlign,
          obscureText: obscureText,

          // Typography from context
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurface,
          ),

          decoration: InputDecoration(
            labelText: label,
            labelStyle: context.text.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
            floatingLabelStyle: context.text.labelLarge?.copyWith(
              color: context.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),

            hintText: hintText,
            hintStyle: context.text.bodyLarge?.copyWith(
              color: placeholderColor,
              fontWeight: FontWeight.normal,
            ),

            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,

            filled: true,
            fillColor: fillColor,

            // PADDING: Using your spacing utils (spaceMd = 16.0 typically)
            contentPadding: EdgeInsets.all(context.spaceMd),

            // BORDERS: Using your rounded utils
            border: OutlineInputBorder(
              borderRadius: context.roundedMd,
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: context.roundedMd,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: context.roundedMd,
              borderSide: BorderSide(
                color: context.colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: context.roundedMd,
              borderSide: BorderSide(color: context.colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: context.roundedMd,
              borderSide: BorderSide(
                color: context.colorScheme.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
