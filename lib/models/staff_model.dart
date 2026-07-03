class Staff {
  // --- ମୁଖ୍ୟ IDs (Primary Identifiers) ---
  final String id;          // ମୂଳ ଷ୍ଟାଫ୍ ID (staff_id)
  final String mappingId;   // କ୍ଲିନିକ୍ ମ୍ୟାପିଂ ID (mapping_id ବା _id)

  // --- ସାଧାରଣ ତଥ୍ୟ (Basic Info) ---
  final String slug;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String image;       // 'profile' ଫିଲ୍ଡ୍ ରୁ ଆସିବ
  final String bio;
  final String experience;
  
  // --- କ୍ଲିନିକ୍ ଏବଂ ଠିକଣା (Clinic & Location) ---
  final String clinicName;
  final String address;
  final String city;
  final String pincode;

  // --- ଷ୍ଟାଟସ୍ ଏବଂ ତାରିଖ (Status & Dates) ---
  final String status;
  final bool isVerified;
  final bool isSuspended;
  final bool isArchived;
  final bool isAdminApproved; // 🚀 ନୂଆ ଫିଲ୍ଡ୍
  final String joinedAt;
  final String createdAt;

  // --- ଡାକ୍ତରଙ୍କ ପାଇଁ ସ୍ୱତନ୍ତ୍ର (Doctor Specific) ---
  final String specialty;       // Departments ରୁ ପାର୍ସ ହେବ
  final int consultationFees;
  final int followUpFees;
  
  // --- ଅନ୍ୟ ଷ୍ଟାଫ୍ ମାନଙ୍କ ପାଇଁ ସ୍ୱତନ୍ତ୍ର (Other Staff Specific) ---
  final String shiftType;
  final String salary;
  final String salaryType;

  // --- ଆରେ ଏବଂ ଲିଷ୍ଟ (Arrays / Lists) ---
  final List<String> languages;
  final List<String> highlights; // 🚀 ନୂଆ ଫିଲ୍ଡ୍
  final List<Map<String, String>> educations;
  final List<dynamic> rawDepartments; 
  final List<dynamic> rawServices;    
  final List<dynamic> rawSlots;       
  final List<dynamic> availableSlots; // 🚀 ନୂଆ ଫିଲ୍ଡ୍

  Staff({
    required this.id,
    required this.mappingId,
    required this.slug,
    required this.name,
    this.email = '',
    this.phone = '',
    this.role = 'staff',
    this.image = '',
    this.bio = '',
    this.experience = '',
    
    this.clinicName = 'Unknown Clinic',
    this.address = '',
    this.city = '',
    this.pincode = '',

    this.status = 'active',
    this.isVerified = false,
    this.isSuspended = false,
    this.isArchived = false,
    this.isAdminApproved = false,
    this.joinedAt = '',
    this.createdAt = '',

    this.specialty = 'General',
    this.consultationFees = 0,
    this.followUpFees = 0,

    this.shiftType = 'full_time',
    this.salary = '',
    this.salaryType = 'monthly',

    this.languages = const [],
    this.highlights = const [],
    this.educations = const [],
    this.rawDepartments = const [],
    this.rawServices = const [],
    this.rawSlots = const [],
    this.availableSlots = const [],
  });

  // ==========================================
  // 1. FROM JSON (API ରୁ ଡାଟା ପଢିବା ପାଇଁ)
  // ==========================================
  factory Staff.fromJson(Map<String, dynamic> json) {
    // 🚀 IDs Parsing
    final String parsedMappingId = json['mapping_id']?.toString() ?? json['_id']?.toString() ?? '';
    final String parsedStaffId = json['staff_id']?.toString() ?? parsedMappingId;

    // 🚀 Clinic Info Parsing 
    final clinicMap = json['clinic_info'] is Map ? json['clinic_info'] : (json['clinic'] is Map ? json['clinic'] : {});
        
    String cName = clinicMap['name']?.toString() ?? 'Private Clinic';
    String cAddress = json['address']?.toString() ?? clinicMap['address']?.toString() ?? '';
    String cCity = json['city']?.toString() ?? clinicMap['city']?.toString() ?? '';
    String cPincode = json['pincode']?.toString() ?? clinicMap['pincode']?.toString() ?? '';

    // Phone parsing
    String parsedPhone = json['phone']?.toString() ?? '';
    if (parsedPhone.isEmpty && clinicMap['phone'] is List && (clinicMap['phone'] as List).isNotEmpty) {
      parsedPhone = clinicMap['phone'][0].toString();
    }

    // 🚀 Department / Specialty Parsing
    String parsedSpecialty = 'General';
    List<dynamic> depts = json['departments'] is List ? json['departments'] : [];
    if (depts.isNotEmpty) {
      final firstDept = depts[0];
      String rawDept = firstDept is Map ? (firstDept['department'] ?? firstDept['name'] ?? '') : firstDept.toString();
      parsedSpecialty = rawDept.split('-').map((w) => w.isNotEmpty ? "${w[0].toUpperCase()}${w.substring(1)}" : "").join(" ");
    }

    // 🚀 Services & Slots
    List<dynamic> svcs = json['services'] is List ? json['services'] : [];
    List<dynamic> slots = json['doctor_slots'] is List ? json['doctor_slots'] : [];
    List<dynamic> availSlots = json['available_slots'] is List ? json['available_slots'] : [];

    // 🚀 Education Parsing
    List<Map<String, String>> eduList = [];
    if (json['educations'] is List) {
      for (var e in json['educations']) {
        if (e is Map) {
          eduList.add({
            'degree': e['degree']?.toString() ?? '',
            'institution': e['institution']?.toString() ?? '',
            'year_of_completion': e['year_of_completion']?.toString() ?? '',
          });
        }
      }
    }

    // 🚀 Languages & Highlights Parsing
    List<String> langList = [];
    if (json['languages'] is List) {
      langList = (json['languages'] as List).map((e) => e.toString()).toList();
    }

    List<String> highlightList = [];
    if (json['highlights'] is List) {
      highlightList = (json['highlights'] as List).map((e) => e.toString()).toList();
    }

    return Staff(
      id: parsedStaffId,
      mappingId: parsedMappingId,
      slug: json['slug']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Staff',
      email: json['email']?.toString() ?? '',
      phone: parsedPhone,
      role: json['role']?.toString() ?? 'staff',
      image: json['profile']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      experience: json['experience']?.toString() ?? '',
      
      clinicName: cName,
      address: cAddress,
      city: cCity,
      pincode: cPincode,

      status: json['status']?.toString() ?? 'active',
      isVerified: json['isVerified'] ?? false,
      isSuspended: json['isSuspended'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isAdminApproved: json['isAdminApproved'] ?? false,
      joinedAt: json['joined_at']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',

      specialty: parsedSpecialty,
      consultationFees: int.tryParse(json['consultation_fees']?.toString() ?? '0') ?? 0,
      followUpFees: int.tryParse(json['follow_up_fees']?.toString() ?? '0') ?? 0,

      shiftType: json['shift_type']?.toString() ?? 'full_time',
      salary: json['salary']?.toString() ?? '',
      salaryType: json['salary_type']?.toString() ?? 'monthly',

      languages: langList,
      highlights: highlightList,
      educations: eduList,
      rawDepartments: depts,
      rawServices: svcs,
      rawSlots: slots,
      availableSlots: availSlots,
    );
  }

  // ==========================================
  // 2. TO JSON (API କୁ ଡାଟା ପଠାଇବା ପାଇଁ / Payload)
  // ==========================================
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'slug': slug,
      'email': email,
      'phone': phone,
      'role': role,
      'experience': experience,
      'bio': bio,
      'address': address,
      'city': city,
      'pincode': pincode,
      'languages': languages,
      'highlights': highlights,
      'educations': educations,
    };

    if (role == 'doctor') {
      data['consultation_fees'] = consultationFees;
      data['follow_up_fees'] = followUpFees;
      data['departments'] = rawDepartments;
      data['services'] = rawServices;
      data['doctor_slots'] = rawSlots;
    } else {
      data['shift_type'] = shiftType;
      data['salary'] = salary;
      data['salary_type'] = salaryType;
    }

    if (mappingId.isNotEmpty) {
      data['id'] = mappingId;
    }

    return data;
  }

  // 🚀 [NEW]: Local State Update ପାଇଁ copyWith ମେଥଡ୍
  Staff copyWith({
    bool? isSuspended,
    bool? isArchived,
    String? status,
  }) {
    return Staff(
      id: this.id,
      mappingId: this.mappingId,
      slug: this.slug,
      name: this.name,
      email: this.email,
      phone: this.phone,
      role: this.role,
      image: this.image,
      bio: this.bio,
      experience: this.experience,
      clinicName: this.clinicName,
      address: this.address,
      city: this.city,
      pincode: this.pincode,
      
      status: status ?? this.status,
      isSuspended: isSuspended ?? this.isSuspended,
      isArchived: isArchived ?? this.isArchived,
      
      isAdminApproved: this.isAdminApproved,
      isVerified: this.isVerified,
      joinedAt: this.joinedAt,
      createdAt: this.createdAt,
      specialty: this.specialty,
      consultationFees: this.consultationFees,
      followUpFees: this.followUpFees,
      shiftType: this.shiftType,
      salary: this.salary,
      salaryType: this.salaryType,
      languages: this.languages,
      highlights: this.highlights,
      educations: this.educations,
      rawDepartments: this.rawDepartments,
      rawServices: this.rawServices,
      rawSlots: this.rawSlots,
      availableSlots: this.availableSlots,
    );
  }
}