import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/super_admin/clinics/add_clinic_screen.dart';
import 'package:my_new_app/screens/subscription_plans_screen.dart';

// IMPORTANT: Make sure to import your new ClinicDetailsScreen here.
import 'clinic_details_screen.dart';

class AdminClinicsScreen extends StatefulWidget {
  const AdminClinicsScreen({super.key});

  @override
  State<AdminClinicsScreen> createState() => _AdminClinicsScreenState();
}

class _AdminClinicsScreenState extends State<AdminClinicsScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<dynamic> _clinics = [];
  bool _isLoading = true;
  bool _isSuperAdmin = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _fetchClinics();
  }

  Future<void> _checkRole() async {
    final role = await _storage.read(key: 'admin_role');
    if (mounted) setState(() => _isSuperAdmin = (role == 'SuperAdmin'));
  }

  Future<void> _fetchClinics() async {
    if (_clinics.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }

    try {
      final response = await _apiService.getAdminClinics();

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _clinics = data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching clinics: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ACTIONS ---
  Future<void> _confirmDelete(String clinicId, String clinicName) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Facility"),
        content: Text("Are you sure you want to remove '$clinicName'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Keep it"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) _deleteClinic(clinicId);
  }

  Future<void> _deleteClinic(String clinicId) async {
    try {
      final response = await _apiService.deleteClinic(clinicId);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Facility removed successfully")),
          );
        }
        _fetchClinics();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _suspendClinic(
    String clinicId,
    Map<String, dynamic> currentData,
  ) async {
    try {
      final newStatus = (currentData['status'] == 'active')
          ? 'suspended'
          : 'active';
      final payload = {...currentData, 'status': newStatus};

      final response = await _apiService.updateAdminClinic(
        clinicId,
        payload,
        null,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context);
          _fetchClinics();
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // --- NAVIGATION HELPERS ---

  void _navigateToClinicDetails(String clinicId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClinicDetailsScreen(clinicId: clinicId),
      ),
    ).then((_) => _fetchClinics());
  }

  void _navigateToClinicForm({String? clinicId}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddClinicScreen(clinicId: clinicId)),
    );
    if (result == true) _fetchClinics();
  }

  // --- CARD TAP 2-ACTION PROMPT ---
  void _showCardTapActions(String clinicId) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Choose Action",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildBigActionButton(
                        icon: LucideIcons.eye,
                        label: "Clinic Details",
                        color: const Color(0xFF6366F1), // Indigo
                        onTap: () {
                          Navigator.pop(ctx);
                          _navigateToClinicDetails(clinicId);
                        },
                      ),
                    ),
                    if (_isSuperAdmin) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildBigActionButton(
                          icon: LucideIcons.edit3,
                          label: "Edit Clinic",
                          color: const Color(0xFFF59E0B), // Amber
                          onTap: () {
                            Navigator.pop(ctx);
                            _navigateToClinicForm(clinicId: clinicId);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBigActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MENU SHEET (3 Dots) ---
  void _showContextMenu(Map<String, dynamic> clinic) {
    final theme = Theme.of(context);
    final String clinicId = clinic['_id'] ?? clinic['id'];
    final bool isActive = clinic['status'] == 'active';

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildMenuItem(LucideIcons.eye, "Clinic Details", () {
                  Navigator.pop(ctx);
                  _navigateToClinicDetails(clinicId);
                }),
                if (_isSuperAdmin) ...[
                  _buildMenuItem(LucideIcons.edit3, "Edit Clinic", () {
                    Navigator.pop(ctx);
                    _navigateToClinicForm(clinicId: clinicId);
                  }),
                  _buildMenuItem(
                    isActive ? LucideIcons.pause : LucideIcons.play,
                    isActive ? "Suspend Operations" : "Resume Operations",
                    () => _suspendClinic(clinicId, clinic),
                    isDestructive: isActive,
                  ),
                  const Divider(height: 32),
                  _buildMenuItem(LucideIcons.trash2, "Delete Facility", () {
                    Navigator.pop(ctx);
                    _confirmDelete(clinicId, clinic['name']);
                  }, isDestructive: true),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchClinics,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading && _clinics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        if (_clinics.isEmpty)
          _buildEmptyState(theme)
        else ...[
          ..._clinics.map((clinic) => _buildFacilityCard(clinic, theme)),
          const SizedBox(height: 32),
          _buildGrowthCard(theme),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.building2,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "No Facilities Yet",
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> clinic, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final String clinicId = clinic['_id'] ?? clinic['id'];

    // Parsing basic details
    final String name = clinic['name'] ?? "Unnamed Facility";
    final String city = clinic['city'] ?? "";
    final String address = clinic['address'] ?? "";
    final bool isActive = clinic['status'] == 'active';
    final bool isVerified = clinic['isVerified'] ?? false;
    final List services = clinic['services'] ?? [];
    final int staffCount = clinic['staffCount'] ?? 0;

    // --- UPDATED: Defaulting to GROWTH plan instead of FREE ---
    final String rawPlan =
        (clinic['planName'] ??
                clinic['plan'] ??
                clinic['subscriptionPlan'] ??
                'GROWTH')
            .toString()
            .toUpperCase();
    String expiryDate =
        (clinic['planExpiryDate'] ??
                clinic['planExpiry'] ??
                clinic['expiryDate'] ??
                '')
            .toString();

    // Auto-generate a default expiry date (30 days from now) if API doesn't provide one
    if (expiryDate.isEmpty) {
      final nextMonth = DateTime.now().add(const Duration(days: 30));
      expiryDate =
          "${nextMonth.day.toString().padLeft(2, '0')}/${nextMonth.month.toString().padLeft(2, '0')}/${nextMonth.year}";
    }

    String displayPlan = 'FREE Plan';
    Color planColor = const Color(0xFF64748B); // Slate

    if (rawPlan.contains('GROWTH')) {
      displayPlan = 'GROWTH (₹1000/mo)';
      planColor = const Color(0xFF3B82F6); // Blue
    } else if (rawPlan.contains('PARTNER')) {
      displayPlan = 'PARTNER (₹15,000/mo)';
      planColor = const Color(0xFF8B5CF6); // Purple
    } else if (rawPlan.contains('LIFETIME')) {
      displayPlan = 'LIFETIME (₹1000/yr)';
      planColor = const Color(0xFFF59E0B); // Amber
    }

    // Safely parse dynamic Logo Data
    final dynamic rawLogo = clinic['logo'];
    ImageProvider? logoImageProvider;

    if (rawLogo is String && rawLogo.isNotEmpty) {
      logoImageProvider = NetworkImage(rawLogo);
    } else if (rawLogo is Map<String, dynamic> && rawLogo['data'] != null) {
      try {
        logoImageProvider = MemoryImage(base64Decode(rawLogo['data']));
      } catch (e) {
        debugPrint("Error decoding Base64 Logo: $e");
      }
    }

    final String locationText = [
      address,
      city,
    ].where((s) => s.isNotEmpty).join(", ");

    final activeBg = isActive
        ? Colors.green.withValues(alpha: 0.1)
        : colorScheme.errorContainer;
    final activeText = isActive
        ? Colors.green[700]
        : colorScheme.onErrorContainer;
    final activeDot = isActive ? Colors.green[700] : colorScheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showCardTapActions(clinicId),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        image: logoImageProvider != null
                            ? DecorationImage(
                                image: logoImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: logoImageProvider == null
                          ? Icon(
                              LucideIcons.building2,
                              color: colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.badgeCheck,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  locationText.isNotEmpty
                                      ? locationText
                                      : "Location not set",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showContextMenu(clinic),
                      icon: Icon(
                        LucideIcons.moreVertical,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (services.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: services.take(3).map<Widget>((service) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          service['name'] ?? "Service",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // --- PLAN DETAILS BANNER ---
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: planColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: planColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.creditCard,
                            size: 16,
                            color: planColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            displayPlan,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: planColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (expiryDate.isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendarClock,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Ends: $expiryDate",
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildStatBadge(
                        LucideIcons.users,
                        "$staffCount Staff",
                        colorScheme.onSurfaceVariant,
                        theme,
                      ),
                      const SizedBox(width: 16),
                      if (services.length > 3)
                        _buildStatBadge(
                          LucideIcons.layers,
                          "+${services.length - 3} More",
                          colorScheme.onSurfaceVariant,
                          theme,
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: activeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: activeDot,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? "Active" : "Suspended",
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: activeText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(
    IconData icon,
    String text,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Expand Your Reach",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Manage multiple clinics from one account.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "This feature will be free in the future. Need it now?",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SubscriptionPlansScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1E293B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Unlock with Partner Plan",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
