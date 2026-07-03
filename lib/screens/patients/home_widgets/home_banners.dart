import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:provider/provider.dart';
import 'package:my_new_app/controllers/language_controller.dart';

class HomeBanners extends StatefulWidget {
  const HomeBanners({super.key});

  @override
  State<HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<HomeBanners> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // --- DATA SOURCE (Unchanged) ---
  final List<Map<String, dynamic>> _bannerData = [
    {
      "id": "doctor_discount",
      "colorStart": const Color(0xFF2563EB),
      "colorEnd": const Color(0xFF60A5FA),
      "icon": Icons.confirmation_number_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=400&q=80",
    },
    {
      "id": "top_specialists",
      "colorStart": const Color(0xFF0F172A),
      "colorEnd": const Color(0xFF334155),
      "icon": Icons.verified_user_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80",
    },
    {
      "id": "video_consult",
      "colorStart": const Color(0xFF7C3AED),
      "colorEnd": const Color(0xFFA78BFA),
      "icon": Icons.video_camera_front_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=400&q=80",
    },
    {
      "id": "clinic_visit",
      "colorStart": const Color(0xFFEA580C),
      "colorEnd": const Color(0xFFFB923C),
      "icon": Icons.location_on_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&q=80",
    },
    {
      "id": "dental_care",
      "colorStart": const Color(0xFF0891B2),
      "colorEnd": const Color(0xFF22D3EE),
      "icon": Icons.health_and_safety_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1606811841689-23dfddce3e95?w=400&q=80",
    },
    {
      "id": "preventive_check",
      "colorStart": const Color(0xFF059669),
      "colorEnd": const Color(0xFF34D399),
      "icon": Icons.monitor_heart_outlined,
      "image_url":
          "https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&q=80",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % _bannerData.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    // 🔥 ADJUSTED HEIGHT: Compact
    // Min: 140px (Small enough for tight spaces)
    // Max: 210px (Stops it from getting huge)
    final double bannerHeight = context.percentHeight(0.18).clamp(140.0, 210.0);

    return SizedBox(
      height: bannerHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) => setState(() => _currentPage = index),
            itemCount: _bannerData.length,
            itemBuilder: (context, index) {
              final data = _bannerData[index];
              final texts = _getLocalizedTexts(data['id'], isOdia);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                child: _buildModernBanner(
                  context,
                  title: texts['title']!,
                  subtitle: texts['subtitle']!,
                  btnText: texts['btnText']!,
                  badgeText: texts['badgeText']!,
                  startColor: data['colorStart'],
                  endColor: data['colorEnd'],
                  icon: data['icon'],
                  imageUrl: data['image_url'],
                  height: bannerHeight,
                ),
              );
            },
          ),

