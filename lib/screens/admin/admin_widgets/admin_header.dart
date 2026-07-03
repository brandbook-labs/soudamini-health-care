import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Import Theme Context
import 'package:my_new_app/services/api_service.dart';

class AdminHeader extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? pageTitle; // 🚀 Added to support dynamic page titles

  const AdminHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.pageTitle,
  });

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

// 🚀 Added SingleTickerProviderStateMixin for the emergency animation
class _AdminHeaderState extends State<AdminHeader>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<Map<String, dynamic>?> _profileFuture;

  // Animation for the emergency pulse
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 🔔 NOTE: Set this to true dynamically based on your actual notification stream
  bool hasEmergency = true;

  @override
  void initState() {
    super.initState();
    // One time call to fetch profile/clinic details
    _profileFuture = _getProfileData();

    // Initialize the urgent pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (hasEmergency) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getProfileData() async {
    try {
      final response = await _apiService.getAdminProfile();
      if (response.data != null && response.data['data'] != null) {
        return response.data['data'];
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = context.colorScheme.outline.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        // border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- LEFT SIDE ---
          Expanded(
            child: Row(
              children: [
                // A. Back Button OR Profile Image
                if (widget.showBackButton)
                  GestureDetector(
                    onTap: widget.onBack ?? () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor),
                      ),
                      child: Icon(
                        LucideIcons.arrowLeft,
                        color: context.colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  )
                else
                  FutureBuilder<Map<String, dynamic>?>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final data = snapshot.data;
                      final String name = data?['name'] ?? "Admin";
                      final String? imageUrl = data?['logo'];

                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(color: borderColor),
                          image: DecorationImage(
                            image: NetworkImage(
                              imageUrl ??
                                  "https://ui-avatars.com/api/?name=$name&background=074EE7&color=fff",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(width: 12),

                // B. Text Info (Dynamic depending on page)
                Expanded(
                  child: widget.showBackButton && widget.pageTitle != null
                      // Sub-page View (e.g., Analytics, Clinics)
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Go Back",
                              style: context.text.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              widget.pageTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        )
                      // Dashboard View (Welcome + Name + Role Pill)
                      : FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            final data = snapshot.data;
                            final String name = data?['name'] ?? "Admin";
                            final String role =
                                data?['role'] ?? "Administrator"; // Fallback role

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Welcome,",
                                  style: context.text.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                Row(
                                  children: [
                                    // 🚀 Wrap the name in Flexible to prevent overflow
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 🚀 Role Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: context.colorScheme.primary
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: context.text.labelSmall
                                            ?.copyWith(
                                              color:
                                                  context.colorScheme.primary,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // --- RIGHT SIDE (Emergency Notification) ---
          GestureDetector(
            onTap: () {
              // Handle Admin Notifications
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasEmergency
                      ? Colors.red.withValues(alpha: 0.5)
                      : borderColor,
                ),
                boxShadow: [
                  if (!context.isDarkMode)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.bell,
                    color: hasEmergency
                        ? Colors.red
                        : context.colorScheme.onSurface,
                    size: 22,
                  ),
                  // 🚀 Emergency Pulse Dot
                  if (hasEmergency)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}