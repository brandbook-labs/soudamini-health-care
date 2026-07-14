import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this points to your theme context
// Assuming AppPalette is in your tokens/theme folder based on your previous code

class AdminCommunicationsHub extends StatelessWidget {
  const AdminCommunicationsHub({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: Simulating the different types of incoming data
    final List<Map<String, dynamic>> inboxItems = [
      {
        "type": "emergency_walkin",
        "title": "Emergency Walk-in",
        "subtitle": "Patient reported with severe chest pain at front desk.",
        "time": "2 mins ago",
        "isCritical": true,
      },
      {
        "type": "unanswered_query",
        "title": "Unanswered Query",
        "subtitle": "Dr. Sarah's patient asking about post-op bleeding.",
        "time": "15 mins ago",
        "isCritical": true,
      },
      {
        "type": "jivan_review",
        "title": "New Doctor Review",
        "subtitle":
            "⭐⭐⭐⭐⭐ 'Dr. Amit was very patient and explained everything.'",
        "time": "1 hr ago",
        "isCritical": false,
      },
      {
        "type": "google_review",
        "title": "Google Clinic Review",
        "subtitle": "⭐⭐⭐ 'Wait time was a bit long, but good facilities.'",
        "time": "3 hrs ago",
        "isCritical": false,
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
                "Needs Attention",
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full inbox
                },
                child: const Text("View Inbox"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 0),

        // --- INBOX LIST ---
        ListView.separated(
          shrinkWrap:
              true, // Prevents layout errors inside a scrolling dashboard
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          itemCount: inboxItems.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: 8), // Tighter gap
          itemBuilder: (context, index) {
            return _InboxItemTile(item: inboxItems[index]);
          },
        ),
      ],
    );
  }
}

// ── SUB-WIDGET ───────────────────────────────────────────────────────────────

class _InboxItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _InboxItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isCritical = item['isCritical'] == true;
    final type = item['type'] as String;

    // 1. Determine Icon and Colors based on the type of message
    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'emergency_walkin':
        icon = LucideIcons.alertTriangle;
        iconColor = Colors.red.shade700;
        bgColor = Colors.red.withValues(alpha: 0.1);
        break;
      case 'unanswered_query':
        icon = LucideIcons.messageSquareDashed;
        iconColor = Colors.orange.shade700;
        bgColor = Colors.orange.withValues(alpha: 0.1);
        break;
      case 'google_review':
        icon = LucideIcons.globe;
        iconColor = Colors.blueGrey;
        bgColor = Colors.blueGrey.withValues(alpha: 0.1);
        break;
      case 'jivan_review':
      default:
        icon = LucideIcons.star;
        iconColor = AppPalette.jivanBlue600;
        bgColor = AppPalette.jivanBlue600.withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Flat styling aligned with your active doctor cards
        color: isCritical
            ? Colors.red.withValues(
                alpha: 0.03,
              ) // Very subtle red tint for critical
            : AppPalette.info50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCritical
              ? Colors.red.withValues(alpha: 0.2)
              : AppPalette.info200.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ICON ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(
                6,
              ), // Squircle matching queue pill
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),

          const SizedBox(width: 12),

          // --- CONTENT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isCritical
                              ? Colors.red.shade700
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['time'],
                      style: context.text.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                Text(
                  item['subtitle'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withAlpha(200),
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 8),

                // --- ACTION PILL (Styled like Queue Status) ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () {
                      // Handle click
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCritical
                            ? Colors.red.withValues(alpha: 0.1)
                            : AppPalette.info50.withValues(
                                alpha: 0.5,
                              ), // Matches card but slightly deeper
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCritical
                              ? Colors.red.withValues(alpha: 0.2)
                              : AppPalette.info200.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCritical ? "Take Action Now" : "Read Full Review",
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isCritical
                                  ? Colors.red.shade700
                                  : AppPalette.jivanBlue600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 12,
                            color: isCritical
                                ? Colors.red.shade700
                                : AppPalette.jivanBlue600,
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
