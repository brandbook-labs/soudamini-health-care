import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // ThemeContext

// --- SCREEN IMPORTS ---
import 'package:my_new_app/screens/patients/doctors_list_screen.dart';
import 'package:my_new_app/screens/patients/labs/lab_listing_screen.dart';
import 'package:my_new_app/screens/patients/medicine_orders_screen.dart';
import 'package:my_new_app/screens/patients/medicine_shop_screen.dart';
import 'package:my_new_app/screens/patients/clinics_listing_screen.dart'; // Added Clinics Screen Import

class QuickActionsGrid extends StatelessWidget {
  final Function(int) onTabChange;

  const QuickActionsGrid({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    final List<Map<String, dynamic>> actions = [
      {
        "id": "doctor",
        "title": isOdia ? "ଡାକ୍ତର" : "Doctor",
        "subtitle": isOdia ? "ଦୈନିକ ବିଜେତା" : "Daily Winner",
        "mainStat": isOdia ? "ମାଗଣା" : "FREE",
        "totalLabel": isOdia ? "ପରାମର୍ଶ" : "Consult",
        "icon": LucideIcons.stethoscope,
        "color": context.colorScheme.primary,
        "isLive": true,
        "liveStat": 12,
        "liveLabel": isOdia ? "ଜଣ" : "Online",
        "progress": isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book Now",
      },
      {
        // REPLACED 'knowledge' with 'clinic'
        "id": "clinic",
        "title": isOdia ? "କ୍ଲିନିକ୍" : "Clinics",
        "subtitle": isOdia ? "ନିକଟସ୍ଥ କ୍ଲିନିକ୍" : "Nearby Clinics",
        "mainStat": "Nearby",
        "totalLabel": isOdia ? "କେନ୍ଦ୍ର" : "Centers",
        "icon": LucideIcons.building2, // Changed icon to building
        "color":
            context.semantic.success ??
            Colors.green, // Using a green/success color
        "isLive": true,
        "liveStat": 5, // Showing some are currently open
        "progress": isOdia ? "ଦେଖନ୍ତୁ" : "Explore",
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: AppSpacing.xs,
        mainAxisSpacing: AppSpacing.xs,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _CleanWidgetCard(
          data: actions[index],
          onTap: () => _handleNavigation(context, actions[index]['id']),
        );
      },
    );
  }

  // Navigation Logic
  void _handleNavigation(BuildContext context, String id) {
    switch (id) {
      case "doctor":
        // Switch to Tab Index 1 (Doctors)
        onTabChange(1);
        break;

      case "lab":
        // Switch to Tab Index 3 (Labs)
        onTabChange(3);
        break;

      case "clinic": // NEW: Handle Clinic Navigation
        onTabChange(2);
        break;

      case "medicine":
        // onTabChange(4); // If you have a dedicated Medicine tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MedicineShopScreen()),
        );
        break;

      default:
        debugPrint("Unknown ID: $id");
    }
  }
}

class _CleanWidgetCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _CleanWidgetCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color themeColor = data['color'];
    final bool isLive = data['isLive'] == true;
    final bool isPromo = [
      "FREE",
      "WIN",
      "100%",
      "ମାଗଣା",
      "ଜିତନ୍ତୁ",
    ].contains(data['mainStat']);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.roundedLg,
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.info50,
            borderRadius: context.roundedSm,
            border: Border.all(
              color: AppPalette.info200.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.all(context.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Icon(data['icon'], size: 28, color: themeColor),
                    // if (isLive)
                    //   _FlatLiveBadge(
                    //     count: data['liveStat'],
                    //     color: context.colorScheme.error,
                    //   ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'],
                      style: context.titleLg?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    context.gapSm,
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          data['mainStat'],
                          style: context.bodyMd?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isPromo ? themeColor : context.onSurface,
                            letterSpacing: -0.5,
                            height: 1,
                          ),
                        ),
                        context.gapXs,
                        Expanded(
                          child: Text(
                            data['totalLabel'],
                            style: context.labelMd?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      data['progress'],
                      style: context.labelLg?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                    ),
                    context.gapXs,
                    Icon(
                      LucideIcons.arrowRight,
                      size: 14,
                      color: themeColor.withOpacity(0.7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatLiveBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _FlatLiveBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.spaceXs,
        vertical: context.spaceXs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          context.gapXs,
          Text(
            "$count",
            style: context.labelSm?.copyWith(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
