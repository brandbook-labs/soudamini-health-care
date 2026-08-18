// lib/screens/patients/profile/profile_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';

// --- NAVIGATION ---
import '../app_settings_screen.dart';
import '../notification_settings_screen.dart';

// --- API SERVICE ---
import '../../../services/api_service.dart';

class ProfileSettingsScreen extends StatelessWidget {
  final bool isBiometricEnabled;
  final Function(bool) onToggleBiometrics;
  final VoidCallback onLogout;

  const ProfileSettingsScreen({
    super.key,
    required this.isBiometricEnabled,
    required this.onToggleBiometrics,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const bgColor = Colors.white; // Pure white for flat list

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // Zero horizontal padding to allow edge-to-edge lists
        padding: const EdgeInsets.only(top: 12, bottom: 40),
        child: Column(
          children: [
            // Top bounding line
            _buildSettingsItem(
              icon: LucideIcons.shieldCheck,
              title: "Account & Security",
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Account & Security screen is coming soon."),
                ),
              ), // TODO: build a real edit password/email screen; this was a
              // silent no-op before, which looks broken to reviewers/users.
            ),
            _buildSettingsItem(
              icon: LucideIcons.bell,
              title: "Notifications",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              ),
            ),
            _buildSettingsItem(
              icon: LucideIcons.settings,
              title: "App Settings",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
              ),
            ),
            _buildSettingsItem(
              icon: LucideIcons.fingerprint,
              title: "Biometric Login",
              trailing: SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.85, // Makes the switch a bit sleeker
                  child: Switch(
                    value: isBiometricEnabled,
                    onChanged: onToggleBiometrics,
                    activeColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primary.withValues(
                      alpha: 0.3,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, // Removes the 48px hidden padding
                  ),
                ),
              ),
              onTap: () => onToggleBiometrics(!isBiometricEnabled),
            ),
            _buildSettingsItem(
              icon: LucideIcons.trash2,
              title: "Delete Account",
              iconColor: Colors.red.shade600,
              textColor: Colors.red.shade600,
              showDivider: false, // Last item in the block
              onTap: () => _showDeleteAccountSheet(context),
            ),

            //  bounding line
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showDivider = true,
    Widget? trailing,
  }) {
    final baseColor = const Color(0xFF0F172A);
    final mutedColor = const Color(0xFF64748B);

    // If it has a switch, tapping the row shouldn't trigger ripples (the switch handles it)
    final bool isInteractiveRow = trailing == null;

    return InkWell(
      onTap: isInteractiveRow ? onTap : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: iconColor ?? mutedColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor ?? baseColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (title !=
                    "Delete Account") // No chevron for Delete Account
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: mutedColor.withValues(alpha: 0.3),
                  ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(
              height: 1,
              thickness: 1,
              indent: 60, // Indented past the icon to align with text
              endIndent: 0, // Stretches edge-to-edge on the right
              color: Color(0xFFF1F5F9),
            ),
        ],
      ),
    );
  }

  // --- DELETE ACCOUNT BOTTOM SHEET ---
  void _showDeleteAccountSheet(BuildContext context) {
    final dobController = TextEditingController();
    final apiService = ApiService();
    bool isLoading = false;
    String errorMsg = "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.alertTriangle,
                      color: Colors.red.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Delete Account",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "This action cannot be undone. All your appointments, medical records, and data will be permanently erased.",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Confirm Date of Birth",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dobController,
                    keyboardType: TextInputType.datetime,
                    decoration: InputDecoration(
                      hintText: "DD/MM/YYYY",
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      errorText: errorMsg.isNotEmpty ? errorMsg : null,
                      prefixIcon: const Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.red.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (dobController.text.trim().isEmpty) {
                                    setModalState(
                                      () => errorMsg =
                                          "Date of Birth is required",
                                    );
                                    return;
                                  }

                                  setModalState(() {
                                    isLoading = true;
                                    errorMsg = "";
                                  });

                                  try {
                                    final response = await apiService
                                        .deleteAccount(
                                          dobConfirmation: dobController.text
                                              .trim(),
                                        );

                                    final success =
                                        response.statusCode == 200 ||
                                        response.statusCode == 202 ||
                                        response.statusCode == 204;

                                    if (!success) {
                                      throw Exception(
                                        response.data is Map
                                            ? (response.data['msg'] ??
                                                  "Deletion request failed")
                                            : "Deletion request failed",
                                      );
                                    }

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx); // Close sheet
                                      Navigator.pop(
                                        context,
                                      ); // Pop settings screen
                                      onLogout(); // Trigger global logout sequence
                                    }
                                  } on DioException catch (e) {
                                    final serverMsg =
                                        e.response?.data is Map
                                        ? e.response?.data['msg']
                                        : null;
                                    setModalState(() {
                                      isLoading = false;
                                      errorMsg =
                                          serverMsg ??
                                          "We couldn't verify your date of birth or reach the server. Please try again.";
                                    });
                                  } catch (e) {
                                    setModalState(() {
                                      isLoading = false;
                                      errorMsg =
                                          "Something went wrong. Please try again or contact support.";
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Delete Forever",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
