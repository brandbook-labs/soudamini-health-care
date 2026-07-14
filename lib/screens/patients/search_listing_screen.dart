import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/patients/path/to/clinic_card_widget.dart';
import 'package:my_new_app/screens/patients/path/to/doctor_card_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';

// --- THEME & COMPONENTS ---
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/core/components/index.dart';

// --- SERVICES & PROVIDERS ---
import 'package:my_new_app/services/api_service.dart';
// ⚠️ ଆପଣଙ୍କର UserProvider ର ସଠିକ୍ ପାଥ୍ ଦିଅନ୍ତୁ 
import 'package:my_new_app/screens/patients/providers/user_provider.dart';

// --- MODELS & WIDGETS ---
import 'package:my_new_app/models/doctor_model.dart';
import 'package:my_new_app/models/clinic_model.dart';

// --- NAVIGATION ---
import 'doctor_profile/doctor_profile_screen.dart';
import 'clinic_details_screen.dart';

class SearchListingScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchListingScreen({super.key, this.initialQuery});

  @override
  State<SearchListingScreen> createState() => _SearchListingScreenState();
}

class _SearchListingScreenState extends State<SearchListingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ApiService _apiService = ApiService();

  String _selectedCategory = "All";
  bool _isLoading = false; // 🚀 ପ୍ରଥମରୁ ଲୋଡିଂ false ରହିବ କାରଣ ଆମେ ଖାଲି ସ୍କ୍ରିନ୍ ଦେଖାଇବା
  bool _isSearching = false;

  List<dynamic> _allApiResults = [];
  List<dynamic> _filteredResults = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // 🚀 ଯଦି ଆଗରୁ କିଛି ସର୍ଚ୍ଚ କ୍ୱେରୀ ଆସିଛି, ତେବେ ସିଧା ସର୍ଚ୍ଚ କରନ୍ତୁ
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _performApiSearch(widget.initialQuery!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ===========================================================================
  // 🚀 [SUPER SENIOR LOGIC]: SINGLE API CALL FOR GLOBAL SEARCH
  // ===========================================================================
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () { // API ଲୋଡ୍ ବଞ୍ଚାଇବା ପାଇଁ 500ms
      final query = _searchController.text.trim();
      _performApiSearch(query);
    });
  }

  Future<void> _performApiSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _allApiResults = [];
        _filteredResults = [];
        _isLoading = false;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      // ୧. UserProvider ରୁ ଲୋକେସନ୍ ଆଣନ୍ତୁ
      final userProvider = context.read<UserProvider>();
      
      // ୨. ଆମର ନୂଆ ସ୍ମାର୍ଟ ଗ୍ଲୋବାଲ୍ API କୁ କଲ୍ କରନ୍ତୁ
      final response = await _apiService.getGlobalSearchWithDoctorClinic(
        lat: userProvider.latitude,
        lng: userProvider.longitude,
        locationText: userProvider.city, // ବ୍ୟାକଅପ୍ ପାଇଁ
        searchValue: query,
      );

      if (mounted) {
        setState(() {
          _allApiResults = response['results'] ?? [];
          _applyLocalCategoryFilter(); // "All", "Doctor", "Clinic" ଅନୁସାରେ ଫିଲ୍ଟର୍ କରନ୍ତୁ
          _isLoading = false;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint("Global Search API Error: $e");
      if (mounted) {
        setState(() {
          _allApiResults = [];
          _filteredResults = [];
          _isLoading = false;
          _isSearching = false;
        });
      }
    }
  }

  // --- LOCAL CATEGORY FILTER (Doctor vs Clinic Tabs) ---
  void _applyLocalCategoryFilter() {
    if (_selectedCategory == "All") {
      _filteredResults = _allApiResults;
    } else {
      // ବ୍ୟାକଏଣ୍ଡ୍ 'doctor' ଆଉ 'clinic' ଛୋଟ ଅକ୍ଷରରେ (lowercase) ପଠାଉଛି
      final targetType = _selectedCategory.toLowerCase(); 
      _filteredResults = _allApiResults.where((item) => item['type'] == targetType).toList();
    }
  }

  void _onCategorySelected(String label) {
    setState(() {
      _selectedCategory = label;
      _applyLocalCategoryFilter();
    });
  }

  // --- NAVIGATION LOGIC ---
  void _handleNavigation(dynamic item) {
    if (item['type'] == 'doctor') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileScreen(doctorId: item['id']),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          // ClinicDetailsScreen ଯଦି raw JSON ମାଗୁଥାଏ, ତେବେ ସିଧା item ପଠାନ୍ତୁ
          builder: (_) => ClinicDetailsScreen(clinicData: item), 
        ),
      );
    }
  }

  // ===========================================================================
  // BUILD METHOD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isOdia = false; // ଆପଣଙ୍କର ଲାଙ୍ଗୁଏଜ୍ କଣ୍ଟ୍ରୋଲର୍ ଥିଲେ ବ୍ୟବହାର କରନ୍ତୁ

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: JivanIconBox(
                      icon: LucideIcons.arrowLeft,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Hero(
                      tag: 'searchBar',
                      child: JivanSearchField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        isLoading: _isSearching,
                        onChanged: (v) {}, // Debounce ଲଗାଯାଇଛି ସେଥିପାଇଁ ଏହା ଖାଲି
                        onClear: () {
                          _searchController.clear();
                          _performApiSearch("");
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- CATEGORY FILTERS ---
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  _buildFilter("All", LucideIcons.layoutGrid),
                  const SizedBox(width: 8),
                  _buildFilter("Doctor", LucideIcons.stethoscope),
                  const SizedBox(width: 8),
                  _buildFilter("Clinic", LucideIcons.building2),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- RESULTS LIST ---
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _searchController.text.isEmpty
                      ? _buildEmptyState() // 🚀 ସର୍ଚ୍ଚ ଖାଲି ଥିଲେ ଟ୍ରେଣ୍ଡିଂ ଦେଖାଇବ
                      : _filteredResults.isEmpty
                          ? _buildNoResults()
                          : ListView.separated(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              itemCount: _filteredResults.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (ctx, index) {
                                final item = _filteredResults[index];
                                final isDoctor = item['type'] == 'doctor';

                                // 🚀 TYPE WISE MAPPING (Card Selection) 🚀
                                return GestureDetector(
                                  onTap: () => _handleNavigation(item),
                                  child: isDoctor
                                      ? DoctorCardWidget(
                                          doctor: Doctor.fromJson(item), // JSON ରୁ ମଡେଲ୍ କୁ କନଭର୍ଟ
                                          isOdia: isOdia,
                                          isVertical: false,
                                        )
                                      : ClinicCardWidget(
                                          clinic: Clinic.fromJson(item), // JSON ରୁ ମଡେଲ୍ କୁ କନଭର୍ଟ
                                          isVertical: false, isOdia: isOdia,
                                        ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilter(String label, IconData icon) {
    return JivanFilterChip(
      label: label,
      icon: icon,
      isSelected: _selectedCategory == label,
      onTap: () => _onCategorySelected(label),
    );
  }

  // --- EMPTY STATES ---
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Trending Nearby 🔥",
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              "Cardiologist",
              "Dental Clinic",
              "Blood Test",
              "Dolo 650",
              "City Hospital",
            ].map((t) => _TrendingChip(
                  label: t,
                  // 🚀 Trending ଉପରେ କ୍ଲିକ୍ କଲେ ସିଧା ସର୍ଚ୍ଚ ହେବ
                  onTap: () {
                    _searchController.text = t;
                    _performApiSearch(t);
                  },
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.searchX,
            size: 48,
            color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No matches found",
            style: context.text.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Try different keywords",
            style: context.text.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: context.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          highlightColor: context.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.1),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadius.large,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// SUB-WIDGETS
// =============================================================================

class _TrendingChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap; // 🚀 ନୂଆ କ୍ଲିକ୍ ଲଜିକ୍

  const _TrendingChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: AppRadius.medium,
          border: Border.all(
            color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.trendingUp,
              size: 14,
              color: context.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: context.text.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}