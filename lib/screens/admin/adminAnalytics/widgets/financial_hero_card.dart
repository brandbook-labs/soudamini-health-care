// lib/screens/admin/adminAnalytics/widgets/financial_hero_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class FinancialHeroCard extends StatelessWidget {
  final double totalRevenue;
  final double doctorFees;
  final double medicines;
  final double labTests;

  const FinancialHeroCard({
    super.key,
    required this.totalRevenue,
    required this.doctorFees,
    required this.medicines,
    required this.labTests,
  });

  String _formatCurrency(double amount, {bool isLarge = false}) {
    if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(isLarge ? 2 : 1)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}k";
    }
    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.neutralWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 231, 233, 237),
        ), // Razor thin border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Top Row: Title & Icon ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Net Revenue",
                style: TextStyle(
                  color: Color(0xFF64748B), // Slate 500
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Slate 50
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: const Icon(
                  LucideIcons.wallet,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // --- Middle Row: Giant Number & Trend ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(totalRevenue, isLarge: true),
                style: const TextStyle(
                  color: Color(0xFF0F172A), // Slate 900
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -2.0, // Tight tracking for large SaaS numbers
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 12),
              // SaaS-style Trend Indicator
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5), // Emerald 50
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFD1FAE5),
                  ), // Emerald 100
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.trendingUp,
                      size: 12,
                      color: Color(0xFF059669),
                    ), // Emerald 600
                    SizedBox(width: 4),
                    Text(
                      "+12.5%",
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 24),

          // --- Bottom Row: Feature Breakdown ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Revenue Split",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              // Subtle roadmap badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  "ROADMAP",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- The Metrics ---
          Row(
            children: [
              // 1. ACTIVE Metric
              Expanded(
                child: _buildMetricItem(
                  label: "Doctor Fees",
                  value: _formatCurrency(doctorFees),
                  dotColor: const Color(0xFF3B82F6), // Blue 500
                  isActive: true,
                ),
              ),

              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),

              // 2. INACTIVE Metric
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildMetricItem(
                    label: "Medicines",
                    value:
                        "---", // Replaced actual value with placeholder dashes
                    dotColor: const Color(0xFF94A3B8), // Slate 400
                    isActive: false,
                  ),
                ),
              ),

              Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),

              // 3. INACTIVE Metric
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: _buildMetricItem(
                    label: "Lab Tests",
                    value: "---",
                    dotColor: const Color(0xFF94A3B8),
                    isActive: false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Reusable Metric Builder ---
  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color dotColor,
    required bool isActive,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
