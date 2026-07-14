import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart'; // Theme Context

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  // Made final to fix "prefer_final_fields" warning.
  final String _timeRange = "This Month";

  // --- 1. DYNAMIC DATA SOURCE (Clinic Level) ---
  final double _revenueDoctorFees = 85000;
  final double _revenueMedicines = 150000;
  final double _revenueLabTests = 17500;

  // --- 2. SUPER ADMIN METRICS ---
  final int _activeClinics = 124;
  final int _totalPatientsPlatform = 8540;
  final int _newSignups = 45; // Clinics or Doctors onboarding
  final double _churnRate = 1.2; // % of clinics leaving

  // --- 3. SYSTEM HEALTH (Tech Metrics) ---
  final String _serverUptime = "99.98%";
  final String _avgLatency = "42ms";

  // Department Data
  final List<Map<String, dynamic>> _departmentData = [
    {"name": "General Medicine", "value": 45000.0},
    {"name": "Pediatrics", "value": 32000.0},
    {"name": "Dermatology", "value": 21000.0},
    {"name": "Orthopedics", "value": 12000.0},
  ];

  double get _totalRevenue =>
      _revenueDoctorFees + _revenueMedicines + _revenueLabTests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 0. Super Admin: System Health Banner
          SliverToBoxAdapter(child: _buildSystemHealthBanner(context)),

          // 1. Header with Filter
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Overview",
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Super Admin View",
                        style: context.text.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  _buildTimeFilter(context),
                ],
              ),
            ),
          ),

          // 2. Super Admin: Platform Growth Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Platform Growth",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPlatformGrowthGrid(context),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 3. Clinic Financial Deep Dive (Hero Section)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Financial Performance",
                    style: context.text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialHero(context),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4. Operational Metrics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _buildEfficiencyCard(
                      context: context,
                      label: "Completion Rate",
                      value: "94%",
                      trend: "+2%",
                      isPositive: true,
                      color: Colors.blue,
                      icon: LucideIcons.checkCircle2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildEfficiencyCard(
                      context: context,
                      label: "Cancellations",
                      value: "6%",
                      trend: "-1.5%",
                      isPositive: true,
                      color: Colors.orange,
                      icon: LucideIcons.xCircle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 5. Staff Performance
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Top Performing Doctors",
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildDoctorPerformanceRow(context, index),
                childCount: 3, // Reduced to 3 to save space
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 6. Demographics & Departments (Side by Side Concept or Stacked)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Patient Demographics",
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDemographicsSection(context),
                  const SizedBox(height: 32),
                  Text(
                    "Revenue by Department",
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._buildDepartmentList(context),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- NEW SUPER ADMIN WIDGETS ---

  Widget _buildSystemHealthBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      color: context.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.activity,
            size: 14,
            color: context.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            "System Health: ",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.colorScheme.primary,
            ),
          ),
          Text(
            "All Systems Operational",
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.outline,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Uptime: $_serverUptime",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Latency: $_avgLatency",
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformGrowthGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2; // 2 columns
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildSmallMetricCard(
              context,
              "Active Clinics",
              "$_activeClinics",
              LucideIcons.building2,
              Colors.blue,
              width,
            ),
            _buildSmallMetricCard(
              context,
              "Total Patients",
              "$_totalPatientsPlatform",
              LucideIcons.users,
              Colors.indigo,
              width,
            ),
            _buildSmallMetricCard(
              context,
              "New Signups",
              "+$_newSignups",
              LucideIcons.trendingUp,
              Colors.green,
              width,
            ),
            _buildSmallMetricCard(
              context,
              "Churn Rate",
              "$_churnRate%",
              LucideIcons.alertCircle,
              Colors.red,
              width,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallMetricCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          _buildDemographicRow(context, "Male", 0.45, Colors.blue),
          const SizedBox(height: 12),
          _buildDemographicRow(context, "Female", 0.52, Colors.pink),
          const SizedBox(height: 12),
          _buildDemographicRow(context, "Other", 0.03, Colors.orange),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAgeGroupBadge(context, "18-24", "15%"),
              _buildAgeGroupBadge(context, "25-40", "45%"),
              _buildAgeGroupBadge(context, "40-60", "25%"),
              _buildAgeGroupBadge(context, "60+", "15%"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicRow(
    BuildContext context,
    String label,
    double pct,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          "${(pct * 100).toInt()}%",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAgeGroupBadge(BuildContext context, String age, String pct) {
    return Column(
      children: [
        Text(
          pct,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          age,
          style: TextStyle(
            fontSize: 12,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // --- EXISTING WIDGETS (Unchanged Logic) ---

  Widget _buildTimeFilter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.calendar,
            size: 14,
            color: context.colorScheme.onSurface,
          ),
          const SizedBox(width: 8),
          Text(
            _timeRange,
            style: context.text.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            LucideIcons.chevronDown,
            size: 14,
            color: context.colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHero(BuildContext context) {
    final String formattedTotal = _formatCurrency(_totalRevenue, isLarge: true);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.isDarkMode ? const Color(0xFF1E1E1E) : Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Revenue",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTotal,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.wallet, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildFinanceDetail(
                "Fees",
                _formatCurrency(_revenueDoctorFees),
                Colors.blue.shade300,
              ),
              _buildFinanceDetail(
                "Meds",
                _formatCurrency(_revenueMedicines),
                Colors.green.shade300,
              ),
              _buildFinanceDetail(
                "Labs",
                _formatCurrency(_revenueLabTests),
                Colors.purple.shade300,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceDetail(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard({
    required BuildContext context,
    required String label,
    required String value,
    required String trend,
    required bool isPositive,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: context.text.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorPerformanceRow(BuildContext context, int index) {
    final docs = [
      {
        "name": "Dr. Jhasaketan",
        "rev": "₹42k",
        "pts": "140",
        "spec": "Gen. Med",
      },
      {
        "name": "Dr. Jayashree",
        "rev": "₹38k",
        "pts": "110",
        "spec": "Dermatology",
      },
      {
        "name": "Dr. Snehanshu",
        "rev": "₹21k",
        "pts": "65",
        "spec": "Neurology",
      },
    ];

    final doc = docs[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Text(
            "#${index + 1}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 20,
            backgroundColor: context.colorScheme.surfaceContainerHighest,
            backgroundImage: NetworkImage(
              "https://ui-avatars.com/api/?name=${doc['name']}&background=random",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  doc['spec']!,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                doc['rev']!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: context.colorScheme.primary,
                ),
              ),
              Text(
                "${doc['pts']} pts",
                style: TextStyle(
                  fontSize: 11,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDepartmentList(BuildContext context) {
    double totalDeptValue = _departmentData.fold(
      0,
      (sum, item) => sum + (item['value'] as double),
    );

    return _departmentData.map((dept) {
      final double value = dept['value'] as double;
      final double percentage = (value / totalDeptValue);
      final String percentString = "${(percentage * 100).toStringAsFixed(0)}%";

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: _buildDepartmentBar(
          context,
          dept['name'],
          percentage,
          percentString,
        ),
      );
    }).toList();
  }

  Widget _buildDepartmentBar(
    BuildContext context,
    String name,
    double percent,
    String displayValue,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            Text(
              displayValue,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: context.colorScheme.surfaceContainerHighest,
            color: context.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount, {bool isLarge = false}) {
    if (amount >= 100000) {
      return "₹${(amount / 100000).toStringAsFixed(isLarge ? 2 : 1)}L";
    } else if (amount >= 1000) {
      return "₹${(amount / 1000).toStringAsFixed(1)}k";
    }
    return "₹${amount.toStringAsFixed(0)}";
  }
}
