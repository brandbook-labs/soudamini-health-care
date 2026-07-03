import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanBottomBar extends StatelessWidget {
  final Widget child;
  final bool showBorder;

  const JivanBottomBar({
    super.key,
    required this.child,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        border: showBorder
            ? Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(child: child),
    );
  }
}
