import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';

// --- SYSTEM IMPORTS ---
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/super_admin/logs/audit_logs_screen.dart';
import 'package:my_new_app/screens/super_admin/roles/roles_list_screen.dart';
import 'package:my_new_app/screens/super_admin/settings/app_settings_screen.dart';
import 'package:my_new_app/services/api_service.dart';

// --- SCREEN IMPORTS (Ensure these files exist) ---
import 'database_health_screen.dart';
import 'package:my_new_app/screens/auth/partner_login_screen.dart';

// --- WIDGET IMPORT (This fixes the undefined errors) ---
import 'widgets/hyper_widgets.dart';

class SuperAdminProfileScreen extends StatefulWidget {
  const SuperAdminProfileScreen({super.key});

  @override
  State<SuperAdminProfileScreen> createState() =>
      _SuperAdminProfileScreenState();
}

class _SuperAdminProfileScreenState extends State<SuperAdminProfileScreen> {
  final ApiService _apiService = ApiService();
  late Future<Response> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _getProfile();
  }

  Future<Response> _getProfile() async {
    return _apiService.getAdminProfile();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await _apiService.removeToken(key: 'admin_token');
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const PartnerLoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgBase = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);
    final borderGlass = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white;

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          // Background FX
          Positioned(
            top: -100,
            right: -50,
            child: GlowingBlob(color: context.colorScheme.primary),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Transparent App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 80,
                floating: true,
                pinned: true,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: bgBase.withValues(alpha: 0.8),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.only(left: 20, bottom: 15),
                      child: Text(
                        "Command Center",
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // 2. Profile Card (ID)
                      FutureBuilder<Response>(
                        future: _profileFuture,
                        builder: (context, snapshot) {
                          String name = "Super Admin";
                          String role = "ROOT_ACCESS";
                          String? avatarUrl;

                          if (snapshot.hasData && snapshot.data?.data != null) {
                            final data = snapshot.data!.data is Map
                                ? (snapshot.data!.data['data'] ??
                                      snapshot.data!.data)
                                : {};
                            name = data['name'] ?? name;
                            role =
                                "${(data['role'] ?? "ADMIN").toString().toUpperCase()}_GRANTED";
                            avatarUrl = data['profile'];
                          }

                          return HyperProfileCard(
                            glassColor: glassColor,
                            borderColor: borderGlass,
                            name: name,
                            role: role,
                            status: "ONLINE",
                            avatarUrl: avatarUrl,
                            isLoading:
                                snapshot.connectionState ==
                                ConnectionState.waiting,
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      // 3. Telemetry
                      SystemTelemetryBar(glassColor: glassColor),

                      const SizedBox(height: 32),

                      // 4. SYSTEM CONTROLS
                      const SectionLabel(title: "SYSTEM ADMINISTRATION"),
                      const SizedBox(height: 12),
                      HyperControlGroup(
                        glassColor: glassColor,
                        borderColor: borderGlass,
                        children: [
                          HyperTile(
                            icon: LucideIcons.shieldAlert,
                            color: Colors.indigoAccent,
                            title: "Access & Roles",
                            subtitle: "Manage admin permissions",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RolesListScreen(),
                              ),
                            ),
                          ),
                          const HyperDivider(),
                          HyperTile(
                            icon: LucideIcons.fileText,
                            color: Colors.blueGrey,
                            title: "Audit Logs",
                            subtitle: "View system activity history",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuditLogsScreen(),
                              ),
                            ),
                          ),
                          const HyperDivider(),
                          HyperTile(
                            icon: LucideIcons.settings,
                            color: Colors.orangeAccent,
                            title: "Global Settings",
                            subtitle: "App maintenance & configs",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppSettingsScreen(),
                              ),
                            ),
                          ),
                          const HyperDivider(),
                          HyperTile(
                            icon: LucideIcons.database,
                            color: Colors.purpleAccent,
                            title: "Database Health",
                            subtitle: "Backups & Integrity Check",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DatabaseHealthScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // 5. PREFERENCES
                      const SectionLabel(title: "PREFERENCES"),
                      const SizedBox(height: 12),
                      HyperControlGroup(
                        glassColor: glassColor,
                        borderColor: borderGlass,
                        children: [
                          HyperSwitchTile(
                            icon: LucideIcons.moon,
                            color: Colors.blueAccent,
                            title: "Dark Protocol",
                            value: isDark,
                            onChanged: (v) {
                              /* Toggle Theme */
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),
                      // 6. LOGOUT
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton.icon(
                          onPressed: () => _handleLogout(context),
                          style: TextButton.styleFrom(
                            backgroundColor: context.colorScheme.error
                                .withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            LucideIcons.logOut,
                            color: context.colorScheme.error,
                          ),
                          label: Text(
                            "TERMINATE SESSION",
                            style: TextStyle(
                              color: context.colorScheme.error,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        "JIVAN CORE v4.0.2",
                        style: context.text.labelSmall?.copyWith(
                          color: context.colorScheme.outline,
                          fontFamily: "monospace",
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
