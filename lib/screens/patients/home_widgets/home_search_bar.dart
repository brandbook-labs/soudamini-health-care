import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/search_listing_screen.dart'; // Ensure this file exists

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Language Listener
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SearchListingScreen()),
        );
      },
      child: Container(
        height: 50,
        // Use your context extension for spacing if you like: context.spaceMd
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppPalette.info50,

          // FIX IS HERE: Assign directly, don't use .circular()
          borderRadius: context.roundedSm,

          border: Border.all(
            color: AppPalette.info200.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.search,
              color: context.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOdia
                    ? "ଡାକ୍ତର, ଔଷଧ ଖୋଜନ୍ତୁ..."
                    : "Search doctors, medicines...",
                style: context.text.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
