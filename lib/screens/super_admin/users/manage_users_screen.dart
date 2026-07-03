// import 'package:flutter/material.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:my_new_app/core/components/index.dart';
// import 'package:my_new_app/core/utils/theme_utils.dart';
// import 'package:my_new_app/services/api_service.dart';

// class ManageUsersScreen extends StatefulWidget {
//   const ManageUsersScreen({super.key});

//   @override
//   State<ManageUsersScreen> createState() => _ManageUsersScreenState();
// }

// class _ManageUsersScreenState extends State<ManageUsersScreen>
//     with SingleTickerProviderStateMixin {
//   final ApiService _apiService = ApiService();

//   late TabController _tabController;
//   late Future<List<Map<String, dynamic>>> _allUsersFuture;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = "";

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _allUsersFuture = _fetchAllData();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }

//   Future<List<Map<String, dynamic>>> _fetchAllData() async {
//     try {
//       final results = await Future.wait([
//         _apiService.getAdminAppointments('auth_token'), // Assuming this fetches patients?
//         _apiService.getAdminStaffs(),
//       ]);

//       final userResponse = results[0];
//       final staffResponse = results[1];

//       List<Map<String, dynamic>> combinedList = [];

//       if (userResponse.statusCode == 200) {
//         final data = userResponse.data['data'] ?? userResponse.data;
//         if (data is List) {
//           for (var item in data) {
//             combinedList.add({
//               ...item,
//               'unified_role': 'patient',
//               'unified_status': item['isVerify'] == true
//                   ? 'Verified'
//                   : 'Pending',
//             });
//           }
//         }
//       }

//       if (staffResponse.statusCode == 200) {
//         final data = staffResponse.data['data'] ?? staffResponse.data;
//         if (data is List) {
//           for (var item in data) {
//             combinedList.add({
//               ...item,
//               'unified_role': item['role'] ?? 'staff',
//               'unified_status': item['isVerified'] == true
//                   ? 'Verified'
//                   : 'Pending',
//             });
//           }
//         }
//       }
//       return combinedList;
//     } catch (e) {
//       debugPrint("Error fetching data: $e");
//       return [];
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = context.colorScheme;

//     // Use Transparent Scaffold to blend with SuperAdminLayout
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       body: Column(
//         children: [
//           // --- Search & Refresh Row ---
//           Padding(
//             padding: const EdgeInsets.fromLTRB(
//               AppSpacing.lg,
//               AppSpacing.lg, // Top padding since AppBar is gone
//               AppSpacing.lg,
//               0,
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     onChanged: (val) =>
//                         setState(() => _searchQuery = val.toLowerCase()),
//                     decoration: InputDecoration(
//                       hintText: "Search users...",
//                       prefixIcon: Icon(
//                         LucideIcons.search,
//                         color: colorScheme.onSurfaceVariant,
//                         size: 20,
//                       ),
//                       filled: true,
//                       fillColor: context.theme.cardColor,
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 12,
//                       ),
//                       border: OutlineInputBorder(
//                         borderRadius: AppRadius.medium,
//                         borderSide: BorderSide.none,
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: AppRadius.medium,
//                         borderSide: BorderSide(
//                           color: colorScheme.outline.withValues(alpha: 0.1),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 // Refresh Button (Relocated)
//                 Container(
//                   decoration: BoxDecoration(
//                     color: context.theme.cardColor,
//                     borderRadius: AppRadius.medium,
//                     border: Border.all(
//                       color: colorScheme.outline.withValues(alpha: 0.1),
//                     ),
//                   ),
//                   child: IconButton(
//                     icon: const Icon(LucideIcons.rotateCw),
//                     onPressed: () =>
//                         setState(() => _allUsersFuture = _fetchAllData()),
//                     tooltip: "Refresh Data",
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: AppSpacing.md),

//           // --- Tabs ---
//           Container(
//             height: 40,
//             margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
//             child: TabBar(
//               controller: _tabController,
//               indicatorSize: TabBarIndicatorSize.tab,
//               dividerColor: Colors.transparent,
//               indicator: BoxDecoration(
//                 color: colorScheme.primary,
//                 borderRadius: BorderRadius.circular(AppRadius.full),
//                 boxShadow: context.shadowSm,
//               ),
//               splashBorderRadius: BorderRadius.circular(AppRadius.full),
//               labelColor: colorScheme.onPrimary,
//               unselectedLabelColor: colorScheme.onSurfaceVariant,
//               labelStyle: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 13,
//               ),
//               tabs: const [
//                 Tab(text: "All"),
//                 Tab(text: "Doctors"),
//                 Tab(text: "Patients"),
//               ],
//             ),
//           ),

//           const SizedBox(height: AppSpacing.md),

