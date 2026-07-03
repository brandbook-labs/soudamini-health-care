// lib/screens/patients/profile/widgets/profile_shared_widgets.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- CONSTANTS ---
class AppSpacing {
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static final BorderRadius medium = BorderRadius.circular(8);
  static final BorderRadius large = BorderRadius.circular(8);
  static final BorderRadius full = BorderRadius.circular(999);
}

// --- REUSABLE WIDGETS ---
class MenuCard extends StatelessWidget {
  final List<Widget> children;
  const MenuCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isComingSoon;
  final Widget? trailing;

  const MenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isComingSoon = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contentColor = isComingSoon
        ? colorScheme.onSurface.withValues(alpha: 0.4)
        : colorScheme.onSurface;

    return ListTile(
      onTap: (isComingSoon || trailing is Switch) ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 4,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isComingSoon
              ? colorScheme.surfaceContainerHighest
              : colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: isComingSoon
              ? colorScheme.onSurfaceVariant
              : colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: contentColor,
        ),
      ),
      trailing:
          trailing ??
          (isComingSoon
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    "COMING SOON",
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                )
              : Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                )),
    );
  }
}

class MenuDivider extends StatelessWidget {
  const MenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}

class GuestBenefitRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const GuestBenefitRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
