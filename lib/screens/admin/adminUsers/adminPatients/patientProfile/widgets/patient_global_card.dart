import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class PatientGlobalCard extends StatelessWidget {
  // 🚀 These are fed dynamically by the Profile Screen
  final String patientName;
  final String patientId;
  final String phoneNumber;
  final String demographics;
  final String avatarUrl;

  const PatientGlobalCard({
    super.key,
    required this.patientName,
    required this.patientId,
    required this.phoneNumber,
    required this.demographics,
    required this.avatarUrl,
  });

  // --- ACTIONS ---
  Future<void> _launchDialer(String phone) async {
    if (phone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    final cleanNumber = phone.replaceAll(RegExp(r'\D'), '');
    final fullNumber = cleanNumber.length == 10
        ? "91$cleanNumber"
        : cleanNumber;
    final Uri url = Uri.parse("https://wa.me/$fullNumber");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- AVATAR & BASIC INFO ---
          Row(
            children: [
              // Premium Avatar Ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 34,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              const SizedBox(width: 16),

              // Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // ID Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "ID: $patientId",
                        style: context.text.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      demographics,
                      style: context.text.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),

          // --- MEDICAL TAGS (Using Wrap to prevent overflow) ---
          // Wrap(
          //   spacing: 8,
          //   runSpacing: 8,
          //   children: [
          //     _MedicalBadge(
          //       label: "O+ Blood",
          //       color: Colors.red.shade700,
          //       icon: LucideIcons.droplet,
          //     ),
          //     _MedicalBadge(
          //       label: "Penicillin Allergy",
          //       color: Colors.red.shade700,
          //       icon: LucideIcons.alertTriangle,
          //     ),
          //     _MedicalBadge(
          //       label: "Type 2 Diabetes",
          //       color: Colors.orange.shade700,
          //       icon: LucideIcons.activity,
          //     ),
          //   ],
          // ),

          // const SizedBox(height: 24),

          // --- QUICK CONTACT BUTTONS ---
          Row(
            children: [
              Expanded(
                child: _QuickActionBtn(
                  icon: LucideIcons.phone,
                  label: "Call",
                  color: colorScheme.primary,
                  onTap: () => _launchDialer(phoneNumber),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionBtn(
                  icon: LucideIcons.messageCircle,
                  label: "WhatsApp",
                  color: Colors.green.shade600,
                  onTap: () => _launchWhatsApp(phoneNumber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── SUB-WIDGETS ──────────────────────────────────────────────────────────────

class _MedicalBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _MedicalBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
