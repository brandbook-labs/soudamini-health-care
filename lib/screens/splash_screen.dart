import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 🚀 NEW: For Token Checking

import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/auth/login_screen.dart';
import 'package:my_new_app/screens/main_layout.dart'; // 🚀 NEW: For User Dashboard
import 'package:my_new_app/screens/admin/admin_layout.dart'; // 🚀 NEW: For Admin Dashboard

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _rippleController;

  late Animation<double> _logoScale;
  late Animation<double> _fadeText;
  late Animation<Offset> _slideText;

  // 🚀 ଷ୍ଟୋରେଜ୍ ଇନଷ୍ଟାନ୍ସ (Storage Instance)
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeText = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideText = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
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

    // 🚀 ଆନିମେସନ୍ ସରିବା ଯାଏଁ ଅପେକ୍ଷା କରନ୍ତୁ ଏବଂ ତା'ପରେ ଟୋକେନ୍ ଚେକ୍ କରନ୍ତୁ
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) _checkAuthAndNavigate();
    });
  }

  // =========================================================================
  // 🚀 [SUPER SENIOR LOGIC]: ROLE-BASED ROUTING
  // =========================================================================
  Future<void> _checkAuthAndNavigate() async {
    try {
      // ଦୁଇଟି ଯାକ ଟୋକେନ୍ ଚେକ୍ କରନ୍ତୁ
      String? authToken = await _storage.read(key: 'auth_token');
      String? adminToken = await _storage.read(key: 'admin_token');

      if (!mounted) return;

      // ୧. ପ୍ରଥମେ Admin ଚେକ୍ କରନ୍ତୁ (Admin Priority)
      if (adminToken != null && adminToken.isNotEmpty) {
        _navigateWithFade(
          const AdminLayout(),
        ); // ⚠️ ଏଠାରେ ଆପଣଙ୍କ ଆଡମିନ୍ ପେଜ୍ ର ନାମ ଦିଅନ୍ତୁ
      }
      // ୨. ତା'ପରେ User ଚେକ୍ କରନ୍ତୁ
      else if (authToken != null && authToken.isNotEmpty) {
        _navigateWithFade(const MainLayout());
      }
      // ୩. ଯଦି କେହିବି ଲଗଇନ୍ ନାହାଁନ୍ତି, ତେବେ ଲଗଇନ୍ ସ୍କ୍ରିନ୍ କୁ ନିଅନ୍ତୁ
      else {
        _navigateWithFade(const LoginScreen());
      }
    } catch (e) {
      // ଯଦି ଷ୍ଟୋରେଜ୍ ରେ କିଛି ଏରର୍ ଆସେ, ତେବେ ସୁରକ୍ଷା ଦୃଷ୍ଟିରୁ ଲଗଇନ୍ କୁ ପଠାଇ ଦିଅନ୍ତୁ
      if (mounted) _navigateWithFade(const LoginScreen());
    }
  }

  // 🚀 ରିୟୁଜେବଲ୍ (Reusable) ନାଭିଗେସନ୍ ଫଙ୍କସନ୍
  void _navigateWithFade(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... ଆପଣଙ୍କର ପୁରୁଣା ସମ୍ପୂର୍ଣ୍ଣ UI କୋଡ୍ ଏଠାରେ ରହିବ (କୌଣସି ପରିବର୍ତ୍ତନ ନାହିଁ) ...
    final colorScheme = context.colorScheme;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: context.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: context.theme.scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: context.isDarkMode
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: context.isDarkMode
                    ? [
                        colorScheme.surface,
                        context.theme.scaffoldBackgroundColor,
                      ]
                    : [
                        colorScheme.surface,
                        colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                      ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedBuilder(
                      animation: _rippleController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: PulseRipplePainter(
                            animationValue: _rippleController.value,
                            color: colorScheme.primary,
                          ),
                          child: const SizedBox(width: 300, height: 300),
                        );
                      },
                    ),
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 120,
                        height: 120,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 10,
                              offset: const Offset(0, 10),
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
                  ],
                ),
                context.gapXl,
                SlideTransition(
                  position: _slideText,
                  child: FadeTransition(
                    opacity: _fadeText,
                    child: Column(
                      children: [
                        Text(
                          "Soudamini Healthcare",
                          style: context.displaySm?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: -1.5,
                            height: 1.0,
                          ),
                        ),
                        context.gapSm,
                        Text(
                          "Your Health Companion",
                          style: context.bodyLg?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: AppSpacing.xxl,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeText,
              child: Column(
                children: [
                  Text(
                    "Powered by",
                    style: context.labelSm?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  context.gapXs,
                  Text(
                    "Jivan Healthtech",
                    style: context.titleMd?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
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

// ── RIPPLE PAINTER (Unchanged) ───────────────────────────────────────────────────────────
class PulseRipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  PulseRipplePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 3; i++) {
      final double startOffset = i * 0.33;
      final double adjustedValue = (animationValue + startOffset) % 1.0;
      final double radius = 60 + (adjustedValue * 90);
      final double opacity =
          (1.0 - adjustedValue) * 0.2 * math.sin(adjustedValue * math.pi);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(PulseRipplePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
