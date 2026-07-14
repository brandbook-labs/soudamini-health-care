import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/components/index.dart'; // JivanAppBar, JivanCard
import 'package:my_new_app/core/utils/theme_utils.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  // Mock Data
  List<Map<String, dynamic>> banners = [
    {
      "id": "1",
      "title": "Summer Health Camp",
      "image":
          "https://via.placeholder.com/400x200/2196F3/FFFFFF?text=Summer+Camp",
      "target": "/campaigns/summer",
      "isActive": true,
    },
    {
      "id": "2",
      "title": "20% Off Medicines",
      "image":
          "https://via.placeholder.com/400x200/4CAF50/FFFFFF?text=Discount",
      "target": "/pharmacy",
      "isActive": false,
    },
  ];

  void _openBannerForm({Map<String, dynamic>? banner}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (ctx) => _BannerFormSheet(
        initialData: banner,
        onSubmit: (data) {
          setState(() {
            if (banner == null) {
              // Create
              banners.add({
                ...data,
                "id": DateTime.now().toString(),
                "isActive": true,
              });
            } else {
              // Update
              final index = banners.indexWhere((b) => b['id'] == banner['id']);
              banners[index] = {...banner, ...data};
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JivanAppBar(title: "App Banners", showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBannerForm(),
        icon: const Icon(LucideIcons.plus),
        label: const Text("New Banner"),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: banners.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return _BannerCard(
            data: banner,
            onEdit: () => _openBannerForm(banner: banner),
            onDelete: () => setState(() => banners.removeAt(index)),
            onToggle: (val) => setState(() => banner['isActive'] = val),
          );
        },
      ),
    );
  }
}

// --- WIDGETS ---

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const _BannerCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = data['isActive'];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  data['image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade200,
                    height: 150,
                    child: const Icon(LucideIcons.image),
                  ),
                ),
                if (!isActive)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.5),
                      child: const Center(
                        child: Text(
                          "INACTIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        data['target'],
                        style: TextStyle(
                          color: theme.disabledColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: isActive, onChanged: onToggle),
                IconButton(
                  icon: const Icon(LucideIcons.edit3, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: Colors.red,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFormSheet extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSubmit;

  const _BannerFormSheet({this.initialData, required this.onSubmit});

  @override
  State<_BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends State<_BannerFormSheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(
      text: widget.initialData?['title'] ?? '',
    );
    _urlCtrl = TextEditingController(text: widget.initialData?['target'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.initialData == null ? "Add New Banner" : "Edit Banner",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Image Picker Placeholder
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.3),
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(LucideIcons.uploadCloud, size: 32, color: Colors.blue),
                SizedBox(height: 8),
                Text(
                  "Tap to upload image",
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: "Banner Title",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: "Target Screen / URL",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () {
                widget.onSubmit({
                  "title": _titleCtrl.text,
                  "target": _urlCtrl.text,
                  "image":
                      "https://via.placeholder.com/400x200/000000/FFFFFF?text=New+Image", // Mock
                });
              },
              child: const Text("Save Banner"),
            ),
          ),
        ],
      ),
    );
  }
}
