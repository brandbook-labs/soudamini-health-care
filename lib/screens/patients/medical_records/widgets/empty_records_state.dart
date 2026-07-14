// lib/screens/medical_records/widgets/empty_records_state.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class EmptyRecordsState extends StatelessWidget {
  final VoidCallback? onAddRecord;

  const EmptyRecordsState({super.key, this.onAddRecord});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const bgLight = Color(0xFFF8FAFC);
    const borderCol = Color(0xFFE2E8F0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- 1. HERO ICON (Glowing & Inviting) ---
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.folderHeart,
                    size: 32,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- 2. EMPOWERING HEADLINE ---
            const Text(
              "Your Digital Health Vault",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              "Keep all your prescriptions, lab reports, and medical scans in one secure place. Never lose a medical document again.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. VALUE PROP CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bgLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF10B981,
                      ).withValues(alpha: 0.15), // Emerald green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Private & Secure",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Your records are securely stored and easily shareable with doctors.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 4. CLEAR CALL TO ACTION ---
            if (onAddRecord != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddRecord,
                  icon: const Icon(LucideIcons.uploadCloud, size: 18),
                  label: const Text(
                    "Upload First Record",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
