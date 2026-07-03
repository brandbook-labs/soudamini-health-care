// lib/screens/admin/adminUsers/adminStaff/admin_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/screens/admin/admin_layout.dart';

// --- IMPORTS ---
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminStaff/add_staff_screen.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminStaff/link_staff_screen.dart';

// 🚀 କେବଳ ଟାଇପ୍ (Type) ଜାଣିବା ପାଇଁ Model ଇମ୍ପୋର୍ଟ କରାଗଲା, ପାର୍ସିଂ ପାଇଁ ନୁହେଁ
import 'package:my_new_app/models/staff_model.dart'; 

// --- WIDGET IMPORTS ---
import 'widgets/staff_roles.dart'; 
import 'widgets/staff_stat_card.dart';
import 'widgets/staff_list_card.dart';
import 'widgets/staff_list_skeleton.dart';

class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  // 🚀 List<Doctor> ବଦଳରେ List<Staff>
  List<Staff> _allStaff = [];
  List<Staff> _filteredStaff = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((staff) {
        final name = staff.name.toLowerCase();
        final role = staff.role.toLowerCase();
        return name.contains(query) || role.contains(query);
      }).toList();
    });
  }

  // 🚀 [SUPER SENIOR FIX]: କୌଣସି JSON Parsing ନାହିଁ! ସିଧା API ରୁ Model ଆସିବ
  Future<void> _fetchStaff() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ସର୍ଭିସ୍ ସିଧାସଳଖ List<Staff> ଦେବ
      final List<Staff> staffs = await _apiService.getAdminStaffs();

      if (mounted) {
        setState(() {
          _allStaff = staffs;
          _filteredStaff = _allStaff;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching staff list: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

// update UI 
  void _updateStaffInList(Staff updatedStaff) {
    setState(() {
      final allIndex = _allStaff.indexWhere((s) => s.id == updatedStaff.id);
      if (allIndex != -1) _allStaff[allIndex] = updatedStaff;

      final filterIndex = _filteredStaff.indexWhere((s) => s.id == updatedStaff.id);
      if (filterIndex != -1) _filteredStaff[filterIndex] = updatedStaff;
    });
  }

  // --- ACTIONS ---
  void _handleCall(String phone) {
    if(phone.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Calling $phone...")));
  }

 // 🚀 [SUPER SENIOR FIX]: Only update the specific card without refetching all data
  Future<void> _handleSuspend(Staff staff) async {
    final bool currentlySuspended = staff.isSuspended || staff.status.toLowerCase() == 'suspended';
    final bool newStatus = !currentlySuspended; 
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _apiService.updateAdminStaffStatus(
        staff.mappingId.isNotEmpty ? staff.mappingId : staff.id, 
        {'isSuspended': newStatus}
      );

      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        // 🚀 API Response ରୁ ପ୍ରକୃତ ଷ୍ଟାଟସ୍ ବାହାର କରନ୍ତୁ
        final bool updatedSuspendStatus = response.data['data']['isSuspended'] ?? newStatus;

        setState(() {
          // ୧. ସମସ୍ତ ଷ୍ଟାଫ୍ ଲିଷ୍ଟ୍ ରେ ଅପଡେଟ୍ କରନ୍ତୁ
          final allIndex = _allStaff.indexWhere((s) => s.id == staff.id);
          if (allIndex != -1) {
            _allStaff[allIndex] = _allStaff[allIndex].copyWith(
              isSuspended: updatedSuspendStatus,
              status: updatedSuspendStatus ? 'suspended' : 'active'
            );
          }

          // ୨. ଫିଲ୍ଟର୍ ହୋଇଥିବା ଲିଷ୍ଟ୍ ରେ ମଧ୍ୟ ଅପଡେଟ୍ କରନ୍ତୁ (ଯାହା UI ରେ ଦେଖାଯାଉଛି)
          final filterIndex = _filteredStaff.indexWhere((s) => s.id == staff.id);
          if (filterIndex != -1) {
            _filteredStaff[filterIndex] = _filteredStaff[filterIndex].copyWith(
              isSuspended: updatedSuspendStatus,
              status: updatedSuspendStatus ? 'suspended' : 'active'
            );
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(updatedSuspendStatus ? "Staff Suspended Successfully" : "Staff Activated Successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update status"), backgroundColor: Colors.red),
      );
    }
  }

  // 🚀 [SUPER SENIOR FIX]: Archive ବିନା Refetch ରେ
  Future<void> _handleDelete(Staff staff) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await _apiService.updateAdminStaffStatus(
        staff.mappingId.isNotEmpty ? staff.mappingId : staff.id, 
        {'is_archived': true} 
      );

      Navigator.pop(context); // Close loader

      if (response.statusCode == 200) {
        setState(() {
          // ଲୋକାଲ୍ ଷ୍ଟେଟ୍ ରେ ଡାଟା ଅପଡେଟ୍
          final allIndex = _allStaff.indexWhere((s) => s.id == staff.id);
          if (allIndex != -1) {
            _allStaff[allIndex] = _allStaff[allIndex].copyWith(isArchived: true, status: 'archived');
          }

          final filterIndex = _filteredStaff.indexWhere((s) => s.id == staff.id);
          if (filterIndex != -1) {
            _filteredStaff[filterIndex] = _filteredStaff[filterIndex].copyWith(isArchived: true, status: 'archived');
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Staff Archived Successfully"), 
            backgroundColor: Colors.orange, 
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to archive staff"), backgroundColor: Colors.red),
      );
    }
  }

  // --- BOTTOM SHEET MENU ---
  void _showAddStaffOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Add Staff Member",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.link, color: Colors.blue),
                  ),
                  title: const Text("Link Existing Staff", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Search and add someone already on the Jivan platform.", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LinkStaffScreen()),
                    );
                    _fetchStaff();
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.userPlus, color: Colors.green),
                  ),
                  title: const Text("Create New Staff", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Manually create a new profile for someone not on Jivan.", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddStaffScreen()),
                    );
                    _fetchStaff(); 
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

 @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AdminLayout(
      activeTabIndex: 4, // 🚀 Settings ଟ୍ୟାବ୍ (ଇଣ୍ଡେକ୍ସ 4) କୁ ଆକ୍ଟିଭ୍ ରଖିବ
      customBody: Stack(
        children: [
          // 🚀 Positioned.fill ଦେବା ଦ୍ୱାରା ଏହା ସମ୍ପୂର୍ଣ୍ଣ ସ୍କ୍ରିନ୍ ନେବ ଏବଂ କ୍ଲିକ୍ ଫ୍ରିଜ୍ ହେବନି
          Positioned.fill(
            child: Material(
              color: Colors.transparent, 
              child: RefreshIndicator(
                onRefresh: _fetchStaff,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // --- ୧. STAFF STAT CARDS ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16), 
                        child: SizedBox(
                          height: 80, 
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: StaffStatCard(
                                  label: "Total Staff",
                                  value: "${_allStaff.length}",
                                  icon: LucideIcons.users,
                                  iconColor: Colors.blue,
                                  theme: theme,
                                ),
                              ),
                              ...STAFF_ROLES.map((role) {
                                final count = _allStaff
                                    .where((s) => s.role.toLowerCase() == role['value']) 
                                    .length;

                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: StaffStatCard(
                                    label: role['label'],
                                    value: "$count",
                                    icon: role['icon'],
                                    iconColor: theme.colorScheme.primary,
                                    theme: theme,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- ୨. SEARCH BAR ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.5),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: "Search by name, role...",
                                    hintStyle: TextStyle(
                                      color: theme.hintColor,
                                      fontSize: 14,
                                    ),
                                    prefixIcon: Icon(
                                      LucideIcons.search,
                                      color: theme.hintColor,
                                      size: 18,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.dividerColor.withValues(alpha: 0.5),
                                ),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  LucideIcons.filter,
                                  color: theme.iconTheme.color,
                                  size: 20,
                                ),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- ୩. STAFF LIST ---
                    _isLoading
                        ? const SliverToBoxAdapter(child: StaffListSkeleton())
                        : _filteredStaff.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      LucideIcons.searchX,
                                      size: 48,
                                      color: theme.disabledColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "No staff found matching your search.",
                                      style: TextStyle(color: theme.disabledColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 100, 
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((context, index) {
                                final staff = _filteredStaff[index]; 
                                return StaffListCard(
                                  staff: staff, 
                                  theme: theme,
                                  onCall: () => _handleCall(staff.phone),
                                  onSuspend: () => _handleSuspend(staff),
                                  onDelete: () => _handleDelete(staff),
                                  onUpdate: _updateStaffInList,
                                );
                              }, childCount: _filteredStaff.length),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
          
          // 🚀 FLOATING ACTION BUTTON 
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "unique_admin_staff_fab", // 🌟 ମୁଖ୍ୟ ସମାଧାନ: ଏହା ସ୍କ୍ରିନ୍ କୁ ଫ୍ରିଜ୍ ହେବାରୁ ବଞ୍ଚାଇବ!
              onPressed: () => _showAddStaffOptions(context), 
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(LucideIcons.plus),
              label: const Text(
                "Add Staff",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}