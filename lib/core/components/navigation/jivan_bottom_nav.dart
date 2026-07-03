import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import '../../../../controllers/language_controller.dart';

class JivanBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  // Changed from bool isAdmin to String userRole
  // Values: 'patient', 'admin', 'super_admin'
  final String userRole;

  const JivanBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userRole = 'patient', // Default to patient
  });

  @override
  Widget build(BuildContext context) {
    // 1. Language Listener
    bool isOdia = false;
    try {
      final locale = context.watch<LanguageController>().currentLocale;
      isOdia = locale.languageCode == 'or';
    } catch (_) {
      isOdia = false;
    }

    // 2. DEFINE MENUS

    // A. Patient Menu
    final List<Map<String, dynamic>> patientItems = [
      {"icon": LucideIcons.home, "label": isOdia ? "ମୁଖ୍ୟ" : "Home"},
      {"icon": LucideIcons.stethoscope, "label": isOdia ? "ଡାକ୍ତର" : "Doctors"},
      {"icon": LucideIcons.building2, "label": isOdia ? "କ୍ଲିନିକ" : "Clinics"},
      {"icon": LucideIcons.flaskConical, "label": isOdia ? "ଲ୍ୟାବ୍" : "Labs"},
      {"icon": LucideIcons.user, "label": isOdia ? "ପ୍ରୋଫାଇଲ୍" : "Profile"},
    ];

    // B. Admin (Clinic) Menu - Updated exactly as requested
    final List<Map<String, dynamic>> adminItems = [
      {
        "icon": LucideIcons.layoutDashboard,
        "label": isOdia ? "ଡ୍ୟାସବୋର୍ଡ" : "Home",
      },
      {
        "icon": LucideIcons.receipt, // 🚀 ସୁରକ୍ଷିତ ଆଇକନ୍ (କୌଣସି ଏରର୍ ଆସିବ ନାହିଁ)
        "label": isOdia ? "ବିଲିଂ" : "Billing",
      },
      {
        "icon": LucideIcons.lineChart, 
        "label": isOdia ? "ବିଶ୍ଳେଷଣ" : "Analytics", // ସଠିକ୍ ଓଡ଼ିଆ ଅନୁବାଦ
      },
      {
        "icon": LucideIcons.users, 
        "label": isOdia ? "ରୋଗୀ" : "Patients",
      },
      {
        "icon": LucideIcons.settings,
        "label": isOdia ? "ସେଟିଙ୍ଗସ୍" : "Settings",
      },
    ];

    // C. Super Admin (Platform Owner) Menu
    final List<Map<String, dynamic>> superAdminItems = [
      {"icon": LucideIcons.barChart3, "label": "Overview"}, // Global Stats
      {"icon": LucideIcons.store, "label": "Clinics"}, // Manage Clinics
      {"icon": LucideIcons.users, "label": "Users"}, // Manage Doctors/Patients
      {
        "icon": LucideIcons.shieldCheck,
        "label": "Approvals",
      }, // Pending Requests
      {"icon": LucideIcons.user, "label": "Profile"},
    ];

    // 3. SELECT MENU BASED ON ROLE
    List<Map<String, dynamic>> items;
    if (userRole == 'super_admin') {
      items = superAdminItems;
    } else if (userRole == 'admin') {
      items = adminItems;
    } else {
      items = patientItems;
    }

    final bgColor = context.colorScheme.surface;
    final borderColor = context.colorScheme.outlineVariant.withValues(
      alpha: 0.2,
    );

    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: context.colorScheme.outline.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          return _NavBarItem(
            icon: items[index]['icon'] as IconData,
            label: items[index]['label'] as String,
            isSelected: currentIndex == index,
            onTap: () {
              HapticFeedback.lightImpact();
              onTap(index);
            },
          );
        }),
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
    final selectedColor = context.colorScheme.primary;
    final unselectedColor = context.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: context.text.labelSmall!.copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 10,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}