import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/search_listing_screen.dart';

class HomeSearchBar extends StatefulWidget {
  const HomeSearchBar({super.key});

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar> {
  bool _isPressed = false;

  void _onTapSearch(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchListingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';
    final isDark = context.isDarkMode;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => _onTapSearch(context),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOutCubic,
        child: Container(
          height: 56, // Increased height for better target accessibility
          padding: const EdgeInsets.only(left: 18.0, right: 6.0),
          decoration: BoxDecoration(
            color: isDark ? context.colorScheme.surface : Colors.white,
            borderRadius: BorderRadius.circular(
              100,
            ), // Perfect sleek capsule look
            border: Border.all(
              color: context.colorScheme.primary.withOpacity(
                isDark ? 0.15 : 0.08,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withOpacity(
                  isDark ? 0.05 : 0.04,
                ),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Lead Search Icon
              Icon(
                LucideIcons.search,
                color: context.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 14),

              // Dynamic Text Field Substitute
              Expanded(
                child: Text(
                  isOdia
                      ? "ଡାକ୍ତର, ଔଷଧ ଖୋଜନ୍ତୁ..."
                      : "Search doctors, medicines...",
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant.withOpacity(
                      0.7,
                    ),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Visual Smart Filter Accent (Implicit target indicator)
            ],
          ),
        ),
      ),
    );
  }
}
