import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/core/utils/theme_utils.dart'; 
import 'package:my_new_app/services/api_service.dart'; // 🚀 API Service Import

class LocationPickerScreen extends StatefulWidget {
  final String? currentCity; 

  const LocationPickerScreen({super.key, this.currentCity});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = "";
  String? _matchedCity;

  // 🚀 API ରୁ ଆସିବାକୁ ଥିବା Data ପାଇଁ Variables
  List<String> _activeCities = [];
  List<String> _popularCities = [];
  
  bool _isLoading = true; // API କଲ୍ ପାଇଁ ଲୋଡିଂ ଷ୍ଟେଟ୍
  bool _isGpsLoading = false; // "Use Current Location" ପାଇଁ ଲୋଡିଂ

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchLocationsFromApi(); // 🚀 ସ୍କ୍ରିନ୍ ଖୋଲିବା ମାତ୍ରେ API କଲ୍
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // =======================================================================
  // 🚀 LOGIC 1: FETCH API DATA
  // =======================================================================
  Future<void> _fetchLocationsFromApi() async {
    try {
      final response = await _apiService.getClinicLocations();
      
      // ନୋଟ୍: ଆପଣଙ୍କର ବ୍ୟାକ୍-ଏଣ୍ଡ୍ { popular: [], all: [] } ଫର୍ମାଟ୍ ରେ ଡାଟା ଦେଉଛି
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        
        setState(() {
          // Dynamic Data ସେଟ୍ କରନ୍ତୁ (Type Casting ପାଇଁ List<String>.from ବ୍ୟବହାର)
          _popularCities = List<String>.from(data['popular'] ?? []);
          _activeCities = List<String>.from(data['all'] ?? []);
          _isLoading = false;

          _matchedCity = _findBestMatchCity(widget.currentCity, _activeCities);
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
      setState(() {
        _isLoading = false;
      });
      // Error ହେଲେ ୟୁଜର୍ କୁ ଏକ ଛୋଟ ମେସେଜ୍ ଦେଇପାରିବେ (Optional)
    }
  }

  String? _findBestMatchCity(String? currentLoc, List<String> availableCities) {
    if (currentLoc == null || currentLoc.isEmpty) return null;
    
    // ୧. ଯଦି ସିଧାସଳଖ ଏକ୍ସାକ୍ଟ ମ୍ୟାଚ୍ ହୁଏ
    if (availableCities.contains(currentLoc)) return currentLoc;

    // ୨. କମା (,) ଦ୍ୱାରା ଅଲଗା କରିବା ("Banksahi, Bhadrak" -> ["Banksahi", "Bhadrak"])
    List<String> parts = currentLoc.split(',').map((e) => e.trim()).toList();
    
    // ୩. ପ୍ରଥମେ Banksahi ଖୋଜିବ, ନମିଳିଲେ Bhadrak ଖୋଜିବ
    for (String part in parts) {
      for (String city in availableCities) {
        if (city.toLowerCase() == part.toLowerCase()) {
          return city; // ଯେଉଁଟା ପ୍ରଥମେ ମିଳିଲା ସେଇଟାକୁ ରିଟର୍ଣ୍ଣ କରିବ
        }
      }
    }
    return null; // କିଛି ନ ମିଳିଲେ ନଲ୍
  }

  // =======================================================================
  // 🚀 LOGIC 2: USE CURRENT LOCATION (GPS) - [ULTIMATE FALLBACK FIX]
  // =======================================================================
  Future<void> _useCurrentLocation() async {
    setState(() {
      _isGpsLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
            
      // ୧. ସାଙ୍ଗେ ସାଙ୍ଗେ ନୂଆ GPS ଲୋକେସନ୍ ଆଣନ୍ତୁ
      await userProvider.forceRefreshGPSLocation(context);

      if (!mounted) return;

      String gpsCity = userProvider.city;
      String gpsDistrict = userProvider.district;
      String fallbackAddress = userProvider.fullAddress; // 🚀 NEW: Geocoding ଫେଲ୍ ହେଲେ ଏହା ବ୍ୟବହାର ହେବ

      // ୨. ଆମର ସ୍ମାର୍ଟ ମ୍ୟାଚିଂ ଲଜିକ୍
      String? matchedGpsLocation = _findBestMatchCity(gpsCity, _activeCities) ?? 
                                   _findBestMatchCity(gpsDistrict, _activeCities);

      // ୩. 🚀 [SUPER SENIOR LOGIC]: ଫାଇନାଲ୍ ଲୋକେସନ୍ ସିଲେକ୍ଟ 
      // ଯଦି Geocoding ଫେଲ୍ ହୋଇଛି, ତେବେ fallbackAddress ("Location Found" ବା ଯାହା ବି ଅଛି) ନିଅନ୍ତୁ!
      String finalLocation = matchedGpsLocation ?? 
          (gpsCity.isNotEmpty ? gpsCity : 
          (gpsDistrict.isNotEmpty ? gpsDistrict : fallbackAddress));

      // ୪. ଯଦି କୌଣସି ବି ଲୋକେସନ୍ ମିଳିଲା (ଏବେ ଏହା କେବେବି ଖାଲି ରହିବ ନାହିଁ!)
      if (finalLocation.isNotEmpty && finalLocation != "Locating...") {
        Navigator.pop(context, finalLocation);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Could not fetch location. Please ensure GPS is ON and permission is granted."),
            backgroundColor: context.colorScheme.error,
          ),
        );
      }
    } catch (e) {
      debugPrint("🚀 [SUPER SENIOR DEBUG]: GPS Catch Error -> $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGpsLoading = false;
        });
      }
    }
  }

  // =======================================================================
  // SEARCH FILTER LOGIC
  // =======================================================================
  List<String> get _filteredLocations {
    if (_searchQuery.isEmpty) return _activeCities;
    return _activeCities
        .where(
          (city) => city.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  bool get _isServiceUnavailable {
    if (_searchQuery.isEmpty) return false;
    return _filteredLocations.isEmpty;
  }

  void _onLocationSelected(String location) {
    Navigator.pop(context, location);
  }

  // =======================================================================
  // UI BUILD (ସମ୍ପୂର୍ଣ୍ଣ ଅକ୍ଷୁର୍ଣ୍ଣ ଅଛି)
  // =======================================================================
  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Select Location",
          style: context.titleLg?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.x, color: context.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- 1. ENHANCED SEARCH BAR ---
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spaceMd,
              0,
              context.spaceMd,
              context.spaceMd,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _searchFocus.hasFocus
                      ? context.colorScheme.primary
                      : context.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: context.bodyLg,
                decoration: InputDecoration(
                  hintText: "Search city or pincode...",
                  hintStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 20,
                    color: _searchFocus.hasFocus
                        ? context.colorScheme.primary
                        : context.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.xCircle, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // --- 2. GPS / CURRENT LOCATION ROW ---
          if (_searchQuery.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
              child: Material(
                color: context.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  // 🚀 GPS ବ୍ୟବହାର କରନ୍ତୁ ବା ଲୋଡିଂ ଦେଖାନ୍ତୁ
                  onTap: _isGpsLoading ? null : _useCurrentLocation, 
                  child: Padding(
                    padding: EdgeInsets.all(context.spaceMd),
                    child: Row(
                      children: [
                        // GPS ଲୋଡିଂ ଇଣ୍ଡିକେଟର୍ 
                        _isGpsLoading 
                          ? SizedBox(
                              width: 22, height: 22, 
                              child: CircularProgressIndicator(strokeWidth: 2, color: context.colorScheme.primary)
                            )
                          : Icon(
                              LucideIcons.crosshair,
                              color: context.colorScheme.primary,
                              size: 22,
                            ),
                        context.gapSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Use Current Location",
                                style: context.titleMd?.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Enable GPS to find nearest services",
                                style: context.bodySm?.copyWith(
                                  color: context.colorScheme.primary
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: context.colorScheme.primary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (_searchQuery.isEmpty) context.gapMd,

          // --- 3. SCROLLABLE LIST OR LOADER ---
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) // 🚀 API ଲୋଡିଂ 
              : _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // A. EMPTY STATE (Service Unavailable)
    if (_isServiceUnavailable) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(context.spaceXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mapPinOff,
                  size: 40,
                  color: context.colorScheme.outline,
                ),
              ),
              context.gapLg,
              Text(
                "Not available in \"$_searchQuery\"",
                style: context.titleLg?.copyWith(fontWeight: FontWeight.bold),
              ),
              context.gapSm,
              Text(
                "We are currently expanding! We will be in your area soon.",
                textAlign: TextAlign.center,
                style: context.bodyMd?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // B. LIST CONTENT
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
      physics: const BouncingScrollPhysics(),
      children: [
        // --- POPULAR CITIES SECTION ---
        if (_searchQuery.isEmpty && _popularCities.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "POPULAR CITIES",
              style: context.labelMd?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _popularCities.map((city) {
              final isSelected = _matchedCity == city;
              return FilterChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (_) => _onLocationSelected(city),
                checkmarkColor: context.colorScheme.onPrimary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: context.colorScheme.surface,
                selectedColor: context.colorScheme.primary,
                side: BorderSide(
                  color: isSelected
                      ? Colors.transparent
                      : context.colorScheme.outline.withOpacity(0.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          if (_filteredLocations.isNotEmpty) ...[
            Text(
              "ALL CITIES",
              style: context.labelMd?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],

        // --- ALL CITIES LIST ---
        ..._filteredLocations.map((city) {
          final bool isSelected = _matchedCity == city;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colorScheme.primary.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: () => _onLocationSelected(city),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mapPin,
                  size: 18,
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                city,
                style: context.bodyLg?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? context.colorScheme.primary
                      : context.colorScheme.onSurface,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      LucideIcons.check,
                      size: 20,
                      color: context.colorScheme.primary,
                    )
                  : null,
            ),
          );
        }),

        // Bottom padding to avoid cut-off
        SizedBox(height: context.spaceXl),
      ],
    );
  }
}