import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class GlobalMapWidget extends StatelessWidget {
  final double lat;
  final double lng;
  final String title;
  final double height; // 🚀 ବିଭିନ୍ନ ସ୍କ୍ରିନ୍ ପାଇଁ ହାଇଟ୍ କଷ୍ଟମାଇଜ୍ କରିବାକୁ

  const GlobalMapWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
    this.height = 180.0, // ଡିଫଲ୍ଟ ହାଇଟ୍ 180
  });

  // 🚀 Google Maps ଆପ୍ ରେ ସିଧାସଳଖ ଖୋଲିବା ପାଇଁ ଲଜିକ୍
  Future<void> _openGoogleMaps() async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = LatLng(lat, lng);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 14, 
            color: Theme.of(context).colorScheme.onSurface
          )
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: location,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      // 🚀 ସ୍କ୍ରୋଲ୍ କଲାବେଳେ ଯେମିତି ମ୍ୟାପ୍ ନ ଅଟକେ ସେଥିପାଇଁ କେବଳ Drag ଓ Pinch ରଖିବା ବେଷ୍ଟ୍
                      flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom, 
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.your_app.jivan', // ନିଜ ଆପ୍ ର ପ୍ୟାକେଜ୍ ନାମ ଦେବେ
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: location,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on, 
                            color: Colors.red, 
                            size: 40
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // 🚀 ନେଭିଗେସନ୍ (Direction) ବଟନ୍
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: "map_btn_${lat}_$lng", // Multiple map ଥିଲେ ଏରର୍ ନଆସିବା ପାଇଁ
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    onPressed: _openGoogleMaps,
                    child: Icon(Icons.directions, color: Theme.of(context).colorScheme.primary),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}