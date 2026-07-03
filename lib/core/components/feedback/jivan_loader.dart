import 'package:flutter/material.dart';
import '../../utils/theme_utils.dart';

class JivanLoader extends StatelessWidget {
  final bool isOverlay;

  const JivanLoader({super.key, this.isOverlay = false});

  @override
  Widget build(BuildContext context) {
    final loader = CircularProgressIndicator(
      color: context.colorScheme.primary,
      backgroundColor: context.colorScheme.primaryContainer,
    );

    if (isOverlay) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: loader,
        ),
      );
    }

    return Center(child: loader);
  }
}
