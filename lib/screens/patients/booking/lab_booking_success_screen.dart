import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/main_layout.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);

class LabBookingSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> bookingDetails;

  const LabBookingSuccessScreen({super.key, required this.bookingDetails});

  @override
  State<LabBookingSuccessScreen> createState() =>
      _LabBookingSuccessScreenState();
}

class _LabBookingSuccessScreenState extends State<LabBookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect Theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    final details = widget.bookingDetails;
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // --- 1. SUCCESS ANIMATION ---
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kGreenColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.check,
                      color: kGreenColor,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Order Placed!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Our phlebotomist will arrive at your location for sample collection.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // --- 2. ORDER RECEIPT CARD ---
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.flaskConical,
                              color: kPrimaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "TEST DETAILS",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: subTextColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  details['testName'] ?? "Lab Test",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildRow(
                            "Booking ID",
                            details['bookingId'] ?? "#123",
                            textColor,
                            subTextColor,
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            "Patient",
                            details['patientName'] ?? "Guest",
                            textColor,
                            subTextColor,
                          ),
                          const SizedBox(height: 16),
                          _buildRow(
                            "Schedule",
                            "${details['date']} • ${details['time']}",
                            textColor,
                            subTextColor,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "Address",
                                  style: TextStyle(
                                    color: subTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  details['address'] ?? "Home Collection",
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // FIXED: Removed invalid 'style' parameter from Divider
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(thickness: 1, color: Colors.grey),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                currencyFormat.format(details['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 3. ACTIONS ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Home and clear stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainLayout(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to Order History
                },
                child: Text(
                  "View Order History",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    Color textColor,
    Color subTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: subTextColor, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
