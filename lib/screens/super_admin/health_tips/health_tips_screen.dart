import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JivanAppBar(title: "Health Tips & Blogs", showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to full editor screen
        },
        child: const Icon(LucideIcons.penTool),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(
                      "https://via.placeholder.com/100?text=Tip+$index",
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                "10 Tips for a Healthy Heart in Summer",
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: const [
                    Icon(LucideIcons.calendar, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      "Published: 12 Oct 2025",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              trailing: PopupMenuButton(
                icon: const Icon(LucideIcons.moreVertical),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text("Edit Content"),
                  ),
                  const PopupMenuItem(
                    value: 'unpublish',
                    child: Text("Unpublish"),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
