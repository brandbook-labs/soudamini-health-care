// lib/screens/admin/adminAnalytics/admin_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/services/api_service.dart';

// --- WIDGET IMPORTS ---
// (We keep these imports, but we will natively handle the UI to make it look premium and hide splits)
import 'widgets/efficiency_card.dart';
// Note: FinancialHeroCard, DoctorPerformanceRow, DepartmentBreakdownCard 
// are intentionally NOT used in the build method as per new requirements, 
// but kept in imports to avoid breaking your file structure.

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  
  // --- FILTER STATE ---
  String _timeRange = "This Month";
  DateTime _selectedDate = DateTime.now();
  String _filterType = 'monthly'; // 'daily' or 'monthly'

  bool _isLoading = true;

  // --- DYNAMIC DATA STATE ---
  double _totalRevenue = 0;
  
  // 🚀 Future Revenue Splits (Commented out as requested)
  /*
  double _revenueDoctorFees = 0;
  double _revenueMedicines = 0;
  double _revenueLabTests = 0;
  */

  int _totalPatients = 0;
  int _appointmentsToday = 0;
  String _avgWaitTime = "0 mins";
  int _retentionRate = 0;

  int _totalAppointments = 0;
  int _completedAppointments = 0;
  int _cancelledAppointments = 0;

  List<dynamic> _ageDemographics = [];
  Map<String, dynamic> _genderDemographics = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalyticsData();
  }

  // --- 🚀 THE API ENGINE ---
  Future<void> _fetchAnalyticsData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Format Date/Month for API Query
      String? dateParam;
      String? monthParam;
      final String yyyy = _selectedDate.year.toString();
      final String mm = _selectedDate.month.toString().padLeft(2, '0');
      final String dd = _selectedDate.day.toString().padLeft(2, '0');

      if (_filterType == 'daily') {
        dateParam = "$yyyy-$mm-$dd";
      } else {
        monthParam = "$yyyy-$mm";
      }

      // 2. Fetch Analytics Data directly using the updated getAnalytics (Token Based)
      // 🚀 Removed the old getAdminClinics() call as it's no longer needed
      final response = await _apiService.getAnalytics(
        date: dateParam, 
        month: monthParam,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? {};

        // Parse Revenue safely (e.g., "₹5110" -> 5110.0)
        String revStr = data['revenue']?.toString() ?? "0";
        revStr = revStr.replaceAll(RegExp(r'[^0-9.]'), ''); 
        double totalRev = double.tryParse(revStr) ?? 0.0;

        if (mounted) {
          setState(() {
            _totalRevenue = totalRev;
            
            // 🚀 Future implementations (Commented out)
            // _revenueDoctorFees = totalRev * 0.70;
            // _revenueMedicines = totalRev * 0.20;
            // _revenueLabTests = totalRev * 0.10;

            _totalPatients = data['totalPatients'] ?? 0;
            _appointmentsToday = data['appointmentsToday'] ?? 0;
            _avgWaitTime = data['avgWaitTime']?.toString() ?? "0 mins";
            _retentionRate = int.tryParse(data['retentionRate']?.toString() ?? "0") ?? 0;

            // Demographics Parsing
            if (data['demographics'] != null) {
               _ageDemographics = data['demographics']['age'] ?? [];
               _genderDemographics = data['demographics']['gender'] ?? {};
            }

            // Appointments Parsing
            final appts = data['appointments'] ?? {};
            _totalAppointments = appts['total'] ?? 0;
            _completedAppointments = appts['completed'] ?? 0;
            _cancelledAppointments = appts['cancelled'] ?? 0;

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- FILTER UI ---
  void _openFilterSelection() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      IconButton(icon: Icon(LucideIcons.x, color: theme.disabledColor), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.calendarDays, color: Colors.blue)),
                  title: const Text("Daily Analytics", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Select a specific date"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickDate(isDaily: true);
                  },
                ),
                ListTile(
                  leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.calendarRange, color: Colors.purple)),
                  title: const Text("Monthly Analytics", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text("Select a whole month"),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickDate(isDaily: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickDate({required bool isDaily}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isDaily ? "SELECT DATE" : "SELECT MONTH (Pick any day)",
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterType = isDaily ? 'daily' : 'monthly';
        
        final String yyyy = _selectedDate.year.toString();
        final String mm = _selectedDate.month.toString().padLeft(2, '0');
        final String dd = _selectedDate.day.toString().padLeft(2, '0');

        _timeRange = isDaily ? "$dd-$mm-$yyyy" : "$mm-$yyyy";
      });
      _fetchAnalyticsData(); 
    }
  }

  // --- HELPERS FOR API COLORS ---
  Color _parseApiColor(String? colorClass) {
    if (colorClass == null) return Colors.grey;
    if (colorClass.contains('blue')) return Colors.blue;
    if (colorClass.contains('indigo')) return Colors.indigo;
    if (colorClass.contains('purple')) return Colors.purple;
    if (colorClass.contains('rose') || colorClass.contains('red')) return Colors.pinkAccent;
    if (colorClass.contains('green')) return Colors.green;
    if (colorClass.contains('orange')) return Colors.orange;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Calculate Rates (Safely)
    final completionRate = _totalAppointments > 0
        ? (_completedAppointments / _totalAppointments * 100).toStringAsFixed(1)
        : "0.0";
    final cancellationRate = _totalAppointments > 0
        ? (_cancelledAppointments / _totalAppointments * 100).toStringAsFixed(1)
        : "0.0";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Header with Filter
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Clinic Insights",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    _buildTimeFilter(),
                  ],
                ),
              ),
            ),
          ),

          // 2. 🚀 Premium Master Hero Card (Replaces FinancialHeroCard to hide splits)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary, // Premium Solid Color
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Revenue",
                          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.trendingUp, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text("Active", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₹${_totalRevenue.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildHeroStat("Today's Appts", "$_appointmentsToday", LucideIcons.calendarCheck),
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
                        Expanded(
                          child: _buildHeroStat("Total Patients", "$_totalPatients", LucideIcons.users),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 3. 🚀 High-Level KPI (Wait Time & Retention)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.clock, color: Colors.orange, size: 24),
                          const SizedBox(height: 12),
                          Text(_avgWaitTime, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                          Text("Avg Wait Time", style: TextStyle(fontSize: 12, color: theme.disabledColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.heartPulse, color: Colors.purple, size: 24),
                          const SizedBox(height: 12),
                          Text("$_retentionRate%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
                          Text("Retention Rate", style: TextStyle(fontSize: 12, color: theme.disabledColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 4. 🚀 Efficiency Cards (Rates instead of raw appointments)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: EfficiencyCard(
                      label: "Completion Rate",
                      value: "$completionRate%",
                      trend: "Total: $_totalAppointments", 
                      isPositive: true,
                      color: Colors.green.shade600,
                      icon: LucideIcons.checkCircle2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: EfficiencyCard(
                      label: "Cancellations",
                      value: "$cancellationRate%",
                      trend: "Canceled: $_cancelledAppointments", 
                      isPositive: false,
                      color: Colors.red.shade500,
                      icon: LucideIcons.xCircle,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 5. 🚀 Premium Gender Demographics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Gender Demographics", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardColor, borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildGenderStat("Male", _genderDemographics['male'] ?? 0, LucideIcons.user, Colors.blue, theme),
                        Container(width: 1, height: 40, color: theme.dividerColor.withValues(alpha: 0.2)),
                        _buildGenderStat("Female", _genderDemographics['female'] ?? 0, LucideIcons.user, Colors.pink, theme),
                        Container(width: 1, height: 40, color: theme.dividerColor.withValues(alpha: 0.2)),
                        _buildGenderStat("Other", _genderDemographics['other'] ?? 0, LucideIcons.users, Colors.purple, theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // 6. 🚀 Premium Age Groups (Replaces Doctor Performance)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Age Distribution", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  if (_ageDemographics.isEmpty)
                     Text("No age data available.", style: TextStyle(color: theme.disabledColor))
                  else
                     GridView.builder(
                       shrinkWrap: true,
                       physics: const NeverScrollableScrollPhysics(),
                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                         crossAxisCount: 2,
                         crossAxisSpacing: 12,
                         mainAxisSpacing: 12,
                         childAspectRatio: 2.2,
                       ),
                       itemCount: _ageDemographics.length,
                       itemBuilder: (context, index) {
                         final ageData = _ageDemographics[index];
                         final color = _parseApiColor(ageData['color']);
                         return Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: color.withValues(alpha: 0.08),
                             borderRadius: BorderRadius.circular(16),
                             border: Border.all(color: color.withValues(alpha: 0.2)),
                           ),
                           child: Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Text(ageData['label'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.onSurface)),
                                   const SizedBox(height: 4),
                                   Text("Patients", style: TextStyle(fontSize: 10, color: theme.disabledColor, fontWeight: FontWeight.w600)),
                                 ],
                               ),
                               Container(
                                 padding: const EdgeInsets.all(10),
                                 decoration: BoxDecoration(color: theme.cardColor, shape: BoxShape.circle),
                                 child: Text("${ageData['value']}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
                               ),
                             ],
                           ),
                         );
                       },
                     )
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTimeFilter() {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _openFilterSelection,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              _filterType == 'daily' ? LucideIcons.calendarDays : LucideIcons.calendarRange,
              size: 14,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _timeRange,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Icon(LucideIcons.chevronDown, size: 14, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGenderStat(String label, int value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text("$value", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.disabledColor)),
      ],
    );
  }
}