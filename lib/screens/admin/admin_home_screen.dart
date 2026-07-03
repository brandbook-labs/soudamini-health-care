import 'package:flutter/material.dart';
import 'package:my_new_app/screens/admin/AdminPlanDetailsCard.dart';
import 'package:my_new_app/screens/admin/admin_widgets/AdminCommunicationsHub..dart';
import 'package:my_new_app/screens/admin/admin_widgets/DoctorUpdatesAlerts.dart';
import 'package:my_new_app/screens/admin/admin_widgets/LiveClinicStatusView.dart';
import 'package:my_new_app/screens/admin/admin_widgets/SystemInventoryAlerts.dart';
import 'package:my_new_app/screens/admin/admin_widgets/dashboard_overview.dart';
import 'package:my_new_app/screens/admin/admin_widgets/quick_management_grid.dart';
import 'package:my_new_app/screens/admin/admin_widgets/upcoming_queue.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    // IMPORTANT: DO NOT use Scaffold here.
    // Just a Scrollable widget (ListView/SingleChildScrollView)
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      // Use BouncingScrollPhysics to enable the "pull down" effect of the header
      physics: const BouncingScrollPhysics(),
      children: [
        // No AdminHeader here! It is in the layout.
        // const SizedBox(height: 12),
        // const DoctorUpdatesAlerts(),
        const SizedBox(height: 20),

        // --- 2. DASHBOARD OVERVIEW ---
        const DashboardOverview(),

        const SizedBox(height: 20),

        // const UserPlanDetailsCard(
        //   planName: "Premium Partner Plan",
        //   clinicName: "City Care Super Specialty Hospital",
        //   validityDate: "24 Oct, 2026",
        //   isActive: true, // Set to false when the plan expires
        // ),
        // const SizedBox(height: 5),
        const QuickManagementGrid(),
        // const SizedBox(height: 5),
        // const LiveClinicStatusView(),
        // const SizedBox(height: 20),
        // const AdminCommunicationsHub(),
        // const SizedBox(height: 20),
        // const SystemInventoryAlerts(),
        const SizedBox(height: 20),

        // --- 3. UPCOMING QUEUE ---
        const UpcomingQueue(),
      ],
    );
  }
}
