import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Uses your ThemeContext extension

class SuperAdminHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onNotificationTap;
  final Widget? trailingAction; // Optional custom action (e.g. "Save")

  const SuperAdminHeader({
    super.key,
    required this.title,
    this.onNotificationTap,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Determine Navigation State
    final canPop = Navigator.canPop(context);

    // 2. Theme Extraction (Using your extensions)
    final isDark = context.isDarkMode;

    // Dynamic Glass Colors based on your AppPalette/Theme logic
    final glassColor = isDark
        ? context.colorScheme.surface.withValues(alpha: 0.7)
        : context.colorScheme.surface.withValues(alpha: 0.85);

    final borderColor = context.colorScheme.outline.withValues(alpha: 0.1);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.only(
            top: context.mediaQuery.padding.top + 12, // Safe Area
            bottom: 12,
            left: context.spaceMd,
            right: context.spaceMd,
          ),
          decoration: BoxDecoration(
            color: glassColor,
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --- LEFT: Dynamic Leading (Back vs Dashboard Icon) ---
              Row(
                children: [
                  InkWell(
                    onTap: canPop ? () => Navigator.pop(context) : null,
                    borderRadius: context.roundedMd,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: canPop
                            ? context.colorScheme.surface
                            : context.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                        borderRadius: context.roundedMd,
                        border: canPop ? Border.all(color: borderColor) : null,
                      ),
                      child: Icon(
                        canPop
                            ? LucideIcons.arrowLeft
                            : LucideIcons.shieldCheck,
                        size: 20,
                        color: canPop
                            ? context.colorScheme.onSurface
                            : context.colorScheme.primary,
                      ),
                    ),
                  ),

                  SizedBox(width: context.spaceSm),

                  // --- TITLE with Hero-like Fade ---
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.05, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                    child: Text(
                      title,
                      key: ValueKey<String>(title),
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              // --- RIGHT: Global Actions ---
              Row(
                children: [
                  if (trailingAction != null) ...[
                    trailingAction!,
                    SizedBox(width: context.spaceXs),
                  ] else ...[
                    _HeaderAction(
                      icon: LucideIcons.search,
                      onTap: () {
                        // Global Search Trigger
                      },
                    ),
                    SizedBox(width: context.spaceXs),
                    _HeaderAction(
                      icon: LucideIcons.bell,
                      onTap: onNotificationTap ?? () {},
                      showBadge: true,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool showBadge;

  const _HeaderAction({
    required this.icon,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.transparent, // Transparent for cleaner look on glass
          shape: BoxShape.circle,
          border: Border.all(
            color: context.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: context.colorScheme.onSurface),
            if (showBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
