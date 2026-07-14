import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/booking/appointment_booking_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/doctor_model.dart';
import '../../../../models/booking_models.dart';
import '../../doctor_profile/doctor_profile_screen.dart';

const Color _kGold = Color(0xFFFFC107);

class DoctorCardWidget extends StatelessWidget {
  final Doctor doctor;
  final bool isOdia;
  final bool isVertical;

  const DoctorCardWidget({
    super.key,
    required this.doctor,
    required this.isOdia,
    this.isVertical = true,
  });

  // ---------------------------------------------------------------------------
  // 🎨 PALETTE-DRIVEN COLOR TOKENS (track the brand seed / theme)
  // ---------------------------------------------------------------------------
  Color _brand(bool dark) =>
      dark ? AppPalette.jivanBlue300 : AppPalette.jivanBlue600;
  Color get _brandSolid => AppPalette.jivanBlue500;
  Color _surface(bool dark) =>
      dark ? AppPalette.neutral900 : AppPalette.neutralWhite;
  Color _titleColor(bool dark) =>
      dark ? AppPalette.neutralWhite : AppPalette.neutralBlack;
  Color _mutedText(bool dark) =>
      dark ? AppPalette.neutral400 : AppPalette.neutral600;
  Color _mutedIcon(bool dark) =>
      dark ? AppPalette.neutral400 : AppPalette.neutral500;
  Color _imageBg(bool dark) => dark ? AppPalette.neutral800 : AppPalette.info50;
  Color _chipBg(bool dark) =>
      dark ? AppPalette.neutral800 : AppPalette.neutral100;
  Color _hairline(bool dark) => dark
      ? AppPalette.neutral700.withValues(alpha: 0.4)
      : AppPalette.neutral200;

  bool get _hasSlots =>
      doctor.nextAvailable.isNotEmpty &&
      doctor.nextAvailable.toLowerCase() != "check slots" &&
      doctor.nextAvailable.toLowerCase() != "unavailable" &&
      doctor.nextAvailable.toLowerCase() != "null";

