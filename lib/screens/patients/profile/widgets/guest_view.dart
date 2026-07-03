// lib/screens/patients/profile/widgets/guest_view.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/screens/auth/login_screen.dart';

class GuestView extends StatelessWidget {
  final VoidCallback onLoginSuccess;

  const GuestView({super.key, required this.onLoginSuccess});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Premium SaaS Colors
    const slate900 = Color(0xFF0F172A);
    const slate500 = Color(0xFF64748B);
    const slate50 = Color(0xFFF8FAFC);
    const slate200 = Color(0xFFE2E8F0);

    return Container(
      color: Colors.white, // Pure white background
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 1. HERO GRAPHIC ---
              Container(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons
                        .shieldCheck, // Swapped lock for a more positive "Secure/Protected" icon
                    size: 48,
                    color: colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. TYPOGRAPHY ---
              const Text(
                "Your Health, Unlocked",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: slate900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sign in to book appointments, access your medical records, and stay on top of your health.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: slate500,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // --- 3. PREMIUM FEATURE BOX ---
              Container(
                decoration: BoxDecoration(
                  color:
                      slate50, // Soft grey background instead of harsh white box
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: slate200),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFeatureRow(
                      colorScheme,
                      icon: LucideIcons.calendarCheck,
                      title: "Manage Appointments",
                      subtitle: "Book & track doctor visits instantly",
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, indent: 56, color: slate200),
                    ),
                    _buildFeatureRow(
                      colorScheme,
                      icon: LucideIcons.folderHeart,
                      title: "Medical Records",
                      subtitle: "Securely store your prescriptions",
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, indent: 56, color: slate200),
                    ),
                    _buildFeatureRow(
                      colorScheme,
                      icon: LucideIcons.bellRing,
                      title: "Smart Reminders",
                      subtitle: "Never miss a pill or lab test",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- 4. CALL TO ACTION ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    ).then(
                      (_) => onLoginSuccess(),
                    ); // 🚀 ଫେରିବା ପରେ ଷ୍ଟାଟସ୍ ଚେକ୍
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0, // Flat design
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Softer, modern radius
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "Login or Sign Up",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary subtle action if needed, or just safe space
              const Text(
                "Takes less than 30 seconds",
                style: TextStyle(
                  color: slate500,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- INTERNAL FEATURE ROW BUILDER ---
  // Replaced the external GuestBenefitRow dependency here so we have absolute control over the spacing and colors.
  Widget _buildFeatureRow(
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2), // Visual alignment
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
