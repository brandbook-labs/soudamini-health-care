import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DoctorSliverAppBar extends StatelessWidget {
  final String imageUrl;

  const DoctorSliverAppBar({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    bool hasValidImage =
        imageUrl.isNotEmpty && !imageUrl.contains("ui-avatars");
    const Color primaryColor = Color.fromARGB(255, 22, 96, 255);

    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            hasValidImage
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  )
                : Container(
                    color: primaryColor.withValues(alpha: 0.05),
                    child: Center(
                      child: Icon(
                        LucideIcons.stethoscope,
                        size: 100,
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
