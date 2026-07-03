// lib/screens/medical_records/widgets/record_type_selector.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/record_model.dart';

class RecordTypeSelector extends StatelessWidget {
  final MedicalRecordType selectedType;
  final ValueChanged<MedicalRecordType> onChanged;

  const RecordTypeSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  // Helper to map enum to beautiful UI configuration
  Map<String, dynamic> _getTypeConfig(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.labReport:
        return {
          'label': 'Lab Report',
          'icon': LucideIcons.testTube2,
          'color': const Color(0xFF0EA5E9),
        };
      case MedicalRecordType.prescription:
        return {
          'label': 'Prescription',
          'icon': LucideIcons.pill,
          'color': const Color(0xFFE11D48),
        };
      case MedicalRecordType.dischargeSummary:
        return {
          'label': 'Discharge Summary',
          'icon': LucideIcons.clipboardPaste,
          'color': const Color(0xFF10B981),
        };
      case MedicalRecordType.admissionForm:
        return {
          'label': 'Admission Form',
          'icon': LucideIcons.fileCheck2,
          'color': const Color(0xFF10B981),
        };
      case MedicalRecordType.scanImage:
        return {
          'label': 'Scan / X-Ray',
          'icon': LucideIcons.scan,
          'color': const Color(0xFF8B5CF6),
        };
      case MedicalRecordType.other:
        return {
          'label': 'Other',
          'icon': LucideIcons.fileText,
          'color': const Color(0xFF64748B),
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE2E8F0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: MedicalRecordType.values.map((type) {
          final config = _getTypeConfig(type);
          final isSelected = selectedType == type;
          final baseColor = config['color'] as Color;

          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? baseColor.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? baseColor : borderCol,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    config['icon'],
                    size: 16,
                    color: isSelected ? baseColor : Colors.black45,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    config['label'],
                    style: TextStyle(
                      color: isSelected ? baseColor : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
