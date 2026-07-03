import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../models/doctor_model.dart';

class DoctorAboutSection extends StatelessWidget {
  final Doctor doctor;
  final bool isOdia;

  const DoctorAboutSection({
    super.key,
    required this.doctor,
    required this.isOdia,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const Color primaryColor = Color.fromARGB(255, 22, 96, 255);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          context,
          isOdia ? "ଡାକ୍ତରଙ୍କ ବିଷୟରେ" : "About Doctor",
          isDarkMode,
        ),
        const SizedBox(height: 12),
        Text(
          doctor.about,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isDarkMode ? Colors.grey.shade400 : Colors.blueGrey.shade700,
            height: 1.6,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        if (doctor.rawEducation.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            isOdia ? "ଶିକ୍ଷା" : "Education",
            isDarkMode,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doctor.rawEducation
                .map(
                  (edu) => _buildTag(
                    context,
                    edu,
                    LucideIcons.graduationCap,
                    isDarkMode,
                    primaryColor,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
        ],
        if (doctor.languages.isNotEmpty) ...[
          _buildSectionTitle(
            context,
            isOdia ? "ଭାଷା" : "Languages",
            isDarkMode,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: doctor.languages
                .map(
                  (lang) => _buildTag(
                    context,
                    lang,
                    LucideIcons.languages,
                    isDarkMode,
                    primaryColor,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 32),
        ],
        const SizedBox(height: 100), // Padding for sticky bottom bar
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

  Widget _buildTag(
    BuildContext context,
    String text,
    IconData icon,
    bool isDarkMode,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isDarkMode
                  ? Colors.grey.shade300
                  : Colors.blueGrey.shade700,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
