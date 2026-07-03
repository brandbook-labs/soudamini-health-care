// lib/screens/patient_reviews/models/review_model.dart

class ReviewModel {
  final String id;
  final String targetName;
  final String targetType; // 'Doctor', 'Clinic', or 'Staff'
  final String targetImage;
  double rating;
  String comment;
  final String date;

  ReviewModel({
    required this.id,
    required this.targetName,
    required this.targetType,
    required this.targetImage,
    required this.rating,
    required this.comment,
    required this.date,
  });
}
