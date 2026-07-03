// lib/screens/admin/adminUsers/adminStaff/link_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../services/api_service.dart';

class LinkStaffScreen extends StatefulWidget {
  const LinkStaffScreen({super.key});

  @override
  State<LinkStaffScreen> createState() => _LinkStaffScreenState();
}

class _LinkStaffScreenState extends State<LinkStaffScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  bool _hasSearched = false;
  List<Map<String, dynamic>> _searchResults = [];

  final Set<String> _pendingInvites = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- API LOGIC ---
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchResults = [];
    });

    try {
      // TODO: Replace with actual API endpoint
      await Future.delayed(const Duration(milliseconds: 1200));

      if (query.length >= 5) {
        _searchResults = [
          {
            '_id': 'usr_12345',
            'name': 'Dr. Alok Mohanty',
            'role': 'doctor',
            'phone': query,
            'profile': '',
            'status': 'active',
          },
          {
            '_id': 'usr_67890',
            'name': 'Priya Das',
            'role': 'nurse',
            'phone': '9876543210',
            'profile': '',
            'status': 'active',
          },
        ];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Search failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendFinalInvite(
    String userId,
    String name,
    Map<String, dynamic> offerDetails,
  ) async {
    setState(() {
      _pendingInvites.add(userId);
    });

    try {
      // TODO: Include offerDetails in your API payload
      // final payload = {
      //   'user_id': userId,
      //   'clinic_id': 'current_clinic',
      //   'offer': offerDetails,
      // };
      // await _apiService.sendStaffInvite(payload);

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Detailed offer sent to $name!"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _pendingInvites.remove(userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send invite: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- UPGRADED: SMART OFFER CONFIGURATION SHEET ---
  void _openOfferConfiguration(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role = (user['role'] ?? 'staff').toString().toLowerCase();
    final isDoctor = role == 'doctor';

    // Controllers
    final compensationController = TextEditingController();
    final responsibilitiesController = TextEditingController();

    // Doctor Specific Controllers
    final volumeController = TextEditingController();
    final facilitiesController = TextEditingController();

    // Staff Specific Controllers (Pre-filled with default clinic hours)
    final timingController = TextEditingController(
      text: isDoctor ? "" : "09:00 AM - 06:00 PM",
    );

    // State variable for Doctor's compensation type
    String docCompensationType = 'revenue_share';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // StatefulBuilder allows the bottom sheet to update its own UI dynamically
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- HEADER ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Draft Offer",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              "For ${user['name']} (${role.toUpperCase()})",
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x),
                          onPressed: () => Navigator.pop(ctx),
                          style: IconButton.styleFrom(
                            backgroundColor: theme.dividerColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ==========================================
                    // DOCTOR SPECIFIC UI
                    // ==========================================
                    if (isDoctor) ...[
                      Text(
                        "Compensation Model",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Dynamic Selector Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCompChip(
                            'revenue_share',
                            "Revenue Share",
                            docCompensationType,
                            theme,
                            setModalState,
                            (val) => docCompensationType = val,
                          ),
                          _buildCompChip(
                            'per_patient',
                            "Per Patient",
                            docCompensationType,
                            theme,
                            setModalState,
                            (val) => docCompensationType = val,
                          ),
                          _buildCompChip(
                            'per_session',
                            "Per Session",
                            docCompensationType,
                            theme,
                            setModalState,
                            (val) => docCompensationType = val,
                          ),
                          _buildCompChip(
                            'fixed',
                            "Fixed Salary",
                            docCompensationType,
                            theme,
                            setModalState,
                            (val) => docCompensationType = val,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSheetInput(
                        theme: theme,
                        controller: compensationController,
                        label: "Compensation Amount/Percentage",
                        icon: docCompensationType == 'revenue_share'
                            ? LucideIcons.percent
                            : LucideIcons.indianRupee,
                        hint: docCompensationType == 'revenue_share'
                            ? "e.g. 60%"
                            : "e.g. 500",
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetInput(
                              theme: theme,
                              controller: volumeController,
                              label: "Expected Volume",
                              icon: LucideIcons.users,
                              hint: "e.g. 20-30/day",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildSheetInput(
                        theme: theme,
                        controller: facilitiesController,
                        label: "Clinic Facilities / Perks",
                        icon: LucideIcons.building,
                        hint:
                            "e.g. Dedicated cabin, Nursing assistant provided...",
                        maxLines: 2,
                      ),
                    ]
                    // ==========================================
                    // STAFF SPECIFIC UI
                    // ==========================================
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildSheetInput(
                              theme: theme,
                              controller: compensationController,
                              label: "Monthly Salary (₹)",
                              icon: LucideIcons.banknote,
                              hint: "e.g. 15000",
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSheetInput(
                              theme: theme,
                              controller: timingController,
                              label: "Shift Timings",
                              icon: LucideIcons.clock,
                              hint: "09:00 AM - 06:00 PM",
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // --- COMMON FIELD ---
                    _buildSheetInput(
                      theme: theme,
                      controller: responsibilitiesController,
                      label: "Roles & Responsibilities",
                      icon: LucideIcons.fileText,
                      hint: "Briefly describe their core duties...",
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // --- SUBMIT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Compile the correct payload based on role
                          final offerDetails = isDoctor
                              ? {
                                  'compensation_type': docCompensationType,
                                  'compensation_value':
                                      compensationController.text,
                                  'expected_volume': volumeController.text,
                                  'facilities': facilitiesController.text,
                                  'responsibilities':
                                      responsibilitiesController.text,
                                }
                              : {
                                  'compensation_type': 'fixed_salary',
                                  'compensation_value':
                                      compensationController.text,
                                  'shift_timings': timingController.text,
                                  'responsibilities':
                                      responsibilitiesController.text,
                                };

                          Navigator.pop(ctx);
                          _sendFinalInvite(
                            user['_id'],
                            user['name'],
                            offerDetails,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Send Official Request",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER: DOCTOR COMPENSATION CHIP ---
  Widget _buildCompChip(
    String value,
    String label,
    String currentValue,
    ThemeData theme,
    StateSetter setModalState,
    Function(String) onSelect,
  ) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () => setModalState(() => onSelect(value)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : theme.hintColor,
          ),
        ),
      ),
    );
  }

  // --- HELPER: INPUT FIELD ---
  Widget _buildSheetInput({
    required ThemeData theme,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: theme.hintColor.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 18, color: theme.disabledColor)
                : null,
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Link Existing Staff",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Search the Jivan network by Phone Number or ID to send a secure join request.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // --- MODERN PROMPT-STYLE SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _performSearch(),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: "Enter Phone Number...",
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Icon(
                      LucideIcons.search,
                      color: theme.hintColor.withValues(alpha: 0.8),
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 50),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isSearching
                          ? Container(
                              width: 44,
                              height: 44,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 2.5,
                              ),
                            )
                          : IconButton(
                              onPressed: _performSearch,
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: const CircleBorder(),
                                minimumSize: const Size(44, 44),
                              ),
                              icon: const Icon(
                                LucideIcons.arrowRight,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // --- DYNAMIC RESULTS AREA ---
          Expanded(child: _buildResultsArea(theme)),
        ],
      ),
    );
  }

  Widget _buildResultsArea(ThemeData theme) {
    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Searching Jivan Network...",
              style: TextStyle(
                color: theme.hintColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return _buildEmptyState(
        theme: theme,
        icon: LucideIcons.fileScan,
        color: theme.colorScheme.primary,
        title: "Ready to Connect",
        subtitle: "Enter a phone number above to find their profile.",
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        theme: theme,
        icon: LucideIcons.userMinus,
        color: Colors.orange.shade600,
        title: "No Match Found",
        subtitle:
            "We couldn't find anyone with that number.\nYou can create a new profile for them instead.",
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return _buildResultCard(user, theme);
      },
    );
  }

  Widget _buildEmptyState({
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.hintColor,
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> user, ThemeData theme) {
    final String id = user['_id'];
    final String name = user['name'] ?? 'Unknown';
    final String roleRaw = (user['role'] ?? 'staff').toString();
    final String role = roleRaw[0].toUpperCase() + roleRaw.substring(1);
    final String phone = user['phone'] ?? '';
    final String imageUrl = user['profile'] ?? '';

    final bool isPending = _pendingInvites.contains(id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              image: imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageUrl.isEmpty
                ? Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "$role  •  $phone",
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isPending
                ? Container(
                    key: const ValueKey('pending'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.check, size: 14, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          "Sent",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  )
                : OutlinedButton(
                    key: const ValueKey('invite'),
                    onPressed: () => _openOfferConfiguration(user),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 0,
                      ),
                    ),
                    child: const Text(
                      "Draft Offer",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
