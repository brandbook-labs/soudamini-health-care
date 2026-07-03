// lib/screens/admin/adminUsers/adminPatients/models/patient_model.dart

class Patient {
  final String id;
  final String name;
  final String phone;
  final String age;
  final String gender;
  final String lastVisit;
  final DateTime lastVisitDate;
  final String status;
  final String bookingId;

  Patient({
    required this.id,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.lastVisit,
    required this.lastVisitDate,
    required this.status,
    required this.bookingId,
  });

  // 🚀 [THE FIX]: ସୁରକ୍ଷିତ (Safe & Secure) ପାର୍ସିଂ (Parsing) ନୂଆ API ଅନୁଯାୟୀ
  factory Patient.fromJson(Map<String, dynamic> json) {
    // ନେଷ୍ଟେଡ୍ (Nested) ଅବଜେକ୍ଟ୍ କୁ ସୁରକ୍ଷିତ ଭାବେ ଆଣିବା (Null Check ସହିତ)
    final details = json['patient_details'] ?? {};
    final summary = json['visit_summary'] ?? {};
    final bookedBy = json['booked_by'] ?? {};

    // ତାରିଖ (Date) କୁ ସୁରକ୍ଷିତ ଭାବେ ପାର୍ସ କରିବା
    DateTime parsedDate = DateTime.now();
    String formattedDate = '';
    
    if (summary['last_visit_date'] != null) {
      try {
        parsedDate = DateTime.parse(summary['last_visit_date']);
        // Format to YYYY-MM-DD
        formattedDate = "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (e) {
        parsedDate = DateTime.now(); // Fallback Date
      }
    }

    return Patient(
      // ID ପାଇଁ user_id କିମ୍ବା last_appointment_id ର ବ୍ୟବହାର
      id: bookedBy['user_id']?.toString() ?? summary['last_appointment_id']?.toString() ?? '',
      
      // Patient Details
      name: details['name']?.toString() ?? 'Unknown',
      phone: details['phone']?.toString() ?? '',
      age: details['age']?.toString() ?? 'N/A',
      gender: details['gender']?.toString() ?? 'Unknown',
      
      // Visit Summary
      lastVisit: formattedDate,
      lastVisitDate: parsedDate,
      status: summary['last_appointment_status']?.toString() ?? 'unknown',
      bookingId: summary['last_appointment_id']?.toString() ?? '',
    );
  }
}