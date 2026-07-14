import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import '../../../../models/doctor_model.dart';

const Color _kGold = Color(0xFFFFC107);

class DoctorInfoHeader extends StatelessWidget {
  final Doctor doctor;
  final String currentClinicName;
  final bool isOdia;

  const DoctorInfoHeader({
    super.key,
    required this.doctor,
    required this.currentClinicName,
    required this.isOdia,
  });

  double get _rating => double.tryParse(doctor.rating.toString()) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    // Gentle fade-in-up so the profile feels alive when it loads.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 14),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME + VERIFIED
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  doctor.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: scheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (doctor.isVerified) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.verified, color: scheme.primary, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          // CLINIC
          Row(
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 15,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  currentClinicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // RATING — grouped amber chip + review count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ..._buildStars(),
                    const SizedBox(width: 6),
                    Text(
                      _rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: AppPalette.warning700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${doctor.reviews} reviews",
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // SPECIALTY (prominent) + EXPERIENCE + TOP RATED — one line
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                // Specialty pills — the star of this row (solid, bold)
                for (final dept in doctor.specialty.split(RegExp(r'[,&]')))
                  if (dept.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _specialtyPill(context, dept.trim()),
                    ),

                // Experience (secondary chip)
                if (doctor.experience.toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _trustChip(
                      LucideIcons.award,
                      "${doctor.experience}",
                      AppPalette.teal500,
                    ),
                  ),

                // Top rated (secondary chip)
                if (_rating >= 4.5)
                  _trustChip(Icons.trending_up_rounded, "Top Rated", _kGold),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // STATS STRIP — elevated card with colourful stat badges
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _stat(
                  context,
                  "1.2k+",
                  "Patients",
                  LucideIcons.users,
                  scheme.primary,
                ),
                _divider(scheme),
                _stat(
                  context,
                  "${doctor.experience}",
                  "Experience",
                  LucideIcons.award,
                  AppPalette.teal500,
                ),
                _divider(scheme),
                _stat(
                  context,
                  "${doctor.reviews}+",
                  "Reviews",
                  LucideIcons.messageSquare,
                  _kGold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    return List.generate(5, (i) {
      final diff = _rating - i;
      final icon = diff >= 1
          ? Icons.star_rounded
          : diff >= 0.5
          ? Icons.star_half_rounded
          : Icons.star_outline_rounded;
      return Icon(icon, size: 16, color: _kGold);
    });
  }

  // Shared chip height so specialty / experience / top-rated line up.
  static const double _chipHeight = 32;

  // Prominent, solid pill for the specialty — visually the most important.
  Widget _specialtyPill(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: _chipHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.stethoscope, size: 15, color: scheme.onPrimary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustChip(IconData icon, String label, Color color) {
    return Container(
      height: _chipHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme scheme) => Container(
    width: 1,
    height: 42,
    color: scheme.outlineVariant.withValues(alpha: 0.5),
  );

  Widget _stat(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
