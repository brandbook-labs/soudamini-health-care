import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- APP IMPORTS ---
import 'package:my_new_app/core/utils/theme_utils.dart'; // Import Theme Context

// --- NAVIGATION IMPORTS ---
import 'package:my_new_app/screens/admin/admin_widgets/scan_qr_screen.dart';
import 'package:my_new_app/screens/admin/admin_widgets/slots/slot_create_screen.dart';
import 'package:my_new_app/screens/admin/admin_widgets/walkin_screen.dart';
import 'package:my_new_app/screens/admin/inventory_billing/inventory/medicine_inventory_list.dart';
import 'package:my_new_app/screens/admin/receipts_screen.dart';

class QuickManagementGrid extends StatelessWidget {
  const QuickManagementGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // 🎨 Using standard colors, but they will be dynamically styled below
    final List<Map<String, dynamic>> actions = [
      {
        "icon": LucideIcons.userPlus,
        "label": "Walk-in",
        "color": const Color(0xFF074EE7), // Jivan Blue
        "page": const AdminWalkInScreen(),
      },
      {
        "icon": LucideIcons.calendarPlus,
        "label": "Slot",
        "color": Colors.purple,
        "page": const SlotCreateScreen(),
      },
      {
        "icon": LucideIcons.scanLine,
        "label": "Scan QR",
        "color": Colors.orange,
        "page": const AdminScanQrScreen(),
      },
      {
        "icon": LucideIcons.boxes,
        "label": "Inventory",
        "color": Colors.green,
        "page": const MedicineInventoryList(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actions.map((action) {
          return Expanded(child: _ActionButton(action: action));
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final Map<String, dynamic> action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final Color color = action['color'];
    final colorScheme = context.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        // 🚀 Better UX: The whole column is clickable, with a nice ripple
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => action['page']),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- ICON BOX ---
              Container(
                width: 60, // Slightly larger for better proportions
                height: 60,
                decoration: BoxDecoration(
                  // Soft tinted background based on the icon's color
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(
                    18,
                  ), // Softer squircle shape
                  // Crisp edge border
                  border: Border.all(
                    color: AppPalette.info200.withValues(alpha: 0.0),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    action['icon'],
                    color: color,
                    size: 26, // Scaled up icon slightly to match new box size
                  ),
                ),
              ),

              const SizedBox(
                height: 10,
              ), // Increased spacing for breathing room
              // --- LABEL ---
              Text(
                action['label'],
                style: context.text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
