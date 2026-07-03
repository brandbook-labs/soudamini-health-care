import 'package:flutter/material.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
// Dark Mode
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Mock State
  bool _appointmentsPush = true;
  bool _appointmentsSms = true;
  bool _appointmentsEmail = false;

  bool _ordersPush = true;
  bool _ordersSms = true;

  bool _promosPush = true;
  bool _healthTipsPush = false;

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
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notification Settings",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. APPOINTMENTS ---
            _buildSectionHeader("Appointments", kPrimaryColor),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Push Notifications",
                "Reminders 1 hr before visit",
                _appointmentsPush,
                (val) => setState(() => _appointmentsPush = val),
                textColor,
                subTextColor,
                kPrimaryColor,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "SMS Alerts",
                "Booking confirmation & OTPs",
                _appointmentsSms,
                (val) => setState(() => _appointmentsSms = val),
                textColor,
                subTextColor,
                kPrimaryColor,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Email Updates",
                "Digital prescriptions & invoices",
                _appointmentsEmail,
                (val) => setState(() => _appointmentsEmail = val),
                textColor,
                subTextColor,
                kPrimaryColor,
              ),
            ]),

            const SizedBox(height: 24),

            // --- 2. MEDICINE ORDERS ---
            _buildSectionHeader("Orders & Deliveries", Colors.green),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Order Status",
                "Shipped, Out for Delivery alerts",
                _ordersPush,
                (val) => setState(() => _ordersPush = val),
                textColor,
                subTextColor,
                Colors.green,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "SMS Updates",
                "Delivery agent contact info",
                _ordersSms,
                (val) => setState(() => _ordersSms = val),
                textColor,
                subTextColor,
                Colors.green,
              ),
            ]),

            const SizedBox(height: 24),

            // --- 3. GENERAL ---
            _buildSectionHeader("General", Colors.orange),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Promotions & Offers",
                "Discounts on checkups",
                _promosPush,
                (val) => setState(() => _promosPush = val),
                textColor,
                subTextColor,
                Colors.orange,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Health Tips",
                "Daily wellness advice",
                _healthTipsPush,
                (val) => setState(() => _healthTipsPush = val),
                textColor,
                subTextColor,
                Colors.orange,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: color,
      ),
    );
  }

  Widget _buildSettingsContainer(
    Color color,
    Color borderColor,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    Color textColor,
    Color subTextColor,
    Color activeColor,
  ) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: subTextColor),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color);
  }
}
