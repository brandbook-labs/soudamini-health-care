import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/screens/patients/notifications_screen.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';

class HomeHeader extends StatefulWidget {
  final int currentIndex;
  final VoidCallback onBackTap;

  const HomeHeader({
    super.key,
    required this.currentIndex,
    required this.onBackTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().initializeData(context);
    });
  }

  /// 🚀 SMART UX: Dynamic Time-Based Greeting
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning 👋";
    if (hour < 17) return "Good Afternoon ☀️";
    if (hour < 21) return "Good Evening 🌙";
    return "Good Night 💤";
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final String userName = userProvider.userName.isNotEmpty
        ? userProvider.userName
        : "Guest";
    final String userProfileImage = userProvider.userProfileImage;

    final bool isHome = widget.currentIndex == 0;

    // 🚀 Dynamic Contextual Titles
    String subtitle = "";
    String title = "";

    switch (widget.currentIndex) {
      case 0:
        subtitle = _getTimeBasedGreeting();
        title = userName;
        break;
      case 1:
        subtitle = "Specialists";
        title = "Find Doctors";
        break;
      case 2:
        subtitle = "Healthcare";
        title = "Nearby Clinics";
        break;
      case 3:
        subtitle = "Diagnostics";
        title = "Pathology Labs";
        break;
      case 4:
        subtitle = "Account";
        title = "My Profile";
        break;
      default:
        subtitle = "Welcome";
        title = "Soudamini Health";
    }

    return SafeArea(
      bottom: false,
      child: Container(
        color: context.theme.scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ---------------------------------------------------------
            // 1. SMART AVATAR / BACK BUTTON
            // ---------------------------------------------------------
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isHome
                  ? _buildProfileAvatar(context, userProfileImage, userName)
                  : _buildBackButton(context),
            ),

            const SizedBox(width: 16),

            // ---------------------------------------------------------
            // 2. DYNAMIC TEXT HIERARCHY
            // ---------------------------------------------------------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Muted Contextual Subtitle
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      subtitle,
                      key: ValueKey<String>("sub_$subtitle"),
                      style: context.text.labelMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Bold Primary Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      title,
                      key: ValueKey<String>("title_$title"),
                      style: context.text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: context.colorScheme.onSurface,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ---------------------------------------------------------
            // 3. PREMIUM NOTIFICATION ACTION
            // ---------------------------------------------------------
            _buildNotificationBell(context),
          ],
        ),
      ),
    );
  }

  // --- SUB-COMPONENTS FOR CLEAN CODE ---

  Widget _buildProfileAvatar(
    BuildContext context,
    String imageUrl,
    String name,
  ) {
    return Stack(
      key: const ValueKey('avatar'),
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.primary.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: JivanAvatar(
            size: 48,
            imageUrl: imageUrl.isNotEmpty
                ? imageUrl
                : 'https://ui-avatars.com/api/?name=$name&background=random',
            name: name,
          ),
        ),
        // Smart "Online" / Active Indicator
        Positioned(
          bottom: 0,
          right: 2,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: context.semantic.success ?? Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.theme.scaffoldBackgroundColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      key: const ValueKey('back_btn'),
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onBackTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.surface,
            border: Border.all(
              color: context.colorScheme.outlineVariant.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Icon(
            LucideIcons.arrowLeft,
            color: context.colorScheme.onSurface,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
        ),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Soft background for a modern glass/neumorphic feel
            color: context.colorScheme.onSurface.withOpacity(0.04),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                LucideIcons.bell,
                color: context.colorScheme.onSurface,
                size: 22,
              ),
              // Unread Badge
              Positioned(
                right: 12,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colorScheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.theme.scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
