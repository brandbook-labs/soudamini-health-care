// lib/screens/slots/widgets/doctor_selector.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DoctorSelector extends StatelessWidget {
  final List<Map<String, dynamic>> doctorList;
  final List<String> selectedIds;
  final Function(String) onToggle;

  const DoctorSelector({
    super.key,
    required this.doctorList,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (doctorList.isEmpty) {
      return const Text(
        "No doctors available",
        style: TextStyle(color: Colors.black54),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: doctorList.map((doc) {
          final isSelected = selectedIds.contains(doc['id']);
          return GestureDetector(
            onTap: () => onToggle(doc['id']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4F46E5)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: NetworkImage(doc['image']),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    doc['name'],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF4F46E5)
                          : Colors.black87,
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      LucideIcons.checkCircle2,
                      size: 16,
                      color: Color(0xFF4F46E5),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
