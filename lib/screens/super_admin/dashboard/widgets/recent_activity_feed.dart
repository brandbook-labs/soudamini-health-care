import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart'; // Assuming JivanCard exists here
import 'package:my_new_app/core/utils/theme_utils.dart';

class RecentActivityFeed extends StatelessWidget {
  const RecentActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return JivanCard(
          padding: const EdgeInsets.all(12),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.activity,
                size: 20,
                color: colorScheme.onSurface,
              ),
            ),
            title: const Text("New Clinic Registered"),
            subtitle: Text(
              "Apollo Pharmacy - Unit ${index + 1}",
              style: context.text.bodySmall,
            ),
            trailing: Text(
              "${index + 2}m ago",
              style: context.text.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ),
        );
      },
    );
  }
}
