// lib/screens/medical_records/widgets/my_care_team/dossier_empty_state.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DossierEmptyState extends StatelessWidget {
  const DossierEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: const Icon(
                LucideIcons.users,
                size: 40,
                color: Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Doctors Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Once you complete an appointment, your doctors will appear here so you can easily manage their records.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
