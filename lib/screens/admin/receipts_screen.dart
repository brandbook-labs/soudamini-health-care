import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminReceiptsScreen extends StatelessWidget {
  const AdminReceiptsScreen({super.key});

  final List<Map<String, dynamic>> _receipts = const [
    {
      "id": "RCP-9821",
      "name": "Rohan Das",
      "date": "Jan 26, 10:30 AM",
      "amount": "₹500",
      "status": "Paid",
      "type": "Consultation",
    },
    {
      "id": "RCP-9822",
      "name": "Priya Singh",
      "date": "Jan 26, 11:15 AM",
      "amount": "₹1,200",
      "status": "Pending",
      "type": "Lab Test",
    },
    {
      "id": "RCP-9823",
      "name": "Amit Kumar",
      "date": "Jan 25, 04:00 PM",
      "amount": "₹300",
      "status": "Paid",
      "type": "Follow-up",
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Receipts & Reports",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.download, color: colorScheme.primary),
            onPressed: () {
              // Logic to export all report
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _receipts.length,
        itemBuilder: (context, index) {
          final receipt = _receipts[index];
          final isPaid = receipt['status'] == "Paid";

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Icon Box
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.receipt,
                    color: isPaid ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${receipt['id']} • ${receipt['type']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Action
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      receipt['amount'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        receipt['status'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
