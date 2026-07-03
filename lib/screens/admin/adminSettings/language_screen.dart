import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/controllers/language_controller.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageController = Provider.of<LanguageController>(context);
    final currentCode = languageController.currentLocale.languageCode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Select Language"),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          _buildLanguageOption(
            context,
            label: "English",
            code: "en",
            isSelected: currentCode == "en",
            onTap: () => languageController.changeLanguage(const Locale('en')),
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context,
            label: "ଓଡ଼ିଆ (Odia)",
            code: "or",
            isSelected: currentCode == "or",
            onTap: () => languageController.changeLanguage(const Locale('or')),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String label,
    required String code,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
