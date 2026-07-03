import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/theme_utils.dart';

class JivanPhoneInput extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool readOnly;

  // FIX 1: Declare the variable
  final Widget? suffixIcon;

  const JivanPhoneInput({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.readOnly = false,
    this.enabled = true,
    // FIX 2: Add to constructor
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = context.isDarkMode
        ? Colors.white10
        : Colors.grey.shade300;

    final fillColor = readOnly
        ? (context.isDarkMode
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100)
        : (context.isDarkMode ? context.colorScheme.surface : Colors.white);

    final placeholderColor = context.isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.phone,
          enabled: enabled,
          readOnly: readOnly,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: context.text.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            height: 1.25,
            color: readOnly
                ? context.colorScheme.onSurface.withValues(alpha: 0.6)
                : null,
          ),
          cursorColor: context.colorScheme.primary,
          onChanged: (val) {
            if (onChanged != null) onChanged!("+91$val");
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: context.text.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),

            // FIX 3: Pass the suffix icon here
            suffixIcon: suffixIcon,

            floatingLabelStyle: context.text.labelLarge?.copyWith(
              color: readOnly
                  ? context.colorScheme.onSurfaceVariant
                  : context.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
            hintText: "98765 43210",
            hintStyle: context.text.bodyLarge?.copyWith(
              color: placeholderColor,
              fontWeight: FontWeight.normal,
              letterSpacing: 1.5,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.only(left: 12, right: 12),
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: context.isDarkMode
                        ? Colors.white10
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("🇮🇳", style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    "+91",
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: readOnly
                          ? context.colorScheme.onSurface.withValues(alpha: 0.6)
                          : context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (!readOnly)
                    Icon(
                      LucideIcons.chevronDown,
                      size: 14,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: fillColor,
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),

            // FIX 4: Removed BorderRadius.circular() wrapper
            // Assuming AppRadius.md is already a BorderRadius object based on your tokens
            border: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.medium,
              borderSide: BorderSide(
                color: readOnly ? borderColor : context.colorScheme.primary,
                width: readOnly ? 1 : 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
