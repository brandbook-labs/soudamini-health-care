import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this path is correct

// --- 1. Glowing Blob ---
class GlowingBlob extends StatelessWidget {
  final Color color;
  const GlowingBlob({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.3), Colors.transparent],
        ),
      ),
    );
  }
}

// --- 2. Hyper Profile Card ---
class HyperProfileCard extends StatelessWidget {
  final Color glassColor, borderColor;
  final String name, role, status;
  final String? avatarUrl;
  final bool isLoading;

  const HyperProfileCard({
    super.key,
    required this.glassColor,
    required this.borderColor,
    this.name = "",
    this.role = "",
    this.status = "",
    this.avatarUrl,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: glassColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(24),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.black,
                      backgroundImage: avatarUrl != null
                          ? NetworkImage(avatarUrl!)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(
                              LucideIcons.user,
                              color: Colors.white,
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "● $status",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            role,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamily: "monospace",
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// --- 3. System Telemetry Bar ---
class SystemTelemetryBar extends StatelessWidget {
  final Color glassColor;
  const SystemTelemetryBar({super.key, required this.glassColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        TelemetryItem(label: "CPU", value: "12%", color: Colors.blueAccent),
        SizedBox(width: 12),
        TelemetryItem(label: "RAM", value: "4.2GB", color: Colors.purpleAccent),
        SizedBox(width: 12),
        TelemetryItem(label: "PING", value: "24ms", color: Colors.greenAccent),
      ],
    );
  }
}

class TelemetryItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const TelemetryItem({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 4. Hyper Control Group ---
class HyperControlGroup extends StatelessWidget {
  final Color glassColor, borderColor;
  final List<Widget> children;
  const HyperControlGroup({
    super.key,
    required this.glassColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

// --- 5. Hyper Tile ---
class HyperTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final VoidCallback onTap;
  const HyperTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(LucideIcons.chevronRight, size: 18),
    );
  }
}

// --- 6. Hyper Switch Tile ---
class HyperSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  const HyperSwitchTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: color),
    );
  }
}

// --- 7. Hyper Divider ---
class HyperDivider extends StatelessWidget {
  const HyperDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
    );
  }
}

// --- 8. Section Label ---
class SectionLabel extends StatelessWidget {
  final String title;
  const SectionLabel({super.key, required this.title});

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
