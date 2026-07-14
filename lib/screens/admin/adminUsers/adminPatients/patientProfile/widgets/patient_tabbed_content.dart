import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

import 'tabs/clinical_history_tab.dart';
import 'tabs/billing_tab.dart';

class PatientTabbedContent extends StatelessWidget {
  final Map<String, dynamic> overviewData;
  final Map<String, dynamic> bookedByData;
  final List<dynamic> clinicalHistory;
  final List<dynamic> billingHistory;

  const PatientTabbedContent({
    super.key,
    required this.overviewData,
    required this.bookedByData,
    required this.clinicalHistory,
    required this.billingHistory,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 ଏବେ ୩ଟି ଟ୍ୟାବ୍ ଅଛି
    return DefaultTabController(
      length: 3, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: context.colorScheme.primary,
              indicatorWeight: 3,
              labelColor: context.colorScheme.primary,
              unselectedLabelColor: context.colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "Overview"), // 🚀 ନୂଆ ଟ୍ୟାବ୍
                Tab(text: "Clinical History"),
                Tab(text: "Billing"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOverviewTab(context), // 🚀 Overview UI
                ClinicalHistoryTab(historyData: clinicalHistory), 
                BillingTab(billingData: billingHistory),          
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 Premium Overview Tab Widget
  Widget _buildOverviewTab(BuildContext context) {
    final colorScheme = context.colorScheme;
    
    // Parse booked_by info safely
    final String bookedByName = bookedByData['user_name']?.toString().isNotEmpty == true 
        ? bookedByData['user_name'] 
        : "Unknown User";
    final String bookedByPhone = bookedByData['phone']?.toString() ?? "N/A";

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Text("Visit Summary", style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        const SizedBox(height: 16),
        
        // 🚀 Metrics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _buildStatBox(context, "Total Spent", "₹${overviewData['total_spent'] ?? 0}", LucideIcons.banknote, Colors.orange.shade700),
            _buildStatBox(context, "Total Visits", overviewData['total_visits']?.toString() ?? "0", LucideIcons.calendar, colorScheme.primary),
            _buildStatBox(context, "Completed", overviewData['completed_visits']?.toString() ?? "0", LucideIcons.checkCircle2, Colors.green),
            _buildStatBox(context, "Cancelled", overviewData['cancelled_visits']?.toString() ?? "0", LucideIcons.xCircle, Colors.red),
          ],
        ),

        const SizedBox(height: 32),
        Text("Account Management", style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
        const SizedBox(height: 16),
        
        // 🚀 Booked By Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.userCheck, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookedByName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Linked Phone: $bookedByPhone", 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text("PRIMARY", style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 9)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper Widget for Stats
  Widget _buildStatBox(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: context.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: context.colorScheme.onSurface)),
        ],
      ),
    );
  }
}