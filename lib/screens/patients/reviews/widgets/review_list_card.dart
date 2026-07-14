import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/review_model.dart';

class ReviewListCard extends StatelessWidget {
  final ReviewModel review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ReviewListCard({
    super.key,
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 🚀 ଷ୍ଟାଟସ୍ କୁ ଡିଫଲ୍ଟ PENDING ରଖାଯାଇଛି (ଯଦି ଆପଣଙ୍କ ମଡେଲ୍ ରେ review.status ଅଛି, ତାହା ବ୍ୟବହାର କରିବେ)
    final String status = "PENDING"; 

    // ❌ "What went well" / Tags ଲଜିକ୍ କୁ ଏଠାରୁ ସମ୍ପୂର୍ଣ୍ଣ ବାଦ୍ ଦିଆଯାଇଛି (Not Needed)

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Premium curve
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================
          // 1. HEADER SECTION (Profile, Name, Date, Rating)
          // ==========================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF8FAFC),
                  backgroundImage: review.targetImage.isNotEmpty
                      ? NetworkImage(review.targetImage)
                      : null,
                  child: review.targetImage.isEmpty
                      ? const Icon(LucideIcons.user, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              
              // Name, Badge & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Doctor/Clinic Badge
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.targetName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            review.targetType.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Date & Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          review.date,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            "•",
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                          ),
                        ),
                        Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 🚀 Premium Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFEF3C7), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          // ==========================================
          // 2. COMMENT BOX SECTION (Italic Quote Box)
          // ==========================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  LucideIcons.quote, 
                  color: Color(0xFFCBD5E1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"${review.comment}"', // 🚀 ସିଧାସଳଖ comment ବ୍ୟବହାର କରାଗଲା
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.5),
          const SizedBox(height: 8),

          // ==========================================
          // 3. ACTION BUTTONS SECTION (Footer)
          // ==========================================
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.flag, size: 16),
                label: const Text(
                  "Report Issue", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              
              const Spacer(),
              
              // 🚀 Edit Button
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Edit", 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)
                ),
              ),
              
              const SizedBox(width: 8),
              
              // 🚀 Delete Button
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text(
                  "Delete", 
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}