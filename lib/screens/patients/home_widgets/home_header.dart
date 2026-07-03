import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/screens/location/location_picker_screen.dart';
import 'package:my_new_app/screens/patients/notifications_screen.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

// 🚀 UserProvider Import
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
// 🚀 NEW: DoctorProvider Import (ତୁରନ୍ତ ସର୍ଚ୍ଚ କରିବା ପାଇଁ)
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    // 🚀 Provider ରୁ ଡାଟା ଲିସିନ୍ (Listen) କରାଯାଉଛି
    final userProvider = context.watch<UserProvider>();

    final String userName = userProvider.userName;
    final String userProfileImage = userProvider.userProfileImage;
    // final String userLocation = userProvider.fullAddress;
    final bool isLoadingLocation = userProvider.isLoadingLocation;

    // =======================================================================
    // 🚀 [SUPER SENIOR UI FIX]: ଡିସପ୍ଲେ କରିବା ପୂର୍ବରୁ ଲୋକେସନ୍ କୁ ଫିଲ୍ଟର୍ କରନ୍ତୁ
    // =======================================================================
    String rawLocation = userProvider.fullAddress;
    
    bool isInvalidDisplayCity = rawLocation.isEmpty ||
        rawLocation.contains("Locating") ||
        rawLocation.contains("Found") ||
        rawLocation.contains("Unavailable") ||
        rawLocation.replaceAll(",", "").trim().isEmpty;

    // ଯଦି ଗୁଗଲ୍ ଖରାପ ଡାଟା ଦେଇଛି ବା Location Found ଅଛି, ତେବେ Current Location ଦେଖାନ୍ତୁ
    final String userLocation = isInvalidDisplayCity ? "Current Location" : rawLocation;

    bool isHome = widget.currentIndex == 0;
    String title = "";

    switch (widget.currentIndex) {
      case 0:
        title = isOdia ? "ନମସ୍କାର, $userName" : "Hello, $userName";
        break;
      case 1:
        title = isOdia ? "ଡାକ୍ତର ଖୋଜନ୍ତୁ" : "Find Doctors";
        break;
      case 2:
        title = isOdia ? "ନିକଟସ୍ଥ କ୍ଲିନିକ" : "Nearby Clinics";
        break;
      case 3:
        title = isOdia ? "ପାଥୋଲୋଜି ଲ୍ୟାବ" : "Pathology Labs";
        break;
      case 4:
        title = isOdia ? "ମୋ ପ୍ରୋଫାଇଲ୍" : "My Profile";
        break;
      default:
        title = "Jivan App";
    }

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
          Row(
            children: [
              if (isHome)
                JivanAvatar(
                  size: 48,
                  imageUrl: userProfileImage.isNotEmpty
                      ? userProfileImage
                      : 'https://ui-avatars.com/api/?name=$userName&background=random',
                  name: userName,
                )
              else
                GestureDetector(
                  onTap: widget.onBackTap,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      LucideIcons.arrowLeft,
                      color: context.colorScheme.onSurface,
                      size: 20,
                    ),
                  ),
                ),

              const SizedBox(width: 12),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      title,
                      key: ValueKey<String>(title),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // ========================================================
                  // 🚀 LOCATION PICKER BUTTON
                  // ========================================================
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationPickerScreen(currentCity: userLocation),
                          fullscreenDialog: true,
                        ),
                      );

                      // 🚀 [SUPER SENIOR LOGIC]: ୧୦୦% ବୁଲେଟ୍ ପ୍ରୁଫ୍ (Bulletproof)
                      if (result != null) {
                        if (mounted) {
                          String cleanCity = "";
                          double finalLat = 0.0;
                          double finalLng = 0.0;

                          if (result is Map) {
                            // 🚀 ଯଦି City ନାମ ଖାଲି ଥାଏ ବା "Location Found" ଆସେ, "Current Location" ଦେଖାଇବ
                            String tempCity = result['city']?.toString().trim() ?? "";

                            // 🚀 [SUPER SENIOR BULLETPROOF CHECK]
                            // ଯଦି ଟେକ୍ସଟ୍ ସମ୍ପୂର୍ଣ୍ଣ ଖାଲି ଅଛି, କିମ୍ବା କେବଳ କମା/ସ୍ପେସ୍ ଅଛି, 
                            // ବା ଆମର କୌଣସି ଫଲବ୍ୟାକ୍ ଏରର୍ ଟେକ୍ସଟ୍ ଅଛି...
                            bool isInvalidCity = tempCity.isEmpty ||
                                tempCity.contains("Locating") ||
                                tempCity.contains("Found") ||
                                tempCity.contains("Unavailable") ||
                                tempCity.replaceAll(",", "").trim().isEmpty;

                            // ଯଦି ଅବୈଧ ଟେକ୍ସଟ୍ ଆସେ, ତେବେ ସୁନ୍ଦର ଭାବରେ "Current Location" ଦେଖାଇବ
                            cleanCity = isInvalidCity ? "Current Location" : tempCity;

                            // ସୁରକ୍ଷିତ ଭାବରେ ଡବଲ୍ କୁ କନଭର୍ଟ କରିବା
                            finalLat = double.tryParse(result['lat'].toString()) ?? 0.0;
                            finalLng = double.tryParse(result['lng'].toString()) ?? 0.0;
                          } 
                          else if (result is String) {
                            cleanCity = result.trim();
                          }

                          // ଏହିଠାରେ ଆମେ ସଠିକ୍ ଡାଟା UserProvider କୁ ଦେଉଛୁ
                          context.read<UserProvider>().updateManualLocation(
                            context,
                            cleanCity,
                            finalLat,
                            finalLng,
                          );

                          JivanToast.show(
                            context,
                            title: "Location Updated",
                            message: "Exploring near $cleanCity",
                          );
                        }
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 12,
                          color: context.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          userLocation,
                          style: context.text.bodySmall?.copyWith(
                            color: isHome
                                ? context.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  )
                                : context.colorScheme.primary,
                            fontWeight: isHome
                                ? FontWeight.normal
                                : FontWeight.w600,
                          ),
                        ),
                        if (isLoadingLocation) ...[
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: context.colorScheme.primary,
                            ),
                          ),
                        ],
                        if (isHome && !isLoadingLocation) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              IconButton(
                onPressed: () =>
                    context.read<LanguageController>().toggleLanguage(),
                icon: Icon(
                  Icons.translate,
                  color: isOdia
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),

              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    // color: context.theme.cardColor,
                    shape: BoxShape.circle,
                    // border: Border.all(color: borderColor),
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        LucideIcons.bell,
                        color: context.colorScheme.onSurface,
                        size: 22,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
