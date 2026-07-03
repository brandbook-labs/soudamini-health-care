// lib/screens/patients/profile/widgets/logged_in_view.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_new_app/screens/patients/appointments/my_appointments_screen.dart';
import 'package:my_new_app/screens/patients/edit_profile_screen.dart';
import 'package:my_new_app/screens/patients/medical_records/manage_records_screen.dart';
import 'package:my_new_app/screens/patients/medical_records/my_doctors_screen.dart';
import 'package:my_new_app/screens/patients/reviews/patient_reviews_screen.dart';

// 🚀 Provider
import 'package:provider/provider.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';

// --- NEW IMPORTS ---
import '../profile_settings_screen.dart';

class LoggedInView extends StatelessWidget {
  final UserProvider userProvider;
  final bool isBiometricEnabled;
  final Function(bool) onToggleBiometrics;
  final VoidCallback onLogout;
  final VoidCallback onProfileUpdated;

  const LoggedInView({
    super.key,
    required this.userProvider,
    required this.isBiometricEnabled,
    required this.onToggleBiometrics,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 🚀 Provider Data
    String userName = userProvider.userName;
    final String userPhone = userProvider.userPhone;
    final String userAvatarUrl = userProvider.userProfileImage;
    final bool isVerified = true;

    // Handle Empty Name
    final bool isNameEmpty =
        userName.trim().isEmpty || userName.toLowerCase() == "guest";
    if (isNameEmpty) userName = "Complete Your Profile";

    final bgColor = isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC);
    final sectionBgColor = isDark ? const Color(0xFF18181B) : Colors.white;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // 1. SAAS-STYLE HEADER (Left Aligned, Clean)
            // ==========================================
            Container(
              width: double.infinity,
              color: sectionBgColor,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                        width: 1,
                      ),
                      color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: userAvatarUrl.isNotEmpty
                            ? CachedNetworkImageProvider(userAvatarUrl)
                            : const NetworkImage(
                                    "https://ui-avatars.com/api/?name=User&background=random",
                                  )
                                  as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isNameEmpty
                                      ? colorScheme.primary
                                      : (isDark
                                            ? Colors.white
                                            : const Color(0xFF0F172A)),
                                  fontStyle: isNameEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isNameEmpty && isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.blue,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userPhone,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade300
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit Button
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ).then((_) => onProfileUpdated()),
                    icon: Icon(
                      LucideIcons.pencil,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey.shade100,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12), // Space before lists
            // ==========================================
            // 2. PRIMARY ACTIONS (Edge-to-Edge List)
            // ==========================================
            Container(
              color: sectionBgColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: LucideIcons.calendarDays,
                    iconBgColor: Colors.blue,
                    title: "Appointments",
                    subtitle: "Manage your upcoming visits",
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyAppointmentsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.folderOpen,
                    iconBgColor: Colors.purple,
                    title: "Medical Records",
                    subtitle: "Prescriptions and lab reports",
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageRecordsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.pill,
                    iconBgColor: Colors.teal,
                    title: "Medicine Orders",
                    subtitle: "Track your pharmacy deliveries",
                    isComingSoon: true,
                    isDark: isDark,
                    showDivider: false, // Last item in this group
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12), // Group Separator
            // ==========================================
            // 3. SECONDARY ACTIONS
            // ==========================================
            Container(
              color: sectionBgColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: LucideIcons.users,
                    iconBgColor: Colors.orange,
                    title: "My Doctors",
                    subtitle: "Your saved specialists",
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyDoctorsScreen(),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.star,
                    iconBgColor: Colors.amber,
                    title: "My Reviews",
                    subtitle: "Feedback you've shared",
                    isDark: isDark,
                    showDivider: false,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientReviewsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 4. ACCOUNT & SETTINGS
            // ==========================================
            Container(
              color: sectionBgColor,
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: LucideIcons.settings,
                    iconBgColor: Colors.grey.shade600,
                    title: "Settings",
                    subtitle: "Biometrics and app preferences",
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSettingsScreen(
                          isBiometricEnabled: isBiometricEnabled,
                          onToggleBiometrics: onToggleBiometrics,
                          onLogout: onLogout,
                        ),
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.logOut,
                    iconBgColor: Colors.red.shade500,
                    title: "Log Out",
                    subtitle: "Sign out securely from your device",
                    textColor: Colors.red.shade600,
                    isDark: isDark,
                    showDivider: false,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- NATIVE WHATSAPP/IOS STYLE MENU ITEM ---
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String subtitle, // 👈 NEW: Subtext added
    required VoidCallback onTap,
    required bool isDark,
    Color? textColor,
    bool isComingSoon = false,
    bool showDivider = true,
  }) {
    final baseColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.grey.shade300 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return InkWell(
      onTap: isComingSoon ? null : onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Rounded Square Icon (SaaS/Native look)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isComingSoon
                        ? mutedColor.withValues(alpha: 0.2)
                        : iconBgColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isComingSoon
                        ? mutedColor.withValues(alpha: 0.5)
                        : iconBgColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isComingSoon
                              ? mutedColor.withValues(alpha: 0.5)
                              : (textColor ?? baseColor),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: isComingSoon
                              ? mutedColor.withValues(alpha: 0.3)
                              : mutedColor,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Action
                if (isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "COMING SOON",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? Colors.grey.shade300
                            : const Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  )
                else if (title != "Log Out")
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: mutedColor.withValues(alpha: 0.4),
                  ),
              ],
            ),
          ),

          // Indented Divider (Starts after the icon to mimic native OS settings)
        ],
      ),
    );
  }
}
