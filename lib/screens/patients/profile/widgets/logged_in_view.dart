// lib/screens/patients/profile/widgets/logged_in_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/screens/patients/appointments/my_appointments_screen.dart';
import 'package:my_new_app/screens/patients/edit_profile_screen.dart';
import 'package:my_new_app/screens/patients/medical_records/manage_records_screen.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import '../profile_settings_screen.dart';

class LoggedInView extends StatelessWidget {
  final UserProvider userProvider;
  final bool isBiometricEnabled;
  final Function(bool) onToggleBiometrics;
  final VoidCallback onLogout;
  final VoidCallback onProfileUpdated;

  const LoggedInView({
    super.key,
    required this.userProvider,
    required this.isBiometricEnabled,
    required this.onToggleBiometrics,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  @override
  Widget build(BuildContext context) {
    String userName = userProvider.userName;
    final String userPhone = userProvider.userPhone;
    final String userAvatarUrl = userProvider.userProfileImage;

    final bool isNameEmpty =
        userName.trim().isEmpty || userName.toLowerCase() == "guest";
    if (isNameEmpty) userName = "Guest\nUser.";

    // Split name for dramatic typography (first name on one line, last name on another if possible)
    final nameParts = userName.split(' ');
    final dramaticName = nameParts.length > 1
        ? '${nameParts[0]}\n${nameParts.sublist(1).join(' ')}.'
        : '$userName.';

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      // 1. THE AMBIENT GLOW BACKGROUND
      body: Stack(
        children: [
          // Top Right Glow (Primary Color)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.primary.withOpacity(0.15),
              ),
            ),
          ),
          // Bottom Left Glow (Purple/Secondary)
          Positioned(
            top: 300,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF7C3AED), // Vibrant Purple
              ),
            ),
          ),
          // The Glass Layer covering the glows
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // 2. THE EDITORIAL CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dramatic Typography
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.onSurface,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  "VERIFIED PATIENT",
                                  style: TextStyle(
                                    color:
                                        context.theme.scaffoldBackgroundColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                dramaticName,
                                style: context.text.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                  letterSpacing: -2.0,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // High-tech phone badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: context.colorScheme.outlineVariant,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  userPhone,
                                  style: context.text.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontFamily:
                                        'monospace', // Adds a cool tech vibe
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Oversized Avatar
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          ).then((_) => onProfileUpdated()),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.colorScheme.primary
                                        .withOpacity(0.5),
                                    width: 4,
                                  ),
                                  image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: userAvatarUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            userAvatarUrl,
                                          )
                                        : const NetworkImage(
                                                "https://ui-avatars.com/api/?name=User&background=random",
                                              )
                                              as ImageProvider,
                                  ),
                                ),
                              ),
                              // Edit Floating Action
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.colorScheme.primary
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  LucideIcons.pencil,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // --- DRAMATIC ACTION CARDS ---

                    // 1. Hero Action Card (Appointments)
                    _EditorialCard(
                      title: "Appointments",
                      subtitle: "Manage your upcoming visits",
                      icon: LucideIcons.calendarClock,
                      accentColor: context.colorScheme.primary,
                      isDarkFilled: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAppointmentsScreen(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. Twin Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _EditorialCard(
                            title: "Records",
                            subtitle: "Labs & Rx",
                            icon: LucideIcons.folderHeart,
                            accentColor: const Color(0xFF7C3AED),
                            height: 160,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageRecordsScreen(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _EditorialCard(
                            title: "Medicines",
                            subtitle: "Coming Soon",
                            icon: LucideIcons.pill,
                            accentColor: const Color(0xFF059669),
                            height: 160,
                            isMuted: true,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 3. Settings Horizontal Strip
                    _EditorialStrip(
                      title: "App Settings & Security",
                      icon: LucideIcons.fingerprint,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileSettingsScreen(
                            isBiometricEnabled: isBiometricEnabled,
                            onToggleBiometrics: onToggleBiometrics,
                            onLogout: onLogout,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 4. Logout Strip
                    _EditorialStrip(
                      title: "Log Out",
                      icon: LucideIcons.power,
                      isDestructive: true,
                      onTap: onLogout,
                    ),

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DRAMATIC UI COMPONENTS
// ============================================================================

/// A bold, magazine-style card with an oversized, clipped background icon.
class _EditorialCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool isDarkFilled;
  final bool isMuted;
  final double height;
  final VoidCallback onTap;

  const _EditorialCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.isDarkFilled = false,
    this.isMuted = false,
    this.height = 140,
  });

  @override
  State<_EditorialCard> createState() => _EditorialCardState();
}

class _EditorialCardState extends State<_EditorialCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.theme.brightness == Brightness.dark;

    // Determine colors based on style
    final Color bgColor = widget.isDarkFilled
        ? widget.accentColor
        : (isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.6));

    final Color textColor = widget.isDarkFilled
        ? Colors.white
        : context.colorScheme.onSurface;

    final Color subTextColor = widget.isDarkFilled
        ? Colors.white70
        : context.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Glassmorphism
            child: Container(
              height: widget.height,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: widget.isMuted ? bgColor.withOpacity(0.2) : bgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: widget.isDarkFilled
                      ? Colors.transparent
                      : Colors.white.withOpacity(isDarkMode ? 0.1 : 0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // --- THE OVERSIZED WATERMARK ICON ---
                  Positioned(
                    right: -30,
                    bottom: -30,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Icon(
                        widget.icon,
                        size: widget.height * 0.9,
                        color: widget.isDarkFilled
                            ? Colors.black.withOpacity(0.15)
                            : widget.accentColor.withOpacity(0.1),
                      ),
                    ),
                  ),

                  // --- THE CONTENT ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        widget.icon,
                        color: widget.isMuted
                            ? subTextColor.withOpacity(0.5)
                            : textColor,
                        size: 28,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subtitle.toUpperCase(),
                            style: TextStyle(
                              color: widget.isMuted
                                  ? subTextColor.withOpacity(0.5)
                                  : subTextColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.title,
                            style: context.text.titleLarge?.copyWith(
                              color: widget.isMuted
                                  ? textColor.withOpacity(0.5)
                                  : textColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A sleek, minimalistic horizontal strip for actions like Settings and Logout.
class _EditorialStrip extends StatefulWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _EditorialStrip({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_EditorialStrip> createState() => _EditorialStripState();
}

class _EditorialStripState extends State<_EditorialStrip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? context.colorScheme.error
        : context.colorScheme.onSurface;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: widget.isDestructive
                ? color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isDestructive
                  ? color.withOpacity(0.3)
                  : context.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: color, size: 22),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: context.text.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Icon(
                LucideIcons.arrowRight,
                color: color.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
