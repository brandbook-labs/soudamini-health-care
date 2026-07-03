class Clinic {
  final String id;
  final String slug;
  final String name;
  final String location;
  final String address;
  final String distance;
  final String rating;
  final String image;
  final bool isOpen;
  final bool is24h;
  final List<String> tags;
  final String phone;
  final Map<String, dynamic> fullData;

  Clinic({
    required this.id,
    required this.slug,
    required this.name,
    required this.location,
    required this.address,
    required this.distance,
    required this.rating,
    required this.image,
    required this.isOpen,
    required this.is24h,
    required this.tags,
    required this.phone,
    required this.fullData,
  });

  factory Clinic.fromJson(Map<String, dynamic> json) {
    final city = json['city']?.toString() ?? '';
    final state = json['state']?.toString() ?? '';
    String displayLocation = json['address']?.toString() ?? "Address not available";
    
    if (city.isNotEmpty) {
      displayLocation = "$city${state.isNotEmpty ? ', $state' : ''}";
    }

    final opHours = json['operating_hours'] ?? {};
    final facilities = List<String>.from(json['facilities'] ?? []);

    // 🚀 SAFE IMAGE EXTRACTION (No hardcoded images)
    String imageUrl = "";
    if (json['logo'] != null && json['logo'].toString().isNotEmpty) {
      imageUrl = json['logo'].toString();
    }

    // 🚀 SAFE PHONE EXTRACTION (Array to String)
    String parsedPhone = "";
    if (json['phone'] is List && (json['phone'] as List).isNotEmpty) {
      parsedPhone = json['phone'][0].toString();
    } else if (json['phone'] != null && json['phone'].toString().isNotEmpty) {
      parsedPhone = json['phone'].toString();
    }

    // 🚀 SAFE DISTANCE EXTRACTION
    String parsedDistance = "";
    if (json['distance'] != null) {
      parsedDistance = json['distance'].toString();
    }

    return Clinic(
      id: json['_id']?.toString() ?? "",
      slug: json['slug']?.toString() ?? "",
      name: json['name']?.toString() ?? "Unknown Clinic",
      location: displayLocation,
      address: json['address']?.toString() ?? "Address not available",
      distance: parsedDistance, // 🔥 API ରୁ ରିଅଲ୍ ଡାଟା
      rating: "4.5", // ଡିଫଲ୍ଟ ବା ଆପଣ API ରୁ ଆଣିପାରିବେ
      image: imageUrl, // 🔥 ପ୍ରକୃତ ଲୋଗୋ ବା ଖାଲି
      isOpen: opHours['isOpen'] == true,
      is24h: opHours['is24h'] == true,
      tags: facilities.isNotEmpty ? facilities : ["General", "Clinic"],
      phone: parsedPhone, // 🔥 ସୁରକ୍ଷିତ ଫୋନ୍ ନମ୍ବର୍
      fullData: json,
    );
  }
}