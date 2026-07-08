import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/doctor_model.dart';

class DoctorAboutSection extends StatefulWidget {
  final Doctor doctor;
  final bool isOdia;

  const DoctorAboutSection({
    super.key,
    required this.doctor,
    required this.isOdia,
  });

  @override
  State<DoctorAboutSection> createState() => _DoctorAboutSectionState();
}

class _DoctorAboutSectionState extends State<DoctorAboutSection> {
  bool _expanded = false;

  bool get _isOdia => widget.isOdia;
  Doctor get doctor => widget.doctor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final about = doctor.about;
    final isLong = about.length > 180;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(context, _isOdia ? "ଡାକ୍ତରଙ୍କ ବିଷୟରେ" : "About Doctor"),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Text(
            about,
            maxLines: (isLong && !_expanded) ? 4 : null,
            overflow: (isLong && !_expanded)
                ? TextOverflow.ellipsis
                : TextOverflow.visible,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    _expanded
                        ? (_isOdia ? "କମ୍ ଦେଖନ୍ତୁ" : "Read less")
                        : (_isOdia ? "ଅଧିକ ପଢ଼ନ୍ତୁ" : "Read more"),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: scheme.primary,
                  ),
                ],
              ),
            ),
          ),

        // EDUCATION TIMELINE
        if (doctor.rawEducation.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionTitle(context, _isOdia ? "ଶିକ୍ଷା" : "Education"),
          const SizedBox(height: 14),
          Column(
            children: List.generate(doctor.rawEducation.length, (i) {
              final isLast = i == doctor.rawEducation.length - 1;
              return _timelineRow(context, doctor.rawEducation[i], isLast);
            }),
          ),
        ],

        // LANGUAGES
        if (doctor.languages.isNotEmpty) ...[
          const SizedBox(height: 28),
          _sectionTitle(context, _isOdia ? "ଭାଷା" : "Languages"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doctor.languages
                .map((lang) => _langChip(context, lang))
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _timelineRow(BuildContext context, String text, bool isLast) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.graduationCap,
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 7, bottom: isLast ? 0 : 18),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langChip(BuildContext context, String lang) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.languages, size: 14, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            lang,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
