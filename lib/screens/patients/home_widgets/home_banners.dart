import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:provider/provider.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeBanners extends StatefulWidget {
  const HomeBanners({super.key});

  @override
  State<HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<HomeBanners> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // --- REFINED DATA SOURCE (3 High-Impact Banners) ---
  final List<Map<String, dynamic>> _bannerData = [
    {
      "id": "top_specialists",
      "icon": LucideIcons.stethoscope,
      "color": const Color(0xFF2563EB), // Primary Blue
      "image_url":
          "https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=800&q=80",
    },
    {
      "id": "video_consult",
      "icon": LucideIcons.video,
      "color": const Color(0xFF7C3AED), // Premium Purple
      "image_url":
          "https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80",
    },
    {
      "id": "preventive_check",
      "icon": LucideIcons.activity,
      "color": const Color(0xFF059669), // Wellness Green
      "image_url":
          "https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80",
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

    // Cinematic aspect ratio height (Fixed height ensures consistent layout)
    final double bannerHeight = 180.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int index) => setState(() => _currentPage = index),
            itemCount: _bannerData.length,
            itemBuilder: (context, index) {
              final data = _bannerData[index];
              final texts = _getLocalizedTexts(data['id'], isOdia);

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                child: _buildCinematicBanner(
                  context,
                  title: texts['title']!,
                  subtitle: texts['subtitle']!,
                  btnText: texts['btnText']!,
                  badgeText: texts['badgeText']!,
                  themeColor: data['color'],
                  icon: data['icon'],
                  imageUrl: data['image_url'],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // --- MODERN INDICATOR DOTS ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerData.length, (index) {
            final isActive = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: isActive ? 24 : 6,
              decoration: BoxDecoration(
                color: isActive
                    ? context.colorScheme.primary
                    : context.colorScheme.outlineVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(100),
              ),
            );
          }),
        ),
      ],
    );
  }

  Map<String, String> _getLocalizedTexts(String id, bool isOdia) {
    switch (id) {
      case 'top_specialists':
        return {
          'title': isOdia ? "ଶୀର୍ଷ ବିଶେଷଜ୍ଞ" : "Top Specialists",
          'subtitle': isOdia
              ? "ଅଭିଜ୍ଞ ଡାକ୍ତରଙ୍କ ସହିତ ପରାମର୍ଶ କରନ୍ତୁ"
              : "Book appointments with top-rated doctors.",
          'btnText': isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book Now",
          'badgeText': "TRUSTED CARE",
        };
      case 'video_consult':
        return {
          'title': isOdia ? "ଭିଡିଓ ପରାମର୍ଶ" : "Video Consult",
          'subtitle': isOdia
              ? "ଘରେ ବସି ଡାକ୍ତରଙ୍କୁ ଦେଖାନ୍ତୁ"
              : "Talk to specialists from your home.",
          'btnText': isOdia ? "ପରାମର୍ଶ କରନ୍ତୁ" : "Consult Now",
          'badgeText': "INSTANT",
        };
      case 'preventive_check':
        return {
          'title': isOdia ? "ସ୍ୱାସ୍ଥ୍ୟ ଯାଞ୍ଚ" : "Health Checkup",
          'subtitle': isOdia
              ? "ସୁସ୍ଥ ରୁହନ୍ତୁ, ସଜାଗ ରୁହନ୍ତୁ"
              : "Comprehensive full body checkups.",
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

  Widget _buildCinematicBanner(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String btnText,
    required String badgeText,
    required Color themeColor,
    required IconData icon,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.roundedLg ?? BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: themeColor),
          ),

          // 2. Cinematic Dark Gradient Overlay
          // Ensures perfect white text readability regardless of the image behind it
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withOpacity(0.85), // Dark on left for text
                  Colors.black.withOpacity(0.4),
                  Colors.transparent, // Fades out on the right
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minimalist Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Title
                Text(
                  title,
                  maxLines: 1,
                  style: context.titleLg?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    fontSize: 22,
                  ),
                ),

                const SizedBox(height: 4),

                // Subtitle
                SizedBox(
                  width:
                      MediaQuery.of(context).size.width *
                      0.55, // Prevents text from going too far right
                  child: Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySm?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ),

                const Spacer(),

                // Action Button (Glassmorphism inspired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        btnText,
                        style: TextStyle(
                          color: themeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 14, color: themeColor),
                    ],
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
