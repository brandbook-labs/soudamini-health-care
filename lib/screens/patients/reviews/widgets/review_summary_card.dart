// lib/screens/patient_reviews/widgets/review_summary_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ReviewSummaryCard extends StatelessWidget {
  final int totalReviews;

  const ReviewSummaryCard({super.key, required this.totalReviews});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ), // Gives it breathing room from the list

      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP SECTION: THE HARD METRIC ---
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.trendingUp,
                          color: primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Big Number Stat
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "LIFETIME CONTRIBUTIONS",
                              style: TextStyle(
                                color: Colors.black45,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  totalReviews.toString(),
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 40,
                                    letterSpacing: -1.0,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Reviews",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // --- BOTTOM SECTION: THE VALUE MESSAGE ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    // Soft tint to separate from the metric
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Trust Badge
                      Row(
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            size: 16,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalReviews > 0
                                ? "Verified Contributor"
                                : "Community Member",
                            style: TextStyle(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Punchy Message
                      const Text(
                        "Your honest feedback directly helps other patients make informed healthcare decisions and holds our clinics to the highest standards. Thank you for your voice.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
