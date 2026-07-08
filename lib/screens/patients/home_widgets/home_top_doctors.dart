import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

// --- APP IMPORTS ---
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
  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();

    _userProvider = context.read<UserProvider>();

    // Refetch doctors as soon as location becomes available.
    _userProvider.addListener(_syncLocationWithDoctorProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationWithDoctorProvider();
    });
  }

  @override
  void dispose() {
    _userProvider.removeListener(_syncLocationWithDoctorProvider);
    super.dispose();
  }

  // =========================================================================
  // Secure sync (guards against the location/profile race condition)
  // =========================================================================
  void _syncLocationWithDoctorProvider() {
    if (_userProvider.isLoadingLocation || _userProvider.isLoadingProfile) {
      return;
    }

    // Fallback order: City -> District -> Profile saved address
    String fallback = _userProvider.city;
    if (fallback.isEmpty) fallback = _userProvider.district;
    if (fallback.isEmpty) fallback = _userProvider.userSavedAddress;

    context.read<DoctorProvider>().updateLocationFromUserProvider(
      lat: _userProvider.latitude,
      lng: _userProvider.longitude,
      fallbackLocation: fallback,
    );
  }

  void _shareApp() {
    HapticFeedback.mediumImpact();
    const shareMessage =
        "Check out Jivan Health App! Find and book the best doctors near you. https://play.google.com/store/apps/details?id=com.jivan.health";
    Share.share(shareMessage);
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();
    final userProvider = context.watch<UserProvider>();

    final topDoctors = doctorProvider.doctorsList;
    final isPageLoading =
        doctorProvider.isListFirstLoading || userProvider.isLoadingLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JivanSectionHeader(
          title: "Top Specialists",
          subtitle: "Highly rated doctors nearby",
          actionLabel: "See All",
          onActionTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DoctorsListScreen()),
          ),
        ),

        // 🚀 VERTICAL LIST — flows inside the home page's own scroll view.
        // shrinkWrap + NeverScrollableScrollPhysics => no nested scrolling.
        if (isPageLoading && topDoctors.isEmpty)
          _buildShimmerList(context)
        else if (topDoctors.isEmpty)
          _buildEmptyState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              context.spaceMd,
              context.spaceXs,
              context.spaceMd,
              0,
            ),
            itemCount: topDoctors.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: context.spaceSm),
            itemBuilder: (context, index) {
              return DoctorCardWidget(
                doctor: topDoctors[index],
                isOdia: false,
                isVertical: false, // wide row card, matches the list screen
              );
            },
          ),
      ],
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        context.spaceMd,
        context.spaceXs,
        context.spaceMd,
        0,
      ),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: context.spaceSm),
      itemBuilder: (context, index) =>
          const DoctorCardSkeleton(isVertical: false),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: context.spaceMd),
      padding: EdgeInsets.all(context.spaceLg),
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
              color: context.colorScheme.primary.withValues(alpha: 0.1),
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
            "We haven't reached you yet",
            textAlign: TextAlign.center,
            style: context.titleLg?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.colorScheme.onSurface,
            ),
          ),
          context.gapXs ?? const SizedBox(height: 12),
          Text(
            "We are expanding to your area quickly! Help us bring top doctors here faster by inviting your clinics, doctors and friends.",
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
              onPressed: _shareApp,
              icon: const Icon(LucideIcons.share2, size: 18),
              label: Text(
                "Invite Doctors",
                style: context.titleMd?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.onPrimary,
                ),
              ),
              style: ElevatedButton.styleFrom(
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
