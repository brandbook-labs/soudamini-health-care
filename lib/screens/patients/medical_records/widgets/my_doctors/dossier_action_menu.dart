// lib/screens/medical_records/widgets/my_care_team/dossier_action_menu.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/past_consultation_model.dart';

class DossierActionMenu {
  static void show(BuildContext context, PastConsultationModel doctor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(doctor.imageUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Actions for ${doctor.doctorName}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              ListTile(
                leading: const Icon(LucideIcons.star, color: Colors.amber),
                title: const Text(
                  "Write a Review",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              if (doctor.isJivanVerified)
                ListTile(
                  leading: const Icon(
                    LucideIcons.calendarPlus,
                    color: Color(0xFF4F46E5),
                  ),
                  title: const Text(
                    "Book Follow-up",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
              ListTile(
                leading: const Icon(LucideIcons.user, color: Colors.black87),
                title: const Text(
                  "View Doctor Profile",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              ListTile(
                leading: const Icon(
                  LucideIcons.userMinus,
                  color: Color(0xFFE11D48),
                ),
                title: const Text(
                  "Remove from Care Team",
                  style: TextStyle(
                    color: Color(0xFFE11D48),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
