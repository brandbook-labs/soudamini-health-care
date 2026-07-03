import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

enum BadgeType { success, warning, error, info, neutral }

class JivanBadge extends StatelessWidget {
  final String text;
  final BadgeType type;

  const JivanBadge({
    super.key,
    required this.text,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _getColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        text.toUpperCase(),
        style: context.text.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  (Color, Color) _getColors(BuildContext context) {
    switch (type) {
      case BadgeType.success:
        return (
          context.semantic.success.withValues(alpha: 0.1),
          context.semantic.success,
        );
      case BadgeType.warning:
        return (
          context.semantic.warning.withValues(alpha: 0.1),
          context.semantic.warning,
        );
      case BadgeType.error:
        return (
          context.colorScheme.error.withValues(alpha: 0.1),
          context.colorScheme.error,
        );
      case BadgeType.info:
        return (
          context.semantic.info.withValues(alpha: 0.1),
          context.semantic.info,
        );
      case BadgeType.neutral:
        return (
          context.colorScheme.surfaceContainerHighest,
          context.colorScheme.onSurfaceVariant,
        );
    }
  }
}
