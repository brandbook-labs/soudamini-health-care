import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class AdminStatsOverview extends StatelessWidget {
  const AdminStatsOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: "Total Clinics",
                value: "124",
                icon: LucideIcons.building2,
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: "Active Users",
                value: "8.5k",
                icon: LucideIcons.users,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: _StatCard(
                label: "Total Revenue",
                value: "₹45L",
                icon: LucideIcons.indianRupee,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: "Pending",
                value: "12",
                icon: LucideIcons.clock,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: context.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
