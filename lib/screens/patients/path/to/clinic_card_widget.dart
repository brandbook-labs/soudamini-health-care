import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_new_app/core/theme/tokens/app_palette.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_new_app/screens/patients/clinic_details_screen.dart';
import '../../../../models/clinic_model.dart';

const Color _primaryColor = Color.fromARGB(255, 22, 96, 255);
const Color _greenColor = Color(0xFF16A34A);

class ClinicCardWidget extends StatelessWidget {
  final Clinic clinic;
  final bool isOdia;
  final bool isVertical;

  const ClinicCardWidget({
    super.key,
    required this.clinic,
    required this.isOdia,
    this.isVertical = true,
  });

  // 🚀 DISTANCE FORMATTER (m / km) safely handled by Model now
  String get _formattedDistance {
    if (clinic.distance.isEmpty || clinic.distance == "null") return "";
    double dist =
        double.tryParse(clinic.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;
    if (dist == 0) return "";
    return dist >= 1000
        ? "${(dist / 1000).toStringAsFixed(1)} km"
        : "${dist.toInt()} m";
  }

  bool get _hasPhone =>
      clinic.phone.isNotEmpty &&
      clinic.phone != "null" &&
      clinic.phone.length > 5;

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicDetailsScreen(clinicData: clinic.fullData),
      ),
    );
  }

  Future<void> _makeCall(BuildContext context) async {
    if (_hasPhone) {
      final Uri launchUri = Uri(scheme: 'tel', path: clinic.phone);
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

  @override
  Widget build(BuildContext context) {
    return isVertical
        ? _buildVerticalCard(context)
        : _buildHorizontalCard(context);
  }

  // =========================================================================
  // 1. VERTICAL DESIGN (Doctor Widget Border + Smart Tags Layout)
  // =========================================================================
  Widget _buildVerticalCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasValidImage =
        clinic.image.isNotEmpty && !clinic.image.contains("ui-avatars");
    final String dist = _formattedDistance;

    return GestureDetector(
      onTap: () => _navigateToDetails(context),
      child: Container(
        width: 250, 
        margin: const EdgeInsets.only(right: 12, bottom: 8),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : AppPalette.info50,
          borderRadius: BorderRadius.circular(10), // Premium curve
          border: Border.all(
            color: AppPalette.info200.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- HERO IMAGE ---
            SizedBox(
              height: 120, 
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: isDarkMode ? Colors.black26 : Colors.blue.shade50,
                    child: hasValidImage
                        ? CachedNetworkImage(
                            imageUrl: clinic.image,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildFallbackImage(isDarkMode),
                          )
                        : _buildFallbackImage(isDarkMode),
                  ),
                  Positioned(top: 8, left: 8, child: _buildStatusBadge()),
                ],
              ),
            ),

            // --- DETAILS SECTION ---
            Flexible(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(), 
                child: Padding(
                  // 🚀 [PADDING MANAGE HERE]: ଏହି 12 ରୁ ସମ୍ପୂର୍ଣ୍ଣ ଭିତର ଗ୍ୟାପ୍ କଣ୍ଟ୍ରୋଲ୍ ହେଉଛି
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        clinic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 13,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clinic.location,
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
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dist,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 🚀 SMART TAGS (1 Tag + Count)
                      if (clinic.tags.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ୧ମ ଟ୍ୟାଗ୍ (First Tag)
                            Flexible(
                              child: Container(
                                // 🚀 [TAG PADDING MANAGE HERE]
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : AppPalette.neutral200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  clinic.tags.first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // ବଡ଼ ନାମ ଥିଲେ '...' ହୋଇଯିବ
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            
                            // ବାକି ଟ୍ୟାଗ୍ ର ସଂଖ୍ୟା (Remaining Count)
                            if (clinic.tags.length > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : AppPalette.neutral200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "+${clinic.tags.length - 1}", // 🚀 ଏଠାରେ +2, +3 ଆଦି ଦେଖାଯିବ
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      // 🚀 କେବଳ କଲ୍ (Call) ବଟନ୍ 
                      if (_hasPhone) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 36, 
                          child: FilledButton.icon(
                            onPressed: () => _makeCall(context),
                            icon: const Icon(LucideIcons.phone, size: 14),
                            label: Text(
                              isOdia ? "କଲ୍ କରନ୍ତୁ" : "Call Clinic",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDarkMode 
                                  ? _primaryColor.withValues(alpha: 0.15) 
                                  : _primaryColor.withValues(alpha: 0.1),
                              foregroundColor: isDarkMode ? Colors.blue.shade200 : _primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 2. HORIZONTAL DESIGN (Premium UX - Clickable Card & Only Call Button)
  // =========================================================================
  Widget _buildHorizontalCard(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool hasValidImage =
        clinic.image.isNotEmpty && !clinic.image.contains("ui-avatars");
    final String dist = _formattedDistance;

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // ଲିଷ୍ଟ୍ ରେ କାର୍ଡ ଗୁଡିକ ମଧ୍ୟରେ ଗ୍ୟାପ୍
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : AppPalette.neutralWhite,
        borderRadius: BorderRadius.circular(16), // Premium Curve
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDarkMode ? Colors.white12 : AppPalette.info200.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // 🚀 UX UX UX: Material ଏବଂ InkWell ବ୍ୟବହାର ହେଲା କ୍ଲିକ୍ ଇଫେକ୍ଟ୍ ପାଇଁ
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToDetails(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // 🚀 Overflow ରୋକିବା ପାଇଁ 'stretch' ହଟାଗଲା
            children: [
              // --- IMAGE SECTION ---
              Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90, // ସାମାନ୍ୟ ସ୍ମାର୍ଟ ୱିଡ୍ଥ୍
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.1),
                          width: 2,
                        ),
                        color: isDarkMode ? Colors.black26 : Colors.blue.shade50,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasValidImage
                          ? CachedNetworkImage(
                              imageUrl: clinic.image,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  _buildFallbackImage(isDarkMode),
                            )
                          : _buildFallbackImage(isDarkMode),
                    ),
                    Positioned(
                      bottom: -6,
                      child: _buildStatusBadge(),
                    ),
                  ],
                ),
              ),

              // --- DETAILS SECTION ---
              Expanded(
                child: Padding(
                  // 🚀 Left padding ହଟାଗଲା କାରଣ ଇମେଜ୍ ରେ padding ଅଛି
                  padding: const EdgeInsets.fromLTRB(0, 14, 12, 14), 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 🚀 Overflow ରୋକିବ
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              clinic.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          // 🚀 UX: Right Arrow (Chevron) ଯାହା କ୍ଲିକ୍ କରିବାର ସଂକେତ ଦେବ
                          Icon(
                            LucideIcons.chevronRight,
                            size: 18,
                            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 13,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              clinic.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
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
                                color: _primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                dist,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 🚀 SMART TAGS (1 Tag + Count)
                      if (clinic.tags.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ୧ମ ଟ୍ୟାଗ୍ (First Tag)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  clinic.tags.first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis, // ବଡ଼ ନାମ ଥିଲେ '...' ହୋଇଯିବ
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            
                            // ବାକି ଟ୍ୟାଗ୍ ର ସଂଖ୍ୟା (Remaining Count)
                            if (clinic.tags.length > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "+${clinic.tags.length - 1}", // ଏଠାରେ +2, +3 ଦେଖାଯିବ
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                      // 🚀 କେବଳ କଲ୍ (Call) ବଟନ୍ - Full Width
                      if (_hasPhone) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: FilledButton.icon(
                            // ଏଠାରେ ବଟନ୍ କ୍ଲିକ୍ କଲେ କେବଳ କଲ୍ ଲାଗିବ (ଅନ୍ୟ ପେଜ୍ କୁ ଯିବନି)
                            onPressed: () => _makeCall(context),
                            icon: const Icon(LucideIcons.phone, size: 15),
                            label: Text(
                              isOdia ? "କଲ୍ କରନ୍ତୁ" : "Call Clinic",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: isDarkMode 
                                  ? _primaryColor.withValues(alpha: 0.15) 
                                  : _primaryColor.withValues(alpha: 0.1),
                              foregroundColor: isDarkMode ? Colors.blue.shade200 : _primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
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
  // 3. Helper Widgets
  // =========================================================================

  Widget _buildStatusBadge() {
    final bool isOpenNow = clinic.is24h || clinic.isOpen;
    final Color badgeColor = isOpenNow ? _greenColor : Colors.redAccent;
    final String badgeText = clinic.is24h
        ? "24/7"
        : (clinic.isOpen ? "OPEN" : "CLOSED");

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (clinic.is24h) ...[
            const Icon(LucideIcons.clock, size: 10, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.white10 : AppPalette.info50,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.black26 : Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.building,
            size: 48,
            color: _primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

// 🚀 SKELETON LOADER
class ClinicCardSkeleton extends StatelessWidget {
  final bool isVertical;
  const ClinicCardSkeleton({super.key, this.isVertical = true});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.white10 : Colors.grey.shade200,
      highlightColor: isDarkMode ? Colors.white24 : Colors.grey.shade100,
      child: Container(
        width: isVertical ? 230 : double.infinity,
        height: isVertical ? 260 : 155,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
