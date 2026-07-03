import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart'; // JivanAppBar, JivanCard
import 'package:my_new_app/core/utils/theme_utils.dart';

class PayoutsDashboardScreen extends StatefulWidget {
  const PayoutsDashboardScreen({super.key});

  @override
  State<PayoutsDashboardScreen> createState() => _PayoutsDashboardScreenState();
}

class _PayoutsDashboardScreenState extends State<PayoutsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Data
  final List<Map<String, dynamic>> _transactions = [
    {
      "id": "TXN-8821",
      "clinic": "Apollo Pharmacy - Unit 12",
      "amount": "₹45,200",
      "status": "Pending",
      "date": "Today, 10:42 AM",
      "method": "UPI (phonepe@ybl)",
    },
    {
      "id": "TXN-8820",
      "clinic": "Dr. Sarah's Dental",
      "amount": "₹12,500",
      "status": "Processed",
      "date": "Yesterday",
      "method": "Bank Transfer (HDFC)",
    },
    {
      "id": "TXN-8819",
      "clinic": "City Care Hospital",
      "amount": "₹1,20,000",
      "status": "Failed",
      "date": "28 Jan 2026",
      "method": "Bank Transfer (SBI)",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _showProcessSheet(Map<String, dynamic> txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PayoutActionSheet(transaction: txn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: JivanAppBar(
        title: "Financial Overview",
        showBack: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.downloadCloud),
          ),
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.settings)),
        ],
      ),
      body: Column(
        children: [
          // --- LIQUIDITY STATS ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _MoneyCard(
                    label: "Pending Payouts",
                    amount: "₹45.2k",
                    color: Colors.orange,
                    icon: LucideIcons.clock,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MoneyCard(
                    label: "Total Disbursed",
                    amount: "₹8.4L",
                    color: Colors.green,
                    icon: LucideIcons.checkCircle,
                  ),
                ),
              ],
            ),
          ),

          // --- TABS ---
          TabBar(
            controller: _tabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: "Requests"),
              Tab(text: "History"),
              Tab(text: "Disputes"),
            ],
          ),

          // --- LIST ---
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionList(
                  items: _transactions
                      .where((t) => t['status'] == 'Pending')
                      .toList(),
                  onTap: _showProcessSheet,
                ),
                _TransactionList(
                  items: _transactions
                      .where((t) => t['status'] != 'Pending')
                      .toList(),
                  onTap: _showProcessSheet,
                ),
                const Center(child: Text("No active disputes")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class _MoneyCard extends StatelessWidget {
  final String label, amount;
  final Color color;
  final IconData icon;

  const _MoneyCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final Function(Map<String, dynamic>) onTap;

  const _TransactionList({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(LucideIcons.checkCircle, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text("All caught up!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        final isPending = item['status'] == 'Pending';
        final isFailed = item['status'] == 'Failed';

        return InkWell(
          onTap: () => onTap(item),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFailed
                    ? Colors.red.withValues(alpha: 0.3)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withValues(alpha: 0.1)
                        : (isFailed
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPending
                        ? LucideIcons.clock
                        : (isFailed
                              ? LucideIcons.alertCircle
                              : LucideIcons.check),
                    color: isPending
                        ? Colors.orange
                        : (isFailed ? Colors.red : Colors.green),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['clinic'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item['date']} • ${item['method']}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item['amount'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (isPending)
                      const Text(
                        "Action Req.",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PayoutActionSheet extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _PayoutActionSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                "Process Payout",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Transaction ID: ${transaction['id']}",
                style: const TextStyle(
                  fontFamily: "monospace",
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Total Payable",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      transaction['amount'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                "Admin Notes (Optional)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: "Add transaction reference or rejection reason...",
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(LucideIcons.x),
                      label: const Text("Reject"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Payout Processed Successfully"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(LucideIcons.check),
                      label: const Text("Approve & Pay"),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Bottom safe area buffer
            ],
          ),
        ),
      ),
    );
  }
}
