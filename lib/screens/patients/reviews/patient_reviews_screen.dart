import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/services/api_service.dart'; 

import 'models/review_model.dart';
import 'widgets/review_summary_card.dart';
import 'widgets/empty_reviews_state.dart';
import 'widgets/review_list_card.dart';
import 'widgets/edit_review_sheet.dart';

class PatientReviewsScreen extends StatefulWidget {
  const PatientReviewsScreen({super.key});

  @override
  State<PatientReviewsScreen> createState() => _PatientReviewsScreenState();
}

class _PatientReviewsScreenState extends State<PatientReviewsScreen> {
  final ApiService _apiService = ApiService(); 
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  List<ReviewModel> _reviews = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMyReviews();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50 &&
          !_isFetchingMore &&
          _hasMore) {
        _fetchMyReviews(loadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🚀 ଆପଣଙ୍କର ଅରିଜିନାଲ୍ ଫେଚ୍ କୋଡ୍ (କୌଣସି ପରିବର୍ତ୍ତନ କରାଯାଇନାହିଁ)
  Future<void> _fetchMyReviews({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => _isFetchingMore = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final res = await _apiService.getUserReviews(page: _currentPage, limit: 10);
      final responseData = res is Map ? res : res?.data;

      if (responseData != null && responseData['code'] == 200) {
        final dataObj = responseData['data'] as Map<String, dynamic>;
        final List<dynamic> reviewsList = dataObj['reviews'] ?? []; 

        final List<ReviewModel> fetchedReviews = reviewsList.map((item) {
          final targetData = item['target_data'] as Map<String, dynamic>? ?? {};

          return ReviewModel(
            id: item['_id']?.toString() ?? '',
            targetName: targetData['name']?.toString() ?? 'Unknown', 
            targetType: item['target_type']?.toString() ?? 'Unknown',
            targetImage: targetData['profile']?.toString() ?? '', 
            rating: (item['rating'] ?? 0).toDouble(),
            comment: item['comment']?.toString() ?? '',
            date: targetData['createdAt']?.toString() ?? item['createdAt']?.toString() ?? '', 
          );
        }).toList();

        if (mounted) {
          setState(() {
            if (loadMore) {
              _reviews.addAll(fetchedReviews);
            } else {
              _reviews = fetchedReviews;
            }

            final int totalPages = dataObj['totalPages'] ?? 1;
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFetchingMore = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Reviews Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingMore = false;
        });
      }
    }
  }

  // 🚀 ACTIVE API: Delete Review
  Future<void> _deleteReview(String reviewId) async {
    try {
      final res = await _apiService.deleteReview(reviewId);
      final responseData = res is Map ? res : res?.data;

      if (responseData != null && responseData['code'] == 200) {
        setState(() {
          _reviews.removeWhere((r) => r.id == reviewId);
        });

        if (mounted) {
          // 🚀 ପ୍ରିମିୟମ୍ JivanToast ବ୍ୟବହାର କରାଗଲା
          JivanToast.show(
            context,
            title: "Deleted",
            message: "Review removed successfully.",
            type: ToastType.info, 
          );
        }
      } else {
        // Error handling
        if (mounted) {
          JivanToast.show(
            context,
            title: "Error",
            message: "Failed to delete review.",
            type: ToastType.error, // Assuming you have ToastType.error
          );
        }
      }
    } catch (e) {
      debugPrint("Delete Review Error: $e");
    }
  }

  void _confirmDelete(ReviewModel review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Review?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete your review for ${review.targetName}? This cannot be undone.", style: const TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteReview(review.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // 🚀 ACTIVE API: Update Review 
  void _handleEditRequest(ReviewModel review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => EditReviewSheet(
        review: review,
        onSave: (String updatedComment, double updatedRating) async {
          
          try {
            // API କଲ୍ 
            final res = await _apiService.updateReview(review.id, {
              'comment': updatedComment,
              'rating': updatedRating
            });
            
            final responseData = res is Map ? res : res?.data;

            if (responseData != null && responseData['code'] == 200) {
              // ସଫଳ ହେଲେ Frontend ଅପଡେଟ୍ କରିବା
              setState(() {
                review.comment = updatedComment;
                review.rating = updatedRating;
              });

              if (mounted) Navigator.pop(ctx);

              if (mounted) {
                // 🚀 ପ୍ରିମିୟମ୍ JivanToast
                JivanToast.show(
                  context,
                  title: "Updated",
                  message: "Feedback successfully updated!",
                  type: ToastType.info, 
                );
              }
            } else {
               if (mounted) {
                 JivanToast.show(context, title: "Error", message: "Failed to update feedback.", type: ToastType.error);
               }
            }
          } catch (e) {
             debugPrint("Update Review Error: $e");
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgMain = Color(0xFFF8FAFC);
    const primary = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Feedback", 
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.5),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                if (_reviews.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: ReviewSummaryCard(totalReviews: _reviews.length),
                    ),
                  ),

                if (_reviews.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyReviewsState(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _reviews.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(child: CircularProgressIndicator(color: primary)),
                          );
                        }
                        return ReviewListCard(
                          review: _reviews[index],
                          onEdit: () => _handleEditRequest(_reviews[index]),
                          onDelete: () => _confirmDelete(_reviews[index]),
                        );
                      }, 
                      childCount: _reviews.length + (_isFetchingMore ? 1 : 0)),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)), 
              ],
            ),
    );
  }
}