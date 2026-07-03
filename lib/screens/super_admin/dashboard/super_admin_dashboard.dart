// import 'package:flutter/material.dart';
// import 'package:my_new_app/core/components/index.dart';
// import 'package:my_new_app/core/utils/theme_utils.dart';

// // Widgets
// import 'widgets/admin_stats_overview.dart';
// import 'widgets/admin_action_grid.dart';
// import 'widgets/recent_activity_feed.dart';

// class SuperAdminDashboard extends StatelessWidget {
//   const SuperAdminDashboard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Removed Scaffold & AppBar because SuperAdminLayout handles them.
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           // 1. High-Level Metrics
//           AdminStatsOverview(),

//           SizedBox(height: 32),

//           // 2. The "Action Hub"
//           JivanSectionHeader(title: "Management Console"),
//           SizedBox(height: 16),
//           AdminActionGrid(),

//           SizedBox(height: 32),

//           // 3. Activity Logs
//           JivanSectionHeader(title: "System Audit"),
//           SizedBox(height: 12),
//           RecentActivityFeed(),

//           // Extra padding at bottom so content isn't hidden behind Bottom Nav
//           SizedBox(height: 80),
//         ],
//       ),
//     );
//   }
// }
