import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AppointmentFeeSection extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;
  final double consultationFee;
  final double followUpFee;
  final bool isOdia;

  const AppointmentFeeSection({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.consultationFee,
    required this.followUpFee,
    required this.isOdia,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color.fromARGB(255, 22, 96, 255);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          isOdia ? "ଆପଣ କ'ଣ ଚାହୁଁଛନ୍ତି?" : "Appointment Type",
          isDarkMode,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTypeChip(
                  "Consultation",
                  "consultation",
                  isDarkMode,
                  primaryColor,
                ),
              ),
              Expanded(
                child: _buildTypeChip(
                  "Follow-up",
                  "follow_up",
                  isDarkMode,
                  primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle(
          context,
          isOdia ? "କ୍ଲିନିକ୍ ଫିସ୍" : "Clinic Fees",
          isDarkMode,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withValues(alpha: 0.9),
                      primaryColor.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.stethoscope,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOdia ? "ପରାମର୍ଶ" : "Consultation",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "₹${consultationFee.toInt()}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.refreshCcw,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isOdia ? "ଫଲୋ-ଅପ୍" : "Follow-up",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "₹${followUpFee.toInt()}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
    String label,
    String value,
    bool isDarkMode,
    Color primaryColor,
  ) {
    bool isSelected = selectedType == value;
    return GestureDetector(
      onTap: () => onTypeChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? const Color(0xFF2C2C2C) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected
                ? primaryColor
                : (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    bool isDarkMode,
  ) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }
}
