import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class GlobalSearchHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final String hintText; // 🚀 ନୂଆ ପାରାମିଟର୍ (ଡାକ୍ତର/କ୍ଲିନିକ୍ ଅନୁସାରେ ବଦଳିବ)

  const GlobalSearchHeader({
    super.key,
    required this.controller,
    required this.onClear,
    required this.hintText, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // 🚀 ପ୍ୟାଡିଂ କୁ ଟିକେ ସୁବିଧାଜନକ (Flexible) କରାଯାଇଛି
      padding: EdgeInsets.fromLTRB(context.spaceMd, 8, context.spaceMd, 8),
      color: context.theme.scaffoldBackgroundColor,
      child: Container(
        height: 50,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppPalette.info50,
          borderRadius: context.roundedSm,
          border: Border.all(
            color: AppPalette.info200.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: TextField(
          controller: controller,
          textAlignVertical: TextAlignVertical.center,
          style: context.text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            hintText: hintText, // 🚀 ଡାଇନାମିକ୍ ହିଣ୍ଟ୍ (Dynamic Hint)
            hintStyle: context.text.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              LucideIcons.search,
              color: context.colorScheme.primary,
              size: 20,
            ),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      LucideIcons.xCircle, // 🚀 ସୁନ୍ଦର ଆଇକନ୍
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onClear,
                  )
                : null,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}