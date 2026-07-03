import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  // Made optional
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const JivanSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    // Removed 'required'
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
          // Only show action button if label is provided
          if (actionLabel != null)
            InkWell(
              onTap: onActionTap,
              child: Text(
                actionLabel!,
                style: context.text.bodyMedium?.copyWith(
                  color: context.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
