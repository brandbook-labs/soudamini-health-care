import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/booking/appointment_booking_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../models/doctor_model.dart';
import '../../../../models/booking_models.dart';
import '../../doctor_profile/doctor_profile_screen.dart';

const Color _primaryColor = Color.fromARGB(255, 22, 96, 255);
const Color _greenColor = Color(0xFF16A34A);

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
        // Slot time ରେ start ଏବଂ end time ପଠାନ୍ତୁ
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
  // 1. ଭର୍ଟିକାଲ୍ ଡିଜାଇନ୍ (ULTIMATE FIX - 100% Overflow Proof)
  // =========================================================================
  Widget _buildVerticalCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasValidImage = doctor.image.isNotEmpty;
    final String dist = _formattedDistance;

    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      child: Container(
        width: 250, // Premium width
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : AppPalette.neutralWhite,
          borderRadius: BorderRadius.circular(10), // Premium curve
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black38 : Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDarkMode ? Colors.white12 : AppPalette.info200.withOpacity(0.15),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HERO IMAGE ---
            // 🚀 ମାଷ୍ଟରଷ୍ଟ୍ରୋକ୍ (Masterstroke): Expanded ବର୍ତ୍ତମାନ Image ରେ ଅଛି!
            // ଏହାଦ୍ୱାରା ତଳ କାର୍ଡ କେବେବି ଫାଟିବ ନାହିଁ, ବରଂ ଇମେଜ୍ ନିଜେ ଜାଗା ଅନୁସାରେ ସାଇଜ୍ ବଦଳାଇବ।
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: isDarkMode ? Colors.black26 : AppPalette.info50,
                      child: hasValidImage
                          ? CachedNetworkImage(
                              imageUrl: doctor.image,
                              fit: BoxFit.cover,
                              alignment: Alignment.center, // 🚀 Center କରାଗଲା ଯାହାଦ୍ୱାରା ଫଟୋ ପରଫେକ୍ଟ୍ ଦେଖାଯିବ
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildFallbackAvatar(isDarkMode),
                            )
                          : _buildFallbackAvatar(isDarkMode),
                    ),
                    Positioned(top: 10, right: 10, child: _buildRatingBadge()),
                  ],
                ),
              ),
            ),

            // --- DETAILS SECTION ---
            // 🚀 ଏଠାରୁ Expanded ହଟାଇ ଦିଆଗଲା। ଏହା କେବଳ ସୀମିତ (ଦରକାରୀ) ଜାଗା ନେବ।
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12), // 🚀 ଠିକ୍ 8px Bottom Padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // ସର୍ବନିମ୍ନ ଜାଗା ନେବ
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
                            fontWeight: FontWeight.w900,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      if (doctor.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: _primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  Text(
                    doctor.specialty,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.blue.shade200 : _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 13,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${doctor.clinicName}, ${doctor.city}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (dist.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            dist,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),

                  _buildSlotAvailabilityWidget(isDarkMode),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: _buildPriceSection(isDarkMode),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildActionButton(context, isDarkMode, isSmall: true),
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
  // 2. ହୋରିଜେଣ୍ଟାଲ୍ ଡିଜାଇନ୍ (Horizontal Design - 100% Overflow Proof)
  // =========================================================================
  Widget _buildHorizontalCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasValidImage = doctor.image.isNotEmpty;
    final String dist = _formattedDistance;

    return GestureDetector(
      onTap: () => _handleProfileTap(context),
      // 🚀 ମୁଖ୍ୟ ପରିବର୍ତ୍ତନ: Fixed Height ହଟାଇ IntrinsicHeight ର ବ୍ୟବହାର
      child: IntrinsicHeight(
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1E1E1E)
                : AppPalette.neutralWhite,
            // borderRadius: BorderRadius.circular(12),
            border: Border(
              bottom: BorderSide(
                color: AppPalette.info200.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment
                .stretch, // 🚀 [FIXED]: ଉଭୟ ପାର୍ଶ୍ୱ ସମାନ ହାଇଟ୍ ନେବ
            children: [
              // --- IMAGE SECTION ---
              SizedBox(
                width: 100,
                child: Center(
                  // <-- Added Center so the circle doesn't stretch into an oval
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100, // Fixed width for circle
                        height: 100, // Fixed height for circle
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, // Make it a circle
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.blue.shade50,
                        ),
                        clipBehavior:
                            Clip.antiAlias, // Clip image inside the circle
                        child: hasValidImage
                            ? CachedNetworkImage(
                                imageUrl: doctor.image,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    _buildFallbackAvatar(isDarkMode),
                              )
                            : _buildFallbackAvatar(isDarkMode),
                      ),
                      Positioned(
                        bottom: -4,
                        left: 0,
                        right: 0,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _buildRatingBadge(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- DETAILS SECTION ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment
                        .spaceBetween, // 🚀 [FIXED]: ଏହା Spacer() ବଦଳରେ କାମ କରିବ ଏବଂ କଟିବ ନାହିଁ
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  doctor.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              if (doctor.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: _primaryColor,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            doctor.specialty,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.blue.shade200
                                  : _primaryColor,
                            ),
                          ),
                          const SizedBox(height: 6),

                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${doctor.clinicName}, ${doctor.city}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              if (dist.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dist,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),

                          _buildSlotAvailabilityWidget(isDarkMode),
                        ],
                      ),

                      const SizedBox(height: 8), // Padding before bottom row

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _buildPriceSection(isDarkMode),
                          ), // 🚀 [FIXED]: Expanded used to prevent row overflow
                          _buildActionButton(
                            context,
                            isDarkMode,
                            isSmall: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 3. ଛୋଟ ଏବଂ ସ୍ମାର୍ଟ ୱିଜେଟ୍ କମ୍ପୋନେଣ୍ଟ୍ (Helper Widgets)
  // =========================================================================

  Widget _buildSlotAvailabilityWidget(bool isDarkMode) {
    if (_hasSlots) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _greenColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.calendarClock, size: 12, color: _greenColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                doctor.nextAvailable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _greenColor,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.calendarOff,
              size: 11,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                isOdia ? "ସ୍ଲଟ୍ ନାହିଁ" : "No Slots Available",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButton(
    BuildContext context,
    bool isDarkMode, {
    required bool isSmall,
  }) {
    if (_hasSlots) {
      return SizedBox(
        height: isSmall ? 36 : 40,
        child: FilledButton(
          onPressed: () => _handleMainAction(context),
          style: FilledButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 40 : 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isDarkMode ? 0 : 2,
            shadowColor: _primaryColor.withValues(alpha: 0.4),
          ),
          child: Text(
            isOdia ? "ବୁକ୍" : "Book",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmall ? 14 : 14,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (_clinicPhone.isNotEmpty) {
      return SizedBox(
        height: isSmall ? 36 : 40,
        child: OutlinedButton.icon(
          onPressed: () => _handleMainAction(context),
          icon: Icon(
            LucideIcons.phone,
            size: 14,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          label: Text(
            isOdia ? "କଲ୍" : "Call",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: isSmall ? 14 : 14,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16),
            side: BorderSide(
              color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildPriceSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // 🚀 ମୁଖ୍ୟ ପରିବର୍ତ୍ତନ: କେବଳ ଦରକାରୀ ଉଚ୍ଚତା ନେବ
      children: [
        Text(
          isOdia ? "ପରାମର୍ଶ ଫି" : "Fees",
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
            height: 1.1, // 🚀 ଲାଇନ୍ ହାଇଟ୍ କମାଗଲା 
          ),
        ),
        const SizedBox(height: 2), // 🚀 ଅଯଥା ଗ୍ୟାପ୍ ହଟାଗଲା
        doctor.price > 0
            ? Text(
                "₹${doctor.price}",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  height: 1.1, // 🚀 ଲାଇନ୍ ହାଇଟ୍ କମାଗଲା
                ),
              )
            : const Text(
                "Contact Clinic",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
      ],
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 12),
          const SizedBox(width: 4),
          Text(
            "${doctor.rating}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(bool isDarkMode) {
    return Container(
      color: isDarkMode
          ? Colors.white10
          : _primaryColor.withValues(alpha: 0.05),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black26 : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.stethoscope,
            size: 28,
            color: _primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  String _parseDegree(List<String> education) {
    if (education.isEmpty) return "";
    final first = education.first;
    if (first.contains("-")) {
      return first.split("-")[0].trim();
    }
    return first;
  }
}

// 🚀 SKELETON LOADER
class DoctorCardSkeleton extends StatelessWidget {
  final bool isVertical;
  const DoctorCardSkeleton({super.key, this.isVertical = true});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.white10 : Colors.grey.shade200,
      highlightColor: isDarkMode ? Colors.white24 : Colors.grey.shade100,
      child: Container(
        width: isVertical ? 240 : double.infinity,
        height: isVertical ? 250 : 155,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
