import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart'; // Add intl: ^0.18.0 to pubspec.yaml

// --- 1. MODEL CLASS (Exact Replica of React Logic) ---
class SlotModel {
  String id;
  String label;
  String start; // Format: "HH:mm" (24h)
  String end; // Format: "HH:mm" (24h)
  String type; // "weekly" or "pattern"
  List<String> days;
  List<int> patternWeeks;
  List<String> patternDays;

  SlotModel({
    required this.id,
    required this.label,
    this.start = "14:00",
    this.end = "18:00",
    this.type = "weekly",
    List<String>? days,
    List<int>? patternWeeks,
    List<String>? patternDays,
  }) : days = days ?? [],
       patternWeeks = patternWeeks ?? [],
       patternDays = patternDays ?? [];

  // --- LOGIC: GENERATE AUTO LABEL (Ported from React) ---
  void generateLabel() {
    String formatTime(String t) {
      if (t.isEmpty) return "";
      try {
        final DateTime dt = DateFormat("HH:mm").parse(t);
        return DateFormat("h:mm a").format(dt); // 2:00 PM
      } catch (e) {
        return t;
      }
    }

    String startTime = formatTime(start);
    String endTime = formatTime(end);
    String timeRange = "$startTime to $endTime";
    String prefix = "";

    const allDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    if (type == "weekly") {
      if (days.isNotEmpty) {
        // Sort days based on index
        days.sort((a, b) => allDays.indexOf(a).compareTo(allDays.indexOf(b)));

        bool isConsecutive = true;
        if (days.length > 1) {
          for (int i = 0; i < days.length - 1; i++) {
            if (allDays.indexOf(days[i + 1]) != allDays.indexOf(days[i]) + 1) {
              isConsecutive = false;
              break;
            }
          }
        }

        if (days.length == 7) {
          prefix = "Everyday";
        } else if (days.length == 5 && isConsecutive && days[0] == "Mon") {
          prefix = "Mon to Fri";
        } else if (isConsecutive && days.length > 2) {
          prefix = "${days.first} to ${days.last}";
        } else {
          prefix = days.join(", "); // React: formatList logic
        }
      } else {
        prefix = "Select Days";
      }
    } else {
      // Pattern Logic
      patternWeeks.sort();
      final wLabels = patternWeeks.map((w) => w == 5 ? "Last" : "$w").toList();
      final dLabels = patternDays
          .map((d) => d.toUpperCase().substring(0, 3))
          .toList();

      String wStr = wLabels.join(", "); // Simplified join
      String dStr = dLabels.join(", ");

      prefix = "${wStr.isNotEmpty ? "WK $wStr" : ""} $dStr".trim();
    }

    label = "$prefix - $timeRange".trim();
  }
}

class SlotCreateScreen extends StatefulWidget {
  const SlotCreateScreen({super.key});

  @override
  State<SlotCreateScreen> createState() => _SlotCreateScreenState();
}

class _SlotCreateScreenState extends State<SlotCreateScreen> {
  // State matches formData.slots
  List<SlotModel> _slots = [];

  // --- ACTIONS ---

  // Equivalent to handleAddSlot in React
  void _addSlot() {
    String nextStart = "14:00";
    String nextEnd = "18:00";

    if (_slots.isNotEmpty) {
      final lastSlot = _slots.last;
      nextStart = lastSlot.end;

      try {
        int h = int.parse(nextStart.split(":")[0]);
        int m = int.parse(nextStart.split(":")[1]);

        int endH = h + 3; // React logic: h + 3
        if (endH > 23) endH = 23;

        nextEnd =
            "${endH.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    final newSlot = SlotModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: "",
      start: nextStart,
      end: nextEnd,
      type: "weekly",
    );
    newSlot.generateLabel();

    setState(() {
      _slots.add(newSlot);
    });
  }

  void _removeSlot(String id) {
    setState(() {
      _slots.removeWhere((s) => s.id == id);
    });
  }

  // Generic updater that triggers label regeneration
  void _updateSlot(String id, Function(SlotModel) updater) {
    setState(() {
      final slot = _slots.firstWhere((s) => s.id == id);
      updater(slot);
      slot.generateLabel();
    });
  }

  // API Submit simulation
  void _handleSubmit() {
    // Transform data exactly like the React 'handleSubmit' logic
    final apiPayload = _slots
        .map(
          (s) => {
            "label": s.label,
            "value": "slot-${s.id}", // Simple slugify
            "start": s.start,
            "end": s.end,
            "type": s.type,
            "recurrence": s.type == "pattern"
                ? {"weeks": s.patternWeeks, "days": s.patternDays}
                : {"weeks": [], "days": s.days},
          },
        )
        .toList();

    print("API Payload: $apiPayload");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Saved ${_slots.length} slots (Check Console)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dark Theme Colors
    const bgMain = Color(0xFF09090B);
    const bgCard = Color(0xFF18181B); // Zinc 900
    const border = Color(0xFF27272A);
    const primary = Color(0xFF4F46E5); // Indigo 600

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: bgMain,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Slots",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.save, color: primary),
            onPressed: _handleSubmit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Switch for Enable Booking (Visual only for this snippet)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Enable Booking",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Switch(
                    value: true,
                    onChanged: (val) {},
                    activeColor: primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Slots List
            ..._slots.map(
              (slot) => _SlotCard(
                slot: slot,
                onRemove: () => _removeSlot(slot.id),
                onUpdate: (updater) => _updateSlot(slot.id, updater),
              ),
            ),

            // Add Button
            GestureDetector(
              onTap: _addSlot,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: border,
                    style: BorderStyle.solid,
                  ), // Dashed border needs a package, using solid for now
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.plus, color: Colors.grey, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Add New Slot",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Safe area bottom
          ],
        ),
      ),
    );
  }
}

