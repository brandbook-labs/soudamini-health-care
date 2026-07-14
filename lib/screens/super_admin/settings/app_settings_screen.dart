import 'dart:ui'; // Required for BackdropFilter
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart'; // Assuming standard components exist
import 'package:my_new_app/core/utils/theme_utils.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // --- GENERAL STATE ---
  bool _maintenanceMode = false;
  bool _allowRegistrations = true;

  // --- SECURITY STATE ---
  bool _enforce2FA = true;
  bool _geoFencing = false;

  @override
  Widget build(BuildContext context) {
    // Theme & Colors
    final colorScheme = context.colorScheme;
    final bgBase = context.theme.scaffoldBackgroundColor;

    // Glassmorphism Logic
    final glassColor = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          // 1. Background Effects (Glowing Blobs)
          Positioned(
            top: 100,
            left: -50,
            child: _GlowingBlob(color: Colors.purpleAccent),
          ),
          Positioned(
            bottom: 200,
            right: -50,
            child: _GlowingBlob(color: Colors.blueAccent),
          ),

          // 2. Scrollable Content
          CustomScrollView(
            slivers: [
              _buildHyperAppBar(context, "System Settings"),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // --- GENERAL SETTINGS ---
                      _HyperSectionHeader(title: "PLATFORM CONTROLS"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        children: [
                          SwitchListTile(
                            title: const Text(
                              "Maintenance Mode",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              "Block access for non-admins.",
                            ),
                            value: _maintenanceMode,
                            activeThumbColor: Colors.purpleAccent,
                            secondary: Icon(
                              LucideIcons.cake,
                              color: _maintenanceMode
                                  ? Colors.purpleAccent
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onChanged: (val) =>
                                setState(() => _maintenanceMode = val),
                          ),
                          Divider(height: 1, color: borderColor),
                          SwitchListTile(
                            title: const Text("Allow Registrations"),
                            subtitle: const Text(
                              "New clinics/patients can sign up.",
                            ),
                            value: _allowRegistrations,
                            activeColor: Colors.blueAccent,
                            secondary: Icon(
                              LucideIcons.userPlus,
                              color: _allowRegistrations
                                  ? Colors.blueAccent
                                  : colorScheme.onSurfaceVariant,
                            ),
                            onChanged: (val) =>
                                setState(() => _allowRegistrations = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- SECURITY PROTOCOLS ---
                      _HyperSectionHeader(title: "SECURITY PROTOCOLS"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        children: [
                          SwitchListTile(
                            title: const Text(
                              "Enforce 2FA (Admins)",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              "Require OTP for sensitive actions.",
                            ),
                            value: _enforce2FA,
                            activeColor: Colors.orangeAccent,
                            secondary: const Icon(
                              LucideIcons.shieldCheck,
                              color: Colors.orangeAccent,
                            ),
                            onChanged: (val) =>
                                setState(() => _enforce2FA = val),
                          ),
                          Divider(height: 1, color: borderColor),
                          SwitchListTile(
                            title: const Text("Geo-Fencing"),
                            subtitle: const Text(
                              "Restrict admin login to India.",
                            ),
                            value: _geoFencing,
                            activeColor: Colors.orangeAccent,
                            secondary: const Icon(
                              LucideIcons.globe,
                              color: Colors.orangeAccent,
                            ),
                            onChanged: (val) =>
                                setState(() => _geoFencing = val),
                          ),
                          Divider(height: 1, color: borderColor),
                          ListTile(
                            title: const Text(
                              "Force Logout All",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              "Expire all active tokens immediately.",
                            ),
                            leading: const Icon(
                              LucideIcons.logOut,
                              color: Colors.redAccent,
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("All users logged out."),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- ACTIVE SESSIONS (Monitoring) ---
                      _HyperSectionHeader(title: "YOUR ACTIVE SESSIONS"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SessionRow(
                            device: "Chrome (Windows)",
                            ip: "192.168.1.42",
                            location: "Bhubaneswar, IN",
                            isCurrent: true,
                          ),
                          Divider(color: borderColor),
                          _SessionRow(
                            device: "iPhone 14 Pro",
                            ip: "10.0.0.5",
                            location: "Cuttack, IN",
                            isCurrent: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- CONFIGURATION ---
                      _HyperSectionHeader(title: "SUPPORT CONFIGURATION"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        children: [
                          TextField(
                            decoration: InputDecoration(
                              icon: const Icon(LucideIcons.mail),
                              labelText: "Support Email Address",
                              border: InputBorder.none,
                              labelStyle: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            controller: TextEditingController(
                              text: "support@jivan.com",
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50), // Bottom padding
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

// --- HYPER DESIGN SYSTEM COMPONENTS ---

class _GlowingBlob extends StatelessWidget {
  final Color color;
  const _GlowingBlob({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.2), Colors.transparent],
        ),
      ),
    );
  }
}

class _HyperContainer extends StatelessWidget {
  final Color glassColor;
  final Color borderColor;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  const _HyperContainer({
    required this.glassColor,
    required this.borderColor,
    required this.children,
    this.padding = EdgeInsets.zero,
  });
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _HyperSectionHeader extends StatelessWidget {
  final String title;
  const _HyperSectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.outline,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final String device;
  final String ip;
  final String location;
  final bool isCurrent;

  const _SessionRow({
    required this.device,
    required this.ip,
    required this.location,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            isCurrent ? LucideIcons.laptop : LucideIcons.smartphone,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "$ip • $location",
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "THIS DEVICE",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(LucideIcons.xCircle, color: Colors.redAccent),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}

SliverAppBar _buildHyperAppBar(BuildContext context, String title) {
  return SliverAppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    pinned: true,
    leading: IconButton(
      icon: Icon(
        LucideIcons.arrowLeft,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () => Navigator.pop(context),
    ),
    flexibleSpace: ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: 0.8),
          alignment: Alignment.center,
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ),
  );
}
