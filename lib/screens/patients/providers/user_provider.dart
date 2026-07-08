import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'package:my_new_app/screens/patients/providers/clinic_provider.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/services/location_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ===========================================================================
  // 🟢 1. USER PROFILE STATE
  // ===========================================================================
  bool isLoadingProfile = false;
  String userName = "Guest";
  String userProfileImage = "";
  String userPhone = "";
  String userAge = "";
  String userGender = "";
  String userEmail = "";
  String userSavedAddress = "";

  // ===========================================================================
  // 🟢 2. LOCATION STATE
  // ===========================================================================
  bool isLoadingLocation = false;
  double latitude = 0.0;
  double longitude = 0.0;
  String city = "";
  String district = "";
  String localArea = "";
  String fullAddress = "Locating...";

  // ===========================================================================
  // 🚀 [CORE ARCHITECTURE]: APP INITIALIZATION & FALLBACK ROUTING
  // ===========================================================================
  /// ଆପ୍ ଷ୍ଟାର୍ଟ ହେବା ମାତ୍ରେ ଏହା କଲ୍ ହେବ।
  /// ଏହା ପ୍ରୋଫାଇଲ୍ ଏବଂ ଲୋକେସନ୍ ଆଣି ଏକ ସ୍ମାର୍ଟ ଡେସିସନ୍ ନେବ ଯେ API କୁ କଣ ପଠାଯିବ।
  Future<void> initializeData(BuildContext context) async {
    try {
      debugPrint(
        "🚀 [SYSTEM BOOT]: Initializing Soudamini Healthcare App Core Data...",
      );

      // ୧. ପ୍ରଥମେ ୟୁଜର୍ ର ପ୍ରୋଫାଇଲ୍ ଡାଟା ଲୋଡ୍ କରନ୍ତୁ (ଏଥିରୁ Address ମିଳିପାରେ)
      await fetchUserProfile();

      // ୨. ତା'ପରେ GPS କିମ୍ବା Cache ରୁ ଲୋକେସନ୍ ଆଣନ୍ତୁ
      await fetchUserLocation(context);

      // 🛡️ SECURITY & MEMORY CHECK: ଯଦି ସ୍କ୍ରିନ୍ ବନ୍ଦ ହୋଇଯାଇଛି, ତେବେ ଅଟକି ଯାଆନ୍ତୁ
      if (!context.mounted) {
        debugPrint(
          "⚠️ [INIT ABORT]: Context unmounted. Preventing memory leak.",
        );
        return;
      }

      // ୩. 🚀 THE WATERFALL FALLBACK ENGINE (Smart Routing)
      String fallbackString = "";
      double finalLat = latitude;
      double finalLng = longitude;

      final bool hasGps = (finalLat != 0.0 && finalLng != 0.0);

      if (hasGps) {
        // ▶ TIER 1: Perfect GPS Data
        fallbackString = city.isNotEmpty
            ? city
            : (district.isNotEmpty ? district : "Current Location");
        debugPrint(
          "📍 [ROUTING - TIER 1]: GPS Active -> Lat: $finalLat, Lng: $finalLng | Area: $fallbackString",
        );
      } else if (userSavedAddress.isNotEmpty) {
        // ▶ TIER 2: GPS Failed/Denied, BUT User has logged in and saved address
        fallbackString = userSavedAddress;
        finalLat = 0.0;
        finalLng = 0.0;
        debugPrint(
          "📍 [ROUTING - TIER 2]: GPS Offline. Using Profile Address -> $fallbackString",
        );
      } else if (fullAddress.isNotEmpty &&
          fullAddress != "Locating..." &&
          fullAddress != "Location Unavailable") {
        // ▶ TIER 3: Generic Cache Fallback
        fallbackString = fullAddress;
        debugPrint(
          "📍 [ROUTING - TIER 3]: Using generic cached address -> $fallbackString",
        );
      }

      // ୪. 🚀 TRIGGER PARALLEL APIs
      // ଯଦି ଆମ ପାଖରେ ନିର୍ଭରଯୋଗ୍ୟ ଡାଟା ଅଛି (Coordinates or Address Text)
      if (hasGps || fallbackString.isNotEmpty) {
        debugPrint(
          "⚡ [API TRIGGER]: Firing Doctor & Clinic Providers parallelly...",
        );

        try {
          context.read<DoctorProvider>().updateLocationFromUserProvider(
            lat: finalLat,
            lng: finalLng,
            fallbackLocation: fallbackString,
          );

          context.read<ClinicProvider>().updateLocationFromUserProvider(
            lat: finalLat,
            lng: finalLng,
            fallbackLocation: fallbackString,
          );

          debugPrint(
            "✅ [INIT SUCCESS]: All core providers are synced and fetching data.",
          );
        } catch (e) {
          debugPrint(
            "❌ [PROVIDER CRASH]: Failed to update sub-providers -> $e",
          );
        }
      } else {
        debugPrint(
          "⚠️ [STANDBY MODE]: No GPS & No Profile. Waiting for manual user input.",
        );
      }
    } catch (e) {
      debugPrint("❌ [FATAL BOOT ERROR]: -> $e");
    }
  }

  // ===========================================================================
  // 🚀 USER PROFILE FETCHING
  // ===========================================================================
  Future<void> fetchUserProfile() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) return;

    isLoadingProfile = true;
    notifyListeners();

    try {
      final response = await _apiService.getUserProfile();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;

        userName = data['name'] ?? "Guest";
        userProfileImage =
            data['profile'] ?? data['profile_image'] ?? data['image'] ?? "";
        userPhone = data['phone'] ?? "";
        userPhone = data['phone'] ?? "";
        userAge = data['age'] ?? "";
        userGender = data['gender'] ?? "";
        userSavedAddress = data['address'] ?? "";

        // 💾 Cache essential profile data
        await Future.wait([
          _storage.write(key: 'user_name', value: userName),
          _storage.write(key: 'user_profile', value: userProfileImage),
          _storage.write(key: 'user_address', value: userSavedAddress),
          _storage.write(key: 'user_age', value: userAge),
          _storage.write(key: 'user_gender', value: userGender),
        ]);
      }
    } catch (e) {
      debugPrint("⚠️ [Profile Fetch Error]: Falling back to cache -> $e");
      userName = await _storage.read(key: 'user_name') ?? "Guest";
      userProfileImage = await _storage.read(key: 'user_profile') ?? "";
      userSavedAddress = await _storage.read(key: 'user_address') ?? "";
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 🚀 LOCATION FETCHING (WITH CACHE STRATEGY)
  // ===========================================================================
  Future<void> fetchUserLocation(BuildContext context) async {
    isLoadingLocation = true;
    notifyListeners();

    try {
      // ୧. ପ୍ରଥମେ Cache ଚେକ୍ କରନ୍ତୁ (ଆପ୍ କୁ ଫାଷ୍ଟ୍ କରିବା ପାଇଁ)
      final savedAddress = await _storage.read(key: 'last_known_address');
      final savedLat = await _storage.read(key: 'last_known_lat');
      final savedLng = await _storage.read(key: 'last_known_lng');
      final savedCity = await _storage.read(key: 'last_known_city');
      final savedDistrict = await _storage.read(key: 'last_known_district');

      if (savedAddress != null &&
          savedAddress.isNotEmpty &&
          savedLat != null &&
          savedLng != null) {
        fullAddress = savedAddress;
        latitude = double.tryParse(savedLat) ?? 0.0;
        longitude = double.tryParse(savedLng) ?? 0.0;
        city = savedCity ?? "";
        district = savedDistrict ?? "";

        isLoadingLocation = false;
        notifyListeners();
        return; // Cache ମିଳିଗଲା, ବାହାରି ଯାଆନ୍ତୁ
      }

      // ୨. Cache ନଥିଲେ ଫ୍ରେସ୍ (Fresh) GPS ଲୋକେସନ୍ ଆଣନ୍ତୁ
      final locationData = await LocationService.getExactLocationWithAddress(
        context,
      );

      if (locationData != null) {
        latitude = locationData.position.latitude;
        longitude = locationData.position.longitude;
        city = locationData.city;
        district = locationData.district;
        localArea = locationData.localArea;

        // ସଠିକ୍ ଠିକଣା ଫର୍ମାଟିଂ
        if (localArea.isNotEmpty && city.isNotEmpty) {
          fullAddress = "$localArea, $city";
        } else if (localArea.isNotEmpty && district.isNotEmpty) {
          fullAddress = "$localArea, $district";
        } else if (city.isNotEmpty) {
          fullAddress = city;
        } else if (district.isNotEmpty) {
          fullAddress = district;
        } else {
          fullAddress = "Location Found";
        }

        // ନୂଆ ଡାଟା କୁ Cache ରେ ସେଭ୍ କରନ୍ତୁ
        _saveLocationToStorage(
          fullAddress,
          latitude,
          longitude,
          city,
          district,
        );
      } else {
        // ୩. GPS ସମ୍ପୂର୍ଣ୍ଣ ଫେଲ୍ ହେଲେ ପ୍ରୋଫାଇଲ୍ ଠିକଣା ଉପରେ ନିର୍ଭର କରନ୍ତୁ
        fullAddress = userSavedAddress.isNotEmpty
            ? userSavedAddress
            : "Location Unavailable";
      }
    } catch (e) {
      debugPrint("❌ [Location Fetch Error]: $e");
      fullAddress = userSavedAddress.isNotEmpty
          ? userSavedAddress
          : "Location Error";
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  // ===========================================================================
  // 🚀 MANUAL LOCATION UPDATE (From Search Picker)
  // ===========================================================================
  void updateManualLocation(
    BuildContext context,
    String newAddress,
    double newLat,
    double newLng,
  ) {
    fullAddress = newAddress;
    city = newAddress;
    district = newAddress;
    latitude = newLat;
    longitude = newLng;

    notifyListeners();

    // 💾 Cache ରେ ସେଭ୍ କରନ୍ତୁ (Workaround: City/District ପାଇଁ newAddress ପାସ୍ କରାଯାଉଛି)
    _saveLocationToStorage(newAddress, newLat, newLng, newAddress, newAddress);

    // ⚡ Update Sub-Providers
    context.read<DoctorProvider>().updateLocationFromUserProvider(
      lat: newLat,
      lng: newLng,
      fallbackLocation: newAddress,
    );

    context.read<ClinicProvider>().updateLocationFromUserProvider(
      lat: newLat,
      lng: newLng,
      fallbackLocation: newAddress,
    );
  }

  // ===========================================================================
  // 🚀 SECURE CACHE MANAGEMENT
  // ===========================================================================
  Future<void> _saveLocationToStorage(
    String address,
    double lat,
    double lng,
    String locCity,
    String locDistrict,
  ) async {
    // Parallel write for better performance
    await Future.wait([
      _storage.write(key: 'last_known_address', value: address),
      _storage.write(key: 'last_known_lat', value: lat.toString()),
      _storage.write(key: 'last_known_lng', value: lng.toString()),
      _storage.write(key: 'last_known_city', value: locCity),
      _storage.write(key: 'last_known_district', value: locDistrict),
    ]);
  }

  /// ୟୁଜର୍ "Use Current Location" ବଟନ୍ ଦବାଇଲେ ଏହା କ୍ୟାସ୍ ଡିଲିଟ୍ କରି Fresh GPS ଆଣିବ।
  Future<void> forceRefreshGPSLocation(BuildContext context) async {
    await Future.wait([
      _storage.delete(key: 'last_known_address'),
      _storage.delete(key: 'last_known_lat'),
      _storage.delete(key: 'last_known_lng'),
      _storage.delete(key: 'last_known_city'),
      _storage.delete(key: 'last_known_district'),
    ]);
    await fetchUserLocation(context);
  }

  // ===========================================================================
  // 🚀 LOGOUT / CLEAR SECURE DATA
  // ===========================================================================
  void clearData() {
    // ୧. Memory Data Reset
    userName = "Guest";
    userProfileImage = "";
    userPhone = "";
    userEmail = "";
    userSavedAddress = "";

    latitude = 0.0;
    longitude = 0.0;
    city = "";
    district = "";
    localArea = "";
    fullAddress = "Locating...";

    isLoadingProfile = false;
    isLoadingLocation = false;

    // ୨. Secure Storage Data Purge (Fire & Forget)
    _storage.deleteAll();

    // ୩. Rebuild UI
    notifyListeners();
  }
}
