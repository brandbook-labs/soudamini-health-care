// lib/screens/medical_records/my_doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/screens/patients/medical_records/widgets/my_doctors/doctor_dossier_card.dart';
import 'package:my_new_app/screens/patients/medical_records/widgets/my_doctors/dossier_empty_state.dart';
import 'package:my_new_app/screens/patients/reviews/models/review_model.dart';
import 'package:my_new_app/screens/patients/reviews/widgets/edit_review_sheet.dart';
import 'package:my_new_app/services/api_service.dart';

import 'models/past_consultation_model.dart';
import 'widgets/add_edit_record_screen.dart';
import 'package:my_new_app/screens/patients/doctor_profile/doctor_profile_screen.dart';

class MyDoctorsScreen extends StatefulWidget {
  const MyDoctorsScreen({super.key});

  @override
  State<MyDoctorsScreen> createState() => _MyDoctorsScreenState();
}

class _MyDoctorsScreenState extends State<MyDoctorsScreen> {
  final ApiService _apiService = ApiService(); 
  bool _isLoading = true;
  bool _isFetchingMore = false; 
  bool _hasMore = true; 
  int _currentPage = 1;
  List<PastConsultationModel> _pastDoctors = [];
  final ScrollController _scrollController = ScrollController(); 

  @override
  void initState() {
    super.initState();
    _fetchPastDoctors(); 

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 &&
          !_isFetchingMore &&
          _hasMore) {
        _fetchPastDoctors(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPastDoctors({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isFetchingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final res = await _apiService.getUserDoctorsAppointments(page: _currentPage, limit: 10);
      final responseData = res is Map ? res : res?.data;

      if (responseData != null && responseData['code'] == 200 && responseData['data'] != null) {
        final dataObj = responseData['data'];
        final List<dynamic> results = dataObj['results'] ?? [];
        final pagination = dataObj['pagination'] ?? {};

        final List<PastConsultationModel> fetchedDoctors = results.map((item) {
          final List<dynamic>? depts = item['departments'];
          final String rawSpecialty = (depts != null && depts.isNotEmpty)
              ? (depts[0]['name'] ?? 'General')
              : 'General';
              
          final String cleanSpecialty = rawSpecialty[0].toUpperCase() + rawSpecialty.substring(1).toLowerCase();

          return PastConsultationModel(
            id: item['_id']?.toString() ?? UniqueKey().toString(),
            doctorName: item['name'] ?? 'Unknown Doctor',
            specialty: cleanSpecialty,
            imageUrl: item['profile'] ?? '',
            lastVisitDate: DateTime.now(), 
            totalVisits: 1, 
            prescriptionsCount: 0,
            labReportsCount: 0,
            recentFiles: [], 
          );
        }).toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              _pastDoctors.addAll(fetchedDoctors); 
            } else {
              _pastDoctors = fetchedDoctors; 
            }

            final int totalPages = pagination['totalPages'] ?? 1;
            if (_currentPage < totalPages) {
              _currentPage++;
              _hasMore = true;
            } else {
              _hasMore = false;
            }

            _isLoading = false;
            _isFetchingMore = false;
          });
        }
      } else {
        _showError(responseData?['msg'] ?? "Failed to fetch doctors.");
      }
    } catch (e) {
      debugPrint("Fetch Doctors Error: $e");
      _showError("An error occurred while fetching your doctors.");
    }
  }

  void _showError(String msg) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openAddRecordForDoctor(PastConsultationModel doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          onSave: (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Record added for ${doctor.doctorName}!')),
            );
          },
        ),
      ),
    );
  }

  void _navigateToDoctorProfile(String doctorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorProfileScreen(doctorId: doctorId),
      ),
    );
  }

  // 🚀 [UPDATED]: API Call ସହିତ Write Review Sheet
  void _openWriteReviewSheet(PastConsultationModel doctor) {
    final newReview = ReviewModel(
      id: "", 
      targetName: doctor.doctorName,
      targetType: "Doctor",
      targetImage: doctor.imageUrl,
      rating: 0.0,
      comment: "",
      date: DateTime.now().toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => EditReviewSheet(
        review: newReview,
        onSave: (String updatedComment, double updatedRating) async {
          // ୧. ସର୍ବପ୍ରଥମେ Bottom Sheet କୁ ବନ୍ଦ କରନ୍ତୁ
          Navigator.pop(ctx);
          
          // ୨. ୟୁଜର୍ କୁ ଏକ 'Submitting' ଲୋଡିଂ ମେସେଜ୍ ଦେଖାନ୍ତୁ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  SizedBox(width: 16),
                  Text('Submitting your review...'),
                ],
              ),
              backgroundColor: Colors.black87,
              duration: Duration(seconds: 2), // ଅଳ୍ପ ସମୟ ପାଇଁ ରହିବ
            ),
          );

          try {
            Map<String, dynamic> reviewPayload = {
              "target_id": doctor.id,        // 🚀 Schema ରେ ଥିବା ନାମ
              "target_type": "Doctor",       // 🚀 Enum: 'Clinic' ବା 'Doctor'
              "rating": updatedRating,       // 🚀 Schema ରେ ଥିବା ନାମ
              "comment": updatedComment,     // 🚀 Schema ରେ ଥିବା ନାମ
            };

            // ୩. 🚀 ଅସଲି API କଲ୍: ଆପଣଙ୍କ ନିର୍ଦ୍ଦେଶ ମୁତାବକ createInvoice ବ୍ୟବହାର କରାଗଲା
            // ନୋଟ୍: ଆପଣଙ୍କର ApiService ରେ ଥିବା createInvoice ର ପାରାମିଟର ଅନୁଯାୟୀ ଏହି ଡାଟାକୁ ଆଡଜଷ୍ଟ (adjust) କରିପାରିବେ।
            final response = await _apiService.addReview(reviewPayload);

            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Loading ସ୍ନାକବାର୍ କୁ କାଟନ୍ତୁ

              // 🚀 ୨. ସୁରକ୍ଷିତ ଭାବେ (Null-Safe) ରେସପନ୍ସ ପଢିବା
              // `?.` ବ୍ୟବହାର କଲେ ଯଦି data null ଥାଏ, ତେବେ ଆପ୍ କ୍ରାସ୍ ହେବନାହିଁ
              final responseData = response?.data;
              
              // status code ଆଣିବା (Dio ରୁ କିମ୍ବା ଆପଣଙ୍କ API ର 'code' ରୁ)
              final int statusCode = response?.statusCode ?? responseData?['code'] ?? 500;
              
              // ଆପଣଙ୍କ API ରୁ ଆସିଥିବା ସୁନ୍ଦର ମେସେଜ୍ ଟିକୁ ଆଣିବା
              final String apiMsg = responseData?['msg'] ?? 'Operation completed successfully.';

              // ୩. ସଫଳତା (200 ବା 201) ଚେକ୍ କରିବା
              if (statusCode == 200 || statusCode == 201) {
                JivanToast.show(
                  context,
                  title: "Success",
                  message: apiMsg, // "Thank you for your valuable feedback..." ଏଠାରେ ଦେଖାଯିବ
                  type: ToastType.success,
                );
              } else {
                // ଯଦି 409 (Already reviewed) କିମ୍ବା ଅନ୍ୟ କୌଣସି ଏରର୍ ଆସେ
                JivanToast.show(
                  context,
                  title: "Notice",
                  message: apiMsg,
                  type: ToastType.warning,
                );
              }
            }
          } catch (e) {
            // ୪. ଯଦି ନେଟୱର୍କ କିମ୍ବା କୋଡ୍ ରେ କିଛି ବିଫଳତା ହୁଏ
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              
              JivanToast.show(
                context,
                title: "Error",
                message: "Failed to submit review. Please try again later.",
                type: ToastType.error,
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgMain = Color(0xFFF8FAFC);
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Doctors Team",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _pastDoctors.isEmpty
              ? const DossierEmptyState()
              : ListView.builder(
                  controller: _scrollController, 
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: _pastDoctors.length + (_isFetchingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _pastDoctors.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Center(child: CircularProgressIndicator(color: primary)),
                      );
                    }

                    final doctor = _pastDoctors[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GestureDetector(
                        onTap: () => _navigateToDoctorProfile(doctor.id),
                        child: DoctorDossierCard(
                          doctor: doctor,
                          onAddRecord: () => _openAddRecordForDoctor(doctor),
                          onWriteReview: () => _openWriteReviewSheet(doctor), 
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}