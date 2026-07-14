import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_new_app/screens/admin/adminSettings/edit_clinic_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminStaff/admin_staff_screen.dart';
import 'package:my_new_app/screens/admin/adminSettings/notification_settings_screen.dart';
import 'package:my_new_app/screens/admin/adminSettings/language_screen.dart';
import 'package:my_new_app/screens/auth/partner_login_screen.dart';

// --- CONSTANTS ---
class AppSpacing {
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static final BorderRadius large = BorderRadius.circular(16);
  static final BorderRadius full = BorderRadius.circular(999);
}

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final ApiService _apiService = ApiService();
  final LocalAuthentication auth = LocalAuthentication();

  late Future<Response> _profileFuture;
  bool _isBiometricEnabled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
    _loadBiometricPreference();
  }

  Future<Response> _getProfile() async {
    return _apiService.getAdminProfile();
  }

  // --- BIOMETRIC LOGIC ---
  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final theme = Theme.of(context);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      try {
        final bool canCheckBiometrics = await auth.canCheckBiometrics;
        final bool isDeviceSupported = await auth.isDeviceSupported();

        if (!canCheckBiometrics || !isDeviceSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Biometrics not supported on this device."),
              ),
            );
          }
          return;
        }

        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(stickyAuth: true),
        );

        if (didAuthenticate) {
          await prefs.setBool('biometric_enabled', true);
          setState(() => _isBiometricEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Biometric Login Enabled"),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Error enabling biometrics: $e");
      }
    } else {
      await prefs.setBool('biometric_enabled', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  // --- UPDATED LOGOUT LOGIC (Retention Style) ---
  void _handleLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B), // Zinc 900
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle Bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.logOut,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                // Text
                const Text(
                  "Log Out?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Are you sure you want to log out? You will need to sign in again to access the account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32),

                // 1. Primary Action (Stay / Cancel Logout)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "No, Stay Here",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Secondary Action (Actual Logout - Text Only)
                TextButton(
                  onPressed: () async {
                    await _apiService.removeToken(key: 'admin_token');
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PartnerLoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[400],
                  ),
                  child: const Text(
                    "Yes, Log Out",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NAVIGATION HANDLER ---
  void _navigateToEditProfile(String? clinicId) {
    if (clinicId == null || clinicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No linked clinic profile found to edit."),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditClinicProfileScreen(clinicId: clinicId),
      ),
    ).then((updated) {
      if (updated == true) {
        setState(() {
          _profileFuture = _getProfile();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // --- 1. PROFILE SECTION ---
            FutureBuilder<Response>(
              future: _profileFuture,
              builder: (context, snapshot) {
                String name = "Clinic Profile";
                String slug = "";
                String email = "";
                String plan = "free";
                int level = 0;
                bool isVerified = false;
                String? imageUrl;
                String? clinicId;

                if (snapshot.hasData && snapshot.data?.data != null) {
                  final responseBody = snapshot.data!.data;
                  final userData = responseBody is Map
                      ? (responseBody['data'] ?? responseBody)
                      : {};

                  name = (userData['name'] ?? userData['username'] ?? "Clinic Profile").toString();
                  slug = (userData['slug'] ?? "").toString();
                  email = (userData['email'] ?? "").toString();
                  plan = (userData['membership_plan'] ?? "free").toString();
                  level = int.tryParse(userData['membership_level']?.toString() ?? "0") ?? 0;
                  isVerified = userData['isVerified'] == true;

                  imageUrl = userData['logo']?.toString() ?? userData['profile']?.toString();
                  clinicId = userData['_id']?.toString() ?? userData['facility_id']?.toString();
                }

                return _buildProfileHeader(
                  context,
                  name: name,
                  slug: slug,
                  email: email,
                  plan: plan,
                  level: level,
                  isVerified: isVerified,
                  imageUrl: imageUrl,
                  clinicId: clinicId,
                );
              },
            ),

            const SizedBox(height: 32),

            // --- 2. PREFERENCES (Staff Management Removed) ---
            _buildSectionHeader(context, "Preferences"),
            const SizedBox(height: 12),
            _MenuCard(
              children: [
                _MenuItem(
                  icon: LucideIcons.contact,
                  title: "Staffs",      
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminStaffScreen(),
                    ),
                  ),
                ),
                _MenuDivider(),
                // _MenuItem(
                //   icon: LucideIcons.bell,
                //   title: "Notifications",
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(
                //       builder: (_) => const NotificationSettingsScreen(),
                //     ),
                //   ),
                // ),
                // _MenuDivider(),
                // _MenuItem(
                //   icon: LucideIcons.globe,
                //   title: "Language",
                //   trailing: const Padding(
                //     padding: EdgeInsets.only(right: 8.0),
                //     child: Text(
                //       "English",
                //       style: TextStyle(fontSize: 13, color: Colors.grey),
                //     ),
                //   ),
                //   onTap: () => Navigator.push(
                //     context,
                //     MaterialPageRoute(builder: (_) => const LanguageScreen()),
                //   ),
                // ),
                _MenuDivider(),
                _MenuItem(
                  icon: LucideIcons.fingerprint,
                  title: "Biometric Login",
                  trailing: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Switch(
                          value: _isBiometricEnabled,
                          onChanged: _toggleBiometrics,
                          activeColor: colorScheme.primary,
                        ),
                  onTap: () => _toggleBiometrics(!_isBiometricEnabled),
                ),
                _MenuDivider(),
                // _MenuItem(
                //   icon: LucideIcons.shieldCheck,
                //   title: "Privacy & Security",
                //   onTap: () {},
                // ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 3. LOGOUT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => _handleLogout(context),
                icon: Icon(LucideIcons.logOut, color: colorScheme.error),
                label: Text(
                  "Log Out",
                  style: TextStyle(
                    color: colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: colorScheme.error.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
                ),
              ),
            ),

            const SizedBox(height: 20),
            Text(
              "Version 1.0.0",
              style: TextStyle(color: theme.disabledColor, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper for Section Headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4.0),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // Updated Helper for Clinic Profile Visuals
  Widget _buildProfileHeader(
    BuildContext context, {
    required String name,
    required String slug,
    required String email,
    required String plan,
    required int level,
    required bool isVerified,
    String? imageUrl,
    String? clinicId,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Capitalize first letter of plan
    String displayPlan = plan.isNotEmpty ? plan[0].toUpperCase() + plan.substring(1) : "Free";

    return Column(
      children: [
        // Avatar Stack
        Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary, width: 3),
                color: colorScheme.surfaceContainerHighest,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: imageUrl != null
                      ? CachedNetworkImageProvider(imageUrl)
                      : const NetworkImage(
                          "https://ui-avatars.com/api/?name=Clinic&background=random",
                        ) as ImageProvider,
                ),
              ),
            ),

            // --- EDIT BUTTON ---
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _navigateToEditProfile(clinicId),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Clinic Name & Verification Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.badgeCheck,
                color: Colors.blue,
                size: 24,
              ),
            ]
          ],
        ),

        const SizedBox(height: 6),

        // Slug
        if (slug.isNotEmpty)
          Text(
            "@$slug",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),

        const SizedBox(height: 4),

        // Email
        if (email.isNotEmpty)
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),

        const SizedBox(height: 16),

        // Beautiful Membership Plan & Level Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: displayPlan.toLowerCase() == 'premium' || displayPlan.toLowerCase() == 'pro'
                ? Colors.amber.withValues(alpha: 0.15)
                : colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: AppRadius.large,
            border: Border.all(
              color: displayPlan.toLowerCase() == 'premium' || displayPlan.toLowerCase() == 'pro'
                  ? Colors.amber.withValues(alpha: 0.5)
                  : colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                displayPlan.toLowerCase() == 'premium' || displayPlan.toLowerCase() == 'pro'
                    ? LucideIcons.crown
                    : LucideIcons.award,
                size: 18,
                color: displayPlan.toLowerCase() == 'premium' || displayPlan.toLowerCase() == 'pro'
                    ? Colors.amber[700]
                    : colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "$displayPlan Plan • Level $level",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: displayPlan.toLowerCase() == 'premium' || displayPlan.toLowerCase() == 'pro'
                      ? Colors.amber[800]
                      : colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// REUSABLE UI COMPONENTS
// =============================================================================

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: trailing is Switch ? null : onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: trailing ??
          Icon(
            LucideIcons.chevronRight,
            size: 18,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
    );
  }
}