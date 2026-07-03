import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_new_app/core/components/index.dart'; 
import 'package:my_new_app/core/components/jivan_confetti.dart'; 

import 'package:my_new_app/screens/admin/adminAnalytics/admin_analytics_screen.dart';
import 'package:my_new_app/screens/admin/admin_home_screen.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/admin_patients_screen.dart';
import 'package:my_new_app/screens/admin/adminSettings/admin_settings_screen.dart';
import 'package:my_new_app/screens/admin/admin_widgets/admin_header.dart';
import 'package:my_new_app/screens/admin/inventory_billing/billing/invoice_listing.dart';

class AdminLayout extends StatefulWidget {
  final bool isNewRegistration;
  final Widget? customBody; 
  final int activeTabIndex; 

  const AdminLayout({
    super.key,
    this.isNewRegistration = false,
    this.customBody, 
    this.activeTabIndex = 0, 
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.activeTabIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 🚀 ସମ୍ପୂର୍ଣ୍ଣ ଅପଡେଟ୍ ହୋଇଥିବା Bottom Nav ଲଜିକ୍
  void _onNavTap(int index) {
    if (widget.customBody != null) {
      // ଯଦି ଆମେ ସବ୍-ସ୍କ୍ରିନ୍ (ଯେପରିକି Staff) ରେ ଅଛୁ:
      if (index == widget.activeTabIndex) {
        // ୧. ଯଦି ୟୁଜର୍ ସେହି ସମାନ ଟ୍ୟାବ୍ (Settings) ଉପରେ କ୍ଲିକ୍ କଲେ, କେବଳ ସ୍କ୍ରିନ୍ ବନ୍ଦ କରିବେ
        Navigator.pop(context); 
      } else {
        // ୨. ଯଦି ୟୁଜର୍ ନୂଆ ଟ୍ୟାବ୍ (Home/Analytics) କ୍ଲିକ୍ କଲେ, ସିଧା ସେହି ଟ୍ୟାବ୍ କୁ ଯିବେ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => AdminLayout(activeTabIndex: index),
          ),
          (route) => false, // 🚀 ଏହା ପୁରୁଣା ଷ୍ଟାକ୍ କ୍ଲିଅର୍ କରି ଆପ୍ କୁ ହ୍ୟାଙ୍ଗ୍/ଫ୍ରିଜ୍ ହେବାରୁ ବଞ୍ଚାଇବ
        );
      }
    } else {
      // ମେନ୍ ଲେଆଉଟ୍ ରେ ଥିବା ବେଳେ ସାଧାରଣ ଟ୍ୟାବ୍ ସୁଇଚ୍
      setState(() => _currentIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _screens => [
    const AdminHomeScreen(),
    const InvoiceListing(),
    const AdminAnalyticsScreen(),
    const AdminPatientsScreen(),
    const AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final bool isHome = widget.customBody == null && _currentIndex == 0;

    return PopScope(
      canPop: widget.customBody != null || isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (widget.customBody == null) _onNavTap(0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: (isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
            .copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              NestedScrollView(
                floatHeaderSlivers: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      pinned: false,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      elevation: innerBoxIsScrolled ? 2 : 0,
                      scrolledUnderElevation: 4,
                      automaticallyImplyLeading: false,
                      toolbarHeight: 70,

                      title: AdminHeader(
                        showBackButton: widget.customBody != null ? true : !isHome,
                        onBack: () {
                          if (widget.customBody != null) {
                            Navigator.pop(context);
                          } else {
                            _onNavTap(0);
                          }
                        },
                      ),
                      titleSpacing: 0,
                    ),
                  ];
                },
                body: widget.customBody ?? PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: _screens,
                ),
              ),

              if (widget.isNewRegistration && widget.customBody == null)
                const JivanConfetti(),
            ],
          ),
          bottomNavigationBar: JivanBottomNav(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            userRole: 'admin',
          ),
        ),
      ),
    );
  }
}