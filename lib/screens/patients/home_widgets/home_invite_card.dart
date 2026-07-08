import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Assuming you have your standard theme utilities

class FooterInviteSection extends StatelessWidget {
  const FooterInviteSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Check language like your previous components
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    // ─── CONTENT TEXTS ──────────────────────────────────────────
    final String shareText = isOdia
        ? 'ଡାକ୍ତର ନିଯୁକ୍ତି ଏବଂ ଔଷଧ ପାଇଁ ଜୀବନ ଆପ୍ ବ୍ୟବହାର କରନ୍ତୁ! ମୋର ଲିଙ୍କ୍ ରୁ ଡାଉନଲୋଡ୍ କରନ୍ତୁ: https://play.google.com/store/apps/details?id=website.jivan.jivanapp.my_new_app&hl=en_IN'
        : 'Book top doctors easily with the Soudamini Healthcare App! Download using my link: https://play.google.com/store/apps/details?id=website.jivan.jivanapp.my_new_app&hl=en_IN';

    final String subText = isOdia
        ? 'ଆପଣଙ୍କ ସାଙ୍ଗ ଏବଂ ପରିବାରକୁ ଜୀବନ ଆପ୍ ସହିତ ଯୋଡନ୍ତୁ। ଦରକାର ସମୟରେ ସହଜରେ ଭଲ ଡାକ୍ତର ଦେଖାଇବାରେ ସେମାନଙ୍କୁ ସାହାଯ୍ୟ କରନ୍ତୁ।'
        : 'Share the gift of health! Onboard your friends and family to the Soudamini Healthcare App and help them easily access the best doctors whenever they need.';

    // ─── ACTIONS ────────────────────────────────────────────────
    void handleShare() {
      Share.share(
        shareText,
        subject: isOdia ? 'ଜୀବନ ଆପ୍' : 'Join Soudamini Healthcare App',
      );
    }

    void handleCopy() async {
      await Clipboard.setData(
        const ClipboardData(
          text:
              'https://play.google.com/store/apps/details?id=website.jivan.jivanapp.my_new_app&hl=en_IN',
        ),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOdia ? "ଲିଙ୍କ୍ କପି ହୋଇଛି!" : "Invite link copied!"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }

    return Container(
      width: double.infinity,

      // A soft, tinted background color matching the image vibe
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── HEADLINE ──────────────────────────────────────────────
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                height: 1.3,
              ),
              children: [
                TextSpan(
                  text: isOdia
                      ? "ନିଜ ପ୍ରିୟଜନଙ୍କୁ ଆମନ୍ତ୍ରଣ କରନ୍ତୁ ଓ "
                      : "Invite loved ones & ",
                ),
                TextSpan(
                  text: isOdia ? "ଉତ୍ତମ ସ୍ୱାସ୍ଥ୍ୟ" : "share good health",
                  style: TextStyle(
                    color: colorScheme.primary, // Highlights the main message
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: isOdia
                      ? " ର ବାର୍ତ୍ତା ବାଣ୍ଟନ୍ତୁ।"
                      : " with easy clinic visits.",
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── SUBTEXT ───────────────────────────────────────────────
          Text(
            subText,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 12),

          // ── BUTTONS ───────────────────────────────────────────────
          Wrap(
            spacing: 12,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Primary Invite Button
              FilledButton(
                onPressed: handleShare,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      colorScheme.primary, // or a specific deep purple
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Pill shape
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOdia ? "ସାଙ୍ଗମାନଙ୍କୁ ଆମନ୍ତ୍ରଣ" : "Invite friends",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.chevronRight, size: 20),
                  ],
                ),
              ),

              // Copy Text Button
              TextButton.icon(
                onPressed: handleCopy,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(LucideIcons.copy, size: 18),
                label: Text(
                  isOdia ? "ଲିଙ୍କ୍ କପି" : "Copy Invite",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── DIVIDER ───────────────────────────────────────────────
          Divider(
            color: colorScheme.onSurface.withValues(alpha: 0.15),
            thickness: 1.5,
          ),

          const SizedBox(height: 20),

          // ── WATERMARK FOOTER ──────────────────────────────────────
          // Kept this in English as it acts like a stylistic brand mark
          Text(
            "MADE WITH LOVE\nFROM JIVAN",
            style: TextStyle(
              fontSize: 52,
              height: 1.00,
              letterSpacing: -1.0,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface.withValues(
                alpha: 0.18,
              ), // Faded look
            ),
          ),
        ],
      ),
    );
  }
}
