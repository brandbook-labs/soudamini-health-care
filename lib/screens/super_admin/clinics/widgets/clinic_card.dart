// lib/screens/super_admin/clinics/widgets/clinic_card.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure url_launcher is in pubspec.yaml

class ClinicCard extends StatelessWidget {
  final Map<String, dynamic> clinic;
  final VoidCallback onTap; // Go to details
  final VoidCallback onLongPress; // Open bottom sheet actions

  const ClinicCard({
    super.key,
    required this.clinic,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    // --- DATA PREP ---
    final String name = clinic['name'] ?? "Unknown Facility";
    final String city = clinic['city'] ?? "Unknown City";
    final String phone = clinic['phone'] ?? "";
    final bool isVerified = clinic['isVerified'] ?? false;
    final int staffCount = clinic['staffCount'] ?? 0;
    final List<dynamic> facilities = clinic['facilities'] ?? [];
    final String status = (clinic['status'] ?? 'active')
        .toString()
        .toLowerCase();
    final bool isActive = status == 'active';

    // Status Colors
    final statusColor = isActive ? const Color(0xFF22C55E) : Colors.orange;
    final statusBg = statusColor.withOpacity(isDark ? 0.15 : 0.1);

    // Card Background Logic
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.grey.shade200;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          splashColor: colorScheme.primary.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- ROW 1: HEADER (Avatar + Name + Status) ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _buildAvatar(name, colorScheme),
                    const SizedBox(width: 12),

                    // Name & Loc
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  LucideIcons.badgeCheck,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Location Row
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: theme.hintColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  city,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Status Badge (Top Right)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        isActive ? "Active" : "Suspended",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // --- ROW 2: TAGS (Conditional) ---
                // If tags exist, show them. If not, this section collapses (height 0)
                if (facilities.isNotEmpty) ...[
                  SizedBox(
                    height: 26,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: facilities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, index) =>
                          _buildTag(context, facilities[index].toString()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- ROW 3: FOOTER (Metrics Left | Actions Right) ---
                // This fixes the "empty space" issue by anchoring actions to the right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Staff Count
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.users,
                            size: 14,
                            color: theme.disabledColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "$staffCount Staff",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right: ACTION DOCK
                    Row(
                      children: [
                        // WhatsApp Action
                        _buildIconButton(
                          context,
                          icon: LucideIcons.messageCircle,
                          color: const Color(0xFF25D366), // WA Brand Color
                          bg: const Color(0xFF25D366).withOpacity(0.1),
                          onTap: () => _launchWhatsApp(phone),
                        ),
                        const SizedBox(width: 8),

                        // Call Action
                        _buildIconButton(
                          context,
                          icon: LucideIcons.phone,
                          color: Colors.blueAccent,
                          bg: Colors.blueAccent.withOpacity(0.1),
                          onTap: () => _launchCall(phone),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildAvatar(String name, ColorScheme colorScheme) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    // Generate a consistent color based on the name character code to make UI lively
    final colors = [Colors.blue, Colors.purple, Colors.teal, Colors.indigo];
    final color = colors[name.hashCode % colors.length];

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }

  // --- ACTIONS LOGIC ---

  Future<void> _launchCall(String phone) async {
    if (phone.isEmpty) return;
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp(String phone) async {
    if (phone.isEmpty) return;
    // Cleanup phone number for WA (remove spaces, ensure country code)
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    // Default to +91 if missing (adjust based on your region needs)
    if (!cleanPhone.startsWith('+')) cleanPhone = "+91$cleanPhone";

    final Uri uri = Uri.parse("https://wa.me/$cleanPhone");
    // External application mode is better for WA
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
