import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- THEME CONSTANTS (From your main.dart) ---
const Color kPrimaryColor = Color.fromARGB(255, 7, 78, 231);
const Color kPrimaryAccessibleDark = Color.fromARGB(255, 4, 61, 231);
const Color kDarkBg = Color.fromARGB(255, 14, 14, 14);
const Color kDarkCard = Color.fromARGB(255, 25, 25, 25);
const Color kLightCard = Colors.white;

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  // --- PLAN DATA (Updated with Boost & Graphics) ---
  final List<Map<String, dynamic>> _plans = [
    {
      "name": "STARTER",
      "price": "FREE",
      "period": "Forever",
      "desc": "Perfect for new clinics.",
      "features": [
        "Full clinic listing on Jivan App.",
        "Manage doctor profiles.",
        "Basic patient attraction tools.",
        "Standard search visibility.",
      ],
      "btnText": "Start for Free",
      "type": "standard",
    },
    {
      "name": "GROWTH",
      "price": "₹1000",
      "period": "/ month",
      "desc": "Accelerate your patient reach.",
      "features": [
        "🚀 2x Visibility Boost in Search.",
        "🎨 3 Customized Social Media Posts/mo.",
        "Manage offline/walk-in bookings.",
        "Smart QR Code Registration.",
      ],
      "btnText": "Upgrade to Growth",
      "type": "recommended", // Highlighted Blue
      "tag": "MOST POPULAR",
    },
    {
      "name": "PARTNER",
      "price": "₹15,000",
      "period": "/ month",
      "desc": "For established brands.",
      "features": [
        "Everything in Growth, plus: ",
        "🚀 Top Rank in Area Listings.",
        "🎨 15 + Festives Customized Social Media Posts/mo.",
        "In-house Lab Orders, Medicine Management.",
      ],
      "btnText": "Become a Partner",
      "type": "standard",
    },
    {
      "name": "LIFETIME",
      "price": "₹2L",
      "period": "One-time + ₹1000/yr",
      "desc": "The ultimate enterprise solution.",
      "features": [
        "👑 Featured on Jivan Home Screen.",
        "🎨 Unlimited Marketing Design Support.",
        "Custom Domain (www.myclinic.com).",
        "White-label website & app listing.",
        "Priority Server Access.",
        "Dedicated Account Manager.",
      ],
      "btnText": "Contact Sales",
      "type": "premium", // Highlighted Dark/Gold
      "tag": "EXCLUSIVE",
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    final currentPlan = _plans[_currentIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Choose Your Plan",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: textColor),
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // --- 1. HEADER TEXT ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                Text(
                  "Scale with Jivan.",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Get premium visibility and marketing support to grow your practice.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- 2. CAROUSEL ---
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final bool isActive = index == _currentIndex;
                return AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: isActive ? 0 : 20,
                  ),
                  child: _SubscriptionCard(
                    data: _plans[index],
                    isActive: isActive,
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),

      // --- 3. DYNAMIC BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_plans.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentIndex == index ? 24 : 6,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? kPrimaryColor
                          : (isDarkMode
                                ? Colors.white24
                                : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Dynamic Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Selected: ${currentPlan['name']}"),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: kPrimaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentPlan['btnText'].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 20),
                    ],
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

// --- WIDGET: INDIVIDUAL PLAN CARD ---
class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  final bool isDarkMode;

  const _SubscriptionCard({
    required this.data,
    required this.isActive,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Card Style Logic
    final type = data['type'];
    final bool isRecommended = type == 'recommended';
    final bool isPremium = type == 'premium';

    // Base Colors
    Color bgColor;
    Color textColor;
    Color subTextColor;
    Color iconColor;
    Color borderColor;

    if (isRecommended) {
      // GROWTH PLAN: Blue Background
      bgColor = kPrimaryColor;
      textColor = Colors.white;
      subTextColor = Colors.white.withValues(alpha: 0.8);
      iconColor = Colors.white;
      borderColor = kPrimaryColor;
    } else if (isPremium) {
      // LIFETIME PLAN: Dark Slate Background
      bgColor = isDarkMode ? kDarkCard : const Color(0xFF1E293B);
      textColor = Colors.white;
      subTextColor = Colors.white70;
      iconColor = const Color(0xFFFFD700); // Gold
      borderColor = isDarkMode ? Colors.white10 : Colors.transparent;
    } else {
      // STANDARD PLAN
      bgColor = isDarkMode ? kDarkCard : kLightCard;
      textColor = isDarkMode ? Colors.white : Colors.black87;
      subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
      iconColor = kPrimaryColor;
      borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? borderColor : borderColor.withValues(alpha: 0.5),
          width: isActive ? 2 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: isRecommended
                  ? kPrimaryColor.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Circle for Recommended/Premium
          if (isRecommended || isPremium)
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TOP BADGE (Optional) ---
                if (data['tag'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isRecommended
                          ? Colors.white.withValues(alpha: 0.2)
                          : (isPremium
                                ? const Color(0xFFFFD700)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      data['tag'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? Colors.black : textColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 34), // Spacer if no tag
                // --- PLAN NAME ---
                Text(
                  data['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: subTextColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),

                // --- PRICE ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      data['price'],
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data['period'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: subTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Text(
                  data['desc'],
                  style: TextStyle(
                    fontSize: 14,
                    color: subTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 24),
                Divider(
                  color: isRecommended || isPremium
                      ? Colors.white24
                      : (isDarkMode ? Colors.white10 : Colors.grey.shade200),
                ),
                const SizedBox(height: 24),

                // --- FEATURES LIST ---
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: (data['features'] as List<String>).map((feat) {
                        // Check if feature is a "Premium/Boost" feature for bolding
                        final bool isSpecial =
                            feat.contains("Boost") ||
                            feat.contains("Graphics") ||
                            feat.contains("Featured");

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                LucideIcons.checkCircle2,
                                size: 20,
                                color: iconColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feat,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textColor,
                                    fontWeight: isSpecial
                                        ? FontWeight.bold
                                        : FontWeight
                                              .w500, // Bold special features
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
