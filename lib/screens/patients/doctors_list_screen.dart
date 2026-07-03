import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

  // 🚀 ତାରିଖ ଏବଂ କ୍ଲିନିକ୍ ଫିଲ୍ଟର୍ ଲଜିକ୍ (ସଂଶୋଧିତ)
  List<Doctor> _getFilteredDoctors(List<Doctor> allDoctors) {
    final query = _filterState.query.toLowerCase().trim();
    
    // 🚀 ଆଜି ଏବଂ ଆସନ୍ତାକାଲି ର ତାରିଖ ବାହାର କରିବା (ମଡେଲ୍ ରେ ଆସୁଥିବା ଫର୍ମାଟ୍ ଅନୁଯାୟୀ)
    // ଉଦାହରଣ: "Wednesday, 1 April"
    // ଯେହେତୁ API ରୁ String ଆକାରରେ ଆସୁଛି (next_slot), ଆମେ ମ୍ୟାଚିଂ କୁ ଟିକେ ସ୍ମାର୍ଟ କରିବା
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    // Day ଏବଂ Month ବାହାର କରିବା (e.g., "1 April")
    final List<String> monthNames = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    final String todayShort = "${now.day} ${monthNames[now.month]}";
    final String tomorrowShort = "${tomorrow.day} ${monthNames[tomorrow.month]}";

    var temp = allDoctors.where((doc) {
      // ୧. ସର୍ଚ୍ଚ ଏବଂ ସ୍ପେସିଆଲିଟି
      final matchesSearch = doc.name.toLowerCase().contains(query) || doc.specialty.toLowerCase().contains(query);
      final matchesSpec = _filterState.specialty == "All" || doc.specialty.toLowerCase() == _filterState.specialty.toLowerCase();
      
      // ୨. 🚀 କ୍ଲିନିକ୍ ଫିଲ୍ଟର୍ (ସିଧାସଳଖ ମଡେଲ୍ ପ୍ରପର୍ଟି ବ୍ୟବହାର କରାଗଲା)
      final String clinicName = doc.clinicName; // No fullData needed!
      final matchesClinic = _filterState.clinic == "All" || clinicName == _filterState.clinic;
      
      // ୩. 🚀 Availability ତାରିଖ ମ୍ୟାଚିଂ (ସିଧାସଳଖ ମଡେଲ୍ ପ୍ରପର୍ଟି ବ୍ୟବହାର କରାଗଲା)
      final String availableDateText = doc.nextAvailable; // ଉଦାହରଣ: "Wednesday, 1 April 9:00 AM"
      
      // ଯଦି ଫିଲ୍ଟର୍ ଅନ୍ ଅଛି, ତେବେ ଟେକ୍ସଟ୍ ଭିତରେ "1 April" ଇତ୍ୟାଦି ଖୋଜିବା
      final matchesToday = !_filterState.isAvailableToday || availableDateText.contains(todayShort);
      final matchesTomorrow = !_filterState.isAvailableTomorrow || availableDateText.contains(tomorrowShort);

      return matchesSearch && matchesSpec && matchesClinic && matchesToday && matchesTomorrow;
    }).toList();

    // ୪. ସର୍ଟିଂ ଲଜିକ୍
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

    // 🚀 ୧. ଉଭୟ ସମ୍ପୂର୍ଣ୍ଣ ଲିଷ୍ଟ୍ ଏବଂ ଫିଲ୍ଟର୍ ହୋଇଥିବା ଲିଷ୍ଟ୍ ବାହାର କରିବା
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
              hintText: "Search name, specialty, or clinic...", 
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
                                      // 🚀 ୨. ସ୍ମାର୍ଟ Empty State କୁ ପାରାମିଟର୍ସ ପଠାଇବା
                                      child: _buildEmptyState(
                                        context: context, 
                                        currentLocation: userProvider.fullAddress,
                                        hasDoctorsInLocation: allDoctors.isNotEmpty, // ପ୍ରକୃତରେ ସେହି ଅଞ୍ଚଳରେ ଡାକ୍ତର ଅଛନ୍ତି କି ନାହିଁ
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
                                    clinics: allDoctors
                                        .map((doc) => doc.clinicName) 
                                        .where((name) => name.isNotEmpty && name != 'Private Clinic') 
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

    // ଯଦି ଲୋକେସନ୍ ରେ ଡାକ୍ତର ଅଛନ୍ତି, କିନ୍ତୁ ଆମ ଲିଷ୍ଟ୍ ଖାଲି ଅଛି, ଅର୍ଥାତ୍ ଏହା ଫିଲ୍ଟର୍ ଯୋଗୁଁ ହୋଇଛି!
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
              // 🚀 ଆଇକନ୍ ଚେଞ୍ଜ: ଫିଲ୍ଟର୍ ପାଇଁ SearchX, ଲୋକେସନ୍ ପାଇଁ MapPinOff
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
                  // 🚀 BUTTON 1: CLEAR FILTERS
                  ? FilledButton.icon(
                      onPressed: () {
                        _searchController.clear();
                        FocusScope.of(context).unfocus();
                        setState(() {
                          _filterState = FilterState(); // ସବୁ ଫିଲ୍ଟର୍ ରିସେଟ୍ କରିଦିଅନ୍ତୁ
                        });
                      },
                      icon: const Icon(LucideIcons.refreshCcw),
                      label: const Text("Clear Filters", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    )
                  // 🚀 BUTTON 2: CHANGE LOCATION
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