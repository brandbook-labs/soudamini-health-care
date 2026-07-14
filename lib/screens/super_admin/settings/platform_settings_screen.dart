import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  bool _maintenanceMode = false;
  bool _registrationOpen = true;
  double _apiRateLimit = 5000;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDarkMode;
    final bgBase = context.theme.scaffoldBackgroundColor;
    final glassColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = colorScheme.outlineVariant.withValues(alpha: 0.2);

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          // Background FX
          Positioned(
            top: -100,
            right: -100,
            child: _GlowingBlob(color: Colors.blueAccent),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _GlowingBlob(color: Colors.purpleAccent),
          ),

          CustomScrollView(
            slivers: [
              _buildHyperAppBar(context, "Global Config"),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // --- MAINTENANCE MODULE ---
                      _HyperSectionHeader(title: "SYSTEM STATE"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: _maintenanceMode
                            ? colorScheme.error
                            : borderColor,
                        children: [
                          SwitchListTile(
                            title: const Text(
                              "Maintenance Mode",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text(
                              "Halts all non-admin traffic immediately.",
                              style: TextStyle(fontSize: 12),
                            ),
                            value: _maintenanceMode,
                            activeColor: colorScheme.error,
                            secondary: Icon(
                              LucideIcons.siren,
                              color: _maintenanceMode
                                  ? colorScheme.error
                                  : colorScheme.onSurface,
                            ),
                            onChanged: (val) =>
                                setState(() => _maintenanceMode = val),
                          ),
                          Divider(height: 1, color: borderColor),
                          SwitchListTile(
                            title: const Text("Allow Clinic Registrations"),
                            subtitle: const Text("Open public sign-ups."),
                            value: _registrationOpen,
                            activeColor: colorScheme.primary,
                            secondary: Icon(
                              LucideIcons.userPlus,
                              color: colorScheme.primary,
                            ),
                            onChanged: (val) =>
                                setState(() => _registrationOpen = val),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- API THROTTLING ---
                      _HyperSectionHeader(title: "API GATEWAY"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        padding: const EdgeInsets.all(20),
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.network,
                                color: Colors.orangeAccent,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Global Rate Limit",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Text(
                                "${_apiRateLimit.toInt()} req/min",
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Slider(
                            value: _apiRateLimit,
                            min: 1000,
                            max: 20000,
                            divisions: 19,
                            activeColor: Colors.orangeAccent,
                            onChanged: (val) =>
                                setState(() => _apiRateLimit = val),
                          ),
                        ],
                      ),
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

// --- SHARED LOCAL WIDGETS (To keep files self-contained) ---
// Note: In a real app, move these to a 'widgets/hyper' folder to avoid duplication

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
