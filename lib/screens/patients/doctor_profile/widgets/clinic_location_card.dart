import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import '../../../../models/doctor_model.dart';

class ClinicLocationCard extends StatelessWidget {
  final Doctor doctor;
  final int selectedIndex;
  final Function(int) onClinicChanged;
  final MapController mapController;
  final double currentLat;
  final double currentLng;
  final String currentClinicName;
  final String currentClinicAddress;
  final String currentDistance;
  final bool isOdia;

  const ClinicLocationCard({
    super.key,
    required this.doctor,
    required this.selectedIndex,
    required this.onClinicChanged,
    required this.mapController,
    required this.currentLat,
    required this.currentLng,
    required this.currentClinicName,
    required this.currentClinicAddress,
    required this.currentDistance,
    required this.isOdia,
  });

  Future<void> _openDirections() async {
    if (currentLat == 0.0 && currentLng == 0.0) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$currentLat,$currentLng',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outlineVariant.withValues(alpha: 0.5);
    final hasMap = currentLat != 0.0 && currentLng != 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (doctor.locations.length > 1) ...[
          _sectionTitle(context, isOdia ? "କ୍ଲିନିକ୍ ବାଛନ୍ତୁ" : "Select Clinic"),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(doctor.locations.length, (index) {
                final loc = doctor.locations[index];
                final clinicName =
                    loc['clinic']?['name'] ?? "Clinic ${index + 1}";
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => onClinicChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? scheme.primary : scheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? scheme.primary : border,
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : const [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check_circle_rounded
                                : LucideIcons.mapPin,
                            size: 16,
                            color: isSelected
                                ? scheme.onPrimary
                                : scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            clinicName,
                            style: TextStyle(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 28),
        ],

        Row(
          children: [
            Expanded(
              child: _sectionTitle(
                context,
                isOdia ? "ଠିକଣା ଏବଂ ମ୍ୟାପ୍" : "Clinic Location",
              ),
            ),
            if (hasMap)
              TextButton.icon(
                onPressed: _openDirections,
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: Text(isOdia ? "ଦିଗ" : "Directions"),
                style: TextButton.styleFrom(
                  foregroundColor: scheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.mapPin,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentClinicName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentClinicAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                          if (currentDistance.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppPalette.success500.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.navigation,
                                    size: 14,
                                    color: AppPalette.success700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentDistance,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppPalette.success700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasMap)
                Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: LatLng(currentLat, currentLng),
                          initialZoom: 16.5,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                Theme.of(context).brightness == Brightness.dark
                                ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png'
                                : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.jivan.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(currentLat, currentLng),
                                width: 140,
                                height: 140,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isOdia ? "କ୍ଲିନିକ୍" : "Clinic",
                                        style: TextStyle(
                                          color: scheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.location_on,
                                      color: scheme.primary,
                                      size: 42,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Floating Directions button
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Material(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _openDirections,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_rounded,
                                  size: 16,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOdia ? "ଦିଗ ପାଆନ୍ତୁ" : "Get Directions",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
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
        Flexible(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
