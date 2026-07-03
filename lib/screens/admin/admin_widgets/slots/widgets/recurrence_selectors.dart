// lib/screens/slots/widgets/recurrence_selectors.dart
import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const TabButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? const Color(0xFF4F46E5) : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class WeeklySelector extends StatelessWidget {
  final List<String> selectedDays;
  final Function(String) onToggle;

  const WeeklySelector({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final isSelected = selectedDays.contains(d);
        return GestureDetector(
          onTap: () => onToggle(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : const Color(0xFFCBD5E1),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: Text(
              d.substring(0, 3),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class PatternSelector extends StatelessWidget {
  final List<int> weeks;
  final List<String> days;
  final Function(int) onToggleWeek;
  final Function(String) onToggleDay;

  const PatternSelector({
    super.key,
    required this.weeks,
    required this.days,
    required this.onToggleWeek,
    required this.onToggleDay,
  });

  String _getRecurrenceLabel() {
    if (weeks.isEmpty && days.isEmpty) return "Select weeks and days above";
    if (weeks.isEmpty) return "Select specific weeks";
    if (days.isEmpty) return "Select days";

    String formatList(List<String> arr) {
      if (arr.isEmpty) return "";
      if (arr.length == 1) return arr[0];
      if (arr.length == 2) return "${arr[0]} & ${arr[1]}";
      return "${arr.sublist(0, arr.length - 1).join(', ')} & ${arr.last}";
    }

    var sortedWeeks = List<int>.from(weeks)..sort();
    var weekLabels = sortedWeeks.map((w) {
      if (w == 5) return "Last";
      if (w == 1) return "1st";
      if (w == 2) return "2nd";
      if (w == 3) return "3rd";
      return "4th";
    }).toList();

    String weekString = formatList(weekLabels);
    String dayString = formatList(days.map((e) => e.substring(0, 3)).toList());

    return "$weekString $dayString";
  }

  @override
  Widget build(BuildContext context) {
    const weekOpts = [1, 2, 3, 4, 5];
    const dayOpts = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    Widget btn(String t, bool s, VoidCallback f) => Expanded(
      child: GestureDetector(
        onTap: f,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: s ? const Color(0xFF4F46E5) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: s ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
            ),
            boxShadow: s
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            t,
            style: TextStyle(
              color: s ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: s ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppPalette.info50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPalette.info200.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "SELECT WEEKS OF THE MONTH",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: weekOpts
                .map(
                  (w) => btn(
                    w == 5 ? "Last" : "${w}W",
                    weeks.contains(w),
                    () => onToggleWeek(w),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              "SELECT DAYS",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Row(
            children: dayOpts
                .map((d) => btn(d[0], days.contains(d), () => onToggleDay(d)))
                .toList(),
          ),
        ],
      ),
    );
  }
}
