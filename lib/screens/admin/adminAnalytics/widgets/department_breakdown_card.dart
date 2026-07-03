import 'package:flutter/material.dart';

class DepartmentBreakdownCard extends StatelessWidget {
  final List<Map<String, dynamic>> departmentData;

  const DepartmentBreakdownCard({super.key, required this.departmentData});

  String _formatCurrency(double amount) {
    if (amount >= 1000) return "₹${(amount / 1000).toStringAsFixed(1)}k";
    return "₹${amount.toStringAsFixed(0)}";
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Departments",
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (departmentData.isEmpty)
            const Text(
              "No data available yet.",
              style: TextStyle(color: Colors.grey),
            ),
          ..._buildDepartmentList(context),
        ],
      ),
    );
  }

  List<Widget> _buildDepartmentList(BuildContext context) {
    double totalDeptValue = departmentData.fold(
      0,
      (sum, item) => sum + (item['value'] as double),
    );

    return departmentData.map((dept) {
      final double value = dept['value'] as double;
      final double percentage = totalDeptValue > 0
          ? (value / totalDeptValue)
          : 0;
      final String percentString = "${(percentage * 100).toStringAsFixed(0)}%";

      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: _buildDepartmentBar(
          context,
          dept['name'],
          percentage,
          percentString,
          value,
        ),
      );
    }).toList();
  }

  Widget _buildDepartmentBar(
    BuildContext context,
    String name,
    double percent,
    String displayValue,
    double rawValue,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
            Row(
              children: [
                Text(
                  _formatCurrency(rawValue),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "($displayValue)",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
