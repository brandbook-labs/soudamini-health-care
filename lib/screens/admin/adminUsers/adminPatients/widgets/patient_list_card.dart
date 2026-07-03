// lib/screens/admin/adminUsers/adminPatients/widgets/patient_list_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/patient_model.dart';

class PatientListCard extends StatelessWidget {
  final Patient patient;
  final VoidCallback onTap;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const PatientListCard({
    super.key,
    required this.patient,
    required this.onTap,
    required this.onCall,
    required this.onChat,
  });

  // 🚀 [THE FIX]: ଷ୍ଟାଟସ୍ ଅନୁଯାୟୀ ସଠିକ୍ ରଙ୍ଗ (Color Logic)
  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'pending') return Colors.orange.shade600;
    if (s == 'confirmed') return Colors.blue.shade600;
    if (s == 'check_in' || s == 'checked_in') return Colors.purple.shade600;
    if (s == 'completed') return Colors.green.shade600;
    if (s == 'cancelled' || s == 'canceled' || s == 'no_show') return Colors.red.shade600;
    return Colors.grey.shade600; // Default fallback
  }

  // 🚀 [THE FIX]: ଷ୍ଟାଟସ୍ ଟେକ୍ସଟ୍ କୁ ସୁନ୍ଦର କରିବା (Format Status Text)
  String _formatStatus(String status) {
    if (status.isEmpty) return "Unknown";
    return status.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return "";
      return "${word[0].toUpperCase()}${word.substring(1)}";
    }).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 🚀 Dynamic Status Color & Text
    final statusColor = _getStatusColor(patient.status);
    final statusText = _formatStatus(patient.status);

    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          highlightColor: colorScheme.primary.withValues(alpha: 0.05),
          splashColor: colorScheme.primary.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- 1. COMPACT AVATAR ---
                Container(
                  width: 48, 
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      patient.name.isNotEmpty
                          ? patient.name[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // --- 2. CONDENSED INFO COLUMN ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name & Status Inline
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              patient.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 🚀 Ultra-compact dynamic status pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Phone & Age Inline
                      Text(
                        "${patient.phone}  •  ${patient.age} Yrs",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Last Visit
                      Text(
                        "Visit: ${patient.lastVisit.isEmpty ? 'N/A' : patient.lastVisit}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // --- 3. HORIZONTAL QUICK ACTIONS ---
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(
                      icon: LucideIcons.phone,
                      color: Colors.green.shade600,
                      onTap: onCall,
                    ),
                    const SizedBox(width: 8), 
                    _buildIconButton(
                      icon: LucideIcons.messageCircle,
                      color: colorScheme.primary,
                      onTap: onChat,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 18,
                      color: theme.dividerColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TINY ICON BUTTON WIDGET ---
  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36, 
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 16,
            color: color,
          ), 
        ),
      ),
    );
  }
}