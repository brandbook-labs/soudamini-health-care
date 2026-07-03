import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color.fromARGB(255, 22, 96, 255);
    const Color greenColor = Color(0xFF16A34A);
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (doctor.locations.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            isOdia ? "କ୍ଲିନିକ୍ ବାଛନ୍ତୁ" : "Select Clinic",
            isDarkMode,
          ),
          const SizedBox(height: 16),
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
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GestureDetector(
                    onTap: () => onClinicChanged(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : (isDarkMode
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? LucideIcons.checkCircle2
                                : LucideIcons.mapPin,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            clinicName,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode
                                        ? Colors.white70
                                        : Colors.black87),
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
          const SizedBox(height: 32),
        ],

        _buildSectionTitle(
          context,
          isOdia ? "ଠିକଣା ଏବଂ ମ୍ୟାପ୍" : "Clinic Location",
          isDarkMode,
        ),
        const SizedBox(height: 16),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        color: primaryColor,
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
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentClinicAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.blueGrey.shade600,
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
                                color: greenColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.navigation,
                                    size: 14,
                                    color: greenColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    currentDistance,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: greenColor,
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
              if (currentLat != 0.0 && currentLng != 0.0)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: LatLng(currentLat, currentLng),
                      initialZoom: 16.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDarkMode
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
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "Clinic",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 45,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    bool isDarkMode,
  ) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }
}
