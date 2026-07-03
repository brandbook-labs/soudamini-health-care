import 'package:flutter/material.dart';

class DoctorBottomBar extends StatelessWidget {
  final int currentPrice;
  final String appointmentType;
  final VoidCallback onBookPressed;
  final bool isOdia;

  const DoctorBottomBar({
    super.key,
    required this.currentPrice,
    required this.appointmentType,
    required this.onBookPressed,
    required this.isOdia,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color.fromARGB(255, 22, 96, 255);
    final cardColor = isDarkMode ? const Color(0xFF191919) : Colors.white;
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    String feeLabel = isOdia ? "ପରାମର୍ଶ ଫି" : "Consultation Fee";
    if (appointmentType == "follow_up") {
      feeLabel = isOdia ? "ଫଲୋ-ଅପ୍ ଫି" : "Follow-up Fee";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: borderColor),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentPrice > 0 ? "₹$currentPrice" : "Contact Clinic",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: FilledButton(
                onPressed: onBookPressed,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book Appointment",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
