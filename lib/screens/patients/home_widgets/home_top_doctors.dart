import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

// --- APP IMPORTS ---
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // ThemeContext
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import '../providers/doctor_provider.dart';
import '../doctors_list_screen.dart';
import '../path/to/doctor_card_widget.dart';

class HomeTopDoctors extends StatefulWidget {
  const HomeTopDoctors({super.key});

  @override
  State<HomeTopDoctors> createState() => _HomeTopDoctorsState();
}

class _HomeTopDoctorsState extends State<HomeTopDoctors> {
  final ScrollController _scrollController = ScrollController();
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();

    // ୧. ପ୍ରୋଭାଇଡର୍ କୁ ରେଫରେନ୍ସ କରନ୍ତୁ
    _userProvider = context.read<UserProvider>();

    // ୨. ଲିସନର୍ ଲଗାନ୍ତୁ ଯାହାଦ୍ୱାରା ଲୋକେସନ୍ ଆସିବା ମାତ୍ରେ ଡାକ୍ତର ଖୋଜିବ
    _userProvider.addListener(_syncLocationWithDoctorProvider);

    // ୩. ଯଦି ଆଗରୁ ଲୋକେସନ୍ ଲୋଡ୍ ହୋଇସାରିଛି ତେବେ ତୁରନ୍ତ ଆରମ୍ଭ କରନ୍ତୁ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationWithDoctorProvider();
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _userProvider.removeListener(_syncLocationWithDoctorProvider);
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 🚀 THE ULTIMATE FIX: Secure Sync (ଏହା Race Condition କୁ ମାରିଦେବ)
  // =========================================================================
  void _syncLocationWithDoctorProvider() {
    // ଯଦି UserProvider ବର୍ତ୍ତମାନ ଲୋକେସନ୍ ବା ପ୍ରୋଫାଇଲ୍ ଖୋଜୁଛି, ତେବେ ଚୁପଚାପ୍ ଅପେକ୍ଷା କରନ୍ତୁ!
    if (_userProvider.isLoadingLocation || _userProvider.isLoadingProfile)
      return;

    // 🚀 ପରଫେକ୍ଟ୍ ବ୍ୟାକଅପ୍: City -> District -> Profile Saved Address
    String fallback = _userProvider.city;
    if (fallback.isEmpty) fallback = _userProvider.district;
    if (fallback.isEmpty) fallback = _userProvider.userSavedAddress;

    // DoctorProvider କୁ ପଠାନ୍ତୁ
    context.read<DoctorProvider>().updateLocationFromUserProvider(
      lat: _userProvider.latitude,
      lng: _userProvider.longitude,
      fallbackLocation: fallback,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      final provider = context.read<DoctorProvider>();
      if (!provider.isLoadingMore && provider.hasMoreData) {
        provider.fetchNearestDoctors();
      }
    }
  }

  void _shareApp(bool isOdia) {
    HapticFeedback.mediumImpact();
    final String shareMessage = isOdia
        ? "ଜୀବନ ହେଲଥ୍ ଆପ୍ ବ୍ୟବହାର କରନ୍ତୁ! ଆପଣଙ୍କ ନିକଟସ୍ଥ ଶ୍ରେଷ୍ଠ ଡାକ୍ତରଙ୍କୁ ଖୋଜନ୍ତୁ ଏବଂ ବୁକ୍ କରନ୍ତୁ। https://play.google.com/store/apps/details?id=com.jivan.health"
        : "Check out Jivan Health App! Find and book the best doctors near you. https://play.google.com/store/apps/details?id=com.jivan.health";
    Share.share(shareMessage);
  }

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';
    final doctorProvider = context.watch<DoctorProvider>();
    final userProvider = context.watch<UserProvider>();

    final topDoctors = doctorProvider.doctorsList;
    final isPageLoading =
        doctorProvider.isListFirstLoading || userProvider.isLoadingLocation;

    return Column(
      children: [
        JivanSectionHeader(
          title: isOdia ? "ଶୀର୍ଷ ବିଶେଷଜ୍ଞ" : "Top Specialists",
          subtitle: isOdia
              ? "ନିକଟସ୍ଥ ଲୋକପ୍ରିୟ ଡାକ୍ତର"
              : "Highly rated doctors nearby",
          actionLabel: isOdia ? "ସମସ୍ତ ଦେଖନ୍ତୁ" : "See All",
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsListScreen()),
          ),
        ),
        SizedBox(
          height: 360,
          child: isPageLoading && topDoctors.isEmpty
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (context, index) => context.gapSm,
                  itemBuilder: (context, index) =>
                      const DoctorCardSkeleton(isVertical: true),
                )
              : topDoctors.isEmpty
              ? _buildEmptyState(context, isOdia)
              : ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                  physics: const BouncingScrollPhysics(),
                  itemCount:
                      topDoctors.length +
                      (doctorProvider.isLoadingMore ? 1 : 0),
                  separatorBuilder: (context, index) => context.gapXs,
                  itemBuilder: (context, index) {
                    if (index == topDoctors.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(context.spaceLg),
                          child: const CircularProgressIndicator(),
                        ),
                      );
                    }
                    return DoctorCardWidget(
                      doctor: topDoctors[index],
                      isOdia: isOdia,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isOdia) {
    // 🎨 Replaced hardcoded checks with ThemeContext extensions
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spaceMd),
      padding: EdgeInsets.all(
        context.spaceLg,
      ), // Approximating the old 32 padding
      decoration: BoxDecoration(
        color: AppPalette.info50,
        borderRadius: context.roundedSm ?? BorderRadius.circular(8),
        border: Border.all(color: AppPalette.info200.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(context.spaceXs),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.mapPin,
              size: 30,
              color: context.colorScheme.primary,
            ),
          ),
          context.gapMd ?? const SizedBox(height: 20),
          Text(
            isOdia
                ? "ଆମେ ଏପର୍ଯ୍ୟନ୍ତ ସେଠାରେ ପହଞ୍ଚି ନାହୁଁ"
                : "We haven't reached you yet",
            textAlign: TextAlign.center,
            style: context.titleLg?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.colorScheme.onSurface,
            ),
          ),
          context.gapXs ?? const SizedBox(height: 12),
          Text(
            isOdia
                ? "ଆମେ ଖୁବ୍ ଶୀଘ୍ର ଆପଣଙ୍କ ଅଞ୍ଚଳକୁ ବିସ୍ତାର କରୁଛୁ! ଏହାକୁ ଶୀଘ୍ର ଆଣିବାରେ ସାହାଯ୍ୟ କରିବାକୁ ଆପଣଙ୍କ ସାଙ୍ଗମାନଙ୍କୁ ଆମନ୍ତ୍ରଣ କରନ୍ତୁ।"
                : "We are expanding to your area quickly! Help us bring top doctors here faster by inviting your clinics, doctors and friends.",
            textAlign: TextAlign.center,
            style: context.bodySm?.copyWith(
              height: 1.2,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          context.gapMd ?? const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => _shareApp(isOdia),
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                isOdia ? "ଡାକ୍ତରଙ୍କୁ ଆମନ୍ତ୍ରଣ କରନ୍ତୁ" : "Invite Doctors",
                style: context.titleMd?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
                // Dynamic High-Contrast Button
                backgroundColor: context.colorScheme.onSurface,
                foregroundColor: context.colorScheme.onPrimary,
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
