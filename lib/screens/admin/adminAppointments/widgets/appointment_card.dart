// lib/screens/admin/adminAppointments/widgets/appointment_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/models/appointment_model.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appt;
  final Color bg;
  final Color surface;
  final Color border;
  final Color primary;
  final Color textMain;
  final Color textSub;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onOptions;
  // 🚀 Action Menu ପାଇଁ ଏକ ନୂଆ Callback (ଯଦି ଦରକାର)
  final VoidCallback? onActionTap;

  const AppointmentCard({
    super.key,
    required this.appt,
    required this.bg,
    required this.surface,
    required this.border,
    required this.primary,
    required this.textMain,
    required this.textSub,
    required this.statusColor,
    required this.onTap,
    required this.onLongPress,
    required this.onCall, // Patient Call
    required this.onWhatsApp, // Patient WhatsApp
    required this.onOptions, // 3-Dots Menu
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 Start Time ବଦଳରେ End Time ଦେଖାଇବା ପାଇଁ ଲଜିକ୍ 
    String startDisplay = appt.startTime;
    String endDisplay = appt.endTime;
    
    // Status Badge Logic (Pending vs Confirmed vs Checked In)
    String statusLabel = appt.status.toUpperCase();
    Color badgeColor = statusColor;
    
    if (appt.status == 'pending') {
      statusLabel = "PENDING";
      badgeColor = Colors.orange.shade600;
    } else if (appt.status == 'confirmed') {
      statusLabel = "CONFIRMED";
      badgeColor = Colors.blue.shade600;
    } else if (appt.status == 'checked_in') {
      statusLabel = "CHECKED IN";
      badgeColor = Colors.purple.shade600;
    } else if (appt.status == 'completed') {
      statusLabel = "COMPLETED";
      badgeColor = Colors.green.shade600;
    } else if (['cancelled', 'no_show'].contains(appt.status)) {
      badgeColor = Colors.red.shade600;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: badgeColor, // 🚀 Uses Dynamic Status Color
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TOP ROW: TIME & STATUS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.clock,
                                    size: 12,
                                    color: textSub,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "$startDisplay - $endDisplay", // 🚀 Shows Time Range
                                    style: TextStyle(
                                      color: textMain,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // 🚀 Slot Number & Status Badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "#${appt.slotNumber}",
                                  style: TextStyle(
                                    color: textSub,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // --- MIDDLE ROW: PATIENT INFO ---
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: border,
                              child: Text(
                                appt.patient.name.isNotEmpty
                                    ? appt.patient.name[0]
                                    : "?",
                                style: TextStyle(
                                  color: textMain,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appt.patient.name, // 🚀 Uses Model Patient
                                    style: TextStyle(
                                      color: textMain,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "${appt.patient.age} Yrs • ${appt.patient.phone}",
                                    style: TextStyle(
                                      color: textSub,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        Divider(color: border, height: 1),
                        const SizedBox(height: 12),
                        
                        // --- BOTTOM ROW: DOCTOR INFO & ACTIONS ---
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        LucideIcons.stethoscope,
                                        size: 12,
                                        color: primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          appt.doctorName,
                                          style: TextStyle(
                                            color: textSub,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    appt.clinicName,
                                    style: TextStyle(
                                      color: textSub.withValues(alpha: 0.8),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            // --- ACTION BUTTONS ---
                            Row(
                              children: [
                                // 🚀 Patient Call Button
                                _CardIconButton(
                                  icon: LucideIcons.phone,
                                  color: Colors.green,
                                  onTap: onCall,
                                ),
                                const SizedBox(width: 8),
                                // 🚀 Patient WhatsApp Button
                                _CardIconButton(
                                  icon: LucideIcons.messageCircle,
                                  color: Colors.blue,
                                  onTap: onWhatsApp,
                                ),
                                const SizedBox(width: 8),
                                // 🚀 3 Dots Action Menu Button
                                _CardIconButton(
                                  icon: LucideIcons.moreHorizontal,
                                  color: textMain,
                                  onTap: onOptions,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CardIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}