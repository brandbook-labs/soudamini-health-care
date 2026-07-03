import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lucide_icons/lucide_icons.dart';

// 🟢 [FIXED]: Added 'district' field to the model
class UserFullLocation {
  final Position position;
  final String fullAddress;
  final String city;
  final String district; // <-- 🚀 NEWLY ADDED
  final String state;
  final String country;
  final String localArea;
  final String pinCode;

  UserFullLocation({
    required this.position,
    required this.fullAddress,
    required this.city,
    required this.district, // <-- 🚀 NEWLY ADDED
    required this.state,
    required this.country,
    required this.localArea,
    required this.pinCode,
  });
}

class LocationService {
  static Future<UserFullLocation?> getExactLocationWithAddress(
    BuildContext context,
  ) async {
    try {
      Position? position = await checkAndRequestLocation(context);

      if (position == null) {
        return null; // GPS ଅନ୍ ନାହିଁ ବା ପରମିସନ୍ ନାହିଁ 
      }

      // 🚀 [SUPER SENIOR FIX]: Geocoding Package Bug ପାଇଁ ସୁରକ୍ଷା ବଳୟ
      String localArea = "";
      String city = "";
      String district = "";
      String state = "";
      String country = "";
      String pinCode = "";
      String fullAddress = "";

      try {
        // କେବଳ ଏତିକି କୋଡ୍ ହିଁ "Unexpected null value" ଦେଉଥିଲା
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;

          // ଏହାକୁ ଆହୁରି ସୁରକ୍ଷିତ କରାଗଲା (fallback to place.name)
          localArea = place.subLocality ?? place.thoroughfare ?? place.name ?? "";
          city = place.locality ?? ""; 
          district = place.subAdministrativeArea ?? ""; 
          state = place.administrativeArea ?? "";
          country = place.country ?? "";
          pinCode = place.postalCode ?? "";

          fullAddress = [
            localArea,
            city.isNotEmpty ? city : district,
            state,
            pinCode,
          ].where((element) => element.isNotEmpty).join(", ");
        }
      } catch (geoError) {
        // ଯଦି ପ୍ୟାକେଜ୍ କ୍ରାସ୍ ହୁଏ, ତଥାପି ଆମର ମେନ୍ କୋଡ୍ କ୍ରାସ୍ ହେବନାହିଁ!
        debugPrint("🚀 Geocoding Package Crashed (Ignored): $geoError");
      }

      // 🚀 ମ୍ୟାଜିକ୍ ଏଠାରେ ଅଛି: Geocoding ଫେଲ୍ ହେଲେ ମଧ୍ୟ ଆମେ Position ପାସ୍ କରୁଛୁ!
      return UserFullLocation(
        position: position,
        fullAddress: fullAddress.isNotEmpty ? fullAddress : "Location Found",
        city: city,
        district: district,
        state: state,
        country: country,
        localArea: localArea,
        pinCode: pinCode,
      );

    } catch (e) {
      debugPrint("Critical Error fetching address: $e");
    }

    return null;
  }

  // =========================================================================
  // ଆପଣଙ୍କର ପୁରୁଣା ପରମିସନ୍ (PERMISSION) କୋଡ୍ ସମ୍ପୂର୍ଣ୍ଣ ଅକ୍ଷୁର୍ଣ୍ଣ ଅଛି
  // =========================================================================

  static Future<Position?> checkAndRequestLocation(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showDialog(
        context,
        title: "Location Disabled",
        body: "Please turn on your GPS to continue.",
        isSettings: true,
      );
      return null;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      return await Geolocator.getCurrentPosition();
    }

    if (permission == LocationPermission.denied) {
      final bool userWantsToGrant = await _showPrePermissionDialog(context);
      if (!userWantsToGrant) return null;

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showDialog(
        context,
        title: "Permission Required",
        body: "Location is permanently denied. Please enable it in settings.",
        isSettings: true,
      );
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<bool> _showPrePermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(LucideIcons.mapPin, size: 40, color: Colors.blue),
            title: const Text("Enable Location?"),
            content: const Text(
              "We need your location to find doctors and labs near you.\n\n"
              "If you select 'Only This Time', we will ask you again next time you open the app.",
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Allow Access"),
              ),
            ],
          ),
        ) ??
        false;
  }

  static void _showDialog(
    BuildContext context, {
    required String title,
    required String body,
    bool isSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          if (isSettings)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: const Text("Open Settings"),
            ),
        ],
      ),
    );
  }
}
