import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Access to ThemeContext

class JivanCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? statusColor;

  const JivanCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      // 1. ALIGNMENT: Remove hardcoded elevation/shadow.
      // Inherits 'elevation: 0' and 'color: surface' from your AppTheme._cardTheme
      surfaceTintColor: Colors.transparent,

      // 2. ALIGNMENT: Smart Shape Logic
      // If statusColor is NULL: It inherits AppTheme defaults (AppRadius.large + Grey Border)
      // If statusColor is SET: We force AppRadius.large + Colored Border
      shape: statusColor != null
          ? RoundedRectangleBorder(
              borderRadius: context.roundedLg, // Match AppTheme (Large)
              side: BorderSide(color: statusColor!, width: 1),
            )
          : null, // Let AppTheme take over

      child: InkWell(
        onTap: onTap,
        child: Container(
          // 3. Status Strip (Keep this visual indicator)
          decoration: statusColor != null
              ? BoxDecoration(
                  border: Border(
                    left: BorderSide(color: statusColor!, width: 4),
                  ),
                )
              : null,
          padding:
              padding ?? EdgeInsets.all(context.spaceMd), // Match AppSpacing.md
          child: child,
        ),
      ),
    );
  }
}
