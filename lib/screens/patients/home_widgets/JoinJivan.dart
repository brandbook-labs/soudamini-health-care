import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/theme/tokens/app_text_tokens.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import '../../../../screens/subscription_plans_screen.dart';

class JivanSubscriptionCard extends StatelessWidget {
  const JivanSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // ── THEME-AWARE COLOR ROLES ──────────────────────────────────────────────
    // Card sits on the surface (white in light / neutral900 in dark).
    // Primary is used only as an accent — border, badge bg, button, icon.
    final cardColor = colorScheme.surfaceContainerHigh;
    final contentColor = colorScheme.onSurface;
    final accentColor = colorScheme.primary;
    const goldColor = Color(
      0xFFFFD700,
    ); // Brand-specific — intentionally hardcoded

    return Container(
      decoration: BoxDecoration(borderRadius: AppRadius.small),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.small,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionPlansScreen(),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              // color: AppPalette.info50,
              // borderRadius: AppRadius.small,
              // border: Border.all(
              //   color: AppPalette.info200.withValues(alpha: 0.10),
              //   width: 1,
              // ),
            ),
            child: Stack(
              children: [
                // ── MAIN CONTENT ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsetsGeometry.fromLTRB(0, 10, 0, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // LEFT: TEXT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // PREMIUM BADGE
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xxs,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.warning100,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                                border: Border.all(
                                  color: AppPalette.warning500,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.crown, size: 12),
                                  const SizedBox(width: AppSpacing.xxs),

                                  Text(
                                    "PREMIUM PARTNER",
                                    style: context.labelSm?.copyWith(
                                      color: AppPalette.warning500,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            context.gapSm,

                            // HEADLINE
                            Text(
                              "Register your Clinic",
                              style: context.titleLg?.copyWith(
                                color: contentColor,
                                fontSize: 24,
                                fontWeight: AppTextTokens.bold,
                                height: 1.3,
                              ),
                            ),

                            context.gapXs,

                            // SUBTITLE
                            Text(
                              "Grow your practice with zero commission fees.",
                              style: context.bodySm?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),

                            context.gapSm,

                            // CTA BUTTON — primary bg, onPrimary text
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                boxShadow: context.shadowSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Register as Partner",
                                    style: context.labelLg?.copyWith(
                                      fontSize: 14,
                                      color: colorScheme.onPrimary,
                                      fontWeight: AppTextTokens.bold,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Icon(
                                    LucideIcons.arrowRight,
                                    size: 14,
                                    color: colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // RIGHT: GRAPHIC
                      context.gapMd,
                      _PremiumIconGraphic(
                        accentColor: accentColor,
                        goldColor: goldColor,
                        surfaceColor: colorScheme.surfaceContainerHighest,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── SUB-WIDGETS ──────────────────────────────────────────────────────────────

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _PremiumIconGraphic extends StatelessWidget {
  final Color accentColor;
  final Color goldColor;
  final Color surfaceColor;

  const _PremiumIconGraphic({
    required this.accentColor,
    required this.goldColor,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 90,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer Ring
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
                width: 2,
              ),
            ),
          ),
          // Inner Glassy Circle
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: surfaceColor,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(LucideIcons.gem, size: 28, color: accentColor),
            ),
          ),
          // Floating sparkle
          Positioned(
            top: 15,
            right: 15,
            child: Icon(LucideIcons.sparkles, size: 16, color: goldColor),
          ),
        ],
      ),
    );
  }
}
