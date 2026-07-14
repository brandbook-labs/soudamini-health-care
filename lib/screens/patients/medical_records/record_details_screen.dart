// lib/screens/medical_records/record_details_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'models/record_model.dart';

class RecordDetailsScreen extends StatelessWidget {
  final MedicalRecordModel record;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RecordDetailsScreen({
    super.key,
    required this.record,
    this.onEdit,
    this.onDelete,
  });

  // --- UI HELPER: Get Icon and Color based on Record Type ---
  Map<String, dynamic> _getTypeConfig(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.labReport:
        return {
          'icon': LucideIcons.testTube2,
          'color': const Color(0xFF0EA5E9),
        };
      case MedicalRecordType.prescription:
        return {'icon': LucideIcons.pill, 'color': const Color(0xFFE11D48)};
      case MedicalRecordType.dischargeSummary:
      case MedicalRecordType.admissionForm:
        return {
          'icon': LucideIcons.clipboardPaste,
          'color': const Color(0xFF10B981),
        };
      case MedicalRecordType.scanImage:
        return {'icon': LucideIcons.scan, 'color': const Color(0xFF8B5CF6)};
      case MedicalRecordType.other:
        return {'icon': LucideIcons.fileText, 'color': const Color(0xFF64748B)};
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    final typeConfig = _getTypeConfig(record.type);
    final typeColor = typeConfig['color'] as Color;

    return Scaffold(
      backgroundColor: Colors.white, // Pure flat white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 🚀 Action Menu for Edit/Delete
          PopupMenuButton<String>(
            icon: const Icon(
              LucideIcons.moreVertical,
              color: Colors.black87,
              size: 20,
            ),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: borderCol),
            ),
            elevation: 4,
            offset: const Offset(0, 40),
            onSelected: (value) {
              if (value == 'edit' && onEdit != null) onEdit!();
              if (value == 'delete' && onDelete != null) onDelete!();
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(LucideIcons.edit3, size: 16, color: Colors.black87),
                    SizedBox(width: 12),
                    Text(
                      "Edit Details",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: Color(0xFFE11D48),
                    ),
                    SizedBox(width: 12),
                    Text(
                      "Delete Record",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER & QUICK ACTIONS ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Date Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              typeConfig['icon'],
                              size: 12,
                              color: typeColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              record.typeString.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text("•", style: TextStyle(color: Colors.black26)),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('dd MMM yyyy').format(record.date),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Document Title
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🚀 ACTION BAR: The primary user needs
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            // View document logic
                          },
                          icon: const Icon(LucideIcons.eye, size: 18),
                          label: const Text(
                            "View Document",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          // Download logic
                        },
                        icon: const Icon(
                          LucideIcons.download,
                          color: Colors.black87,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: bgLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: borderCol),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          // Share logic
                        },
                        icon: const Icon(
                          LucideIcons.share2,
                          color: Colors.black87,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: bgLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: borderCol),
                          ),
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: borderCol, height: 1),

            // --- 2. CLINICAL METADATA (Enterprise Grid Layout) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RECORD DETAILS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Property Grid
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: borderCol),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildPropertyRow(
                          "Provider / Clinic",
                          record.linkedProviderName ?? "Self Uploaded",
                          isTop: true,
                        ),
                        const Divider(color: borderCol, height: 1),
                        _buildPropertyRow(
                          "Date of Record",
                          DateFormat('dd MMMM yyyy').format(record.date),
                        ),
                        const Divider(color: borderCol, height: 1),
                        _buildPropertyRow(
                          "Verification Status",
                          record.linkedProviderId != null
                              ? "Verified by Jivan"
                              : "Unverified Upload",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. REALISTIC FILE PREVIEW ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ATTACHMENT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black45,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (record.fileUrl != null)
                    InkWell(
                      onTap: () {
                        // View document logic
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgLight,
                          border: Border.all(color: borderCol),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: borderCol),
                              ),
                              child: Icon(
                                typeConfig['icon'],
                                size: 28,
                                color: typeColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    record.fileUrl!.split('/').last,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "PDF Document • 1.2 MB", // Mock size
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderCol,
                          style: BorderStyle.solid,
                        ), // Dotted in real app
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            LucideIcons.fileQuestion,
                            size: 28,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "No document attached",
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- 4. NOTES SECTION ---
            if (record.notes != null && record.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ADDITIONAL NOTES",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3).withValues(
                          alpha: 0.3,
                        ), // Very soft yellow sticky note feel
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEF08A)),
                      ),
                      child: Text(
                        record.notes!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // --- 5. BUSINESS HOOK (Optional Action) ---
            if (record.type == MedicalRecordType.labReport) ...[
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.stethoscope,
                          color: primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Need an expert opinion?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Book a quick consult to review these results.",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER FOR METADATA GRID ---
  Widget _buildPropertyRow(String label, String value, {bool isTop = false}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: value == "Verified by Jivan"
                    ? const Color(0xFF4F46E5)
                    : Colors.black87,
                fontSize: 14,
                fontWeight: value == "Verified by Jivan"
                    ? FontWeight.bold
                    : FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
