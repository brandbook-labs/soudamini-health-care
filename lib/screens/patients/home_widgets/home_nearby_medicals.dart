import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart'; 
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart'; 
import 'package:share_plus/share_plus.dart'; 

import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/clinics_listing_screen.dart';

import '../providers/clinic_provider.dart';
import '../path/to/clinic_card_widget.dart';

class HomeNearbyMedicals extends StatefulWidget {
  const HomeNearbyMedicals({super.key});
  @override
  State<HomeNearbyMedicals> createState() => _HomeNearbyMedicalsState();
}

class _HomeNearbyMedicalsState extends State<HomeNearbyMedicals> {
  // 🚀 UserProvider କୁ ଟ୍ରାକ୍ କରିବା ପାଇଁ ଭେରିଏବଲ୍
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    
    // ୧. UserProvider କୁ ରେଫରେନ୍ସ କରନ୍ତୁ ଏବଂ Listener ଲଗାନ୍ତୁ
    _userProvider = context.read<UserProvider>();
    _userProvider.addListener(_syncLocationWithClinicProvider);

    // ୨. ସ୍କ୍ରିନ୍ ଲୋଡ୍ ହେବା ମାତ୍ରେ ଥରେ ସିଙ୍କ୍ (Sync) କରନ୍ତୁ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationWithClinicProvider();
    });
  }

  @override
  void dispose() {
    // ୩. Listener ହଟାନ୍ତୁ
    _userProvider.removeListener(_syncLocationWithClinicProvider);
    super.dispose();
  }

  // =========================================================================
  // 🚀 SUPER SENIOR LOGIC: The Perfect Sync 
  // =========================================================================
  void _syncLocationWithClinicProvider() {
    // ଯଦି ଲୋକେସନ୍ ଆସୁଛି ତେବେ ଅପେକ୍ଷା କରନ୍ତୁ
    if (_userProvider.isLoadingLocation || _userProvider.isLoadingProfile) return;

    // ପରଫେକ୍ଟ୍ ବ୍ୟାକଅପ୍: City -> District -> Profile Address
    String fallback = _userProvider.city;
    if (fallback.isEmpty) fallback = _userProvider.district;
    if (fallback.isEmpty) fallback = _userProvider.userSavedAddress;

    // 🚀 ଏବେ ClinicProvider କୁ ପରଫେକ୍ଟ୍ ଡାଟା ପଠାନ୍ତୁ! 
    context.read<ClinicProvider>().updateLocationFromUserProvider(
      lat: _userProvider.latitude,
      lng: _userProvider.longitude,
      fallbackLocation: fallback,
    );
  }

  void _shareApp(bool isOdia) {
    HapticFeedback.mediumImpact();

    final String shareMessage = isOdia
        ? "ଜୀବନ ହେଲଥ୍ ଆପ୍ ବ୍ୟବହାର କରନ୍ତୁ! ଆପଣଙ୍କ ନିକଟସ୍ଥ ଶ୍ରେଷ୍ଠ ମେଡିକାଲ୍ ଏବଂ କ୍ଲିନିକ୍ ଖୋଜନ୍ତୁ। ଏବେ ଡାଉନଲୋଡ୍ କରନ୍ତୁ: https://play.google.com/store/apps/details?id=com.jivan.health"
        : "Check out Jivan Health App! Find and book the best clinics and medicals near you. Download now: https://play.google.com/store/apps/details?id=com.jivan.health";

    Share.share(shareMessage);
  }

  @override
  Widget build(BuildContext context) {
    final isOdia = context.watch<LanguageController>().currentLocale.languageCode == 'or';
    
    final provider = context.watch<ClinicProvider>();
    final userProvider = context.watch<UserProvider>(); // 🚀 ଲୋଡିଂ ଟ୍ରାକ୍ କରିବା ପାଇଁ
    
    final clinics = provider.clinics.take(5).toList();
    
    // 🚀 ଏକାସାଙ୍ଗରେ ଉଭୟ ପ୍ରୋଭାଇଡର୍ ର ଲୋଡିଂ ଷ୍ଟେଟ୍ ଚେକ୍ କରନ୍ତୁ
    final isPageLoading = provider.isFirstLoading || userProvider.isLoadingLocation;

    return Column(
      children: [
        JivanSectionHeader(
          title: isOdia ? "ନିକଟସ୍ଥ ମେଡିକାଲ୍" : "Nearby Medicals",
          subtitle: isOdia ? "ଜରୁରୀକାଳୀନ ସେବା ୨୪/୭" : "Emergency Ready 24/7",
          actionLabel: isOdia ? "ସମସ୍ତ ଦେଖନ୍ତୁ" : "See All",
          onActionTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ClinicsListingScreen(),
              ),
            );
          },
        ),

        SizedBox(
          height: 282, 
          // 🚀 [FIXED]: ଉଭୟ ଲୋଡ୍ ହେବା ଯାଏଁ Shimmer ଦେଖାନ୍ତୁ
          child: isPageLoading && clinics.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (_, __) => const ClinicCardSkeleton(isVertical: true),
                )
              : clinics.isEmpty
              ? _buildEmptyState(context, isOdia)
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  physics: const BouncingScrollPhysics(),
                  itemCount: clinics.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    return ClinicCardWidget(
                      clinic: clinics[index],
                      isOdia: isOdia,
                      isVertical: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 🚀 Premium, Card-Based Empty State Design
  Widget _buildEmptyState(BuildContext context, bool isOdia) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF18181B) : AppPalette.info50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppPalette.info200.withValues(alpha: 0.10),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1660FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.mapPin, 
              size: 24,
              color: Color(0xFF1660FF), 
            ),
          ),
          const SizedBox(height: 12),

          Text(
            isOdia
                ? "ଆମେ ଏପର୍ଯ୍ୟନ୍ତ ସେଠାରେ ପହଞ୍ଚି ନାହୁଁ"
                : "We haven't reached you yet",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isOdia
                ? "ଆମେ ଖୁବ୍ ଶୀଘ୍ର ଆପଣଙ୍କ ଅଞ୍ଚଳକୁ ବିସ୍ତାର କରୁଛୁ! ଏହାକୁ ଶୀଘ୍ର ଆଣିବାରେ ସାହାଯ୍ୟ କରିବାକୁ ଆପଣଙ୍କ ସାଙ୍ଗମାନଙ୍କୁ ଆମନ୍ତ୍ରଣ କରନ୍ତୁ।"
                : "We are expanding to your area quickly! Help us bring top clinics here faster by inviting your clinics.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _shareApp(isOdia), 
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                isOdia ? "ସାଙ୍ଗମାନଙ୍କୁ ଆମନ୍ତ୍ରଣ କରନ୍ତୁ" : "Invite Clinics",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF0F172A), 
                foregroundColor: isDark ? Colors.black : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100), 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}