import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final VoidCallback onSubmitted;
  final VoidCallback onVoiceTap;
  final VoidCallback onClose;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.onSubmitted,
    required this.onVoiceTap,
    required this.onClose,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {
        _hasText = widget.controller.text.trim().isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 24), // Tweak padding
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Close button on the left to hide keyboard
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                widget.focusNode.unfocus();
                widget.onClose();
              },
              icon: Icon(
                LucideIcons.chevronDown,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 28,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : Colors.white,
                borderRadius: BorderRadius.circular(24), // Softer radius
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        enabled: !widget.isTyping,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4, // Allow text field to grow slightly
                        onSubmitted: (_) {
                          HapticFeedback.lightImpact();
                          widget.onSubmitted();
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: "Tell me how you're feeling...",
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.isTyping
                            ? null
                            : (_hasText
                                  ? () {
                                      HapticFeedback.lightImpact();
                                      widget.onSubmitted();
                                    }
                                  : () {
                                      HapticFeedback.mediumImpact();
                                      widget.onVoiceTap();
                                    }),
                        borderRadius: BorderRadius.circular(100),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: widget.isTyping
                                ? Colors.transparent
                                : const Color(
                                    0xFF1660FF,
                                  ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _hasText ? LucideIcons.send : LucideIcons.mic,
                            size: 20,
                            color: widget.isTyping
                                ? (isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade400)
                                : const Color(0xFF1660FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
