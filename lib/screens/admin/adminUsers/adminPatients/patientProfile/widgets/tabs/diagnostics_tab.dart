// lib/screens/admin/adminUsers/widgets/diagnostics_tab.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Theme Context

class DiagnosticsTab extends StatelessWidget {
  const DiagnosticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- LAB REPORTS SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Lab Reports",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B), // Deep slate
                letterSpacing: -0.3,
              ),
            ),
            TextButton.icon(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(LucideIcons.uploadCloud, size: 16),
              label: const Text(
                "Upload",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          context,
          title: "Complete Blood Count (CBC)",
          date: "15 Nov 2025",
          labName:
              "Dr. Lal PathLabs & Diagnostic Center", // Long name tests overflow
          doctorName: "Dr. Jhasaketan",
          docType: "PDF • 1.2 MB",
          status: "Normal",
          icon: LucideIcons.fileText,
          color: Colors.blue.shade600,
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          context,
          title: "Lipid Profile & Glucose Fasting",
          date: "10 Nov 2025",
          labName: "Apollo Diagnostics",
          doctorName: "Dr. Jayashree",
          docType: "PDF • 845 KB",
          status: "Abnormal",
          icon: LucideIcons.activity,
          color: Colors.red.shade500,
        ),

        const SizedBox(height: 36),

        // --- IMAGING SECTION ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Imaging & Scans",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.3,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(LucideIcons.filter, size: 18),
              color: const Color(0xFF64748B),
            ),
          ],
        ),
        const SizedBox(height: 12),

        _buildDocumentCard(
          context,
          title: "Chest X-Ray (PA View)",
          date: "02 Feb 2026",
          labName: "City Imaging & MRI Center",
          doctorName: "Dr. Snehanshu",
          docType: "JPG • 4.5 MB",
          status: "Reviewed",
          icon: LucideIcons.image,
          color: Colors.purple.shade600,
        ),

        const SizedBox(height: 80), // Bottom padding for scrolling
      ],
    );
  }

  // --- PREMIUM SAAS DOCUMENT CARD ---
  Widget _buildDocumentCard(
    BuildContext context, {
    required String title,
    required String date,
    required String labName,
    required String doctorName,
    required String docType,
    required String status,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    // Status Badge Configuration
    Color statusBgColor;
    Color statusTextColor;

    if (status.toLowerCase() == 'normal' ||
        status.toLowerCase() == 'reviewed') {
      statusBgColor = Colors.green.shade50;
      statusTextColor = Colors.green.shade700;
    } else if (status.toLowerCase() == 'abnormal') {
      statusBgColor = Colors.red.shade50;
      statusTextColor = Colors.red.shade700;
    } else {
      statusBgColor = Colors.orange.shade50;
      statusTextColor = Colors.orange.shade700;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // Soft border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Open document viewer
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- 1. FILE ICON ---
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),

                const SizedBox(width: 16),

                // --- 2. DOCUMENT DETAILS (Wrapped in Expanded to fix overflow) ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Action Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                fontSize: 15,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis, // Fixes long title overflow
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clean status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusTextColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Lab Name (With Expanded to prevent overflow)
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.building,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              labName,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow
                                  .ellipsis, // Fixes long lab name overflow
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Prescribed By
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.stethoscope,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              doctorName,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      Divider(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                        height: 1,
                      ),
                      const SizedBox(height: 12),

                      // --- 3. BOTTOM META & ACTIONS ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Meta Info (Date & Size)
                          Row(
                            children: [
                              Text(
                                date,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  "•",
                                  style: TextStyle(color: Color(0xFFCBD5E1)),
                                ),
                              ),
                              Text(
                                docType,
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),

                          // Quick Actions
                          Row(
                            children: [
                              _buildMiniIconButton(
                                LucideIcons.download,
                                "Download",
                              ),
                              const SizedBox(width: 8),
                              _buildMiniIconButton(
                                LucideIcons.moreHorizontal,
                                "Options",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper for ultra-clean mini icon buttons
  Widget _buildMiniIconButton(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Very light slate
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: const Color(0xFF475569), // Slate 600
        ),
      ),
    );
  }
}
