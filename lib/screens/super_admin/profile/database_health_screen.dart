import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class DatabaseHealthScreen extends StatelessWidget {
  const DatabaseHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgBase = context.theme.scaffoldBackgroundColor;
    final glassColor = context.isDarkMode
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);
    final borderColor = context.colorScheme.outlineVariant.withValues(
      alpha: 0.2,
    );

    return Scaffold(
      backgroundColor: bgBase,
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            right: -50,
            child: _GlowingBlob(color: Colors.greenAccent),
          ),

          CustomScrollView(
            slivers: [
              _buildHyperAppBar(context, "Database Health"),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // --- HEALTH STATUS ---
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: Colors.greenAccent.withValues(alpha: 0.5),
                        padding: const EdgeInsets.all(24),
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const Icon(
                                  LucideIcons.checkCircle,
                                  color: Colors.greenAccent,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "SYSTEM OPERATIONAL",
                                  style: context.text.titleLarge?.copyWith(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Last Integrity Check: 2 mins ago",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- METRICS ---
                      _HyperSectionHeader(title: "METRICS"),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: "Read IOPS",
                              value: "4.2k",
                              color: Colors.blueAccent,
                              glassColor: glassColor,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: "Write IOPS",
                              value: "1.1k",
                              color: Colors.purpleAccent,
                              glassColor: glassColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: "Storage",
                              value: "45%",
                              color: Colors.orangeAccent,
                              glassColor: glassColor,
                              borderColor: borderColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: "Cache Hit",
                              value: "98.2%",
                              color: Colors.greenAccent,
                              glassColor: glassColor,
                              borderColor: borderColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // --- MAINTENANCE OPS ---
                      _HyperSectionHeader(title: "MAINTENANCE TASKS"),
                      const SizedBox(height: 12),
                      _HyperContainer(
                        glassColor: glassColor,
                        borderColor: borderColor,
                        children: [
                          ListTile(
                            leading: const Icon(
                              LucideIcons.refreshCcw,
                              color: Colors.blueAccent,
                            ),
                            title: const Text("Re-Index Database"),
                            subtitle: const Text(
                              "Optimizes query performance.",
                            ),
                            trailing: OutlinedButton(
                              onPressed: () {},
                              child: const Text("Start"),
                            ),
                          ),
                          Divider(height: 1, color: borderColor),
                          ListTile(
                            leading: const Icon(
                              LucideIcons.hardDrive,
                              color: Colors.purpleAccent,
                            ),
                            title: const Text("Manual Backup"),
                            subtitle: const Text("Create a snapshot now."),
                            trailing: OutlinedButton(
                              onPressed: () {},
                              child: const Text("Backup"),
                            ),
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

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color glassColor;
  final Color borderColor;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.glassColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return _HyperContainer(
      glassColor: glassColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.7,
          color: color,
          backgroundColor: color.withValues(alpha: 0.1),
          minHeight: 4,
        ),
      ],
    );
  }
}

// Re-using local widgets...
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
