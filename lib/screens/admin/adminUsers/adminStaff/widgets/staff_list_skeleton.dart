import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class StaffListSkeleton extends StatelessWidget {
  const StaffListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Shimmer.fromColors(
        baseColor: isDark ? Colors.white10 : Colors.grey.shade200,
        highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
        child: Column(
          children: List.generate(
            4,
            (index) => Container(
              height: 140,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
