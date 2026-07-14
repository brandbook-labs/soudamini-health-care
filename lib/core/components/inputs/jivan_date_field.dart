import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'jivan_text_field.dart';

class JivanDateField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const JivanDateField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Format the date nicely (e.g., 2026-01-28)
    // You can use intl package here if you want cleaner formatting later
    final textValue = selectedDate != null
        ? "${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}"
        : "";

    final controller = TextEditingController(text: textValue);

    return JivanTextField(
      label: label,
      controller: controller,

      // 2. These properties now work!
      readOnly: true,
      hintText: "DD/MM/YYYY", // Fixed param name

      prefixIcon: const Icon(LucideIcons.calendar),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(1900),
          lastDate: lastDate ?? DateTime(2100),
          builder: (context, child) {
            // Optional: Customize DatePicker Theme to match app
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(
                  context,
                ).colorScheme, // Uses your app theme
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateSelected(picked);
        }
      },
    );
  }
}
