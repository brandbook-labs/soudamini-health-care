import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this points to your theme context

class LiveClinicStatusView extends StatelessWidget {
  const LiveClinicStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    // MOCK DATA: You will replace this with real API data later
    final capacityData = [
      {"label": "Gen. Wards", "available": 8, "total": 10, "status": "green"},
      {"label": "OPD Rooms", "available": 2, "total": 5, "status": "yellow"},
      {"label": "ICU Beds", "available": 0, "total": 2, "status": "red"},
    ];

    final activeDoctors = [
      {
        "name": "Dr. Sarah Jena",
        "specialty": "Cardiology",
        "currentPatient": "Ramesh Kumar",
        "queue": 4,
        "avatar":
            "https://ui-avatars.com/api/?name=Sarah+Jena&background=074EE7&color=fff",
      },
      {
        "name": "Dr. Amit Das",
        "specialty": "General Physician",
        "currentPatient": "Sujata Mishra",
        "queue": 12,
        "avatar":
            "https://ui-avatars.com/api/?name=Amit+Das&background=006C70&color=fff",
      },
      {
        "name": "Dr. Priya Sen",
        "specialty": "Pediatrics",
        "currentPatient":
            "Reviewing Reports", // Sometimes they aren't with a patient!
        "queue": 1,
        "avatar":
            "https://ui-avatars.com/api/?name=Priya+Sen&background=purple&color=fff",
      },
    ];

    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. SECTION HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Live Operations",
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full staff/clinic view
                },
                child: const Text("View Details"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 0),

        // --- 2. CAPACITY INDICATORS (Green/Yellow/Red) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            children: capacityData.map((data) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: data == capacityData.last ? 0 : 4.0,
                  ),
                  child: _CapacityPill(
                    label: data['label'] as String,
                    available: data['available'] as int,
                    total: data['total'] as int,
                    statusStr: data['status'] as String,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // --- 3. ACTIVE DOCTORS HORIZONTAL LIST ---
        SizedBox(
          height: 140, // Fixed height for the horizontal cards
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: activeDoctors.length,
            separatorBuilder: (context, index) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              return _ActiveDoctorCard(doctor: activeDoctors[index]);
            },
          ),
        ),
      ],
    );
  }
}

// ── SUB-WIDGETS ──────────────────────────────────────────────────────────────

class _CapacityPill extends StatelessWidget {
  final String label;
  final int available;
  final int total;
  final String statusStr;

  const _CapacityPill({
    required this.label,
    required this.available,
    required this.total,
    required this.statusStr,
  });

  @override
  Widget build(BuildContext context) {
    // Map the string status to actual colors
    Color statusColor;
    if (statusStr == "green") {
      statusColor = Colors.green.shade600;
    } else if (statusStr == "yellow") {
      statusColor =
          Colors.orange.shade500; // Orange looks better than bright yellow
    } else {
      statusColor = Colors.red.shade600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withValues(alpha: 0.09)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$available/$total Open",
            style: context.text.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const _ActiveDoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final bool isBusy =
        doctor['queue'] > 5; // Example logic for highlighting high queues

    return Container(
      width: 250, // Fixed width so they scroll nicely
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPalette.info50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppPalette.info200.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Doctor Info & Status
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(doctor['avatar']),
                  ),
                  // Online Indicator Dot
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor['name'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    Text(
                      doctor['specialty'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withAlpha(90),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // 2. Current Patient
          Row(
            children: [
              Icon(LucideIcons.userCheck, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Patient: ${doctor['currentPatient']}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // 3. Queue Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isBusy
                  ? Colors.orange.withValues(alpha: 0.1)
                  : AppPalette.success700.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.users,
                  size: 12,
                  color: isBusy
                      ? Colors.orange.shade700
                      : AppPalette.success700,
                ),
                const SizedBox(width: 6),
                Text(
                  "${doctor['queue']} waiting in queue",
                  style: context.text.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isBusy
                        ? Colors.orange.shade700
                        : AppPalette.success700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
