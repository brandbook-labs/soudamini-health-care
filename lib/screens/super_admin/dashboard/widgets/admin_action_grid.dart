// import 'package:flutter/material.dart';
// import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:my_new_app/core/utils/theme_utils.dart';
// import 'package:my_new_app/screens/super_admin/marketing/marketing_generator.dart';
// import 'package:my_new_app/screens/super_admin/payouts/payouts_dashboard_screen.dart';
// import 'package:my_new_app/screens/super_admin/users/manage_users_screen.dart';
// import '../../banners/banner_management_screen.dart';
// import '../../reviews/review_moderation_screen.dart';
// import '../../clinics/manage_clinics_screen.dart';
// import '../../notifications/send_notification_screen.dart';
// import '../../health_tips/health_tips_screen.dart';
// import '../../verification/verification_queue_screen.dart';

// class AdminActionGrid extends StatelessWidget {
//   const AdminActionGrid({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Focused list: Only frequent business operations
//     final List<AdminActionItem> actions = [
//       // --- ROW 1: NEW & GROWTH ---

//       // [NEW] Marketing Card Generator
//       AdminActionItem(
//         label: "Card Studio",
//         icon: LucideIcons.contact, // Represents a contact/ID card
//         color: Colors.indigo,
//         onTap: () => _navTo(context, const MarketingGeneratorScreen()),
//       ),

//       AdminActionItem(
//         label: "Banners",
//         icon: LucideIcons.image,
//         color: Colors.pink,
//         onTap: () => _navTo(context, const BannerManagementScreen()),
//       ),
//       AdminActionItem(
//         label: "Reviews",
//         icon: LucideIcons.star,
//         color: Colors.amber,
//         badgeCount: 8,
//         onTap: () => _navTo(context, const ReviewModerationScreen()),
//       ),
//       AdminActionItem(
//         label: "Push Notifs",
//         icon: LucideIcons.bellRing,
//         color: Colors.deepOrange,
//         onTap: () => _navTo(context, const SendNotificationScreen()),
//       ),

//       // --- ROW 2: CORE OPERATIONS ---
//       AdminActionItem(
//         label: "Health Tips",
//         icon: LucideIcons.heartPulse,
//         color: Colors.red,
//         onTap: () => _navTo(context, const HealthTipsScreen()),
//       ),
//       AdminActionItem(
//         label: "Clinics",
//         icon: LucideIcons.building2,
//         color: Colors.blue,
//         onTap: () => _navTo(context, const ManageClinicsScreen()),
//       ),
//       AdminActionItem(
//         label: "Users",
//         icon: LucideIcons.users,
//         color: Colors.purple,
//         onTap: () => _navTo(context, const ManageUsersScreen()),
//       ),
//       AdminActionItem(
//         label: "Verify Docs",
//         icon: LucideIcons.fileCheck,
//         color: Colors.teal,
//         badgeCount: 3,
//         onTap: () => _navTo(context, const VerificationQueueScreen()),
//       ),

//       // --- ROW 3: FINANCIALS ---
//       AdminActionItem(
//         label: "Payouts",
//         icon: LucideIcons.wallet,
//         color: Colors.green,
//         onTap: () => _navTo(context, const PayoutsDashboardScreen()),
//       ),
//     ];

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         mainAxisSpacing: 16,
//         crossAxisSpacing: 12,
//         childAspectRatio: 0.75,
//       ),
//       itemCount: actions.length,
//       itemBuilder: (context, index) {
//         return _ActionTile(item: actions[index]);
//       },
//     );
//   }

//   void _navTo(BuildContext context, Widget screen) {
//     Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
//   }
// }

// // --- HELPER CLASSES ---

// class AdminActionItem {
//   final String label;
//   final IconData icon;
//   final Color color;
//   final VoidCallback onTap;
//   final int badgeCount;

//   AdminActionItem({
//     required this.label,
//     required this.icon,
//     required this.color,
//     required this.onTap,
//     this.badgeCount = 0,
//   });
// }

// class _ActionTile extends StatelessWidget {
//   final AdminActionItem item;

//   const _ActionTile({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return InkWell(
//       onTap: item.onTap,
//       borderRadius: BorderRadius.circular(12),
//       splashColor: item.color.withOpacity(
//         0.1,
//       ), // Adjusted for older Flutter versions compatibility
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Stack(
//             clipBehavior: Clip.none,
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: item.color.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(16),
//                   border: Border.all(
//                     color: item.color.withOpacity(0.2),
//                     width: 1,
//                   ),
//                 ),
//                 child: Icon(item.icon, color: item.color, size: 24),
//               ),
//               if (item.badgeCount > 0)
//                 Positioned(
//                   top: -5,
//                   right: -5,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                       border: Border.all(
//                         color: theme.scaffoldBackgroundColor,
//                         width: 2,
//                       ),
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 20,
//                       minHeight: 20,
//                     ),
//                     child: Center(
//                       child: Text(
//                         "${item.badgeCount}",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 10,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 2),
//             child: Text(
//               item.label,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 color: theme.colorScheme.onSurface.withOpacity(0.8),
//                 letterSpacing: -0.2,
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