  String get _formattedDistance {
    if (doctor.distance.isEmpty) return "";
    double dist =
        double.tryParse(doctor.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;
    if (dist == 0) return doctor.distance;
    return dist >= 1000
        ? "${(dist / 1000).toStringAsFixed(1)} km"
        : "${dist.toInt()} m";
  }

  String get _experienceText {
    final raw = doctor.experience.trim();
    if (raw.isEmpty) return "";
    final years = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (years.isEmpty) return "";
    return isOdia ? "$years ବର୍ଷ" : "$years yrs exp";
  }

  String get _clinicPhone {
    if (doctor.phone.isNotEmpty &&
        doctor.phone != "null" &&
        doctor.phone.length > 5) {
      return doctor.phone;
    }
    return "";
  }

  void _handleMainAction(BuildContext context) async {
    if (_hasSlots) {
      final Map<String, dynamic> safeClinicLocation =
          doctor.locations.isNotEmpty
          ? doctor.locations[0]
          : {
              'clinic': {
                '_id': doctor.id,
                'name': doctor.clinicName,
                'address': doctor.location,
              },
              'consultation_fees': doctor.price,
            };

      final selection = BookingSelection(
        slotId: doctor.id,
        date: doctor.slotDate,
        slotTime: "${doctor.startTime} - ${doctor.endTime}",
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentBookingScreen(
            doctor: doctor,
            clinicLocation: safeClinicLocation,
            clinicServices: const [],
            selection: selection,
            initialAppointmentType: 'consultation',
          ),
        ),
      );
    } else if (_clinicPhone.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: _clinicPhone);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Unable to open dialer.")),
          );
        }
      }
    }
  }

  void _handleProfileTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(doctorId: doctor.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isVertical
        ? _buildVerticalCard(context)
        : _buildHorizontalCard(context);
  }

  // =========================================================================
  // 1. VERTICAL CARD — hero image + info (for horizontal carousels)
  // =========================================================================
  Widget _buildVerticalCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hasValidImage = doctor.image.isNotEmpty;
    final dist = _formattedDistance;

    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14, bottom: 10),
        decoration: BoxDecoration(
          color: _surface(dark),
          borderRadius: BorderRadius.circular(4),

          border: Border.all(color: _hairline(dark), width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO IMAGE with scrim ---
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: _imageBg(dark),
                    child: hasValidImage
                        ? CachedNetworkImage(
                            imageUrl: doctor.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            placeholder: (c, u) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (c, u, e) =>
                                _buildFallbackAvatar(dark),
                          )
                        : _buildFallbackAvatar(dark),
                  ),
                  // Bottom gradient scrim for depth
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(top: 12, right: 12, child: _buildRatingPill()),
                  if (_hasSlots)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _statusDot("Available", AppPalette.success500),
                    ),
                ],
              ),
            ),

            // --- DETAILS ---
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          doctor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _titleColor(dark),
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (doctor.isVerified)
                        Icon(Icons.verified, size: 16, color: _brandSolid),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Flexible(child: _specialtyPill(dark)),
                      if (_experienceText.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: _infoChip(
                            LucideIcons.briefcase,
                            _experienceText,
                            dark,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 13,
                        color: _mutedIcon(dark),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${doctor.clinicName}, ${doctor.city}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _mutedText(dark),
                          ),
                        ),
                      ),
                      if (dist.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _buildDistanceBadge(dist),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: _hairline(dark)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildPriceSection(dark),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(context, dark),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. HORIZONTAL CARD — profile-style row card (for vertical lists)
  // =========================================================================
  Widget _buildHorizontalCard(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dist = _formattedDistance;

    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: _surface(dark),
          borderRadius: BorderRadius.circular(8),

          border: Border.all(color: _hairline(dark), width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(72, dark),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    doctor.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: _titleColor(dark),
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                if (doctor.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Icon(
                                      Icons.verified,
                                      size: 15,
                                      color: _brandSolid,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingPill(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _specialtyPill(dark),
                          if (_experienceText.isNotEmpty)
                            _infoChip(
                              LucideIcons.briefcase,
                              _experienceText,
                              dark,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: _mutedIcon(dark),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "${doctor.clinicName}, ${doctor.city}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: _mutedText(dark),
                              ),
                            ),
                          ),
                          if (dist.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            _buildDistanceBadge(dist),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAvailabilityWidget(dark),
            const SizedBox(height: 12),
            Divider(height: 1, color: _hairline(dark)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _buildPriceSection(dark)),
                const SizedBox(width: 10),
                _buildActionButton(context, dark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. HELPER WIDGETS
  // =========================================================================

  Widget _buildAvatar(double size, bool dark) {
    final hasValidImage = doctor.image.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _imageBg(dark),
            border: Border.all(
              color: _brandSolid.withValues(alpha: 0.18),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasValidImage
              ? CachedNetworkImage(
                  imageUrl: doctor.image,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (c, u, e) => _buildFallbackAvatar(dark),
                )
              : _buildFallbackAvatar(dark),
        ),
        if (doctor.isVerified)
          Positioned(
            right: -3,
            bottom: -3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _surface(dark),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.verified, size: 17, color: _brandSolid),
            ),
          ),
      ],
    );
  }

  Widget _specialtyPill(bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _brandSolid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        doctor.specialty,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _brand(dark),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _chipBg(dark),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _mutedIcon(dark)),
          const SizedBox(width: 4),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _mutedText(dark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _kGold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: _kGold, size: 13),
          const SizedBox(width: 3),
          Text(
            "${doctor.rating}",
            style: TextStyle(
              color: AppPalette.warning700,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceBadge(String dist) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _brandSolid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        dist,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _brandSolid,
        ),
      ),
    );
  }

  Widget _buildAvailabilityWidget(bool dark) {
    final available = _hasSlots;
    final color = available ? AppPalette.success500 : AppPalette.error500;
    final onColor = available ? AppPalette.success700 : AppPalette.error500;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(
            available ? LucideIcons.calendarClock : LucideIcons.calendarOff,
            size: 13,
            color: onColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? doctor.nextAvailable
                  : (isOdia ? "ସ୍ଲଟ୍ ନାହିଁ" : "No slots available"),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: onColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, bool dark) {
    if (_hasSlots) {
      // Gradient brand CTA
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppPalette.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _handleMainAction(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOdia ? "ବୁକ୍" : "Book",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.arrowRight,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (_clinicPhone.isNotEmpty) {
      final callColor = _titleColor(dark);
      return SizedBox(
        height: 40,
        child: OutlinedButton.icon(
          onPressed: () => _handleMainAction(context),
          icon: Icon(LucideIcons.phone, size: 14, color: callColor),
          label: Text(
            isOdia ? "କଲ୍" : "Call",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: callColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: BorderSide(color: _hairline(dark), width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPriceSection(bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isOdia ? "ପରାମର୍ଶ ଫି" : "Consultation Fee",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _mutedIcon(dark),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        doctor.price > 0
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "₹${doctor.price}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: _titleColor(dark),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    isOdia ? "/ ଭିଜିଟ୍" : "/ visit",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _mutedIcon(dark),
                    ),
                  ),
                ],
              )
            : Text(
                "Contact Clinic",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppPalette.warning500,
                  fontSize: 12,
                ),
              ),
      ],
    );
  }

  Widget _buildFallbackAvatar(bool dark) {
    return Container(
      color: dark ? AppPalette.neutral800 : _brandSolid.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          LucideIcons.stethoscope,
          size: 28,
          color: _brandSolid.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

// 🚀 SKELETON LOADER
class DoctorCardSkeleton extends StatelessWidget {
  final bool isVertical;
  const DoctorCardSkeleton({super.key, this.isVertical = true});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: dark ? AppPalette.neutral800 : AppPalette.neutral200,
      highlightColor: dark ? AppPalette.neutral700 : AppPalette.neutral100,
      child: Container(
        width: isVertical ? 250 : double.infinity,
        height: isVertical ? 320 : 190,
        decoration: BoxDecoration(
          color: dark ? AppPalette.neutral900 : AppPalette.neutralWhite,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
