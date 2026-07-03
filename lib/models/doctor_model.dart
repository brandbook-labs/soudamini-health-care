class Doctor {
  final String id;
  final String slug; 
  final String name;
  final String specialty;
  final String clinicName;
  final String image;
  final double rating;
  final int reviews;
  final String experience;
  final String location;
  final String city;
  final bool isVerified;
  final bool isSuspended;
  final String nextAvailable;

  // 🚀 [NEW]: Card ରେ ଦେଖାଇବା ପାଇଁ ଫୋନ୍ ଏବଂ ଦୂରତା
  final String phone;
  final String distance;
  final String startTime;
  final String endTime;
  final String slotDate;

  final int price;
  final int originalPrice;
  final List<String> rawEducation;

  final String about;
  final List<String> languages;
  final List<Map<String, dynamic>> education;
  final List<dynamic> availability; 
  final String gender;
  final List<String> mandatoryServices;
  
  final List<dynamic> locations; 

  final bool isValidPlatformPromoted;
  final bool isValidClinicPromoted;
  final int membershipLevel;

  Doctor({
    required this.id,
    required this.slug,
    required this.name,
    required this.specialty,
    required this.clinicName,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.experience,
    required this.location,
    required this.city,
    required this.isVerified,
    required this.isSuspended,
    required this.nextAvailable,
    this.phone = '',      // 🚀 [NEW]
    this.distance = '',   // 🚀 [NEW]
    this.startTime = '',  // 🚀 [NEW]
    this.endTime = '',    // 🚀 [NEW]
    this.slotDate = '',   // 🚀 [NEW]
    this.price = 0,
    this.originalPrice = 0,
    this.rawEducation = const [],
    this.about = '',
    this.languages = const [],
    this.education = const [],
    this.availability = const [],
    this.gender = 'N/A',
    this.mandatoryServices = const [],
    this.locations = const [],
    this.isValidPlatformPromoted = false,
    this.isValidClinicPromoted = false,
    this.membershipLevel = 0,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    
    final bool isProfileData = json.containsKey('locations') && (json['locations'] as List).isNotEmpty;

    String cName = 'Private Clinic';
    String cAddress = 'Odisha';
    String cCity = 'Odisha';
    String cPhone = '';       // 🚀 [NEW]
    String cDistance = '';    // 🚀 [NEW]
    String sTime = '';
    String eTime = '';
    String sDate = '';
    int parsedPrice = 0;
    String availText = "Check Slots";
    
    List<dynamic> allLocations = [];
    List<dynamic> fullAvailabilityArray = [];
    List<String> servicesList = [];

    if (isProfileData) {
      allLocations = json['locations'] as List;
      final Map<String, dynamic> firstLocation = allLocations[0]; 
      
      final clinicMap = firstLocation['clinic'] is Map ? firstLocation['clinic'] : {};
      cName = clinicMap['name']?.toString() ?? cName;
      cAddress = clinicMap['address']?.toString() ?? cAddress;
      cCity = clinicMap['city']?.toString() ?? cCity;
      
      // 🚀 ଫୋନ୍ ଏବଂ ଦୂରତା ବାହାର କରିବା
      if (clinicMap['phone'] is List && (clinicMap['phone'] as List).isNotEmpty) {
        cPhone = clinicMap['phone'][0].toString();
      }
      cDistance = firstLocation['distance']?.toString() ?? '';

      parsedPrice = int.tryParse(firstLocation['consultation_fees']?.toString() ?? '0') ?? 0;
      
      if (firstLocation['services'] is List) {
        servicesList = (firstLocation['services'] as List).map((e) => e.toString()).toList();
      }
      if (firstLocation['availability'] is List) {
        fullAvailabilityArray = firstLocation['availability'];
      }
    } else {
      final clinicMap = json['clinic'] is Map ? json['clinic'] : {};
      cName = clinicMap['name']?.toString() ?? cName;
      cAddress = clinicMap['address']?.toString() ?? cAddress;
      cCity = clinicMap['city']?.toString() ?? cCity;
      
      // 🚀 ଫୋନ୍ ଏବଂ ଦୂରତା ବାହାର କରିବା
      if (clinicMap['phone'] is List && (clinicMap['phone'] as List).isNotEmpty) {
        cPhone = clinicMap['phone'][0].toString();
      }
      cDistance = clinicMap['distance']?.toString() ?? '';

      parsedPrice = int.tryParse(json['consultation_fees']?.toString() ?? '0') ?? 0;

      if (json['availability'] is Map) {
        availText = json['availability']['next_slot']?.toString() ?? "Check Slots";
        sTime = json['availability']['start']?.toString() ?? '';
        eTime = json['availability']['end']?.toString() ?? '';
        sDate = json['availability']['date']?.toString() ?? '';
      }
    }

    String parsedSpecialty = 'General Physician';
    if (json['departments'] is List && (json['departments'] as List).isNotEmpty) {
      if (isProfileData) {
        parsedSpecialty = (json['departments'] as List).map((dept) {
          String rawDept = dept.toString();
          return rawDept.split('-').map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "").join(" ");
        }).join(", "); 
      } else {
        String primaryDept = json['departments'][0].toString();
        parsedSpecialty = primaryDept.split('-').map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "").join(" ");
      }
    }

    String exp = (json['experience']?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    exp = exp.isNotEmpty ? "$exp+ Years" : "N/A";

    List<String> eduList = [];
    if (json['educations'] is List) {
      for (var e in json['educations']) {
        if (e is Map && e['degree'] != null) {
          eduList.add("${e['degree']} - ${e['institution'] ?? ''}");
        }
      }
    }

    List<String> langList = [];
    if (json['languages'] is List) {
      langList = (json['languages'] as List).map((e) => e.toString()).toList();
    }

    // 🚀 [FIXED]: Image Parsing (Check API)
    String parsedImage = json['profile']?.toString() ?? '';

    return Doctor(
      id: json['_id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '', 
      name: json['name']?.toString() ?? 'Unknown Doctor',
      specialty: parsedSpecialty,
      clinicName: cName,
      image: parsedImage,
      rating: 4.8, 
      reviews: 120, 
      experience: exp,
      location: cAddress,
      city: cCity,
      phone: cPhone,       // 🚀 ଯୋଡାଗଲା
      distance: cDistance, // 🚀 ଯୋଡାଗଲା
      startTime: sTime,
      endTime: eTime,
      slotDate: sDate,
      isVerified: json['isVerified'] ?? false,
      isSuspended: json['isSuspended'] ?? false,
      nextAvailable: availText,
      price: parsedPrice,
      originalPrice: 0,
      
      about: json['bio']?.toString() ?? 'No description available.',
      rawEducation: eduList,
      languages: langList,
      mandatoryServices: servicesList,
      
      availability: fullAvailabilityArray,
      locations: allLocations,

      isValidPlatformPromoted: json['isValidPlatformPromoted'] ?? false,
      isValidClinicPromoted: json['isValidClinicPromoted'] ?? false,
      membershipLevel: json['membershipLevel'] ?? 0,
    );
  }
}