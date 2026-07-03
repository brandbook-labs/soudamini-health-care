import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanDropdown<T> extends StatelessWidget {
  final String? label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? itemLabelBuilder;
  final IconData? icon;
  final String? hint;
  final String? Function(T?)? validator;

  const JivanDropdown({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemLabelBuilder,
    this.icon,
    this.hint,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Theme Logic
    final borderColor = context.isDarkMode
        ? Colors.white10
        : Colors.grey.shade300;
    final fillColor = context.isDarkMode ? colorScheme.surface : Colors.white;
    final placeholderColor = context.isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade400;

    // FIX 1: Wrap in LayoutBuilder to get the parent's width
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<T>(
              // FIX 2: Use 'initialValue' logic correctly.
              // Note: DropdownButtonFormField usually takes 'value', not 'initialValue'
              // for reactive state. If you use 'value', ensure 'key' is updated.
              value: value,

              key: ValueKey(value),

              isExpanded: true,
              menuMaxHeight: 300,
              borderRadius: AppRadius.medium,
              elevation: 4,

              // FIX 3: Force the menu items to match the width of the field.
              // We subtract a small buffer (e.g., 30-40px) to account for internal padding
              // and the scrollbar so it doesn't overflow.
              items: items.map((item) {
                final text = itemLabelBuilder != null
                    ? itemLabelBuilder!(item)
                    : item.toString();
                return DropdownMenuItem<T>(
                  value: item,
                  child: Container(
                    // This creates the constraint preventing full-screen expansion
                    width: constraints.maxWidth - 40,
                    child: Text(
                      text,
                      style: context.text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }).toList(),

              selectedItemBuilder: (BuildContext context) {
                return items.map<Widget>((T item) {
                  final text = itemLabelBuilder != null
                      ? itemLabelBuilder!(item)
                      : item.toString();
                  return Text(
                    text,
                    style: context.text.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },

              onChanged: onChanged,
              validator: validator,
              icon: Icon(
                LucideIcons.chevronDown,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              dropdownColor: context.theme.cardColor,

              decoration: InputDecoration(
                labelText: label,
                labelStyle: context.text.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
                floatingLabelStyle: context.text.labelLarge?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                hintText: hint,
                hintStyle: context.text.bodyLarge?.copyWith(
                  color: placeholderColor,
                ),
                prefixIcon: icon != null
                    ? Icon(icon, size: 20, color: colorScheme.onSurfaceVariant)
                    : null,
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
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
                    color: context.colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide(color: context.colorScheme.error),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
