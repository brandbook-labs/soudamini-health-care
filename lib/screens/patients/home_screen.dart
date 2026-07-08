import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Added for the AI Icon

// --- SYSTEM IMPORTS ---
import 'package:my_new_app/screens/patients/home_widgets/JoinJivan.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

// --- WIDGETS ---
import 'home_widgets/home_search_bar.dart';
import 'home_widgets/home_banners.dart';
import 'home_widgets/home_top_doctors.dart';
import 'home_widgets/home_nearby_medicals.dart';
import 'home_widgets/home_invite_card.dart';
import 'home_widgets/quick_actions_grid.dart';

// --- IMPORT AI CHAT SCREEN ---
import 'package:my_new_app/screens/patients/ai/jivan_ai_chat_screen.dart';

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
    SystemChrome.setSystemUIOverlayStyle(
      context.isDarkMode
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,

      // ==========================================
      // 🌟 NEW: FLOATING AI CHAT BUTTON
      // ==========================================
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        // Extra bottom padding to stay clear of your custom bottom nav bar
        padding: const EdgeInsets.only(bottom: 00.0, right: 0.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const JivanAiChatScreen(),
              ),
            );
          },
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // AI Gradient Look
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 60, 122, 255),
                  Color.fromARGB(255, 20, 39, 250),
                ], // Primary to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(
                    255,
                    0,
                    15,
                    45,
                  ).withValues(alpha: 0.6),
                  blurRadius: 25,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Center(
              child: Icon(
                LucideIcons.sparkles, // AI Magic Icon
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),

      // ==========================================
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

                  // 2. Banners
                  const HomeBanners(),

                  context.gapLg,

                  // 3. Quick Actions
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                    child: QuickActionsRow(onTabChange: widget.onTabChange),
                  ),

                  context.gapXl,

                  const HomeTopDoctors(),
                  context.gapXxl,

                  // Add bottom padding so the last item isn't hidden behind the floating button
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
