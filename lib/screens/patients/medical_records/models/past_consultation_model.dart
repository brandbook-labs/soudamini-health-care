// lib/screens/medical_records/models/past_consultation_model.dart

class PastConsultationModel {
  final String id;
  final String doctorName;
  final String specialty;
  final String imageUrl;
  final DateTime lastVisitDate;
  final int totalVisits;
  final int prescriptionsCount;
  final int labReportsCount;
  final bool isJivanVerified;
  final List<Map<String, String>> recentFiles;

  PastConsultationModel({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.imageUrl,
    required this.lastVisitDate,
    required this.totalVisits,
    required this.prescriptionsCount,
    required this.labReportsCount,
    this.isJivanVerified = true,
    this.recentFiles = const [],
  });
}