// --- 2. SLOT CARD COMPONENT ---
class _SlotCard extends StatelessWidget {
  final SlotModel slot;
  final VoidCallback onRemove;
  final Function(Function(SlotModel)) onUpdate;

  const _SlotCard({
    required this.slot,
    required this.onRemove,
    required this.onUpdate,
  });

  // Time Picker helper
  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialStr = isStart ? slot.start : slot.end;
    final parts = initialStr.split(":");
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: Color(0xFF4F46E5)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Format back to HH:mm for logic
      final formatted =
          "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      onUpdate((s) {
        if (isStart)
          s.start = formatted;
        else
          s.end = formatted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF18181B); // Zinc 900
    const borderCol = Color(0xFF27272A);
    const primary = Color(0xFF4F46E5);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Label + Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.label.isEmpty ? "New Slot" : slot.label,
                  style: const TextStyle(
                    color: Color(0xFF818CF8), // Indigo 400
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time Inputs
          Row(
            children: [
              Expanded(
                child: _TimeInput(
                  time: slot.start,
                  onTap: () => _pickTime(context, true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 14,
                  color: Colors.grey,
                ),
              ),
              Expanded(
                child: _TimeInput(
                  time: slot.end,
                  onTap: () => _pickTime(context, false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type Toggle (Weekly / Pattern)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B), // Zinc 950
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _TypeButton(
                  title: "Weekly",
                  isSelected: slot.type == "weekly",
                  onTap: () => onUpdate((s) => s.type = "weekly"),
                ),
                _TypeButton(
                  title: "Pattern",
                  isSelected: slot.type == "pattern",
                  onTap: () => onUpdate((s) => s.type = "pattern"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Conditional UI based on Type
          if (slot.type == "weekly")
            _WeeklySelector(
              selectedDays: slot.days,
              onToggle: (day) => onUpdate((s) {
                if (s.days.contains(day))
                  s.days.remove(day);
                else
                  s.days.add(day);
              }),
            )
          else
            _PatternSelector(
              weeks: slot.patternWeeks,
              days: slot.patternDays,
              onToggleWeek: (wk) => onUpdate((s) {
                if (s.patternWeeks.contains(wk))
                  s.patternWeeks.remove(wk);
                else
                  s.patternWeeks.add(wk);
              }),
              onToggleDay: (day) => onUpdate((s) {
                if (s.patternDays.contains(day))
                  s.patternDays.remove(day);
                else
                  s.patternDays.add(day);
              }),
            ),

          // Recurrence Label (Pattern only)
          if (slot.type == 'pattern')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  // Simple mimic of getRecurrenceLabel logic
                  (slot.patternWeeks.isEmpty && slot.patternDays.isEmpty)
                      ? "Select weeks and days above"
                      : "Pattern selected",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// --- 3. HELPER WIDGETS ---

class _TimeInput extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeInput({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Text(
          time, // Display 24h as per React state, or convert to 12h if preferred
          style: const TextStyle(color: Color(0xFFE4E4E7), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklySelector extends StatelessWidget {
  final List<String> selectedDays;
  final Function(String) onToggle;

  const _WeeklySelector({required this.selectedDays, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (day) => _DayCircle(
              text: day[0],
              isSelected: selectedDays.contains(day),
              onTap: () => onToggle(day),
            ),
          )
          .toList(),
    );
  }
}

class _PatternSelector extends StatelessWidget {
  final List<int> weeks;
  final List<String> days;
  final Function(int) onToggleWeek;
  final Function(String) onToggleDay;

  const _PatternSelector({
    required this.weeks,
    required this.days,
    required this.onToggleWeek,
    required this.onToggleDay,
  });

  @override
  Widget build(BuildContext context) {
    const weekOpts = [1, 2, 3, 4, 5];
    const dayOpts = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "WEEKS",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: weekOpts
              .map(
                (w) => Expanded(
                  child: _PatternButton(
                    text: w == 5 ? "L" : "$w",
                    isSelected: weeks.contains(w),
                    onTap: () => onToggleWeek(w),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        const Text(
          "DAYS",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: dayOpts
              .map(
                (d) => Expanded(
                  child: _PatternButton(
                    text: d[0],
                    isSelected: days.contains(d),
                    onTap: () => onToggleDay(d),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DayCircle extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayCircle({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF27272A),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PatternButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _PatternButton({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4F46E5).withOpacity(0.2)
              : const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4F46E5).withOpacity(0.5)
                : const Color(0xFF27272A),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF818CF8) : Colors.grey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
