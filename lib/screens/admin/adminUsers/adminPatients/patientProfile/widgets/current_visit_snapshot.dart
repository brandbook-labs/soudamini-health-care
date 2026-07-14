// lib/screens/admin/adminUsers/adminPatients/widgets/current_visit_snapshot.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class CurrentVisitSnapshot extends StatelessWidget {
  final Map<String, dynamic> appointmentData;

  const CurrentVisitSnapshot({
    super.key,
    required this.appointmentData,
  });

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'completed') return Colors.green.shade600;
    if (s == 'cancelled' || s == 'no_show') return Colors.red.shade600;
    if (s == 'confirmed') return Colors.blue.shade600;
    if (s == 'check_in') return Colors.purple.shade600;
    return Colors.orange.shade600; 
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return "Unknown";
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    final String date = appointmentData['date'] ?? '';
    final String start = appointmentData['start'] ?? '';
    final String slot = appointmentData['slot_number'] ?? 'N/A';
    final String typeRaw = appointmentData['appointment_type'] ?? 'consultation';
    final String type = typeRaw.replaceAll('_', ' ').toUpperCase();
    final String statusRaw = appointmentData['status'] ?? 'pending';
    final String doctorName = appointmentData['doctor_name'] ?? '';
    final List extraServices = appointmentData['extra_services'] ?? [];

    final statusColor = _getStatusColor(statusRaw);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1.5), 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(LucideIcons.calendarCheck, size: 18, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Visit: Slot $slot • $date, $start",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    _formatStatus(statusRaw),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.3)),
          
          // --- BODY ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    type,
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (doctorName.isNotEmpty) ...[
                  Text("Doctor:", style: context.text.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(LucideIcons.stethoscope, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(doctorName, style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                if (extraServices.isNotEmpty) ...[
                  Text("Reason / Services:", style: context.text.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...extraServices.map((srv) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.check, size: 14, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "${srv['name']} (x${srv['count']})",
                              style: context.text.bodySmall?.copyWith(color: colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ] else ...[
                   Text("Reason:", style: context.text.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold)),
                   const SizedBox(height: 4),
                   Text("General Appointment", style: context.text.bodyMedium),
                ],
              ],
            ),
          ),
          
          // 🚀 [THE FIX]: Status Update Feature is Hidden as requested right now
          /*
          if (!isCompletedOrCancelled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                   const Divider(height: 24),
                   Row(
                     children: [ ... Update Buttons ... ]
                   ),
                ],
              ),
            ),
          */
        ],
      ),
    );
  }
}