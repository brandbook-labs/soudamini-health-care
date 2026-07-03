import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool isLoading;
  final bool autoFocus;

  const JivanSearchField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText = "Search...",
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.isLoading = false,
    this.autoFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        // 1. Match Color: Use cardColor to match HomeSearchBar
        color: context.theme.cardColor,

        // 2. Match Radius: Use roundedLg (Rectangular) instead of full (Pill)
        borderRadius: context.roundedLg,

        // 3. Match Border: Use outline with 0.15 alpha (subtler)
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),

        // 4. Match Shadow
        boxShadow: context.shadowSm,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autoFocus,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        style: context.text.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500, // Matching weight from HomeSearchBar
          color: colorScheme.onSurface,
        ),
        cursorColor: colorScheme.primary,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: context.text.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant, // darker hint
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          // Center the text vertically within the 50px height
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          prefixIcon: Icon(
            LucideIcons.search,
            color: colorScheme.primary,
            size: 20,
          ),
          suffixIcon: isLoading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              : controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    controller.clear();
                    onClear?.call();
                  },
                )
              : null,
        ),
      ),
    );
  }
}
