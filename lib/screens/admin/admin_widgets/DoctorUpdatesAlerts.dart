import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this points to your theme context

class DoctorUpdatesAlerts extends StatefulWidget {
  const DoctorUpdatesAlerts({super.key});

  @override
  State<DoctorUpdatesAlerts> createState() => _DoctorUpdatesAlertsState();
}

class _DoctorUpdatesAlertsState extends State<DoctorUpdatesAlerts> {
  // 🚀 The magic for snapping: viewportFraction defines how much width a card takes (88%).
  final PageController _pageController = PageController(viewportFraction: 0.88);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // MOCK DATA
    final List<Map<String, dynamic>> doctorAlerts = [
      {
        "type": "running_late",
        "severity": "warning",
        "doctorName": "Dr. Sarah Jena",
        "issue": "Running 45 mins late",
        "impact": "6 patients waiting",
        "time": "10m ago",
        "actionText": "Notify",
      },
      {
        "type": "called_sick",
        "severity": "critical",
        "doctorName": "Dr. Amit Das",
        "issue": "Called in sick today",
        "impact": "14 to reschedule",
        "time": "1h ago",
        "actionText": "Manage",
      },
      {
        "type": "canceled_block",
        "severity": "critical",
        "doctorName": "Dr. Priya Sen",
        "issue": "Canceled evening block",
        "impact": "8 slots affected",
        "time": "2h ago",
        "actionText": "Block",
      },
    ];

    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION HEADER ---
        const SizedBox(height: 8),

        // --- 🚀 SNAPPING CAROUSEL ---
        SizedBox(
          height: 80, // Dramatically reduced height!
          child: PageView.builder(
            controller: _pageController,
            padEnds: false, // Forces the first card to stick to the left
            physics: const BouncingScrollPhysics(),
            itemCount: doctorAlerts.length,
            itemBuilder: (context, index) {
              return Padding(
                // Adds a gap between cards
                padding: const EdgeInsets.only(right: 12.0),
                child: _CompactDoctorUpdateTile(alert: doctorAlerts[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── SUB-WIDGET ───────────────────────────────────────────────────────────────

class _CompactDoctorUpdateTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _CompactDoctorUpdateTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isCritical = alert['severity'] == 'critical';
    final type = alert['type'] as String;

    final Color baseColor = isCritical
        ? Colors.red.shade700
        : Colors.orange.shade700;
    final Color bgColor = isCritical
        ? Colors.red.withValues(alpha: 0.03)
        : Colors.orange.withValues(alpha: 0.03);
    final Color borderColor = isCritical
        ? Colors.red.withValues(alpha: 0.2)
        : Colors.orange.withValues(alpha: 0.2);

    IconData icon;
    switch (type) {
      case 'running_late':
        icon = LucideIcons.clock;
        break;
      case 'called_sick':
        icon = LucideIcons.userX;
        break;
      case 'canceled_block':
        icon = LucideIcons.calendarX2;
        break;
      default:
        icon = LucideIcons.alertCircle;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10), // Tighter padding
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SMALLER ICON BOX ---
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: baseColor, size: 16),
          ),

          const SizedBox(width: 10),

          // --- COMPRESSED CONTENT ---
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Title and Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert['doctorName'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      alert['time'],
                      style: context.text.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(150),
                        fontWeight: FontWeight.w600,
                        fontSize: 9, // Smaller timestamp
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // 2. Issue Description
                Text(
                  alert['issue'],
                  style: context.text.labelSmall?.copyWith(
                    color: baseColor,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(), // Pushes bottom row down
                // 3. Impact & Inline Action Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Impact Text
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 10,
                            color: colorScheme.onSurfaceVariant.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              alert['impact'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withAlpha(
                                  200,
                                ),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Compact Action Link
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            alert['actionText'],
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: baseColor,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 12,
                            color: baseColor,
                          ),
                        ],
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
