import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Import Theme Context

class UserPlanDetailsCard extends StatelessWidget {
  final String planName;
  final String clinicName;
  final String validityDate;
  final bool isActive;

  const UserPlanDetailsCard({
    super.key,
    required this.planName,
    required this.clinicName,
    required this.validityDate,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(
          16,
        ), // Adjust to your AppRadius.large
        border: Border.all(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (!context.isDarkMode && isActive)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // --- LEFT: Plan Icon / Badge ---
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.shieldCheck,
              size: 28,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(width: 16),

          // --- RIGHT: Plan Details ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Plan Name & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        planName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(isActive: isActive),
                  ],
                ),

                const SizedBox(height: 8),

                // 2. Clinic Name
                Row(
                  children: [
                    Icon(
                      LucideIcons.building2,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clinicName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // 3. Validity Details
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarClock,
                      size: 14,
                      color: isActive ? colorScheme.primary : colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Valid till $validityDate",
                      style: context.text.labelMedium?.copyWith(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Sub-Widget for Status Pill ---
class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Green for active, Grey/Red for inactive
    final Color badgeColor = isActive ? Colors.green : colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? "ACTIVE" : "EXPIRED",
            style: context.text.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
