import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // Mock Settings State
  bool _notificationsEnabled = true;
  bool _darkMode = true;
  bool _biometricLogin = false;
  final String _selectedLanguage = "English";

  @override
  Widget build(BuildContext context) {
    // 1. ACCESS THEME DATA
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // 2. DEFINE DYNAMIC COLORS FROM THEME
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = textColor.withValues(alpha: 0.6); // Auto-derive grey
    final primaryColor = theme.primaryColor;

    // Border color: White10 for dark mode, Grey200 for light mode
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
          "Settings",
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
            // --- 1. GENERAL ---
            _buildSectionHeader("General", primaryColor),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                icon: LucideIcons.moon,
                title: "Dark Mode",
                subtitle: "Reduce eye strain",
                value: _darkMode,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  // TODO: Call ThemeProvider.toggleTheme()
                },
                activeColor: primaryColor,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              _buildDivider(borderColor),
              _buildDropdownTile(
                icon: LucideIcons.globe,
                title: "Language",
                value: _selectedLanguage,
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () {
                  // Show Language Picker Dialog
                },
              ),
            ]),

            const SizedBox(height: 24),

            // --- 2. NOTIFICATIONS ---
            _buildSectionHeader("Notifications", Colors.orange),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                icon: LucideIcons.bellRing,
                title: "Push Notifications",
                subtitle: "For appointments & offers",
                value: _notificationsEnabled,
                onChanged: (val) => setState(() => _notificationsEnabled = val),
                activeColor: Colors.orange,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
            ]),

            const SizedBox(height: 24),

            // --- 3. SECURITY ---
            _buildSectionHeader("Security", Colors.green),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildSwitchTile(
                icon: LucideIcons.fingerprint,
                title: "Biometric Login",
                subtitle: "FaceID / TouchID",
                value: _biometricLogin,
                onChanged: (val) => setState(() => _biometricLogin = val),
                activeColor: Colors.green,
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              _buildDivider(borderColor),
              _buildNavTile(
                icon: LucideIcons.lock,
                title: "Change Password",
                textColor: textColor,
                onTap: () {
                  // Navigate to Change Password Screen
                },
              ),
            ]),

            const SizedBox(height: 24),

            // --- 4. SUPPORT ---
            _buildSectionHeader("Support", Colors.blueGrey),
            const SizedBox(height: 12),
            _buildSettingsContainer(cardColor, borderColor, [
              _buildNavTile(
                icon: LucideIcons.helpCircle,
                title: "Help Center",
                textColor: textColor,
                onTap: () {},
              ),
              _buildDivider(borderColor),
              _buildNavTile(
                icon: LucideIcons.fileText,
                title: "Terms & Conditions",
                textColor: textColor,
                onTap: () {},
              ),
              _buildDivider(borderColor),
              _buildNavTile(
                icon: LucideIcons.shieldCheck,
                title: "Privacy Policy",
                textColor: textColor,
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: activeColor),
      ),
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

  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: textColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
      trailing: Icon(
        LucideIcons.chevronRight,
        size: 18,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.blue),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: TextStyle(color: subTextColor, fontSize: 13)),
          const SizedBox(width: 4),
          Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildDivider(Color color) {
    return Divider(height: 1, thickness: 1, color: color);
  }
}
