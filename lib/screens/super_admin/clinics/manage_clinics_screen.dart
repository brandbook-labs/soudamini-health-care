import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/super_admin/clinics/add_clinic_screen.dart';

// Import our widgets
import 'widgets/clinic_list_tab.dart';

class ManageClinicsScreen extends StatefulWidget {
  const ManageClinicsScreen({super.key});

  @override
  State<ManageClinicsScreen> createState() => _ManageClinicsScreenState();
}

class _ManageClinicsScreenState extends State<ManageClinicsScreen>
    with SingleTickerProviderStateMixin {
  // Dependencies
  final ApiService _apiService = ApiService();

  // State
  late TabController _tabController;
  late Future<List<dynamic>> _clinicsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  void _loadData() {
    setState(() {
      _clinicsFuture = _fetchClinics();
    });
  }

  Future<List<dynamic>> _fetchClinics() async {
    try {
      final response = await _apiService.getAdminClinics();
      return response.statusCode == 200 ? response.data['data'] ?? [] : [];
    } catch (e) {
      debugPrint("Error fetching clinics: $e");
      return [];
    }
  }

  // --- ACTIONS ---

  void _navigateToForm({String? clinicId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddClinicScreen(clinicId: clinicId)),
    );
    if (result == true) _loadData();
  }

  Future<void> _handleSuspend(
    String clinicId,
    Map<String, dynamic> data,
  ) async {
    try {
      final newStatus = (data['status'] == 'active') ? 'suspended' : 'active';
      final payload = {...data, 'status': newStatus};

      final response = await _apiService.updateAdminClinic(
        clinicId,
        payload,
        null,
      );

      if (response.statusCode == 200) {
        if (mounted) _showSnack("Status updated to $newStatus", isError: false);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnack("Failed to update status: $e", isError: true);
    }
  }

  Future<void> _handleDelete(String clinicId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Facility?"),
        content: Text(
          "Are you sure you want to remove '$name'?\nThis action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await _apiService.deleteClinic(clinicId);
        if (response.statusCode == 200) {
          if (mounted) _showSnack("Facility deleted", isError: false);
          _loadData();
        }
      } catch (e) {
        if (mounted) _showSnack("Error deleting: $e", isError: true);
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // We use Scaffold here solely for the FAB and SnackBar context.
    // Background is transparent to blend with the SuperAdminLayout.
    return Scaffold(
      backgroundColor: Colors.transparent,

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(LucideIcons.plus),
        label: const Text("Add Facility"),
      ),

      body: Column(
        children: [
          // --- Tab Header & Refresh Action ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Tabs
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: colorScheme.primary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      unselectedLabelColor: theme.disabledColor,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: "Active"),
                        Tab(text: "Pending"),
                        Tab(text: "Suspended"),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Refresh Button (Moved from AppBar)
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      LucideIcons.rotateCw,
                      size: 20,
                      color: theme.disabledColor,
                    ),
                    tooltip: 'Refresh Data',
                    onPressed: _loadData,
                  ),
                ),
              ],
            ),
          ),

          // --- Content List ---
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _clinicsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.wifiOff,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Failed to load data",
                          style: TextStyle(color: colorScheme.error),
                        ),
                        TextButton(
                          onPressed: _loadData,
                          child: const Text("Try Again"),
                        ),
                      ],
                    ),
                  );
                }

                final clinics = snapshot.data ?? [];

                return TabBarView(
                  controller: _tabController,
                  children: [
                    ClinicListTab(
                      statusFilter: 'active',
                      allClinics: clinics,
                      onEdit: (id) => _navigateToForm(clinicId: id),
                      onDelete: _handleDelete,
                      onSuspend: _handleSuspend,
                    ),
                    ClinicListTab(
                      statusFilter: 'pending',
                      allClinics: clinics,
                      onEdit: (id) => _navigateToForm(clinicId: id),
                      onDelete: _handleDelete,
                      onSuspend: _handleSuspend,
                    ),
                    ClinicListTab(
                      statusFilter: 'suspended',
                      allClinics: clinics,
                      onEdit: (id) => _navigateToForm(clinicId: id),
                      onDelete: _handleDelete,
                      onSuspend: _handleSuspend,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
