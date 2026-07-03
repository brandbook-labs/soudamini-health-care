import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
// Dark Mode
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

// --- MOCK DATA ---
class MedicineOrder {
  final String orderId;
  final String date;
  final String status; // 'Delivered', 'Processing', 'Cancelled'
  final double totalAmount;
  final List<String> items;

  MedicineOrder({
    required this.orderId,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.items,
  });
}

final List<MedicineOrder> mockOrders = [
  MedicineOrder(
    orderId: "OD-2024-8821",
    date: "18 Jan, 2024",
    status: "Processing",
    totalAmount: 450.00,
    items: ["Paracetamol 500mg (x2)", "Vitamin C Tablets"],
  ),
  MedicineOrder(
    orderId: "OD-2023-1102",
    date: "10 Dec, 2023",
    status: "Delivered",
    totalAmount: 1200.50,
    items: ["Shelcal 500mg", "Diabetes Care Kit", "N95 Masks (Pack of 5)"],
  ),
  MedicineOrder(
    orderId: "OD-2023-0955",
    date: "05 Nov, 2023",
    status: "Cancelled",
    totalAmount: 340.00,
    items: ["Cough Syrup", "Vicks Vaporub"],
  ),
];

class MedicineOrdersScreen extends StatelessWidget {
  const MedicineOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Orders",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockOrders.length,
        itemBuilder: (context, index) {
          return OrderCard(
            order: mockOrders[index],
            cardColor: cardColor,
            textColor: textColor,
            subTextColor: subTextColor,
            borderColor: borderColor,
            isDarkMode: isDarkMode,
          );
        },
      ),
    );
  }
}

// --- ORDER CARD WIDGET ---
class OrderCard extends StatelessWidget {
  final MedicineOrder order;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDarkMode;

  const OrderCard({
    super.key,
    required this.order,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDarkMode,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case "Processing":
        return Colors.orange;
      case "Delivered":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? []
            : [
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
          // Header: ID + Status
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order.orderId.split('-').last}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.date,
                      style: TextStyle(fontSize: 11, color: subTextColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Items List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(LucideIcons.dot, size: 16, color: subTextColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: borderColor),

          // Footer: Total + Action
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total Amount",
                      style: TextStyle(fontSize: 10, color: subTextColor),
                    ),
                    Text(
                      "₹${order.totalAmount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                if (order.status == "Delivered")
                  ElevatedButton.icon(
                    onPressed: () {
                      // Reorder Logic
                    },
                    icon: const Icon(LucideIcons.rotateCcw, size: 14),
                    label: const Text("Reorder"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else
                  OutlinedButton(
                    onPressed: () {
                      // Track Order Logic
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 36),
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Track Order",
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
