import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';

import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/clinics_listing_screen.dart';
import 'package:my_new_app/screens/patients/doctors_list_screen.dart';
import 'package:my_new_app/screens/patients/home_screen.dart';
import 'package:my_new_app/screens/patients/home_widgets/home_header.dart';
import 'package:my_new_app/screens/patients/labs/lab_listing_screen.dart';
import 'package:my_new_app/screens/patients/medicine_shop_screen.dart';
import 'package:my_new_app/screens/patients/profile/profile_screen.dart';
import 'package:my_new_app/services/location_service.dart';
import 'package:my_new_app/services/update_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  late AnimationController _hideButtonController;

  @override
  void initState() {
    super.initState();
    _hideButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService().checkForUpdates(context);
      LocationService.checkAndRequestLocation(context);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideButtonController.dispose();
    super.dispose();
  }

  // ── NAVIGATION ────────────────────────────────────────────────────────────

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
    if (_hideButtonController.status != AnimationStatus.completed) {
      _hideButtonController.forward();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    if (_hideButtonController.status != AnimationStatus.completed) {
      _hideButtonController.forward();
    }
  }

  bool _handleScrollNotification(UserScrollNotification notification) {
    if (notification.metrics.axis == Axis.horizontal) return false;

    if (notification.direction == ScrollDirection.reverse) {
      if (_hideButtonController.status != AnimationStatus.dismissed) {
        _hideButtonController.reverse();
      }
    } else if (notification.direction == ScrollDirection.forward) {
      if (_hideButtonController.status != AnimationStatus.completed) {
        _hideButtonController.forward();
      }
    }
    return false;
  }

  List<Widget> get _screens => [
    HomeScreen(onTabChange: _onNavTap),
    const DoctorsListScreen(),
    // const MedicineShopScreen(),
    const LabListingScreen(),
    const ProfileScreen(),
  ];

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onNavTap(0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value:
            (context.isDarkMode
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark)
                .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── SLIDING HEADER ──────────────────────────────────────
                ClipRect(
                  child: SizeTransition(
                    sizeFactor: CurvedAnimation(
                      parent: _hideButtonController,
                      curve: Curves.easeInOut,
                    ),
                    axisAlignment: 1.0,
                    child: HomeHeader(
                      currentIndex: _currentIndex,
                      onBackTap: () => _onNavTap(0),
                    ),
                  ),
                ),

                // ── BODY ────────────────────────────────────────────────
                Expanded(
                  child: NotificationListener<UserScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const BouncingScrollPhysics(),
                      children: _screens,
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: JivanBottomNav(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            userRole: 'patient',
          ),
        ),
      ),
    );
  }
}
