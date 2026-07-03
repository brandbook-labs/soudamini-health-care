import 'package:intl/intl.dart';
import '../models/clinic_availability_model.dart';

class DoctorScheduleParser {
  /// 1. Main method to generate the calendar
  static List<WeeklyAvailability> generateCalendar({
    required List<dynamic> weeklySnapshots, // overrides
    required List<dynamic> recurrenceRules, // clinic patterns
    int daysToProject = 60,
  }) {
    final Map<String, WeeklyAvailability> consolidated = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // --- A. PROJECT RECURRING RULES ---
    for (int i = 0; i < daysToProject; i++) {
      final date = now.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // Logic: Calculate Week of Month & Last Week status
      final int weekOfMonth = ((date.day - 1) / 7).floor() + 1;
      final bool isLastWeek =
          date.month != date.add(const Duration(days: 7)).month;
      final String dayName = DateFormat('E').format(date); // e.g., "Sun"

      List<ClinicSlot> daySlots = [];

      for (var rule in recurrenceRules) {
        if (rule is! Map) continue;
        final recurrence = rule['recurrence'] ?? {};

        // 1. Day Match (e.g., "Sun" == "Sun")
        final List rawDays = (recurrence['days'] as List? ?? [])
            .map((e) => e.toString())
            .toList();

        if (!rawDays.contains(dayName)) continue;

        // 2. Week Match
        final List rawWeeks = (recurrence['weeks'] as List? ?? []);
        bool weekMatch = true;

        if (rawWeeks.isNotEmpty) {
          final weeksInt = rawWeeks
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .toList();
          bool specificMatch = weeksInt.contains(weekOfMonth);
          bool lastMatch = isLastWeek && weeksInt.contains(5); // 5 = Last week

          if (!specificMatch && !lastMatch) weekMatch = false;
        }

        if (!weekMatch) continue;

        // ✅ MATCH: Add Slot
        daySlots.add(
          ClinicSlot(
            label: rule['label'] ?? "${rule['start']}-${rule['end']}",
            value: rule['value'] ?? "",
            start: rule['start'] ?? "",
            end: rule['end'] ?? "",
            type: "pattern",
          ),
        );
      }

      // Add to map if slots exist
      if (daySlots.isNotEmpty) {
        // Sort slots by start time
        daySlots.sort((a, b) => a.start.compareTo(b.start));

        consolidated[dateKey] = WeeklyAvailability(
          label: DateFormat('EEE, MMM d').format(date),
          status: 'Available',
          slots: daySlots.toSet().toList(), // Remove generic duplicates
          parsedDate: date,
        );
      }
    }

    // --- B. MERGE OVERRIDES (Backend Specific Dates) ---
    for (var snapshot in weeklySnapshots) {
      if (snapshot['label'] == null) continue;

      try {
        // Parse date from label (e.g., "Sat, Jan 31")
        DateTime? dateObj = _parseDateFromLabel(snapshot['label'], now);
        if (dateObj == null) continue;

        final dateKey = DateFormat('yyyy-MM-dd').format(dateObj);

        // 1. Blocked Day
        if (snapshot['status'] == 'Unavailable') {
          // If you want to show it as "Unavailable" in UI, keep it but clear slots
          // Or remove it to hide it completely. Here we keep it to show status.
          consolidated[dateKey] = WeeklyAvailability(
            label: snapshot['label'],
            status: 'Unavailable',
            slots: [],
            parsedDate: dateObj,
          );
          continue;
        }

        // 2. Custom Slots for this specific day
        if (snapshot['slots'] != null &&
            (snapshot['slots'] as List).isNotEmpty) {
          List<ClinicSlot> specificSlots = (snapshot['slots'] as List)
              .map((s) => ClinicSlot.fromJson(s))
              .toList();

          consolidated[dateKey] = WeeklyAvailability(
            label: snapshot['label'],
            status: 'Available',
            slots: specificSlots,
            parsedDate: dateObj,
          );
        }
      } catch (e) {
        print("Error parsing snapshot: $e");
      }
    }

    // --- C. CLEANUP ---
    // Sort by date
    List<WeeklyAvailability> sortedList = consolidated.values.toList();
    sortedList.sort((a, b) {
      if (a.parsedDate == null || b.parsedDate == null) return 0;
      return a.parsedDate!.compareTo(b.parsedDate!);
    });

    // Remove past dates
    return sortedList.where((item) {
      if (item.parsedDate == null) return false;
      return !item.parsedDate!.isBefore(todayStart);
    }).toList();
  }

  static DateTime? _parseDateFromLabel(String label, DateTime now) {
    try {
      List<String> parts = label.split(',');
      String datePart = parts.length > 1 ? parts[1].trim() : parts[0].trim();
      DateTime temp = DateFormat("MMM d", 'en_US').parse(datePart);
      DateTime dateObj = DateTime(now.year, temp.month, temp.day);
      if (dateObj.month < now.month && now.month == 12) {
        dateObj = DateTime(now.year + 1, temp.month, temp.day);
      }
      return dateObj;
    } catch (_) {
      return null;
    }
  }
}