//           // --- List Content ---
//           Expanded(
//             child: FutureBuilder<List<Map<String, dynamic>>>(
//               future: _allUsersFuture,
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           LucideIcons.wifiOff,
//                           size: 48,
//                           color: colorScheme.error,
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           "Failed to load data",
//                           style: TextStyle(color: colorScheme.error),
//                         ),
//                         TextButton(
//                           onPressed: () =>
//                               setState(() => _allUsersFuture = _fetchAllData()),
//                           child: const Text("Try Again"),
//                         ),
//                       ],
//                     ),
//                   );
//                 }
//                 final allData = snapshot.data ?? [];
//                 return TabBarView(
//                   controller: _tabController,
//                   children: [
//                     _buildList(allData, filter: "All"),
//                     _buildList(allData, filter: "doctor"),
//                     _buildList(allData, filter: "patient"),
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildList(List<Map<String, dynamic>> data, {required String filter}) {
//     var filtered = data.where((item) {
//       final name = (item['name'] ?? "").toString().toLowerCase();
//       final email = (item['email'] ?? "").toString().toLowerCase();
//       final id = (item['_id'] ?? "").toString().toLowerCase();
//       return name.contains(_searchQuery) ||
//           email.contains(_searchQuery) ||
//           id.contains(_searchQuery);
//     }).toList();

//     if (filter != "All") {
//       filtered = filtered.where((item) {
//         final role = (item['unified_role'] ?? "").toString().toLowerCase();
//         return role == filter.toLowerCase();
//       }).toList();
//     }

//     if (filtered.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               LucideIcons.users,
//               size: 48,
//               color: context.colorScheme.outline.withValues(alpha: 0.5),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "No users found",
//               style: context.text.bodyLarge?.copyWith(
//                 color: context.colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return ListView.separated(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.lg,
//         0,
//         AppSpacing.lg,
//         80,
//       ), // Bottom padding for Nav
//       itemCount: filtered.length,
//       separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
//       itemBuilder: (context, index) {
//         return _UnifiedUserCard(data: filtered[index]);
//       },
//     );
//   }
// }

// class _UnifiedUserCard extends StatelessWidget {
//   final Map<String, dynamic> data;

//   const _UnifiedUserCard({required this.data});

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = context.colorScheme;

//     final String name = data['name'] ?? "Unknown";
//     final String email = data['email'] ?? "No Email";
//     final String id = data['_id'] ?? "";
//     final String? profile = data['profile'];

//     final String role = (data['unified_role'] ?? "User").toString();
//     final String status = data['unified_status'] ?? "Pending";

//     final bool isDoctor = role.toLowerCase() == 'doctor';
//     final bool isVerified = status == 'Verified';

//     final List<dynamic> departments = (data['departments'] is List)
//         ? data['departments']
//         : [];
//     final String fees = data['consultation_fees'] != null
//         ? "₹${data['consultation_fees']}"
//         : "";

//     final roleColor = isDoctor ? Colors.purple : Colors.green;
//     final roleBg = isDoctor
//         ? Colors.purple.withValues(alpha: 0.1)
//         : Colors.green.withValues(alpha: 0.1);
//     final statusColor = isVerified ? Colors.blue : Colors.orange;

//     return JivanCard(
//       padding: EdgeInsets.zero,
//       child: InkWell(
//         onTap: () {},
//         borderRadius: AppRadius.large,
//         child: Padding(
//           padding: const EdgeInsets.all(AppSpacing.md),
//           child: Row(
//             children: [
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: roleBg,
//                   shape: BoxShape.circle,
//                   image: profile != null && profile.isNotEmpty
//                       ? DecorationImage(
//                           image: NetworkImage(profile),
//                           fit: BoxFit.cover,
//                         )
//                       : null,
//                 ),
//                 child: profile == null || profile.isEmpty
//                     ? Icon(
//                         isDoctor ? LucideIcons.stethoscope : LucideIcons.user,
//                         color: roleColor,
//                         size: 24,
//                       )
//                     : null,
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Flexible(
//                           child: Text(
//                             name,
//                             style: context.text.titleMedium?.copyWith(
//                               fontWeight: FontWeight.bold,
//                               color: colorScheme.onSurface,
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 6,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: statusColor.withValues(alpha: 0.1),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: Text(
//                             status.toUpperCase(),
//                             style: context.text.labelSmall?.copyWith(
//                               color: statusColor,
//                               fontSize: 9,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     if (isDoctor) ...[
//                       Text(
//                         departments.isNotEmpty
//                             ? "Specialist • $fees"
//                             : "Doctor • $fees",
//                         style: context.text.bodySmall?.copyWith(
//                           color: roleColor,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ] else ...[
//                       Text(
//                         "Patient • ...${id.length > 6 ? id.substring(id.length - 6) : id}",
//                         style: context.text.bodySmall?.copyWith(
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                     const SizedBox(height: 2),
//                     Text(
//                       email,
//                       style: context.text.labelSmall?.copyWith(
//                         color: colorScheme.outline,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               PopupMenuButton<String>(
//                 icon: Icon(
//                   LucideIcons.moreVertical,
//                   size: 20,
//                   color: colorScheme.onSurfaceVariant,
//                 ),
//                 itemBuilder: (context) => [
//                   const PopupMenuItem(
//                     value: 'view',
//                     child: Row(
//                       children: [
//                         Icon(LucideIcons.eye, size: 18),
//                         SizedBox(width: 8),
//                         Text("View Details"),
//                       ],
//                     ),
//                   ),
//                   if (isDoctor)
//                     const PopupMenuItem(
//                       value: 'edit',
//                       child: Row(
//                         children: [
//                           Icon(LucideIcons.edit, size: 18),
//                           SizedBox(width: 8),
//                           Text("Edit Profile"),
//                         ],
//                       ),
//                     ),
//                   const PopupMenuItem(
//                     value: 'delete',
//                     child: Row(
//                       children: [
//                         Icon(LucideIcons.trash2, size: 18, color: Colors.red),
//                         SizedBox(width: 8),
//                         Text("Delete", style: TextStyle(color: Colors.red)),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
