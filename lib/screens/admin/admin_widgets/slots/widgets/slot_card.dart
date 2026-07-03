// lib/screens/slots/widgets/slot_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/theme/app_colors.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this matches your project

import '../models/slot_model.dart';
import 'time_box.dart';
import 'doctor_selector.dart';
import 'recurrence_selectors.dart';

class SlotCard extends StatelessWidget {
  final SlotModel slot;
  final List<Map<String, dynamic>> doctorList;
  final VoidCallback onRemove;
  final Function(Function(SlotModel)) onUpdate;
  final Function(String) onDoctorToggle;

  const SlotCard({
    super.key,
    required this.slot,
    required this.doctorList,
    required this.onRemove,
    required this.onUpdate,
    required this.onDoctorToggle,
  });

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final tStr = isStart ? slot.start : slot.end;
    final parts = tStr.split(":");
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF4F46E5),
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      onUpdate((s) => isStart ? s.start = formatted : s.end = formatted);
    }
  }

  // Helper widget for clean section headers
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      // Clean, modern card styling
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderCol, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ClipRRect ensures the thick bottom border stays inside the rounded corners
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(),
          padding: const EdgeInsets.all(20.0), // Proper internal breathing room
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------
              // SECTION 1: HEADER + DELETE BUTTON
              // ----------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildSectionHeader(
                    "ASSIGN DOCTORS",
                    LucideIcons.stethoscope,
                  ),
                  // Delete button moved here! It will never overlap anything.
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- DOCTOR SELECTION CONTENT ---
              if (doctorList.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 20,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "No doctors available. Please add doctors first to assign them.",
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DoctorSelector(
                  doctorList: doctorList,
                  selectedIds: slot.doctorIds,
                  onToggle: onDoctorToggle,
                ),

              const SizedBox(height: 24),

              // ----------------------------------------
              // SECTION 2: DAYS / WEEKLY / PATTERN
              // ----------------------------------------
              _buildSectionHeader("SCHEDULE PATTERN", LucideIcons.calendarDays),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    TabButton(
                      label: "Weekly",
                      isActive: slot.type == "weekly",
                      onTap: () => onUpdate((s) => s.type = "weekly"),
                    ),
                    TabButton(
                      label: "Pattern",
                      isActive: slot.type == "pattern",
                      onTap: () => onUpdate((s) => s.type = "pattern"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // 🚀 ଏଠାରେ ସମାଧାନ କରାଯାଇଛି: SingleChildScrollView ଲଗାଯାଇଛି ଯାହାଦ୍ୱାରା Overflow ନହୁଏ
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(), // ସ୍ମୁଥ୍ ସ୍କ୍ରୋଲିଂ ପାଇଁ
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: slot.type == "weekly"
                      ? WeeklySelector(
                          selectedDays: slot.days,
                          onToggle: (d) => onUpdate(
                            (s) => s.days.contains(d)
                                ? s.days.remove(d)
                                : s.days.add(d),
                          ),
                        )
                      : PatternSelector(
                          weeks: slot.patternWeeks,
                          days: slot.patternDays,
                          onToggleWeek: (w) => onUpdate(
                            (s) => s.patternWeeks.contains(w)
                                ? s.patternWeeks.remove(w)
                                : s.patternWeeks.add(w),
                          ),
                          onToggleDay: (d) => onUpdate(
                            (s) => s.patternDays.contains(d)
                                ? s.patternDays.remove(d)
                                : s.patternDays.add(d),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // ----------------------------------------
              // SECTION 3: TIME SELECTION
              // ----------------------------------------
              _buildSectionHeader("TIME WINDOW", LucideIcons.clock),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TimeBox(
                      label: "Start Time",
                      time: slot.start,
                      onTap: () => _pickTime(context, true),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      LucideIcons.arrowRight,
                      size: 16,
                      color: Colors.black38,
                    ),
                  ),
                  Expanded(
                    child: TimeBox(
                      label: "End Time",
                      time: slot.end,
                      onTap: () => _pickTime(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ----------------------------------------
              // SECTION 4: PREVIEW AT THE BOTTOM
              // ----------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.secondaryLight.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 18,
                      color: AppColors.secondaryLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        slot.label.isEmpty ? "Unconfigured Slot" : slot.label,
                        style: const TextStyle(
                          color: AppColors.secondaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
