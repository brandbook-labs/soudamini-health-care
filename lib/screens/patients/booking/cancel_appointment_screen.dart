import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kRedColor = Color(0xFFEF4444);
// Dark Mode
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

class CancelAppointmentScreen extends StatefulWidget {
  final String appointmentId;

  const CancelAppointmentScreen({super.key, required this.appointmentId});

  @override
  State<CancelAppointmentScreen> createState() =>
      _CancelAppointmentScreenState();
}

class _CancelAppointmentScreenState extends State<CancelAppointmentScreen> {
  String? _selectedReason;
  final TextEditingController _commentController = TextEditingController();

  final List<String> _reasons = [
    "Rescheduling to another time",
    "Found another specialist",
    "Wait time is too long",
    "Distance / Travel issues",
    "Health issue resolved",
    "Other",
  ];

  void _handleCancellation() {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a reason for cancellation"),
        ),
      );
      return;
    }

    // --- API CALL WOULD GO HERE ---
    // await api.cancelAppointment(widget.appointmentId, _selectedReason);

    // Show Success & Go Back
    Navigator.pop(
      context,
      true,
    ); // Return 'true' to indicate cancellation happened
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Appointment cancelled successfully."),
        backgroundColor: kRedColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Cancel Appointment",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- WARNING BOX ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Are you sure? This action cannot be undone. You may lose your specific time slot.",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.orange.shade200
                                  : Colors.orange.shade900,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- REASONS LIST ---
                  Text(
                    "Please select a reason",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: List.generate(_reasons.length, (index) {
                        final reason = _reasons[index];
                        final isSelected = _selectedReason == reason;
                        return Column(
                          children: [
                            RadioListTile<String>(
                              value: reason,
                              groupValue: _selectedReason,
                              onChanged: (val) {
                                setState(() => _selectedReason = val);
                              },
                              activeColor: kRedColor,
                              title: Text(
                                reason,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                            if (index != _reasons.length - 1)
                              Divider(height: 1, color: borderColor),
                          ],
                        );
                      }),
                    ),
                  ),

                  // --- OPTIONAL COMMENT ---
                  if (_selectedReason == "Other") ...[
                    const SizedBox(height: 20),
                    Text(
                      "Tell us more (Optional)",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Type your reason here...",
                        hintStyle: TextStyle(color: subTextColor),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kRedColor),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // --- BOTTOM BUTTONS ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleCancellation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRedColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Confirm Cancellation",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Keep Appointment",
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
