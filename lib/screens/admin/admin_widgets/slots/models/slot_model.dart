// lib/screens/slots/models/slot_model.dart

class SlotModel {
  String id;
  String value;
  String label;
  String start;
  String end;
  String type;
  List<String> days;
  List<int> patternWeeks;
  List<String> patternDays;
  List<String> doctorIds;

  SlotModel({
    required this.id,
    required this.value,
    required this.label,
    this.start = "09:00",
    this.end = "13:00",
    this.type = "weekly",
    List<String>? days,
    List<int>? patternWeeks,
    List<String>? patternDays,
    List<String>? doctorIds,
  }) : days = days ?? [],
       patternWeeks = patternWeeks ?? [],
       patternDays = patternDays ?? [],
       doctorIds = doctorIds ?? [];

  void generateLabel() {
    String formatTime(String t) {
      if (t.isEmpty) {
        return "";
      }
      try {
        final parts = t.split(":");
        final hr = int.parse(parts[0]);
        final min = parts[1];
        final ampm = hr >= 12 ? "PM" : "AM";
        final hour12 = hr % 12 == 0 ? 12 : hr % 12;
        return "$hour12${min != '00' ? ':$min' : ''}$ampm";
      } catch (e) {
        return t;
      }
    }

    String startTime = formatTime(start);
    String endTime = formatTime(end);
    String timeRange = "$startTime to $endTime";

    String formatList(List<String> arr) {
      if (arr.isEmpty) {
        return "";
      }
      if (arr.length == 1) {
        return arr[0];
      }
      if (arr.length == 2) {
        return "${arr[0]} & ${arr[1]}";
      }
      return "${arr.sublist(0, arr.length - 1).join(', ')} & ${arr.last}";
    }

    String prefix = "";

    if (type == "weekly") {
      final allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
      if (days.isNotEmpty) {
        List<String> sorted = List.from(days)
          ..sort((a, b) => allDays.indexOf(a).compareTo(allDays.indexOf(b)));
        bool isConsecutive = true;
        if (sorted.length > 1) {
          for (int i = 0; i < sorted.length - 1; i++) {
            if (allDays.indexOf(sorted[i + 1]) !=
                allDays.indexOf(sorted[i]) + 1) {
              isConsecutive = false;
              break;
            }
          }
        }
        if (days.length == 7) {
          prefix = "Everyday";
        } else if (days.length == 5 && isConsecutive && sorted[0] == "Mon") {
          prefix = "Mon to Fri";
        } else if (isConsecutive && sorted.length > 2) {
          prefix = "${sorted.first} to ${sorted.last}";
        } else {
          prefix = formatList(sorted);
        }
      } else {
        prefix = "Select Days";
      }
    } else {
      List<String> wStrList =
          patternWeeks.toList().map((e) => e.toString()).toList()..sort();
      List<String> wFormatted = wStrList
          .map((w) => w == "5" ? "Last" : w)
          .toList();
      List<String> dFormatted = patternDays
          .map((d) => d.substring(0, 3).toUpperCase())
          .toList();

      String wStr = formatList(wFormatted);
      String dStr = formatList(dFormatted);
      prefix = "${wStr.isNotEmpty ? 'WK $wStr' : ''} $dStr".trim();
    }
    label = "$prefix - $timeRange".trim();
  }
}
