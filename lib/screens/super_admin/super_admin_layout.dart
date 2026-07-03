// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:my_new_app/core/components/index.dart';

// // --- SCREENS ---
// import 'package:my_new_app/screens/super_admin/dashboard/super_admin_dashboard.dart';
// import 'package:my_new_app/screens/super_admin/clinics/manage_clinics_screen.dart';
// import 'package:my_new_app/screens/super_admin/layout/super_admin_header.dart';
// import 'package:my_new_app/screens/super_admin/users/manage_users_screen.dart'; // Ensure correct import path
// import 'package:my_new_app/screens/super_admin/approvals_screen.dart'; // Ensure exists or use placeholder
// import 'package:my_new_app/screens/super_admin/profile/super_admin_profile_screen.dart';

// class SuperAdminLayout extends StatefulWidget {
//   const SuperAdminLayout({super.key});

//   @override
//   State<SuperAdminLayout> createState() => _SuperAdminLayoutState();
// }

// class _SuperAdminLayoutState extends State<SuperAdminLayout> {
//   final PageController _pageController = PageController();
//   int _currentIndex = 0;

//   // --- CONFIGURATION ---

//   // 1. Titles must match the order of _screens
//   final List<String> _titles = [
//     "Overview",
//     "Facilities",
//     "Users",
//     "Approvals",
//     "Profile",
//   ];

//   // 2. Screens List
//   List<Widget> get _screens => [
//     const SuperAdminDashboard(), // Index 0
//     const ManageClinicsScreen(), // Index 1
//     const ManageUsersScreen(), // Index 2 (Renamed from UsersListScreen for consistency?)
//     const ApprovalsScreen(), // Index 3
//     const SuperAdminProfileScreen(), // Index 4
//   ];

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }

//   void _onNavTap(int index) {
//     setState(() => _currentIndex = index);
//     _pageController.jumpToPage(index);
//   }

//   void _onPageChanged(int index) {
//     setState(() => _currentIndex = index);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDarkMode = theme.brightness == Brightness.dark;

//     return PopScope(
//       canPop: _currentIndex == 0,
//       onPopInvokedWithResult: (didPop, result) {
//         if (didPop) return;
//         _onNavTap(0); // Go back to Dashboard on back press
//       },
//       child: AnnotatedRegion<SystemUiOverlayStyle>(
//         value:
//             (isDarkMode
//                     ? SystemUiOverlayStyle.light
//                     : SystemUiOverlayStyle.dark)
//                 .copyWith(statusBarColor: Colors.transparent),
//         child: Scaffold(
//           backgroundColor: theme.scaffoldBackgroundColor,
//           // extendBodyBehindAppBar allows the content to scroll behind the header if needed,
//           // but for a fixed header layout, we usually use a Column.
//           body: Column(
//             children: [
//               // --- 1. UNIFIED HEADER ---
//               // Stays fixed at the top. Updates title based on _currentIndex.
//               SuperAdminHeader(
//                 title: _titles[_currentIndex],
//                 onNotificationTap: () {
//                   // Handle global notification click
//                 },
//               ),

//               // --- 2. SWIPEABLE CONTENT ---
//               Expanded(
//                 child: PageView(
//                   controller: _pageController,
//                   onPageChanged: _onPageChanged,
//                   physics: const BouncingScrollPhysics(), // Smoother swipe feel
//                   children: _screens,
//                 ),
//               ),
//             ],
//           ),

//           // --- 3. BOTTOM NAVIGATION ---
//           bottomNavigationBar: JivanBottomNav(
//             currentIndex: _currentIndex,
//             onTap: _onNavTap,
//             userRole: 'super_admin', // Ensures 5-item menu is rendered
//           ),
//         ),
//       ),
//     );
//   }
// }
