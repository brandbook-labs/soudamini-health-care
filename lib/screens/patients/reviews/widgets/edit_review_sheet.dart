// lib/screens/patient_reviews/widgets/edit_review_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Haptic Feedback
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/review_model.dart';

class EditReviewSheet extends StatefulWidget {
  final ReviewModel review;
  final Function(String comment, double rating) onSave;

  const EditReviewSheet({
    super.key,
    required this.review,
    required this.onSave,
  });

  @override
  State<EditReviewSheet> createState() => _EditReviewSheetState();
}

class _EditReviewSheetState extends State<EditReviewSheet> {
  late TextEditingController _textController;
  late double _currentRating;

  // Quick-tap tags
  Set<String> _selectedTags = {};

  final List<String> _positiveTags = [
    "Friendly Staff",
    "Short Wait Time",
    "Listened Carefully",
    "Clean Facility",
    "Clear Explanations",
    "Effective Treatment",
  ];

  final List<String> _constructiveTags = [
    "Long Wait Time",
    "Rushed Visit",
    "Unfriendly Staff",
    "Unclean Facility",
    "Unclear Instructions",
    "High Cost",
  ];

  @override
  void initState() {
    super.initState();
    _currentRating = widget.review.rating;

    // 🚀 INTELLIGENT PARSING: Extract previously saved tags from the comment string
    String rawComment = widget.review.comment.trim();
    final RegExp tagRegex = RegExp(r'^\[(.*?)\]\s*(.*)$', dotAll: true);
    final match = tagRegex.firstMatch(rawComment);

    if (match != null) {
      // We found previously bundled tags!
      final tagsString = match.group(1) ?? '';
      final actualComment = match.group(2) ?? '';

      _selectedTags = tagsString.split(',').map((e) => e.trim()).toSet();
      _textController = TextEditingController(text: actualComment);
    } else {
      // No tags found, just load the comment
      _textController = TextEditingController(text: rawComment);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // --- SENTIMENT LOGIC ---
  Color get _sentimentColor {
    if (_currentRating >= 4.0)
      return const Color(0xFF4F46E5); // Indigo (Positive)
    if (_currentRating == 3.0)
      return const Color(0xFFF59E0B); // Amber (Neutral)
    return const Color(0xFFEF4444); // Red (Constructive/Negative)
  }

  String _getRatingLabel() {
    if (_currentRating == 5.0) return "Excellent";
    if (_currentRating == 4.0) return "Very Good";
    if (_currentRating == 3.0) return "Average";
    if (_currentRating == 2.0) return "Poor";
    if (_currentRating == 1.0) return "Terrible";
    return "Tap to rate";
  }

  void _updateRating(double newRating) {
    HapticFeedback.lightImpact(); // 🚀 Satisfying physical tap response

    bool wasPositive = _currentRating >= 4.0;
    bool isPositive = newRating >= 4.0;

    setState(() {
      _currentRating = newRating;
      // Reset tags only if crossing the positive/constructive boundary
      if (wasPositive != isPositive) {
        _selectedTags.clear();
      }
    });
  }

  void _handleSave() {
    String finalComment = _textController.text.trim();

    // Bundle tags back into the string for the backend
    if (_selectedTags.isNotEmpty) {
      String tagsString = "[${_selectedTags.join(", ")}]";
      if (finalComment.isNotEmpty) {
        finalComment = "$tagsString\n\n$finalComment";
      } else {
        finalComment = tagsString;
      }
    }

    widget.onSave(finalComment, _currentRating);
  }

  @override
  Widget build(BuildContext context) {
    const borderCol = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    // 🚀 ଏହି ସବୁକୁ ବ୍ୟବହାର କରାଯାଉନାହିଁ, କିନ୍ତୁ ଆପଣଙ୍କ ଲଜିକ୍ ନଷ୍ଟ ନହେବା ପାଇଁ ରଖାଯାଇଛି
    final currentTagsList = _currentRating >= 4.0
        ? _positiveTags
        : _constructiveTags;
    final promptText = _currentRating >= 4.0
        ? "What went well?"
        : "What could be improved?";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- SAA-STYLE DRAG HANDLE ---
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- HEADER WITH CONTEXT ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Share Feedback",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "For ${widget.review.targetName}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 20,
                  color: Colors.black54,
                ),
                onPressed: () => Navigator.pop(context),
                style: IconButton.styleFrom(
                  backgroundColor: bgLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 🚀 FLEXIBLE SCROLL AREA
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- DYNAMIC RATING SECTION ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: _sentimentColor.withValues(
                        alpha: 0.05,
                      ), 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _sentimentColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _getRatingLabel().toUpperCase(),
                          style: TextStyle(
                            color: _sentimentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            final isSelected = index < _currentRating;
                            return GestureDetector(
                              onTap: () => _updateRating(index + 1.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  color: isSelected
                                      ? Colors.amber.shade500
                                      : Colors.grey.shade300,
                                  size: isSelected ? 42 : 36,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🚀 ସମ୍ପୂର୍ଣ୍ଣ DYNAMIC TAGS (promptText ଓ Tags) କୁ କମେଣ୍ଟ୍ କରାଯାଇଛି
                  /*
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey<double>(_currentRating),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promptText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: currentTagsList.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (isSelected) {
                                    _selectedTags.remove(tag);
                                  } else {
                                    _selectedTags.add(tag);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _sentimentColor.withValues(alpha: 0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isSelected
                                        ? _sentimentColor
                                        : borderCol,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      Icon(
                                        LucideIcons.check,
                                        size: 14,
                                        color: _sentimentColor,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      tag,
                                      style: TextStyle(
                                        color: isSelected
                                            ? _sentimentColor
                                            : Colors.black87,
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  */

                  // --- TEXT AREA ---
                  const Text(
                    "Additional Comments (Optional)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _textController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "Provide any extra details about your visit...",
                      hintStyle: const TextStyle(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: borderCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: borderCol),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: _sentimentColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // --- CALL TO ACTION ---
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handleSave,
              icon: const Icon(LucideIcons.checkCircle2, size: 18),
              label: const Text(
                "Save Feedback",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(
                  0xFF4F46E5,
                ), // Always keep primary button color
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF4F46E5).withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}