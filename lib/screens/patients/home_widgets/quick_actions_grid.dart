import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:my_new_app/core/utils/theme_utils.dart';

// --- SCREEN IMPORTS ---
import 'package:my_new_app/screens/patients/doctors_list_screen.dart';
import 'package:my_new_app/screens/patients/labs/lab_listing_screen.dart';
import 'package:my_new_app/screens/patients/medicine_orders_screen.dart';
import 'package:my_new_app/screens/patients/medicine_shop_screen.dart';
import 'package:my_new_app/screens/patients/clinics_listing_screen.dart';

/// A simple data model for each action — cleaner than juggling Map<String, dynamic>.
class _ActionItem {
  final String id;
  final String title;
  final IconData icon;
  final Color color;

  const _ActionItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });
}

class QuickActionsRow extends StatelessWidget {
  final Function(int) onTabChange;

  const QuickActionsRow({super.key, required this.onTabChange});

  static const List<_ActionItem> _actions = [
    _ActionItem(
      id: "appointment",
      title: "Doctor",
      icon: LucideIcons.stethoscope,
      color: Color(0xFF4F7DF3), // blue
    ),
    _ActionItem(
      id: "medicine",
      title: "Medicine",
      icon: LucideIcons.pill,
      color: Color(0xFF19A97C), // green
    ),
    _ActionItem(
      id: "lab",
      title: "Lab Test",
      icon: LucideIcons.flaskConical,
      color: Color(0xFF8B5CF6), // purple
    ),
    _ActionItem(
      id: "records",
      title: "Records",
      icon: LucideIcons.clipboardList,
      color: Color(0xFFF59E0B), // amber
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _actions.map((action) {
        return Expanded(
          child: _ActionCard(
            data: action,
            onTap: () => _handleNavigation(context, action.id),
          ),
        );
      }).toList(),
    );
  }

  void _handleNavigation(BuildContext context, String id) {
    switch (id) {
      case "appointment":
        onTabChange(1); // Doctors tab
        break;
      case "medicine":
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicineShopScreen()),
        );
        break;
      case "lab":
        onTabChange(3); // Labs tab
        break;
      case "records":
        // TODO: Map this to your Health Records Tab or Screen
        debugPrint("Navigate to Health Records");
        break;
      default:
        debugPrint("Unknown ID: $id");
    }
  }
}

/// Animated, gradient-filled action tile with a soft colored shadow
/// and a subtle scale-on-press effect.
class _ActionCard extends StatefulWidget {
  final _ActionItem data;
  final VoidCallback onTap;

  const _ActionCard({required this.data, required this.onTap});

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.data.color;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _pressed ? 0.92 : 1.0,
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOut,
              child: Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.90),
                      Color.lerp(color, Colors.black, 0.18)!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(widget.data.icon, size: 26, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.data.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.labelSm?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
