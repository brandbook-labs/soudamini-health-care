// lib/screens/admin/adminUsers/adminPatients/tabs/clinical_history_tab.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class ClinicalHistoryTab extends StatelessWidget {
  final List<dynamic> historyData;

  const ClinicalHistoryTab({super.key, required this.historyData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          "Visit Timeline",
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        if (historyData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text("No past clinical history found.", style: TextStyle(color: colorScheme.onSurfaceVariant)),
            ),
          )
        else
          ...List.generate(historyData.length, (index) {
            final isLast = index == historyData.length - 1;
            return _TimelineNode(data: historyData[index], isLast: isLast);
          }),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isLast;

  const _TimelineNode({required this.data, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    final String date = data['date']?.toString() ?? 'N/A';
    final String time = data['start']?.toString() ?? '';
    final String status = data['status']?.toString() ?? 'unknown';
    final String typeRaw = data['appointment_type']?.toString() ?? 'Consultation';
    final String type = typeRaw.replaceAll('_', ' ').toUpperCase();
    final String doctor = data['doctor_name']?.toString() ?? 'Unknown Doctor';
    final List extraServices = data['extra_services'] ?? [];
    
    Color getStatusColor() {
      final s = status.toLowerCase();
      if (s == 'completed') return Colors.green;
      if (s == 'cancelled' || s == 'no_show') return Colors.red;
      return Colors.orange;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🚀 [THE FIX]: LEFT - Date & Time in Single Line layout
          SizedBox(
            width: 85, // Slightly wider for full date
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date, // 🚀 Single line (e.g., 25 Mar 2026)
                  style: context.text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurfaceVariant,
                  ),
                )
              ],
            ),
          ),

          // --- MIDDLE: Connected Line ---
          Column(
            children: [
              Container(
                width: 12, height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface, shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 3),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: colorScheme.primary.withValues(alpha: 0.2))),
            ],
          ),

          // --- RIGHT: Visit Card ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface, borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(type, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface, fontSize: 14))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: getStatusColor().withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(status.toUpperCase(), style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: getStatusColor(), fontSize: 9)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (doctor.isNotEmpty)
                      Row(
                        children: [
                          Icon(LucideIcons.stethoscope, size: 14, color: colorScheme.primary), const SizedBox(width: 6),
                          Text(doctor, style: context.text.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    
                    if (extraServices.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...extraServices.map((srv) {
                         return Text("• ${srv['name']}", style: context.text.bodyMedium?.copyWith(color: colorScheme.onSurface, height: 1.4));
                      }),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}