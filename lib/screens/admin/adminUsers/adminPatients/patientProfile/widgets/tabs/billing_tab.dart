// lib/screens/admin/adminUsers/adminPatients/tabs/billing_tab.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class BillingTab extends StatelessWidget {
  final List<dynamic> billingData;

  const BillingTab({super.key, required this.billingData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Billing History", style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
            // TextButton.icon(onPressed: () {}, icon: const Icon(LucideIcons.plus, size: 16), label: const Text("New Bill", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        const SizedBox(height: 16),

        if (billingData.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text("No billing records found.", style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
            ),
          )
        else
          ...List.generate(billingData.length, (index) {
            final bill = billingData[index];
            return _buildDynamicInvoiceCard(context, bill, index);
          }),
      ],
    );
  }

  Widget _buildDynamicInvoiceCard(BuildContext context, Map<String, dynamic> bill, int index) {
    final colorScheme = context.colorScheme;
    
    final String date = bill['visit_date']?.toString() ?? 'N/A';
    final String slot = bill['slot_number']?.toString() ?? 'N/A';
    final String price = bill['total_price']?.toString() ?? '0';
    final String methodRaw = bill['payment_method']?.toString() ?? 'unknown';
    
    // 🚀 [THE FIX]: Appointment Type for Invoice Generation
    final String typeRaw = bill['appointment_type']?.toString() ?? 'general';
    // Format to "SERVICE", "CONSULTATION", "FOLLOWUP"
    final String typeShort = typeRaw.replaceAll('_', '').toUpperCase().substring(0, typeRaw.length > 7 ? 7 : typeRaw.length);
    
    final String formattedMethod = methodRaw.replaceAll('_', ' ').toUpperCase();

    // 🚀 [THE FIX]: Generate Invoice like INV-24MAR-SERVICE-0
    final String dateShort = date.replaceAll(' ', '').toUpperCase().substring(0, 5); // 24MAR
    final String pseudoInvoiceId = "INV-$dateShort-$typeShort-$index";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(LucideIcons.receipt, color: Colors.green.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pseudoInvoiceId, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text("Date: $date  •  Slot: $slot", style: context.text.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("₹$price", style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.green.shade700)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
                child: Text(formattedMethod, style: context.text.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}