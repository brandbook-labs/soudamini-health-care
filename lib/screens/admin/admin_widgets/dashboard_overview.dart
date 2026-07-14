import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

// --- APP IMPORTS ---
import 'package:my_new_app/core/utils/theme_utils.dart'; // Ensure this points to your theme context
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/adminAppointments/admin_appointments_screen.dart';
import 'package:my_new_app/screens/admin/adminAnalytics/admin_analytics_screen.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/admin_patients_screen.dart';

class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  final ApiService _apiService = ApiService();

  // --- STATE VARIABLES ---
  bool _isLoading = true;
  int _totalAppts = 0;
  int _completedAppts = 0;
  int _missedAppts = 0;
  int _liveFootfall = 0; // Pending + Checked In
  double _todayRevenue = 0.0;
  int _patientCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 🚀 ସିଧାସଳଖ ଆପଣଙ୍କର ସିକ୍ୟୁର୍ ଏବଂ ଫାଷ୍ଟ୍ ଡ୍ୟାସବୋର୍ଡ API କୁ କଲ୍ କରନ୍ତୁ
      // (ଏହି ଫଙ୍କସନ୍ ଆପଣଙ୍କର ApiService ରେ ପୂର୍ବରୁ ଅଛି ବୋଲି ଧରିନିଆଗଲା)
      final response = await _apiService.getTodayDashboardStats(); 

      if (response.statusCode == 200) {
        // ବ୍ୟାକେଣ୍ଡ୍ ରୁ ଆସିଥିବା ସଠିକ୍ JSON ଡାଟା
        final data = response.data['data'] ?? {};

        if (mounted) {
          setState(() {
            // ବ୍ୟାକେଣ୍ଡ୍ ରୁ ସିଧା ମିଳୁଥିବା ମୂଲ୍ୟଗୁଡ଼ିକୁ ସେଟ୍ କରନ୍ତୁ (କୌଣସି Loop ଦରକାର ନାହିଁ)
            _totalAppts = data['total_appointments'] ?? 0;
            _completedAppts = data['done'] ?? 0;
            _missedAppts = data['missed'] ?? 0;
            _liveFootfall = data['waiting_patients'] ?? 0;
            _patientCount = data['new_patients'] ?? 0;
            
            // Revenue କୁ double ରେ ପରିବର୍ତ୍ତନ କରନ୍ତୁ
            _todayRevenue = double.tryParse(data['today_revenue']?.toString() ?? "0") ?? 0.0;
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Dashboard Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    // Formatter for Currency
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- SECTION HEADER ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Today's Overview",
                style: context.text.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminAnalyticsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("View Analytics"),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // --- 2x2 STATS GRID ---
        Column(
          children: [
            // ROW 1
            Row(
              children: [
                Expanded(
                  child: _AppointmentsStatCard(
                    isLoading: _isLoading,
                    total: _totalAppts,
                    completed: _completedAppts,
                    missed: _missedAppts,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAppointmentsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    isLoading: _isLoading,
                    title: "Today's Revenue",
                    value: currencyFormat.format(_todayRevenue),
                    icon: LucideIcons.wallet,
                    baseColor: Colors.green.shade700,
                    subInfoText: "Total collections",
                    onTap: () {
                      // Navigate to Revenue/Billing Screen
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ROW 2
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    isLoading: _isLoading,
                    title: "Unique Patients",
                    value: "$_patientCount",
                    icon: LucideIcons.userCheck,
                    baseColor: colorScheme.secondary, // Teal
                    subInfoText: "Visited today",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminPatientsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    isLoading: _isLoading,
                    title: "Live Footfall",
                    value: "$_liveFootfall",
                    icon: LucideIcons.users,
                    baseColor: Colors.orange.shade700,
                    subInfoText: "Awaiting consultation",
                    isWarning: _liveFootfall > 5, // Highlights if busy
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminAppointmentsScreen(),
                      ),
                    ),
                  ),
                ),
                
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ── SUB-WIDGETS ───────────────────────────────────────────────────────────────

/// Standard Stat Card
class _StatCard extends StatelessWidget {
  final bool isLoading;
  final String title;
  final String value;
  final IconData icon;
  final Color baseColor;
  final String subInfoText;
  final bool isWarning;
  final VoidCallback onTap;

  const _StatCard({
    required this.isLoading,
    required this.title,
    required this.value,
    required this.icon,
    required this.baseColor,
    required this.subInfoText,
    required this.onTap,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Material(
      color: AppPalette.info50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: baseColor.withValues(alpha: 0.1),
        highlightColor: baseColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppPalette.info200.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(icon, color: baseColor, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Main Value
              Text(
                isLoading ? "..." : value,
                style: context.text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: isWarning ? baseColor : colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 4),

              // Sub Info
              Text(
                subInfoText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Stat Card for Appointment Breakdown
class _AppointmentsStatCard extends StatelessWidget {
  final bool isLoading;
  final int total;
  final int completed;
  final int missed;
  final VoidCallback onTap;

  const _AppointmentsStatCard({
    required this.isLoading,
    required this.total,
    required this.completed,
    required this.missed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final baseColor = colorScheme.primary;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: baseColor.withValues(alpha: 0.1),
        highlightColor: baseColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      LucideIcons.calendarCheck,
                      color: baseColor,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Appointments",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Main Value (Total)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isLoading ? "..." : total.toString(),
                    style: context.text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Total",
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant.withAlpha(150),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Breakdown Row (Completed vs Missed)
              Row(
                children: [
                  _buildMiniDot(Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    isLoading ? "-" : "$completed Done",
                    style: context.text.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(200),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _buildMiniDot(Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    isLoading ? "-" : "$missed Missed",
                    style: context.text.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(200),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
