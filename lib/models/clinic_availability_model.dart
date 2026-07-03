import 'package:intl/intl.dart';

class WeeklyAvailability {
  final String label; // e.g., "Fri, Jan 30"
  final String status; // "Available" or "Unavailable"
  final List<ClinicSlot> slots;
  final DateTime? parsedDate;

  WeeklyAvailability({
    required this.label,
    required this.status,
    required this.slots,
    this.parsedDate,
  });

  factory WeeklyAvailability.fromJson(Map<String, dynamic> json) {
    // 1. Parse Label to Date (Handle "Sat, Jan 31" -> DateTime)
    DateTime? dateObj;
    String rawLabel = json['label']?.toString() ?? '';

    if (rawLabel.isNotEmpty) {
      try {
        // Remove day name if present (e.g. "Sat, ")
        List<String> parts = rawLabel.split(',');
        String datePart = parts.length > 1 ? parts[1].trim() : parts[0].trim();

        final now = DateTime.now();
        // Parse "MMM d" (e.g. "Jan 31")
        DateTime temp = DateFormat("MMM d", 'en_US').parse(datePart);

        // Construct date with current year
        dateObj = DateTime(now.year, temp.month, temp.day);

        // Handle Year Rollover (e.g. Current is Dec, Slot is Jan)
        if (dateObj.month < now.month && now.month == 12) {
          dateObj = DateTime(now.year + 1, temp.month, temp.day);
        }
      } catch (e) {
        print("Date parsing error for label $rawLabel: $e");
      }
    }

    return WeeklyAvailability(
      label: rawLabel,
      status: json['status'] ?? 'Unavailable',
      parsedDate: dateObj,
      slots:
          (json['slots'] as List?)
              ?.map((e) => ClinicSlot.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ClinicSlot {
  final String label;
  final String value;
  final String start;
  final String end;
  final String type;

  ClinicSlot({
    required this.label,
    required this.value,
    required this.start,
    required this.end,
    required this.type,
  });

  factory ClinicSlot.fromJson(Map<String, dynamic> json) {
    return ClinicSlot(
      label: json['label']?.toString() ?? '',
      value: json['value']?.toString() ?? '',
      start: json['start']?.toString() ?? '',
      end: json['end']?.toString() ?? '',
      type: json['type']?.toString() ?? 'regular',
    );
  }

  String get formattedRange {
    return "${_formatTime(start)} - ${_formatTime(end)}";
  }

  String _formatTime(String time24) {
    if (time24.isEmpty) return "";
    try {
      final parts = time24.split(':');
      final dt = DateTime(2022, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return time24;
    }
  }
}
