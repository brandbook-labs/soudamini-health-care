import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this points to your theme context Ensure this points to your palette

class SystemInventoryAlerts extends StatelessWidget {
  const SystemInventoryAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: Simulating inventory and system alerts
    final List<Map<String, dynamic>> systemAlerts = [
      {
        "type": "capacity",
        "severity": "critical", // Red
        "title": "ICU Bed Capacity",
        "location": "Main Hospital Branch",
        "statusValue": "95% Full",
        "actionText": "Manage Beds",
      },
      {
        "type": "inventory",
        "severity": "warning", // Orange
        "title": "Standard Prescription Pads",
        "location": "Clinic B - South Wing",
        "statusValue": "2 Boxes Left",
        "actionText": "Reorder Now",
      },
      {
        "type": "system",
        "severity": "warning",
        "title": "Ultrasound Machine Maintenance",
        "location": "Diagnostics Dept",
        "statusValue": "Due in 2 days",
        "actionText": "Schedule",
      },
    ];

    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "System & Inventory",
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full inventory/system dashboard
                },
                child: const Text("View All"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 0),

        // --- ALERTS LIST ---
        ListView.separated(
          shrinkWrap:
              true, // Crucial for nested lists in a scrollable dashboard
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          itemCount: systemAlerts.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return _InventoryAlertTile(alert: systemAlerts[index]);
          },
        ),
      ],
    );
  }
}

// ── SUB-WIDGET ───────────────────────────────────────────────────────────────

class _InventoryAlertTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _InventoryAlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isCritical = alert['severity'] == 'critical';
    final type = alert['type'] as String;

    // 1. Determine Color Scheme based on Severity
    final Color baseColor = isCritical
        ? Colors.red.shade700
        : Colors.orange.shade700;
    final Color bgColor = isCritical
        ? Colors.red.withValues(alpha: 0.03)
        : Colors.orange.withValues(alpha: 0.03);
    final Color borderColor = isCritical
        ? Colors.red.withValues(alpha: 0.2)
        : Colors.orange.withValues(alpha: 0.2);

    // 2. Determine Icon based on Type
    IconData icon;
    switch (type) {
      case 'capacity':
        icon = LucideIcons.bedDouble;
        break;
      case 'inventory':
        icon = LucideIcons.packageOpen;
        break;
      case 'system':
      default:
        icon = LucideIcons.settings2;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ICON (Squircle style matching previous components) ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: baseColor, size: 18),
          ),

          const SizedBox(width: 12),

          // --- CONTENT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status Value Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status text (e.g., "95% Full", "2 Boxes Left")
                    Text(
                      alert['statusValue'],
                      style: context.text.labelSmall?.copyWith(
                        color: baseColor,
                        fontWeight: FontWeight.w800, // Make the metric pop
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                // Location / Subtitle
                Row(
                  children: [
                    Icon(
                      LucideIcons.mapPin,
                      size: 10,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        alert['location'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // --- ACTION PILL ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      // Handle click action
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: baseColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alert['actionText'],
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 12,
                            color: baseColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
