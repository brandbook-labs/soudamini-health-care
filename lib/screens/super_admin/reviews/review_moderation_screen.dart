import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';

class ReviewModerationScreen extends StatelessWidget {
  const ReviewModerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JivanAppBar(title: "Moderation Queue", showBack: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _ReviewCard(
            userName: "Rahul Sharma",
            clinicName: "Apollo Pharmacy - Unit ${index + 1}",
            rating: 4.5,
            comment:
                "Great service, but the waiting time was a bit long. The staff was very polite though.",
            date: "2 mins ago",
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String userName;
  final String clinicName;
  final double rating;
  final String comment;
  final String date;

  const _ReviewCard({
    required this.userName,
    required this.clinicName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Text(
                      userName[0],
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 12,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    clinicName,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                date,
                style: TextStyle(color: theme.disabledColor, fontSize: 11),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating.floor() ? LucideIcons.star : LucideIcons.star,
                size: 14,
                color: index < rating.floor()
                    ? Colors.amber
                    : theme.disabledColor.withOpacity(0.3),
              );
            }),
          ),

          const SizedBox(height: 8),
          Text(comment, style: const TextStyle(height: 1.4)),

          const SizedBox(height: 16),
          const Divider(),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.ban, size: 16, color: Colors.red),
                label: const Text(
                  "Reject",
                  style: TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(LucideIcons.check, size: 16),
                label: const Text("Approve"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
