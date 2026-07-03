import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class AppRefresher extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const AppRefresher({super.key, required this.onRefresh, required this.child});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.colorScheme.primary,
      backgroundColor: context.colorScheme.surface,

      // UPDATED: Reduced from 40.0 to 20.0 to hug the top edge
      displacement: 20.0,

      // UPDATED: Ensures the indicator starts checking from the very edge pixel
      edgeOffset: 0,

      child: child,
    );
  }
}
