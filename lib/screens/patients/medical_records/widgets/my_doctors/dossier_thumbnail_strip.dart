// lib/screens/medical_records/widgets/my_care_team/dossier_thumbnail_strip.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DossierThumbnailStrip extends StatelessWidget {
  final List<Map<String, String>> files;

  const DossierThumbnailStrip({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "RECENT FILES (${files.length})",
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 60, // 🚀 Reduced height drastically for compactness
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: files.length,
            itemBuilder: (context, idx) {
              final file = files[idx];
              final isPdf = file['type'] == 'pdf';
              final fileName = file['name'] ?? 'Doc';

              return GestureDetector(
                onTap: () {
                  /* View File */
                },
                child: Container(
                  width: 56, // Narrower thumbnails
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: isPdf ? bgLight : Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                    image: !isPdf
                        ? DecorationImage(
                            image: NetworkImage(file['url']!),
                            fit: BoxFit.cover,
                            opacity: 0.8,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isPdf)
                        Icon(
                          LucideIcons.fileText,
                          color: primary.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      if (isPdf) const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPdf
                              ? Colors.transparent
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          fileName,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: isPdf ? Colors.black87 : Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
