import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

class JivanListTile extends StatelessWidget {
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showBorder;

  const JivanListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: showBorder
          ? BoxDecoration(
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            )
          : null,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        leading: leading,
        title: DefaultTextStyle(
          style: context.text.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
          ),
          child: title,
        ),
        subtitle: subtitle != null
            ? Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: DefaultTextStyle(
                  style: context.text.bodyMedium!.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  child: subtitle!,
                ),
              )
            : null,
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
