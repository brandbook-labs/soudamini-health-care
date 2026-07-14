import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // --- STATE VARIABLES ---

  // Practice Alerts
  bool _newAppts = true;
  bool _cancellations = true;
  bool _patientArrivals = false; // New
  bool _emergency = true; // New

  // Communication
  bool _messages = true; // New
  bool _reviews = false; // New

  // Financials
  bool _paymentReceived = true; // New
  bool _dailyReport = true; // New

  // System
  bool _marketing = false;
  bool _appUpdates = true;

  @override
  Widget build(BuildContext context) {
    // Theme Access
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // Colors derived from theme
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: textColor,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: PRACTICE ALERTS ---
            _buildSectionHeader("Practice Alerts", colorScheme.primary),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "New Appointments",
                "Get notified immediately when a patient books.",
                _newAppts,
                (val) => setState(() => _newAppts = val),
                textColor,
                subTextColor,
                colorScheme.primary,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Cancellations",
                "Alerts when an appointment is cancelled.",
                _cancellations,
                (val) => setState(() => _cancellations = val),
                textColor,
                subTextColor,
                colorScheme.primary,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Patient Arrivals",
                "Notify when a patient checks in at reception.",
                _patientArrivals,
                (val) => setState(() => _patientArrivals = val),
                textColor,
                subTextColor,
                colorScheme.primary,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Emergency Requests",
                "High priority alerts for urgent cases.",
                _emergency,
                (val) => setState(() => _emergency = val),
                textColor,
                subTextColor,
                Colors.red, // Distinct color for emergency
              ),
            ]),

            const SizedBox(height: 24),

            // --- SECTION 2: FINANCIALS ---
            _buildSectionHeader("Financials", Colors.green),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Payment Received",
                "Alerts for successful UPI or Cash logs.",
                _paymentReceived,
                (val) => setState(() => _paymentReceived = val),
                textColor,
                subTextColor,
                Colors.green,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Daily EOD Report",
                "Receive a summary of today's earnings at 9 PM.",
                _dailyReport,
                (val) => setState(() => _dailyReport = val),
                textColor,
                subTextColor,
                Colors.green,
              ),
            ]),

            const SizedBox(height: 24),

            // --- SECTION 3: COMMUNICATION ---
            _buildSectionHeader("Communication", Colors.blue),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Patient Messages",
                "Chat notifications from patients.",
                _messages,
                (val) => setState(() => _messages = val),
                textColor,
                subTextColor,
                Colors.blue,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "Reviews & Ratings",
                "When a patient leaves feedback.",
                _reviews,
                (val) => setState(() => _reviews = val),
                textColor,
                subTextColor,
                Colors.blue,
              ),
            ]),

            const SizedBox(height: 24),

            // --- SECTION 4: SYSTEM & GROWTH ---
            _buildSectionHeader("System & Growth", Colors.orange),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                "Marketing & Tips",
                "Receive growth tips for your clinic.",
                _marketing,
                (val) => setState(() => _marketing = val),
                textColor,
                subTextColor,
                Colors.orange,
              ),
              _buildDivider(borderColor),
              _buildSwitchTile(
                "App Updates",
                "Notify me about new Jivan features.",
                _appUpdates,
                (val) => setState(() => _appUpdates = val),
                textColor,
                subTextColor,
                Colors.orange,
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: color,
        ),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ), // Increased padding for better touch area
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subTextColor),
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color);
  }
}
