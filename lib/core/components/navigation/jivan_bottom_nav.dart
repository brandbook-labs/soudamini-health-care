import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class JivanBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String userRole; // 'patient', 'admin'

  const JivanBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole = 'patient',
  });

  @override
  Widget build(BuildContext context) {
    // A. Patient Menu
    final List<Map<String, dynamic>> patientItems = [
      {"icon": LucideIcons.home, "label": "Home"},
      {"icon": LucideIcons.stethoscope, "label": "Doctors"},
      // {"icon": LucideIcons.tablets, "label": "Medicines"}, // 🚀 Temporarily disabled for this app
      {"icon": LucideIcons.flaskConical, "label": "Labs"},
      {"icon": LucideIcons.user, "label": "Profile"},
    ];

    // B. Admin (Clinic) Menu
    final List<Map<String, dynamic>> adminItems = [
      {"icon": LucideIcons.layoutDashboard, "label": "Home"},
      {"icon": LucideIcons.receipt, "label": "Billing"},
      {"icon": LucideIcons.lineChart, "label": "Analytics"},
      {"icon": LucideIcons.users, "label": "Patients"},
      {"icon": LucideIcons.settings, "label": "Settings"},
    ];

    // 🚀 Super Admin items completely removed for strict scoping

    List<Map<String, dynamic>> items;
    if (userRole == 'admin') {
      items = adminItems;
    } else {
      items = patientItems; // Safely defaults to patient
    }

    // Handle OS bottom safe areas (e.g., iPhone home indicator)
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        // Crisp, subtle top border to separate nav from content
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
        ),
        // Soft ambient shadow for depth without being overpowering
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64, // Standard, predictable hit-target height
          child: Row(
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _NavBarItem(
                  icon: items[index]['icon'] as IconData,
                  label: items[index]['label'] as String,
                  isSelected: currentIndex == index,
                  onTap: () {
                    if (currentIndex != index) {
                      HapticFeedback.selectionClick();
                      onTap(index);
                    }
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = context.colorScheme.primary;
    final inactiveColor = context.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      // InkWell provides native, accessible touch feedback (ripple)
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: activeColor.withOpacity(0.05),
        child: Stack(
          children: [
            // 1. Top Highlight Indicator
            // Anchored to the top, expands smoothly when selected
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: 3,
                  width: isSelected ? 32 : 0,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Icon and Text
            // Static positioning prevents jarring layout shifts
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      icon,
                      key: ValueKey<bool>(isSelected),
                      size: 24,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: context.text.labelSmall!.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                      fontSize: 11,
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}