// lib/screens/medical_records/widgets/my_care_team/doctor_dossier_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/patients/medical_records/my_doc_details_screen.dart';

import '../../models/past_consultation_model.dart';
import 'dossier_thumbnail_strip.dart';
import 'dossier_action_menu.dart';

class DoctorDossierCard extends StatelessWidget {
  final PastConsultationModel doctor;
  final VoidCallback onAddRecord;
  
  final VoidCallback? onWriteReview;

  const DoctorDossierCard({
    super.key,
    required this.doctor,
    required this.onAddRecord,
    this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    const bgLight = Color(0xFFF8FAFC);

    final hasAnyRecords =
        doctor.prescriptionsCount > 0 || doctor.labReportsCount > 0;
    final totalFiles = doctor.prescriptionsCount + doctor.labReportsCount;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: borderCol, width: 1.0),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProviderCareDetailsScreen(doctor: doctor),
            ),
          );
        },
        // ଆପଣ ଚାହିଁଲେ ଏହି ଲଙ୍ଗ୍ ପ୍ରେସ୍ କୁ ବି କମେଣ୍ଟ୍ କରିପାରିବେ, କିନ୍ତୁ ବର୍ତ୍ତମାନ କେବଳ 3-dot କୁ ଲୁଚାଯାଇଛି
        onLongPress: () => DossierActionMenu.show(context, doctor),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. PREMIUM HEADER ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24, 
                    backgroundImage: NetworkImage(doctor.imageUrl),
                    backgroundColor: bgLight,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Verified Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                doctor.doctorName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (doctor.isJivanVerified) ...[
                              const SizedBox(width: 6),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Specialty
                        Text(
                          doctor.specialty.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.black45,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 🚀 ଏଠାରୁ ୩-ଡଟ୍ (3-dot) ମେନୁ କୁ ସୁରକ୍ଷିତ ଭାବେ କମେଣ୍ଟ୍ କରାଯାଇଛି
                  /*
                  IconButton(
                    icon: const Icon(
                      LucideIcons.moreVertical,
                      size: 18,
                      color: Colors.black45,
                    ),
                    onPressed: () => DossierActionMenu.show(context, doctor),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                  */
                ],
              ),
            ),

            // --- 2. MODERN STAT CHIPS ---
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatChip(
                    LucideIcons.calendarDays,
                    DateFormat('MMM dd, yyyy').format(doctor.lastVisitDate),
                  ),
                  _buildStatChip(
                    LucideIcons.activity,
                    "${doctor.totalVisits} Visit${doctor.totalVisits != 1 ? 's' : ''}",
                  ),
                  _buildStatChip(
                    LucideIcons.fileText,
                    "$totalFiles File${totalFiles != 1 ? 's' : ''}",
                  ),
                ],
              ),
            ),

            // --- 3. RECENT FILES (If any) ---
            if (doctor.recentFiles.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: DossierThumbnailStrip(files: doctor.recentFiles),
              ),
            ],

            const Divider(height: 1, color: borderCol),

            // --- 4. SEGMENTED ACTION FOOTER ---
            
            // 🚀 ପୁରୁଣା Upload ଫିଚର୍ କୁ ସୁରକ୍ଷିତ ଭାବେ କମେଣ୍ଟ୍ କରାଯାଇଛି
            /*
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: hasAnyRecords
                    ? Colors.transparent
                    : primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasAnyRecords
                              ? "Manage health records"
                              : "No files saved yet",
                          style: TextStyle(
                            color: hasAnyRecords
                                ? Colors.black87
                                : primary.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasAnyRecords
                              ? "Tap to view full history."
                              : "Upload their prescription here.",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The Action Button
                  FilledButton.icon(
                    onPressed: onAddRecord,
                    icon: Icon(
                      LucideIcons.upload,
                      size: 14,
                      color: hasAnyRecords ? Colors.black87 : Colors.white,
                    ),
                    label: Text(
                      "Upload",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: hasAnyRecords ? Colors.black87 : Colors.white,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: hasAnyRecords ? bgLight : primary,
                      side: hasAnyRecords
                          ? const BorderSide(color: borderCol)
                          : null,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            */

            // 🌟 ଆକ୍ଟିଭ୍ ଫିଚର୍: କେବଳ "Write Review" ବଟନ୍ ରହିବ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Share your experience",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Write a review to help others.",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Write Review Button
                  if (onWriteReview != null)
                    FilledButton.icon(
                      onPressed: onWriteReview,
                      icon: const Icon(
                        LucideIcons.messageSquarePlus,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Write Review",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), 
                        ),
                        elevation: 0,
                      ),
                    ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  // 🚀 MODERN CHIP UI WIDGET
  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}