// lib/screens/medical_records/models/record_model.dart

// Define distinct record types for UI indexing and logic
enum MedicalRecordType {
  labReport,
  prescription,
  dischargeSummary,
  admissionForm,
  scanImage,
  other,
}

class MedicalRecordModel {
  final String id;
  final MedicalRecordType type;
  final String
  title; // E.g., 'Full Blood Count Report' or 'Dr. Singh Prescription'
  final DateTime date; // Date of the record/visit
  final String? notes; // Optional user notes
  final String? fileUrl; // URL or local path to the attached document/image
  final String? linkedProviderId; // ID of the Doctor/Clinic from Jivan
  final String? linkedProviderName; // Name of non-Jivan Doctor/Clinic

  MedicalRecordModel({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    this.notes,
    this.fileUrl,
    this.linkedProviderId,
    this.linkedProviderName,
  });

  // Helper to get string representation of type for display/API payload
  String get typeString {
    switch (type) {
      case MedicalRecordType.labReport:
        return "Lab Report";
      case MedicalRecordType.prescription:
        return "Prescription";
      case MedicalRecordType.dischargeSummary:
        return "Discharge Summary";
      case MedicalRecordType.admissionForm:
        return "Admission Form";
      case MedicalRecordType.scanImage:
        return "Scan Image";
      case MedicalRecordType.other:
        return "Other";
    }
  }
}
