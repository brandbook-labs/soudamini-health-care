// lib/screens/medical_records/widgets/record_list_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../models/record_model.dart';

class RecordListCard extends StatelessWidget {
  final MedicalRecordModel record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordListCard({
    super.key,
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  // --- UI HELPER: Get Icon and Color based on Record Type ---
  Map<String, dynamic> _getTypeConfig(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.labReport:
        return {
          'icon': LucideIcons.testTube2,
          'color': const Color(0xFF0EA5E9),
        }; // Blue
      case MedicalRecordType.prescription:
        return {
          'icon': LucideIcons.pill,
          'color': const Color(0xFFE11D48),
        }; // Rose
      case MedicalRecordType.dischargeSummary:
      case MedicalRecordType.admissionForm:
        return {
          'icon': LucideIcons.clipboardPaste,
          'color': const Color(0xFF10B981),
        }; // Green
      case MedicalRecordType.scanImage:
        return {
          'icon': LucideIcons.scan,
          'color': const Color(0xFF8B5CF6),
        }; // Violet
      case MedicalRecordType.other:
        return {
          'icon': LucideIcons.fileText,
          'color': const Color(0xFF64748B),
        }; // Slate
    }
  }

  // --- TAP AND HOLD ACTION MENU ---
  void _showActionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                "Record Options",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(LucideIcons.edit3, color: Colors.black87),
              title: const Text(
                "Edit Details",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2, color: Color(0xFFE11D48)),
              title: const Text(
                "Delete Record",
                style: TextStyle(
                  color: Color(0xFFE11D48),
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE2E8F0);
    final typeConfig = _getTypeConfig(record.type);
    final typeColor = typeConfig['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // Reduced to 12
        border: Border.all(color: borderCol, width: 1.0),
        // Shadows removed completely
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () =>
              _showActionOptions(context), // Tap and hold implemented
          borderRadius: BorderRadius.circular(12),
          highlightColor: typeColor.withValues(alpha: 0.05),
          splashColor: typeColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TYPE ICON ---
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(typeConfig['icon'], color: typeColor, size: 24),
                ),
                const SizedBox(width: 16),

                // --- MAIN CONTENT ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Date Row
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.calendarDays,
                            size: 14,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('dd MMM yyyy').format(record.date),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- LINKED PROVIDER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildLinkedProviderInfo(record)),

                          // Subtle Chevron indicating it's tappable
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- PREMIUM DYNAMIC BADGE ---
  Widget _buildLinkedProviderInfo(MedicalRecordModel record) {
    if (record.linkedProviderId == null && record.linkedProviderName == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // Slate
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            "No Provider Linked",
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final isJivan = record.linkedProviderId != null;
    final name = record.linkedProviderName ?? "Jivan Doctor";

    final bgColor = isJivan
        ? const Color(0xFF4F46E5).withValues(alpha: 0.08)
        : const Color(0xFFF8FAFC);
    final borderColor = isJivan
        ? const Color(0xFF4F46E5).withValues(alpha: 0.15)
        : const Color(0xFFE2E8F0);
    final textColor = isJivan ? const Color(0xFF4F46E5) : Colors.black87;

    // Requested Change: Icon is always LucideIcons.user regardless of Jivan status
    final icon = isJivan ? LucideIcons.user : LucideIcons.user;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
