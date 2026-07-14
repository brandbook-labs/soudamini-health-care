import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatHeader extends StatelessWidget {
  final VoidCallback onClose;

  const ChatHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Avatar with Online Indicator
          Stack(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=47'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981), // Calming Emerald Green
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF18181B) : Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jivan Care Guide", // Softer name
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "Here to help you feel better.", // Empathetic subtitle
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                size: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
