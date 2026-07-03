import 'package:flutter/material.dart';
import '../../theme/tokens/app_radius.dart';

class JivanIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isLightMode; // To determine background opacity style

  const JivanIconBox({
    super.key,
    required this.icon,
    required this.color,
    this.isLightMode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isLightMode
            ? color.withValues(alpha: 0.1)
            : Colors.white.withValues(
                alpha: 0.2,
              ), // Glassmorphism for dark/colored bg
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: isLightMode
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: isLightMode ? color : Colors.white, size: 20),
    );
  }
}
