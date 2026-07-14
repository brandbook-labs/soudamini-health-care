import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/patients/home_widgets/global_search_header.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/widgets/app_refresher.dart';

import './providers/clinic_provider.dart';
import './path/to/clinic_card_widget.dart';
import '../../models/clinic_model.dart';
import 'package:my_new_app/screens/location/location_picker_screen.dart';

class ClinicsListingScreen extends StatefulWidget {
  const ClinicsListingScreen({super.key});

  @override
  State<ClinicsListingScreen> createState() => _ClinicsListingScreenState();
}

class _ClinicsListingScreenState extends State<ClinicsListingScreen> {
  String _selectedFacilityType = "All";
  bool _isOpenNow = false;
  bool _is24Hours = false;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();

    _userProvider = context.read<UserProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationWithClinicProvider();
    });

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🚀 FETCH ONCE LOGIC
  Future<void> _syncLocationWithClinicProvider() async {
    if (_userProvider.latitude == 0.0 &&
        _userProvider.longitude == 0.0 &&
        _userProvider.city.isEmpty) {
      await _userProvider.fetchUserLocation(context);
    }

    String fallback = _userProvider.city;
    if (fallback.isEmpty) fallback = _userProvider.district;
    if (fallback.isEmpty) fallback = _userProvider.userSavedAddress;

    if (mounted) {
      context.read<ClinicProvider>().updateLocationFromUserProvider(
        lat: _userProvider.latitude,
        lng: _userProvider.longitude,
        fallbackLocation: fallback,
      );
    }
  }

  void _onScroll() {
    final provider = context.read<ClinicProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isLoadingMore && provider.hasMoreData) {
        provider.fetchClinics();
      }
    }
  }

  void _onSearchChanged() {
    setState(() {}); // ଲୋକାଲ୍ ଫିଲ୍ଟରିଂ ପାଇଁ UI ରିଫ୍ରେସ୍
  }

  // 🚀 ADVANCED UI FILTERING LOGIC
  List<Clinic> _getFilteredClinics(List<Clinic> allClinics) {
    final query = _searchController.text.toLowerCase().trim();

    return allClinics.where((clinic) {
      final String rawCity =
          clinic.fullData['city']?.toString().toLowerCase() ?? "";
      final String rawDistrict =
          clinic.fullData['district']?.toString().toLowerCase() ?? "";
      final String rawFacilityType =
          clinic.fullData['facility_type']?.toString().toLowerCase() ?? "";

      final matchesSearch =
          query.isEmpty ||
          clinic.name.toLowerCase().contains(query) ||
          rawCity.contains(query) ||
          rawDistrict.contains(query) ||
          clinic.address.toLowerCase().contains(query);

      final matchesType =
          _selectedFacilityType == "All" ||
          (rawFacilityType == _selectedFacilityType.toLowerCase());

      final matches24h = !_is24Hours || clinic.is24h;
      final matchesOpenNow = !_isOpenNow || clinic.isOpen;

      return matchesSearch && matchesType && matches24h && matchesOpenNow;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicProvider>();
    final userProvider = context.watch<UserProvider>();
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';

    final filteredClinics = _getFilteredClinics(provider.clinics);
    final isPageLoading =
        provider.isFirstLoading || userProvider.isLoadingLocation;
    final showEmpty = !isPageLoading && filteredClinics.isEmpty;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            GlobalSearchHeader(
              controller: _searchController,
              hintText:
                  "Search hospital, clinic, or location...", // କ୍ଲିନିକ୍ ପାଇଁ
              onClear: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
                setState(() {}); // ରିଫ୍ରେସ୍ ପାଇଁ
              },
            ),

            // 🚀 ସଠିକ୍ କ୍ଲିନିକ୍ ଫିଲ୍ଟର୍ ଲାଇନ୍ (ଯାହା ଆପଣ ରଖିବାକୁ ଚାହୁଁଥିଲେ)
            _buildFilterChips(isOdia),

            Expanded(
              child: isPageLoading
                  ? ListView.separated(
                      padding: EdgeInsets.all(context.spaceMd),
                      itemCount: 6,
                      separatorBuilder: (ctx, index) => context.gapMd,
                      itemBuilder: (context, index) =>
                          const ClinicCardSkeleton(isVertical: false),
                    )
                  : AppRefresher(
                      onRefresh: () async =>
                          provider.fetchClinics(isRefresh: true),
                      child: showEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _buildEmptyState(
                                        context,
                                        userProvider.fullAddress,
                                        isOdia,
                                      ),
                                    ),
                                  ),
                            )
                          : ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsetsGeometry.fromLTRB(
                                context.spaceMd,
                                context.spaceXs,
                                context.spaceMd,
                                context.spaceMd,
                              ),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount:
                                  filteredClinics.length +
                                  (provider.isLoadingMore ? 1 : 0),
                              separatorBuilder: (ctx, index) => context.gapXs,
                              itemBuilder: (context, index) {
                                if (index == filteredClinics.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                return ClinicCardWidget(
                                  clinic: filteredClinics[index],
                                  isOdia: isOdia,
                                  isVertical: false,
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🚀 QUICK FILTERS UI (CLINIC SPECIFIC)
  // =========================================================================
  Widget _buildFilterChips(bool isOdia) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: context.spaceMd, vertical: 8),
      child: Row(
        children: [
          _customChip(
            "All",
            "All",
            isSelected: _selectedFacilityType == "All",
            onTap: () => setState(() => _selectedFacilityType = "All"),
          ),
          context.gapSm,
          _customChip(
            "clinic",
            isOdia ? "କ୍ଲିନିକ୍" : "Clinics",
            isSelected: _selectedFacilityType == "clinic",
            onTap: () => setState(() => _selectedFacilityType = "clinic"),
          ),
          context.gapSm,
          _customChip(
            "lab",
            isOdia ? "ଲ୍ୟାବ୍" : "Labs",
            isSelected: _selectedFacilityType == "lab",
            onTap: () => setState(() => _selectedFacilityType = "lab"),
          ),
          context.gapSm,
          _customChip(
            "pharmacy",
            isOdia ? "ଫାର୍ମାସୀ" : "Pharmacies",
            isSelected: _selectedFacilityType == "pharmacy",
            onTap: () => setState(() => _selectedFacilityType = "pharmacy"),
          ),
          context.gapSm,

          Container(
            width: 1,
            height: 24,
            color: context.colorScheme.outlineVariant,
          ),
          context.gapSm,

          FilterChip(
            label: Text(isOdia ? "୨୪ ଘଣ୍ଟା" : "24 Hours"),
            selected: _is24Hours,
            onSelected: (val) => setState(() => _is24Hours = val),
            showCheckmark: false,
            avatar: _is24Hours
                ? Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: context.colorScheme.onPrimary,
                  )
                : null,
            selectedColor: context.colorScheme.primary,
            labelStyle: TextStyle(
              color: _is24Hours
                  ? context.colorScheme.onPrimary
                  : context.colorScheme.onSurface,
            ),
          ),
          context.gapSm,

          FilterChip(
            label: Text(isOdia ? "ବର୍ତ୍ତମାନ ଖୋଲା" : "Open Now"),
            selected: _isOpenNow,
            onSelected: (val) => setState(() => _isOpenNow = val),
            showCheckmark: false,
            avatar: _isOpenNow
                ? Icon(
                    LucideIcons.doorOpen,
                    size: 16,
                    color: context.colorScheme.onPrimary,
                  )
                : null,
            selectedColor: Colors.green,
            labelStyle: TextStyle(
              color: _isOpenNow ? Colors.white : context.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _customChip(
    String value,
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: context.colorScheme.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected
            ? context.colorScheme.primary
            : context.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? context.colorScheme.primary
            : context.colorScheme.outlineVariant,
      ),
    );
  }

  // =========================================================================
  // 🚀 EMPTY STATE (ଆଇକନ୍ ପରିବର୍ତ୍ତନ କରାଯାଇଛି)
  // =========================================================================
  Widget _buildEmptyState(
    BuildContext context,
    String currentLocation,
    bool isOdia,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool isSearching =
        _searchController.text.isNotEmpty ||
        _selectedFacilityType != "All" ||
        _isOpenNow ||
        _is24Hours;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              // 🚀 [THE FIX]: ଖାଲି ସମୟରେ ମେଡିକାଲ୍ ବ୍ୟାଗ୍ ଆଇକନ୍, ଆଉ ସର୍ଚ୍ଚ ମ୍ୟାଚ୍ ନହେଲେ SearchX ଆଇକନ୍।
              child: Icon(
                isSearching ? LucideIcons.searchX : LucideIcons.mapPinOff,
                size: 50,
                color: colorScheme.error,
              ),
            ),
            context.gapLg,

            if (isSearching) ...[
              Text(
                "No matches found",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              context.gapSm,
              Text(
                "Try adjusting your search or filters to see more results.",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              context.gapLg,
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedFacilityType = "All";
                    _isOpenNow = false;
                    _is24Hours = false;
                  });
                },
                icon: const Icon(LucideIcons.refreshCcw),
                label: const Text("Clear Filters"),
              ),
            ] else ...[
              Text(
                "We aren't here yet!",
                style: context.text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              context.gapSm,
              Text(
                currentLocation == "Locating..." ||
                        currentLocation.isEmpty ||
                        currentLocation == "Location Unavailable"
                    ? "Please set your exact location to find the best health centers near you."
                    : "Sorry, we currently don't have any partner clinics or labs in '$currentLocation'.",
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocationPickerScreen(),
                        fullscreenDialog: true,
                      ),
                    );
                    if (result != null && result is String) {
                      if (context.mounted) {
                        context.read<UserProvider>().updateManualLocation(
                          context,
                          result.trim(),
                          0.0,
                          0.0,
                        );
                      }
                    }
                  },
                  icon: const Icon(LucideIcons.search),
                  label: const Text(
                    "Change Location",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
