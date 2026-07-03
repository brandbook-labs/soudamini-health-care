// lib/core/components/display/jivan_filter_chip.dart
import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const JivanFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Dynamic Colors based on selection state
    final bgColor = isSelected ? colorScheme.primary : colorScheme.surface;

    final fgColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    final borderColor = isSelected
        ? Colors.transparent
        : colorScheme.outlineVariant.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: borderColor),
          boxShadow: isSelected ? context.shadowSm : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: fgColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
