import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/auth/login_screen.dart';
import 'package:my_new_app/screens/main_layout.dart';
import 'package:my_new_app/screens/admin/admin_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _auraController;

  late Animation<double> _logoScale;
  late Animation<double> _fadeText;
  late Animation<Offset> _slideText;

  // 🚀 ଷ୍ଟୋରେଜ୍ ଇନଷ୍ଟାନ୍ସ (Storage Instance)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    // Controls the initial entrance of the logo and text
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Controls the infinite "breathing" of the background aura
    _auraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.1, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideText = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _startSequence();
  }

  void _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _entranceController.forward();

    // Wait for animation, then route
    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) _checkAuthAndNavigate();
    });
  }

  // =========================================================================
  // 🚀 [SUPER SENIOR LOGIC]: ROLE-BASED ROUTING (Preserved)
  // =========================================================================
  Future<void> _checkAuthAndNavigate() async {
    try {
      String? authToken = await _storage.read(key: 'auth_token');
      String? adminToken = await _storage.read(key: 'admin_token');

      if (!mounted) return;

      if (adminToken != null && adminToken.isNotEmpty) {
        _navigateWithFade(const AdminLayout());
      } else if (authToken != null && authToken.isNotEmpty) {
        _navigateWithFade(const MainLayout());
      } else {
        _navigateWithFade(const LoginScreen());
      }
    } catch (e) {
      if (mounted) _navigateWithFade(const LoginScreen());
    }
  }

  void _navigateWithFade(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _auraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isDark = context.isDarkMode;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: context.theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // =========================================================
          // 1. THE LIQUID AURA BACKGROUND (Vibrant & Calming)
          // =========================================================
          AnimatedBuilder(
            animation: _auraController,
            builder: (context, child) {
              // Create a breathing effect with math.sin
              final breath = math.sin(_auraController.value * math.pi);

              return Stack(
                children: [
                  // Top Right - Vitality Blue
                  Positioned(
                    top: -100 + (breath * 20),
                    right: -50 - (breath * 10),
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(
                          0xFF2563EB,
                        ).withOpacity(isDark ? 0.3 : 0.2),
                      ),
                    ),
                  ),
                  // Center Left - Healing Teal
                  Positioned(
                    top:
                        MediaQuery.of(context).size.height * 0.3 -
                        (breath * 30),
                    left: -100 + (breath * 20),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(
                          0xFF059669,
                        ).withOpacity(isDark ? 0.3 : 0.15),
                      ),
                    ),
                  ),
                  // Bottom Right - Compassion Purple
                  Positioned(
                    bottom: 100 + (breath * 15),
                    right: -100,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(
                          0xFF7C3AED,
                        ).withOpacity(isDark ? 0.3 : 0.15),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Heavy Glass Blur over the orbs creates the mesh gradient effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),

          // =========================================================
          // 2. FOREGROUND CONTENT (Crisp & High Contrast)
          // =========================================================
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.theme.scaffoldBackgroundColor,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.15),
                          blurRadius: 40,
                          spreadRadius: 10,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/SoudaminiHealthcareLogo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.health_and_safety_rounded,
                        size: 60,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Animated Typography
                SlideTransition(
                  position: _slideText,
                  child: FadeTransition(
                    opacity: _fadeText,
                    child: Column(
                      children: [
                        Text(
                          "Soudamini",
                          style: context.displaySm?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          "Healthcare",
                          style: context.displaySm?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
                            letterSpacing: -1.0,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.1,
                            ),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            "YOUR HEALTH COMPANION",
                            style: context.labelSm?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // =========================================================
          // 3. BOTTOM FOOTER
          // =========================================================
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeText,
              child: Column(
                children: [
                  Text(
                    "Powered by",
                    style: context.labelSm?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Jivan Healthtech",
                        style: context.bodySm?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
