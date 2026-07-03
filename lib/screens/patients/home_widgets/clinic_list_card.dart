import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/clinic_details_screen.dart';

class ClinicListCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ClinicListCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: context.roundedLg),
      child: InkWell(
        borderRadius: context.roundedLg,
        onTap: () => _navigateToDetails(context),
        child: Padding(
          padding: EdgeInsets.all(context.spaceSm), // roughly 12px
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(context),
                  context.gapMd, // Space between image and text
                  Expanded(child: _buildInfo(context)),
                ],
              ),

              Padding(
                padding: EdgeInsets.symmetric(vertical: context.spaceXs),
                child: const Divider(height: 1),
              ),

              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// --- 1. Image Section with Fallback ---
  Widget _buildImage(BuildContext context) {
    final String? imageUrl = data['image'];
    final bool isOpen = data['isOpen'] ?? false;

    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: context.roundedMd,
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: Border.all(
              color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(context),
                )
              : _buildPlaceholder(context),
        ),

        // Status Badge
        if (isOpen)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                "OPEN",
                style: context.text.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        LucideIcons.briefcase,
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }

  /// --- 2. Information Section ---
  Widget _buildInfo(BuildContext context) {
    // Safely cast tags or default to empty list
    final List<dynamic> rawTags = data['tags'] ?? [];
    final tags = rawTags.take(2).map((e) => e.toString()).toList();
    final rating = data['rating']?.toString() ?? "New";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & Rating Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                data['name'] ?? "Unknown Clinic",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                  const SizedBox(width: 2),
                  Text(
                    rating,
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        context.gapXs,

        // Address
        Row(
          children: [
            Icon(
              LucideIcons.mapPin,
              size: 13,
              color: context.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                data['address'] ?? "Address not available",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),

        context.gapSm,

        // Tags
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag,
                      style: context.text.labelSmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  /// --- 3. Bottom Actions ---
  Widget _buildActions(BuildContext context) {
    final distance = data['distance']; // Might be null

    return Row(
      children: [
        // Distance Indicator (if available)
        if (distance != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.navigation,
              size: 14,
              color: context.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$distance",
            style: context.text.labelMedium?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ] else
          const Spacer(),

        // Action Buttons
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: () => _makeCall(data['phone']),
            icon: Icon(
              LucideIcons.phone,
              size: 14,
              color: context.colorScheme.onSurface,
            ),
            label: Text(
              "Call",
              style: TextStyle(color: context.colorScheme.onSurface),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(
                color: context.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: () => _navigateToDetails(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text("Book Now"),
          ),
        ),
      ],
    );
  }

  // Helper: Navigation
  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClinicDetailsScreen(clinicData: data),
      ),
    );
  }

  // Helper: Phone Call
  Future<void> _makeCall(dynamic phone) async {
    if (phone != null && phone.toString().isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: phone.toString());
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    }
  }
}
