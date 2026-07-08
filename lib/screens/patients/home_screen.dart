import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:my_new_app/core/utils/theme_utils.dart';

// --- WIDGETS ---
import 'home_widgets/home_search_bar.dart';
import 'home_widgets/home_banners.dart';
import 'home_widgets/home_top_doctors.dart';

import 'home_widgets/quick_actions_grid.dart';

// --- IMPORT YOUR DESIGN SYSTEM REFRESHER ---
import 'package:my_new_app/widgets/app_refresher.dart';

class HomeScreen extends StatefulWidget {
  final Function(int) onTabChange;

  const HomeScreen({super.key, required this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // --- REFRESH LOGIC ---
  Future<void> _onRefresh() async {
    // TODO: Add your real data fetching logic here.
    // Example: await context.read<HomeProvider>().refreshAllData();
    // For now, we simulate a delay so you can see the spinner animation.
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        // Trigger a rebuild if necessary
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically adjust status bar icons based on theme
    SystemChrome.setSystemUIOverlayStyle(
      context.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,

      body: SafeArea(
        // WRAPPED IN APP REFRESHER
        child: AppRefresher(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            controller: _scrollController,
            // IMPORTANT: Use AlwaysScrollableScrollPhysics so pull-to-refresh
            // works even if the content height is small.
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: context.spaceXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                    child: const HomeSearchBar(),
                  ),

                  context.gapMd,

                  // 2. Cinematic Banners
                  const HomeBanners(),

                  context.gapLg,

                  // 3. Quick Actions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                    child: QuickActionsRow(onTabChange: widget.onTabChange),
                  ),

                  context.gapXl,

                  // 4. Top Specialists Section
                  const HomeTopDoctors(),

                  // 5. Safe bottom spacing for the navigation bar
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
