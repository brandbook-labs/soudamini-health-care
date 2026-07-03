import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DotAnimator(delay: 0, isDark: isDark),
                const SizedBox(width: 4),
                _DotAnimator(delay: 200, isDark: isDark),
                const SizedBox(width: 4),
                _DotAnimator(delay: 400, isDark: isDark),
                const SizedBox(width: 12),
                Text(
                  "Finding the right care...", // Empathetic waiting text
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ... Keep your _DotAnimator class exactly the same below this ...

class _DotAnimator extends StatefulWidget {
  final int delay;
  final bool isDark;

  const _DotAnimator({required this.delay, required this.isDark});

  @override
  State<_DotAnimator> createState() => _DotAnimatorState();
}

class _DotAnimatorState extends State<_DotAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade500,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
