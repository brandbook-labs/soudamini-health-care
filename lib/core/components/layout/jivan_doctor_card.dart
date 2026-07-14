import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/models/doctor_model.dart';

class JivanDoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onTap;
  final VoidCallback onBook;

  const JivanDoctorCard({
    super.key,
    required this.doctor,
    required this.onTap,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Availability Logic
    final bool isAvailable =
        doctor.nextAvailable.contains("Today") ||
        doctor.nextAvailable.contains("Closing") ||
        doctor.nextAvailable.contains("Available");

    // 2. Parse Degree
    final String degree = _parseDegree(doctor.rawEducation);

    // 3. Parse Specialties into a List
    final List<String> specialties = doctor.specialty.contains(',')
        ? doctor.specialty.split(',').map((e) => e.trim()).toList()
        : [doctor.specialty];

    return JivanCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // -----------------------------------------------------------------
          // 1. TOP SECTION: Avatar + Info
          // -----------------------------------------------------------------
          Padding(
            padding: EdgeInsets.all(context.spaceMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR
                _buildAvatar(context),

                context.gapMd,

                // INFO COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Rating Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: context.titleMd?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingBadge(context),
                        ],
                      ),

                      context.gapXs,

                      // --- UPDATED: SPECIALTY TAGS ---
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...specialties.map(
                            (spec) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.colorScheme.primary.withOpacity(
                                  0.08,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.colorScheme.primary
                                      .withOpacity(0.15),
                                ),
                              ),
                              child: Text(
                                spec.toUpperCase(), // ALL CAPS
                                style: context.labelSm?.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),

                          // Degree (Inline or next to tags)
                          if (degree.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 2),
                              child: Text(
                                "•  $degree",
                                style: context.labelSm?.copyWith(
                                  color: context.onSurface.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),

                      context.gapSm,

                      // Location
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 13,
                            color: context.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${doctor.clinicName}, ${doctor.city}",
                              style: context.bodySm?.copyWith(
                                color: context.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      context.gapMd,

                      // Availability Badge
                      _buildAvailabilityBadge(context, isAvailable),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // 2. FOOTER SECTION: Price + Button
          // -----------------------------------------------------------------
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.spaceMd,
              vertical: context.spaceSm,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainer.withOpacity(0.3),
              border: Border(
                top: BorderSide(
                  color: context.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // PRICE BLOCK
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (doctor.price > 0) ...[
                      if (doctor.originalPrice > doctor.price!)
                        Text(
                          "₹${doctor.originalPrice}",
                          style: context.labelSm?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: context.onSurface.withOpacity(0.4),
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "₹${doctor.price}",
                            style: context.titleMd?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: context.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "/ visit",
                            style: context.labelSm?.copyWith(
                              color: context.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        "Consultation Fee",
                        style: context.labelSm?.copyWith(
                          color: context.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        "Contact Clinic",
                        style: context.labelMd?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),

                // BOOK BUTTON
                FilledButton(
                  onPressed: onBook,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    "Book Now",
                    style: context.labelMd?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

  String _parseDegree(List<String>? education) {
    if (education == null || education.isEmpty) return "";
    final first = education.first;
    if (first.contains("-")) {
      return first.split("-")[0].trim();
    }
    return first;
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            image:
                (doctor.image.isNotEmpty &&
                    !doctor.image.contains("ui-avatars"))
                ? DecorationImage(
                    image: CachedNetworkImageProvider(doctor.image),
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  )
                : null,
          ),
          child: (doctor.image.isEmpty || doctor.image.contains("ui-avatars"))
              ? Icon(
                  LucideIcons.user,
                  size: 36,
                  color: context.onSurface.withOpacity(0.3),
                )
              : null,
        ),
        if (doctor.isVerified)
          Positioned(
            bottom: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                shape: BoxShape.circle,
                
              ),
              child: const Icon(
                LucideIcons.badgeCheck,
                size: 18,
                color: Colors.blue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            "${doctor.rating}",
            style: context.labelSm?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(BuildContext context, bool isAvailable) {
    final bool isUrgent = doctor.nextAvailable.contains("Closing");
    final bool isFuture = doctor.nextAvailable.contains("Next");

    Color bg;
    Color text;

    if (isAvailable) {
      if (isUrgent) {
        bg = Colors.orange.withOpacity(0.1);
        text = Colors.orange[800]!;
      } else {
        bg = Colors.green.withOpacity(0.1);
        text = Colors.green[700]!;
      }
    } else if (isFuture) {
      bg = context.colorScheme.surfaceContainerHighest.withOpacity(0.5);
      text = context.onSurface.withOpacity(0.6);
    } else {
      bg = context.colorScheme.error.withOpacity(0.08);
      text = context.colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAvailable || isUrgent)
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: text,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: text.withOpacity(0.4), blurRadius: 4),
                ],
              ),
            ),
          Text(
            doctor.nextAvailable,
            style: context.labelSm?.copyWith(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
