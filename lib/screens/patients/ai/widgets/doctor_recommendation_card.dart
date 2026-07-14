import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

const Color _primaryColor = Color.fromARGB(255, 22, 96, 255);
const Color _greenColor = Color(0xFF16A34A);

class DoctorRecommendationCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorRecommendationCard({super.key, required this.doctor});

  // Safe getters for mock data handling
  String get _name => doctor['name'] ?? 'Dr. Saurav Mohanty';
  String get _specialty => doctor['specialty'] ?? 'General Physician';
  String get _clinicName => doctor['clinicName'] ?? 'Jivan Health Clinic';
  String get _city => doctor['city'] ?? 'Bhubaneswar';
  String get _image => doctor['image'] ?? 'https://i.pravatar.cc/150?img=11';
  String get _rating => doctor['rating']?.toString() ?? '4.8';
  String get _price => doctor['price']?.toString() ?? '500';
  String get _nextAvailable => doctor['nextAvailable'] ?? 'Today, 4:00 PM';
  bool get _isVerified => doctor['isVerified'] ?? true;
  List<dynamic> get _reasons =>
      doctor['reasons'] ??
      ["Highly rated for gentle care", "Available to see you today"];

  bool get _hasSlots =>
      _nextAvailable.isNotEmpty &&
      _nextAvailable.toLowerCase() != "check slots" &&
      _nextAvailable.toLowerCase() != "unavailable" &&
      _nextAvailable.toLowerCase() != "null";

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24, right: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TOP SECTION: Avatar & Details (Similar to Horizontal Card) ---
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- IMAGE SECTION ---
                SizedBox(
                  width: 110,
                  child: Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDarkMode
                                ? Colors.black26
                                : Colors.blue.shade50,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CachedNetworkImage(
                            imageUrl: _image,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildFallbackAvatar(isDarkMode),
                          ),
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
                    padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (_isVerified)
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
                              _specialty,
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
                                    "$_clinicName, $_city",
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
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildSlotAvailabilityWidget(isDarkMode),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- DIVIDER ---
          Divider(
            height: 1,
            thickness: 1,
            color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
          ),

          // --- AI REASONS (Why this doctor?) ---
          if (_reasons.isNotEmpty)
            Container(
              color: isDarkMode ? Colors.black12 : const Color(0xFFF8FAFC),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _reasons.map((reason) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LucideIcons.sparkles,
                            size: 14,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.grey.shade300
                                  : const Color(0xFF334155),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // --- BOTTOM ACTION ROW ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _buildPriceSection(isDarkMode)),
                _buildActionButton(context, isDarkMode, isSmall: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER WIDGETS ---

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
                _nextAvailable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
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
            const Flexible(
              child: Text(
                "No Slots Available",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
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
    return SizedBox(
      height: isSmall ? 36 : 40,
      child: FilledButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          // TODO: Route to booking screen passing the mock doctor data
        },
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          padding: EdgeInsets.symmetric(horizontal: isSmall ? 32 : 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isDarkMode ? 0 : 2,
          shadowColor: _primaryColor.withValues(alpha: 0.4),
        ),
        child: Text(
          "Book",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: isSmall ? 14 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          "Consultation Fee",
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
        ),
        _price != "null" && _price.isNotEmpty
            ? Text(
                "₹$_price",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              )
            : const Text(
                "Contact Clinic",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  fontSize: 11,
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
            _rating,
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
            size: 24,
            color: _primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
