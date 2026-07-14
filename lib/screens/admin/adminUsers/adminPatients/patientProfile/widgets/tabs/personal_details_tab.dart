import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class PersonalDetailsTab extends StatelessWidget {
  const PersonalDetailsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- DEMOGRAPHICS ---
        _buildSectionHeader(
          context,
          "Demographics & Address",
          LucideIcons.mapPin,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _InfoRow(label: "Full Name", value: "Rajesh Kumar"),
            _InfoRow(label: "Date of Birth", value: "12 Aug 1983 (42 Yrs)"),
            _InfoRow(label: "Gender", value: "Male"),
            _InfoRow(
              label: "Blood Group",
              value: "O+",
              isHighlight: true,
              highlightColor: Colors.red.shade700,
            ),
            _InfoRow(
              label: "Address",
              value: "Plot 142, Unit 9, Bhubaneswar, Odisha 751022",
            ),
          ],
        ),

        const SizedBox(height: 24),

        // --- EMERGENCY CONTACT ---
        _buildSectionHeader(
          context,
          "Emergency Contact",
          LucideIcons.phoneCall,
        ),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _InfoRow(label: "Name", value: "Sunita Kumar (Wife)"),
            _InfoRow(label: "Phone", value: "+91 98765 00000"),
          ],
        ),

        const SizedBox(height: 24),

        // --- LIFESTYLE HABITS ---
        _buildSectionHeader(context, "Lifestyle Habits", LucideIcons.coffee),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _InfoRow(label: "Smoking", value: "Non-Smoker"),
            _InfoRow(label: "Alcohol", value: "Occasional"),
            _InfoRow(label: "Diet", value: "Vegetarian"),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: context.text.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: context.text.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: isHighlight
                ? Text(
                    value,
                    style: context.text.bodyMedium?.copyWith(
                      color: highlightColor ?? colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : Text(
                    value,
                    style: context.text.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
