import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/models/clinic_availability_model.dart';

// 🚀 Theme Constants (Private to avoid collision)
const Color _primaryColor = Color.fromARGB(255, 22, 96, 255);
const Color _greenColor = Color(0xFF16A34A);

class BookingBottomSheet extends StatefulWidget {
  final String doctorName;
  final String clinicName;
  final List<WeeklyAvailability> weeklyAvailability;
  final bool isOdia;

  const BookingBottomSheet({
    super.key,
    required this.doctorName,
    required this.clinicName,
    required this.weeklyAvailability,
    required this.isOdia,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _selectedDateIndex = 0;
  ClinicSlot? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _autoSelectFirstSlot();
  }

  void _autoSelectFirstSlot() {
    for (int i = 0; i < widget.weeklyAvailability.length; i++) {
      if (widget.weeklyAvailability[i].status == "Available" &&
          widget.weeklyAvailability[i].slots.isNotEmpty) {
        setState(() {
          _selectedDateIndex = i;
          _selectedSlot = widget.weeklyAvailability[i].slots[0];
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weeklyAvailability.isEmpty) {
      return _buildEmptyState(context);
    }

    // ==============================================================
    // 🚀 SUPER SENIOR LOGIC: SEMANTIC COLOR PALETTE 🚀
    // ଏହି ଗୋଟିଏ ଜାଗାରେ ଉଭୟ Light ଏବଂ Dark mode ର ରଙ୍ଗ ପରିଚାଳିତ ହେବ।
    // ତଳେ ଆଉ କେଉଁଠି ବି ଟର୍ନାରୀ ଅପରେଟର୍ ( ? : ) ବ୍ୟବହାର କରିବା ଦରକାର ନାହିଁ।
    // ==============================================================
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color surfaceColor = isDarkMode ? const Color(0xFF252525) : Colors.white;
    final Color surfaceHighlight = isDarkMode ? const Color(0xFF2C2C2C) : Colors.grey.shade50;
    
    final Color textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final Color borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    
    final Color disabledBgColor = isDarkMode ? Colors.white10 : Colors.grey.shade100;
    final Color disabledIconColor = isDarkMode ? Colors.white24 : Colors.black26;
    final Color shadowColor = Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.08);
    // ==============================================================

    final currentDay = widget.weeklyAvailability[_selectedDateIndex];
    final isDayUnavailable = currentDay.status == "Unavailable" || currentDay.slots.isEmpty;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: shadowColor, 
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Handle Bar ---
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: disabledIconColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // --- Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isOdia ? "ସମୟ ବାଛନ୍ତୁ" : "Select Slot",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${widget.doctorName} • ${widget.clinicName}",
                        style: TextStyle(
                          fontSize: 13,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, size: 20, color: textColor),
                  style: IconButton.styleFrom(
                    backgroundColor: disabledBgColor,
                  ),
                ),
              ],
            ),
          ),

          // --- Date Scrubber ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(widget.weeklyAvailability.length, (index) {
                final dayData = widget.weeklyAvailability[index];
                final isSelected = index == _selectedDateIndex;
                final isUnavailable = dayData.status == "Unavailable";

                final labelParts = dayData.label.split(', ');
                final dayName = labelParts.isNotEmpty ? labelParts[0] : "";
                final dateStr = labelParts.length > 1 ? labelParts[1] : "";

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                      _selectedSlot = null; 
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : surfaceHighlight,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? _primaryColor : borderColor,
                        width: 1.5,
                      ),
                      boxShadow: isSelected && !isDarkMode
                          ? [BoxShadow(color: _primaryColor.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white.withValues(alpha: 0.9) : subTextColor,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isSelected ? Colors.white : textColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isUnavailable
                                ? Colors.redAccent.withValues(alpha: isSelected ? 1 : 0.5) 
                                : _greenColor.withValues(alpha: isSelected ? 1 : 0.5), 
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: borderColor),
          const SizedBox(height: 16),

          // --- SMART SLOTS CONTENT ---
          Expanded(
            child: isDayUnavailable
                ? _buildDayUnavailableState(context, disabledBgColor, subTextColor, textColor)
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: currentDay.slots.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final slot = currentDay.slots[index];
                      
                      // 🚀 [SUPER SENIOR FIX]: Unique Selection Logic
                      // କେବଳ slot.value ନୁହେଁ, ବରଂ ପୁରା ବସ୍ତୁ (Object) ର ସମାନତା ଯାଞ୍ଚ କରାଯାଉଛି।
                      // ଏହାଦ୍ୱାରା ନିଶ୍ଚିତ ହେବ ଯେ କେବଳ ଗୋଟିଏ ହିଁ ସ୍ଲଟ୍ ନୀଳ ରଙ୍ଗ (Selected) ହେବ।
                      final isSelected = _selectedSlot != null && 
                                         _selectedSlot!.value == slot.value && 
                                         _selectedSlot!.label == slot.label;
                                         
                      final isPattern = slot.type == 'pattern';

                      final String mainTimeText = (slot.start.isNotEmpty && slot.end.isNotEmpty) 
                          ? "${slot.start} - ${slot.end}" 
                          : slot.label;

                      return InkWell(
                        // 🚀 [SUPER SENIOR FIX]: ମାନୁଆଲି State Update ସଠିକ୍ ଭାବେ ହେବା ପାଇଁ
                        onTap: () {
                          if (!isSelected) {
                            setState(() {
                              _selectedSlot = slot;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected ? _primaryColor.withValues(alpha: 0.1) : surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _primaryColor : borderColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                color: isSelected ? _primaryColor : subTextColor,
                                size: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      mainTimeText,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? _primaryColor : textColor,
                                      ),
                                    ),
                                    if (isPattern && slot.label != mainTimeText) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        slot.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? _primaryColor.withValues(alpha: 0.8) : subTextColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSelected ? _primaryColor : disabledBgColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isPattern ? "PATTERN" : "REGULAR",
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: isSelected ? Colors.white : subTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // --- Bottom Button ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _selectedSlot == null
                    ? null
                    : () {
                        // 🚀 NO CHANGES TO THIS INTEGRATION
                        String formattedDate = currentDay.label;
                        if (currentDay.parsedDate != null) {
                          formattedDate = DateFormat('yyyy-MM-dd').format(currentDay.parsedDate!);
                        }

                        Navigator.pop(context, {
                          'slot_id': _selectedSlot!.value, 
                          'date': formattedDate, 
                          'slotTime': _selectedSlot!.formattedRange,
                        });
                      },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: isDarkMode ? 0 : 4,
                  shadowColor: _primaryColor.withValues(alpha: 0.4),
                  disabledBackgroundColor: disabledBgColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isOdia ? "ସମୟ ନିଶ୍ଚିତ କରନ୍ତୁ" : "Confirm Time Slot",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: _selectedSlot == null ? subTextColor : Colors.white,
                      ),
                    ),
                    if (_selectedSlot != null) ...[
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Empty States (Using injected semantic colors) ---
  Widget _buildEmptyState(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarOff, size: 48, color: isDarkMode ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(
              "No Schedule Available", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayUnavailableState(BuildContext context, Color disabledBgColor, Color subTextColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: disabledBgColor, 
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.coffee, size: 32, color: subTextColor),
          ),
          const SizedBox(height: 16),
          Text(
            "Doctor is Unavailable",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            "Please select a different date",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: subTextColor),
          ),
        ],
      ),
    );
  }
}