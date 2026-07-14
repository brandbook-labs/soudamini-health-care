import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

class AppointmentFeeSection extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;
  final double consultationFee;
  final double followUpFee;
  final bool isOdia;

  const AppointmentFeeSection({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.consultationFee,
    required this.followUpFee,
    required this.isOdia,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          context,
          isOdia ? "ଆପଣ କ'ଣ ଚାହୁଁଛନ୍ତି?" : "Choose Appointment",
        ),
        const SizedBox(height: 6),
        Text(
          isOdia
              ? "ଏକ ବିକଳ୍ପ ବାଛନ୍ତୁ"
              : "Select the type that suits your visit",
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _feeCard(
                context,
                label: isOdia ? "ପରାମର୍ଶ" : "Consultation",
                subtitle: isOdia ? "ପ୍ରଥମ ଭିଜିଟ୍" : "First visit",
                icon: LucideIcons.stethoscope,
                fee: consultationFee,
                gradient: AppPalette.primaryGradient,
                isSelected: selectedType == "consultation",
                tag: isOdia ? "ଲୋକପ୍ରିୟ" : "Popular",
                onTap: () => onTypeChanged("consultation"),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _feeCard(
                context,
                label: isOdia ? "ଫଲୋ-ଅପ୍" : "Follow-up",
                subtitle: isOdia ? "ପୁନଃ ଭିଜିଟ୍" : "Returning",
                icon: LucideIcons.refreshCcw,
                fee: followUpFee,
                gradient: LinearGradient(
                  colors: [AppPalette.teal500, AppPalette.teal700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                isSelected: selectedType == "follow_up",
                onTap: () => onTypeChanged("follow_up"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Trust note
        Row(
          children: [
            Icon(
              Icons.verified_user_rounded,
              size: 15,
              color: AppPalette.success500,
            ),
            const SizedBox(width: 6),
            Text(
              isOdia
                  ? "କୌଣସି ଲୁକ୍କାୟିତ ଚାର୍ଜ୍ ନାହିଁ"
                  : "No hidden charges · Pay at clinic",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _feeCard(
    BuildContext context, {
    required String label,
    required String subtitle,
    required IconData icon,
    required double fee,
    required Gradient gradient,
    required bool isSelected,
    required VoidCallback onTap,
    String? tag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1 : 0.72,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Decorative circles for depth
                Positioned(
                  right: -24,
                  top: -24,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -30,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 15, color: Colors.white),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          else if (tag != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            fee > 0 ? "₹${fee.toInt()}" : "—",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            isOdia ? "/ ଭିଜିଟ୍" : "/ visit",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
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
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
