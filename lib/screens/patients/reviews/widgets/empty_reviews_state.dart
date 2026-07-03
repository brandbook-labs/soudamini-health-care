// lib/screens/patient_reviews/widgets/empty_reviews_state.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class EmptyReviewsState extends StatelessWidget {
  final VoidCallback? onReviewPastVisit;

  const EmptyReviewsState({
    super.key,
    this.onReviewPastVisit, // Pass a function to route them to Past Appointments
  });

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
                  child: const Icon(LucideIcons.star, size: 32, color: primary),
                ),
                // Tiny decorative spark
                Positioned(
                  top: 0,
                  right: 10,
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: Colors.amber.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // --- 2. EMPOWERING HEADLINE ---
            const Text(
              "Your Voice Shapes Better Care",
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
              "You haven't reviewed any doctors or clinics yet. Share your experiences to help providers improve and guide other patients to the right care.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // --- 3. THE "TIT FOR TAT" VALUE PROP CARD ---
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
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      color: Colors.amber.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Build Community Trust",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Submit your first review today to unlock your 'Verified Reviewer' badge.",
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed:
                    onReviewPastVisit ??
                    () {
                      // Fallback if no function is passed: Show a quick toast
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Routing to Past Appointments...'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                icon: const Icon(LucideIcons.calendarCheck, size: 18),
                label: const Text(
                  "Review a Past Visit",
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
