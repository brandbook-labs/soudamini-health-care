import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

// 1. Define the Enum
enum ToastType { info, success, error, warning }

class JivanToast {
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    ToastType type = ToastType.info, // 2. Add Type Parameter
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // 3. Determine Colors & Icons based on Type
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (type) {
      case ToastType.success:
        iconColor = const Color(0xFF10B981); // Success Green
        iconBg = const Color(0xFF10B981).withValues(alpha: 0.1);
        icon = LucideIcons.checkCircle;
        break;
      case ToastType.error:
        iconColor = const Color(0xFFEF4444); // Error Red
        iconBg = const Color(0xFFEF4444).withValues(alpha: 0.1);
        icon = LucideIcons.xCircle;
        break;
      case ToastType.warning:
        iconColor = const Color(0xFFF59E0B); // Warning Amber
        iconBg = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        icon = LucideIcons.alertTriangle;
        break;
      case ToastType.info:
      default:
        iconColor = context.colorScheme.primary;
        iconBg = context.colorScheme.primaryContainer;
        icon = LucideIcons.info;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: context.padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: context.colorScheme.outlineVariant.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.text.labelMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: context.text.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }
}
