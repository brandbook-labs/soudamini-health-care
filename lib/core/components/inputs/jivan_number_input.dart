import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/theme_utils.dart';

class JivanNumberInput extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final String? unit; // e.g. "kg", "yrs"
  final bool showButtons;

  const JivanNumberInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.unit,
    this.showButtons = true,
  });

  @override
  State<JivanNumberInput> createState() => _JivanNumberInputState();
}

class _JivanNumberInputState extends State<JivanNumberInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());

    // Sync external value changes if the parent updates state
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // On blur, validate constraints
        _validateAndNotify(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(JivanNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      // Only update text if we aren't currently typing (avoids cursor jumps)
      if (!_focusNode.hasFocus) {
        _controller.text = widget.value.toString();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _increment() {
    if (widget.value + widget.step <= widget.max) {
      HapticFeedback.selectionClick();
      widget.onChanged(widget.value + widget.step);
      _controller.text = (widget.value + widget.step).toString();
    }
  }

  void _decrement() {
    if (widget.value - widget.step >= widget.min) {
      HapticFeedback.selectionClick();
      widget.onChanged(widget.value - widget.step);
      _controller.text = (widget.value - widget.step).toString();
    }
  }

  void _validateAndNotify(String val) {
    int? parsed = int.tryParse(val);
    if (parsed == null) {
      // Revert to last valid value
      _controller.text = widget.value.toString();
      return;
    }

    // Clamp value
    if (parsed < widget.min) parsed = widget.min;
    if (parsed > widget.max) parsed = widget.max;

    if (parsed != widget.value) {
      widget.onChanged(parsed);
    }
    _controller.text = parsed.toString();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.isDarkMode
        ? Colors.white10
        : Colors.grey.shade300;
    final fillColor = context.isDarkMode
        ? context.colorScheme.surface
        : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: context.text.labelLarge),
          AppSpacing.gapSm,
        ],
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              // --- MINUS BUTTON ---
              if (widget.showButtons)
                _buildControlButton(
                  icon: LucideIcons.minus,
                  onTap: _decrement,
                  isEnabled: widget.value > widget.min,
                  context: context,
                ),

              // --- INPUT AREA ---
              Expanded(
                child: Container(
                  decoration: widget.showButtons
                      ? BoxDecoration(
                          border: Border.symmetric(
                            vertical: BorderSide(color: borderColor),
                          ),
                        )
                      : null,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      suffixText: widget.unit,
                      suffixStyle: context.text.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onSubmitted: _validateAndNotify,
                  ),
                ),
              ),

              // --- PLUS BUTTON ---
              if (widget.showButtons)
                _buildControlButton(
                  icon: LucideIcons.plus,
                  onTap: _increment,
                  isEnabled: widget.value < widget.max,
                  context: context,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
    required BuildContext context,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          width: 56,
          height: double.infinity,
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? context.colorScheme.primary
                : context.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
        ),
      ),
    );
  }
}
