import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

class JivanDivider extends StatelessWidget {
  final String? text;
  final double indent;
  final double endIndent;

  const JivanDivider({
    super.key,
    this.text,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.isDarkMode
        ? Colors.white10
        : context.colorScheme.outlineVariant.withValues(alpha: 0.5);

    // 1. Simple Divider (No Text)
    if (text == null) {
      return Divider(color: dividerColor, indent: indent, endIndent: endIndent);
    }

    // 2. Labeled Divider (Text in middle)
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: dividerColor,
            indent: indent,
            endIndent: AppSpacing.md,
          ),
        ),
        Text(
          text!.toUpperCase(),
          style: context.text.labelSmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        Expanded(
          child: Divider(
            color: dividerColor,
            indent: AppSpacing.md,
            endIndent: endIndent,
          ),
        ),
      ],
    );
  }
}
