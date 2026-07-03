import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptics
import '../../theme/tokens/app_spacing.dart';
import '../../theme/tokens/app_radius.dart';
import '../../utils/theme_utils.dart'; // Import your utils

enum ButtonType { primary, secondary, outline, ghost, destructive, gradient }

enum ButtonSize { small, medium, large }

class JivanButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final ButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final bool iconOnRight; // NEW: Put icon at end?

  const JivanButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconOnRight = false,
  });

  @override
  State<JivanButton> createState() => _JivanButtonState();
}

class _JivanButtonState extends State<JivanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Setup Bouncy Animation
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05, // Shrinks by 5%
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      HapticFeedback.lightImpact(); // TACTILE FEEDBACK
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      _scaleController.reverse();
      widget.onPressed?.call();
    }
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // 1. DETERMINE DIMENSIONS BASED ON SIZE ENUM
    final double height = _getHeight();
    final EdgeInsets padding = _getPadding();
    final double fontSize = _getFontSize();
    final double iconSize = _getIconSize();

    // 2. DETERMINE COLORS
    final colors = _getColors(context);
    final Color backgroundColor = colors.$1;
    final Color foregroundColor = colors.$2;
    final Color borderColor = colors.$3;

    // 3. GRADIENT LOGIC
    final LinearGradient? gradient = widget.type == ButtonType.gradient
        ? context
              .semantic
              .primaryGradient // Uses your Semantic Extension
        : null;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.onPressed == null ? 0.5 : 1.0, // Dim if disabled
          child: Container(
            width: widget.isFullWidth ? double.infinity : null,
            height: height,
            decoration: BoxDecoration(
              color: gradient == null ? backgroundColor : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: widget.type == ButtonType.outline
                  ? Border.all(color: borderColor, width: 1.5)
                  : null,
              boxShadow: _getShadow(context), // Dynamic Shadow
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: null, // We handle tap in GestureDetector for animation
                child: Padding(
                  padding: padding,
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            height: iconSize,
                            width: iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: foregroundColor,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // ICON LEFT
                              if (widget.icon != null &&
                                  !widget.iconOnRight) ...[
                                Icon(
                                  widget.icon,
                                  size: iconSize,
                                  color: foregroundColor,
                                ),
                                SizedBox(width: AppSpacing.sm),
                              ],

                              // TEXT
                              Text(
                                widget.text,
                                style: TextStyle(
                                  color: foregroundColor,
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),

                              // ICON RIGHT
                              if (widget.icon != null &&
                                  widget.iconOnRight) ...[
                                SizedBox(width: AppSpacing.sm),
                                Icon(
                                  widget.icon,
                                  size: iconSize,
                                  color: foregroundColor,
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER METHODS FOR DYNAMIC STYLING ---

  double _getHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 50;
      case ButtonSize.large:
        return 58;
    }
  }

  // 2. PADDING (Refactored)
  // We use context.space... which you defined in your extension
  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        // 16.0 -> spaceMd
        return EdgeInsets.symmetric(horizontal: context.spaceMd);
      case ButtonSize.medium:
        // 24.0 -> spaceLg
        return EdgeInsets.symmetric(horizontal: context.spaceLg);
      case ButtonSize.large:
        // 32.0 -> spaceXl
        return EdgeInsets.symmetric(horizontal: context.spaceXl);
    }
  }

  // 3. FONT SIZE (Refactored)
  // Best Practice: Derive from context.text to respect system scaling
  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return context.text.labelMedium?.fontSize ?? 13;
      case ButtonSize.medium:
        return context.text.labelLarge?.fontSize ?? 16;
      case ButtonSize.large:
        return context.text.titleMedium?.fontSize ?? 18;
    }
  }

  // 4. ICON SIZE (Refactored where possible)
  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return context.spaceMd; // 16.0
      case ButtonSize.medium:
        return 20; // No perfect spacer match (between 16 and 24)
      case ButtonSize.large:
        return context.spaceLg; // 24.0
    }
  }

  // Returns (Background, Foreground, Border)
  (Color, Color, Color) _getColors(BuildContext context) {
    switch (widget.type) {
      case ButtonType.primary:
        return (
          context.colorScheme.primary,
          context.colorScheme.onPrimary,
          Colors.transparent,
        );
      case ButtonType.secondary:
        return (
          context.colorScheme.secondary,
          context.colorScheme.onSecondary,
          Colors.transparent,
        );
      case ButtonType.gradient:
        // Background handled by gradient property, returning transparent here
        return (Colors.transparent, Colors.white, Colors.transparent);
      case ButtonType.outline:
        return (
          Colors.transparent,
          context.colorScheme.primary,
          context.colorScheme.primary,
        );
      case ButtonType.ghost:
        return (
          Colors.transparent,
          context.colorScheme.onSurface,
          Colors.transparent,
        );
      case ButtonType.destructive:
        return (
          context.colorScheme.error,
          context.colorScheme.onError,
          Colors.transparent,
        );
    }
  }

  List<BoxShadow>? _getShadow(BuildContext context) {
    if (widget.type == ButtonType.ghost || widget.type == ButtonType.outline) {
      return null;
    }

    // Softer shadow for primary buttons in light mode
    if (!context.isDarkMode) {
      return [
        BoxShadow(
          color:
              (widget.type == ButtonType.destructive
                      ? context.colorScheme.error
                      : context.colorScheme.primary)
                  .withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return null; // No shadows in dark mode typically
  }
}