          // --- INDICATOR DOTS ---
          Positioned(
            bottom: 8, // Fixed small bottom spacing
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerData.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 3, // Thinner dots
                  width: _currentPage == index ? 16 : 4,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.35),
                    borderRadius: context.roundedFull,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ... (Localization Map Unchanged) ...
  Map<String, String> _getLocalizedTexts(String id, bool isOdia) {
    switch (id) {
      case 'doctor_discount':
        return {
          'title': isOdia ? "୫ ଜଣଙ୍କୁ ବୁକିଂ ରିହାତି" : "Daily Booking Discounts",
          'subtitle': isOdia
              ? "ପ୍ରତିଦିନ ୫ ଜଣ ଭାଗ୍ୟଶାଳୀ ରୋଗୀ"
              : "For 5 Lucky Patients Daily",
          'btnText': isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Claim Now",
          'badgeText': "LUCKY DRAW",
        };
      case 'top_specialists':
        return {
          'title': isOdia ? "ଶୀର୍ଷ ବିଶେଷଜ୍ଞ" : "Top Specialists",
          'subtitle': isOdia
              ? "ଅଭିଜ୍ଞ ଡାକ୍ତରଙ୍କ ସହିତ ପରାମର୍ଶ କରନ୍ତୁ"
              : "Consult with Senior Doctors",
          'btnText': isOdia ? "ଦେଖନ୍ତୁ" : "View All",
          'badgeText': "TRUSTED CARE",
        };
      case 'video_consult':
        return {
          'title': isOdia ? "ଭିଡିଓ ପରାମର୍ଶ" : "Video Consult",
          'subtitle': isOdia
              ? "ଘରେ ବସି ଡାକ୍ତରଙ୍କୁ ଦେଖାନ୍ତୁ"
              : "Talk to Doctors Anywhere",
          'btnText': isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book Now",
          'badgeText': "EASY ACCESS",
        };
      case 'clinic_visit':
        return {
          'title': isOdia ? "କ୍ଲିନିକ୍ ପରିଦର୍ଶନ" : "Clinic Visit",
          'subtitle': isOdia
              ? "ଆପଣଙ୍କ ନିକଟସ୍ଥ କ୍ଲିନିକ୍"
              : "Find Clinics Near You",
          'btnText': isOdia ? "ଖୋଜନ୍ତୁ" : "Find Now",
          'badgeText': "NEARBY",
        };
      case 'dental_care':
        return {
          'title': isOdia ? "ଦାନ୍ତ ଯାଞ୍ଚ" : "Dental Checkup",
          'subtitle': isOdia
              ? "ମାଗଣା ପରାମର୍ଶ ପାଆନ୍ତୁ"
              : "Get Free Consultation",
          'btnText': isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book Now",
          'badgeText': "SPECIAL DEAL",
        };
      case 'preventive_check':
        return {
          'title': isOdia ? "ପ୍ରତିଷେଧକ ଯାଞ୍ଚ" : "Preventive Check",
          'subtitle': isOdia
              ? "ସୁସ୍ଥ ରୁହନ୍ତୁ, ସଜାଗ ରୁହନ୍ତୁ"
              : "Stay Healthy, Stay Alert",
          'btnText': isOdia ? "ପ୍ୟାକେଜ୍ ଦେଖନ୍ତୁ" : "View Packages",
          'badgeText': "WELLNESS",
        };
      default:
        return {
          'title': "Health Offer",
          'subtitle': "Explore our services",
          'btnText': "View",
          'badgeText': "OFFER",
        };
    }
  }

  Widget _buildModernBanner(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String btnText,
    required String badgeText,
    required Color startColor,
    required Color endColor,
    required IconData icon,
    required String imageUrl,
    required double height,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;

        return Container(
          // 🔥 Reduced Padding to prevent overflow on small screens
          padding: EdgeInsets.fromLTRB(
            context.spaceMd,
            8.0, // Top padding reduced securely
            context.spaceMd,
            24.0, // Bottom padding to keep space for dots
          ),
          decoration: BoxDecoration(
            borderRadius: context.roundedSm,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
            boxShadow: context.shadowSm,
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Background Deco Circle
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                  radius: height * 0.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                ),
              ),

              Row(
                children: [
                  // --- TEXT COLUMN ---
                  Expanded(
                    flex: isNarrow ? 4 : 3,
                    // 🚀 THE MAGIC FIX: Align + SingleChildScrollView completely eliminates yellow lines (overflow)
                    // It acts as a safety wrapper. Text wraps nicely, but if it exceeds height, it safely clips!
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                          mainAxisSize: MainAxisSize.min, // Hug content
                          children: [
                            // Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4, // 🚀 Slightly reduced for tight spaces
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: context.roundedSm,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: Colors.white, size: 10),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      badgeText.toUpperCase(),
                                      style: context.labelSm?.copyWith(
                                        color: Colors.white,
                                        fontSize: 10, // Smaller font
                                        letterSpacing: 0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 4), // 🚀 Tight gap

                            // Title
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.headlineLg?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18, // 🚀 Enforce slightly smaller safe size
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 4), // 🚀 Tight gap

                            // Subtitle
                            Text(
                              subtitle,
                              maxLines: 1, // Limit to 1 line for compactness
                              overflow: TextOverflow.ellipsis,
                              style: context.bodySm?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.2,
                              ),
                            ),

                            const SizedBox(height: 6), // 🚀 Tight gap

                            // CTA Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5, // Compact vertical padding
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: context.roundedFull,
                              ),
                              child: Text(
                                btnText,
                                style: context.labelSm?.copyWith(
                                  color: startColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11, // Smaller font
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // --- IMAGE COLUMN ---
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: context.roundedSm,
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}