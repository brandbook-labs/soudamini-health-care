import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/patients/home_widgets/global_search_header.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/screens/patients/home_widgets/doctor_filters.dart';
import 'package:my_new_app/widgets/app_refresher.dart';
import './path/to/doctor_card_widget.dart';
import '../../models/doctor_model.dart';
import './providers/doctor_provider.dart';
import 'doctor_profile/doctor_profile_screen.dart';
import 'package:my_new_app/screens/location/location_picker_screen.dart';

class DoctorsListScreen extends StatefulWidget {
  const DoctorsListScreen({super.key});

  @override
  State<DoctorsListScreen> createState() => _DoctorsListScreenState();
}

class _DoctorsListScreenState extends State<DoctorsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  FilterState _filterState = FilterState();

  late UserProvider _userProvider;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _userProvider.addListener(_syncLocationWithDoctorProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncLocationWithDoctorProvider();
    });

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _userProvider.removeListener(_syncLocationWithDoctorProvider);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncLocationWithDoctorProvider() {
    if (_userProvider.isLoadingLocation || _userProvider.isLoadingProfile) return;

    String fallback = _userProvider.city;
    if (fallback.isEmpty) fallback = _userProvider.district;
    if (fallback.isEmpty) fallback = _userProvider.userSavedAddress;

    context.read<DoctorProvider>().updateLocationFromUserProvider(
      lat: _userProvider.latitude,
      lng: _userProvider.longitude,
      fallbackLocation: fallback,
    );
  }

  void _onScroll() {
    final provider = context.read<DoctorProvider>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!provider.isLoadingMore && provider.hasMoreData) {
        provider.fetchNearestDoctors();
      }
    }
  }

  // 🚀 ତାରିଖ ଏବଂ ଡିପାର୍ଟମେଣ୍ଟ୍ ଫିଲ୍ଟର୍ ଲଜିକ୍ (କ୍ଲିନିକ୍ ଫିଲ୍ଟର୍ ହଟାଯାଇଛି)
  List<Doctor> _getFilteredDoctors(List<Doctor> allDoctors) {
    final query = _filterState.query.toLowerCase().trim();
    
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    final List<String> monthNames = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    final String todayShort = "${now.day} ${monthNames[now.month]}";
    final String tomorrowShort = "${tomorrow.day} ${monthNames[tomorrow.month]}";

    var temp = allDoctors.where((doc) {
      // ୧. ସର୍ଚ୍ଚ ଏବଂ ସ୍ପେସିଆଲିଟି (Departments)
      final matchesSearch = doc.name.toLowerCase().contains(query) || doc.specialty.toLowerCase().contains(query);
      final matchesSpec = _filterState.specialty == "All" || doc.specialty.toLowerCase() == _filterState.specialty.toLowerCase();
      
      // ୨. 🚀 Availability ତାରିଖ ମ୍ୟାଚିଂ (କ୍ଲିନିକ୍ ଲଜିକ୍ ଏଠାରୁ ହଟାଯାଇଛି)
      final String availableDateText = doc.nextAvailable; 
      
      final matchesToday = !_filterState.isAvailableToday || availableDateText.contains(todayShort);
      final matchesTomorrow = !_filterState.isAvailableTomorrow || availableDateText.contains(tomorrowShort);

      return matchesSearch && matchesSpec && matchesToday && matchesTomorrow;
    }).toList();

    // ୩. ସର୍ଟିଂ ଲଜିକ୍
    if (_filterState.sortBy == 'price_low') {
      temp.sort((a, b) => (a.price).compareTo(b.price));
    } else if (_filterState.sortBy == 'experience') {
      temp.sort((a, b) {
        final int expA = int.tryParse(a.experience.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final int expB = int.tryParse(b.experience.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return expB.compareTo(expA);
      });
    }
    return temp;
  }

  void _onSearchChanged() {
    setState(() => _filterState.query = _searchController.text);
  }

  void _handleFilterChange(FilterState newState) {
    setState(() => _filterState = newState);
  }

  @override
  Widget build(BuildContext context) {
    final doctorProvider = context.watch<DoctorProvider>();
    final userProvider = context.watch<UserProvider>();
    final isOdia = context.watch<LanguageController>().currentLocale.languageCode == 'or';

    final allDoctors = doctorProvider.doctorsList; 
    final filteredDoctors = _getFilteredDoctors(allDoctors);
    
    final isPageLoading = doctorProvider.isListFirstLoading || userProvider.isLoadingLocation;
    final showEmpty = !isPageLoading && filteredDoctors.isEmpty;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            GlobalSearchHeader(
              controller: _searchController,
              hintText: "Search name or specialty...", // କ୍ଲିନିକ୍ ୱାର୍ଡ ହଟାଗଲା
              onClear: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
                setState(() {}); 
              },
            ),

            Expanded(
              child: isPageLoading
                  ? _buildShimmerList()
                  : AppRefresher(
                      onRefresh: () async =>
                          doctorProvider.fetchNearestDoctors(isRefresh: true),
                      child: showEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    child: SizedBox(
                                      height: constraints.maxHeight,
                                      child: _buildEmptyState(
                                        context: context, 
                                        currentLocation: userProvider.fullAddress,
                                        hasDoctorsInLocation: allDoctors.isNotEmpty, 
                                      ),
                                    ),
                                  ),
                            )
                          : CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: DoctorFilters(
                                    currentFilters: _filterState,
                                    // 🚀 SENIOR DEV LOGIC: ଡାକ୍ତରଙ୍କ ଲିଷ୍ଟ୍ ରୁ Unique Departments ବାହାର କରି ପଠାଯାଇଛି
                                    departments: allDoctors
                                        .map((doc) => doc.specialty)
                                        .where((specialty) => specialty.isNotEmpty)
                                        .toSet()
                                        .toList(),
                                    onFilterChanged: _handleFilterChange,
                                  ),
                                ),
                                SliverPadding(
                                  padding: EdgeInsetsGeometry.fromLTRB(context.spaceMd, context.spaceXs, context.spaceMd, 0),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate((context, index) {
                                      if (index == filteredDoctors.length) {
                                        return doctorProvider.isLoadingMore
                                            ? Padding(padding: EdgeInsets.all(context.spaceMd), child: const Center(child: CircularProgressIndicator()))
                                            : const SizedBox.shrink();
                                      }
                                      final doctor = filteredDoctors[index];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: context.spaceXs),
                                        child: DoctorCardWidget(doctor: doctor, isOdia: isOdia, isVertical: false),
                                      );
                                    }, childCount: filteredDoctors.length + 1),
                                  ),
                                ),
                                SliverToBoxAdapter(child: context.gapXxl),
                              ],
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 🚀 DYNAMIC EMPTY STATE (Filters vs Location)
  // =========================================================================
  Widget _buildEmptyState({
    required BuildContext context, 
    required String currentLocation,
    required bool hasDoctorsInLocation, 
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool isFilterEmpty = hasDoctorsInLocation; 

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(color: colorScheme.errorContainer.withValues(alpha: 0.3), shape: BoxShape.circle),
              child: Icon(
                isFilterEmpty ? LucideIcons.searchX : LucideIcons.mapPinOff, 
                size: 50, 
                color: colorScheme.error
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              isFilterEmpty ? "No matches found" : "We aren't here yet!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            
            Text(
              isFilterEmpty 
                  ? "Try adjusting your search or filters to see more doctors."
                  : (currentLocation == "Locating..." || currentLocation.isEmpty || currentLocation == "Location Unavailable"
                      ? "Please set your exact location to find the best doctors near you."
                      : "Sorry, we currently don't have any partner doctors in '$currentLocation'."),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            SizedBox(
              height: 50, width: double.infinity,
              child: isFilterEmpty
                  ? FilledButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _filterState = FilterState(); 
                        });
                      },
                      icon: const Icon(LucideIcons.refreshCcw),
                      label: const Text("Clear Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationPickerScreen(), fullscreenDialog: true));
                        if (result != null && result is String) {
                          if (context.mounted) {
                            final cleanCity = result.trim();
                            context.read<UserProvider>().updateManualLocation(context, cleanCity, 0.0, 0.0);
                          }
                        }
                      },
                      icon: const Icon(LucideIcons.mapPin),
                      label: const Text("Change Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: EdgeInsets.all(context.spaceMd),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(padding: EdgeInsets.only(bottom: context.spaceMd), child: const DoctorCardSkeleton(isVertical: false)),
    );
  }
}