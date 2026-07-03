// lib/screens/medical_records/models/provider_model.dart

class ProviderModel {
  final String id;
  final String name;
  final String? specialty; // E.g., Cardiology, Diagnostics
  final String? imageUrl; // Profile picture for Jivan providers
  final bool isJivanVerified; // True if sourced from Jivan platform

  ProviderModel({
    required this.id,
    required this.name,
    this.specialty,
    this.imageUrl,
    this.isJivanVerified = false,
  });
}
