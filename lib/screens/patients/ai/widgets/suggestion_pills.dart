import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SuggestionPills extends StatelessWidget {
  final List<Map<String, String>> options;
  final Function(String) onSelect;

  const SuggestionPills({
    super.key,
    required this.options,
    required this.onSelect,
  });

  // Helper to map string names from the AI to actual Lucide Icons
  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'thermometer':
        return LucideIcons.thermometer;
      case 'activity':
        return LucideIcons.activity;
      case 'stomach':
        return LucideIcons.coffee;
      case 'skin':
        return LucideIcons.sparkles;
      case 'clock':
        return LucideIcons.clock;
      case 'calendar':
        return LucideIcons.calendar;
      case 'alert':
        return LucideIcons.alertCircle;
      case 'bone':
        return LucideIcons.bone;
      default:
        return LucideIcons.helpCircle; // Fallback icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((option) {
          final String label = option['label'] ?? '';
          final String iconName = option['icon'] ?? 'help';

          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                onSelect(label); // We only send the text label back to the chat
              },
              borderRadius: BorderRadius.circular(20),
              splashColor: const Color(0xFF1660FF).withValues(alpha: 0.1),
              highlightColor: Colors.transparent,
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.85, // Made slightly wider for the new layout
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF18181B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade100,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // --- VISUAL ICON CONTAINER ---
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1660FF).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIcon(iconName),
                        color: const Color(0xFF1660FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // --- TEXT LABEL ---
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          letterSpacing: -0.3,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    // --- ACTION INDICATOR ---
                    Icon(
                      LucideIcons.chevronRight,
                      size: 20,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
