import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
// Ensure this import points to your updated card
import 'clinic_card.dart';

class ClinicListTab extends StatelessWidget {
  final String statusFilter;
  final List<dynamic> allClinics;
  final Function(String) onEdit;
  final Function(String, String) onDelete;
  final Function(String, Map<String, dynamic>) onSuspend;

  const ClinicListTab({
    super.key,
    required this.statusFilter,
    required this.allClinics,
    required this.onEdit,
    required this.onDelete,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Filter Data
    final filteredList = allClinics.where((clinic) {
      final clinicStatus = (clinic['status'] ?? 'active')
          .toString()
          .toLowerCase();
      if (statusFilter == 'pending') return clinicStatus == 'pending';
      if (statusFilter == 'suspended') return clinicStatus == 'suspended';
      return clinicStatus == 'active';
    }).toList();

    // 2. Empty State UI
    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.clipboardList,
                size: 48,
                color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "No ${statusFilter.toUpperCase()} facilities",
              style: TextStyle(
                color: Theme.of(context).disabledColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // 3. List Builder
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final clinic = filteredList[index];
        final String clinicId = clinic['_id'] ?? clinic['id'];

        return ClinicCard(
          clinic: clinic,
          // Single Tap: Navigate to Edit/Details
          onTap: () => onEdit(clinicId),
          // Long Press: Show Action Menu
          onLongPress: () => _showClinicOptions(context, clinic),
        );
      },
    );
  }

  // --- INTERNAL BOTTOM SHEET LOGIC ---
  void _showClinicOptions(BuildContext context, Map<String, dynamic> clinic) {
    final String clinicId = clinic['_id'] ?? clinic['id'];
    final String name = clinic['name'] ?? "Facility";
    final bool isActive = (clinic['status'] == 'active');

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Divider(),

                // Navigate to Details
                _buildSheetItem(
                  ctx,
                  LucideIcons.eye,
                  "View / Edit Details",
                  () {
                    Navigator.pop(ctx);
                    onEdit(clinicId);
                  },
                ),

                // Suspend / Activate
                _buildSheetItem(
                  ctx,
                  isActive ? LucideIcons.ban : LucideIcons.checkCircle,
                  isActive ? "Suspend Facility" : "Activate Facility",
                  () {
                    Navigator.pop(ctx);
                    onSuspend(clinicId, clinic);
                  },
                  color: isActive ? Colors.orange : Colors.green,
                ),

                // Delete
                _buildSheetItem(ctx, LucideIcons.trash2, "Delete Facility", () {
                  Navigator.pop(ctx);
                  onDelete(clinicId, name);
                }, color: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  ListTile _buildSheetItem(
    BuildContext ctx,
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color? color,
  }) {
    final theme = Theme.of(ctx);
    final itemColor = color ?? theme.colorScheme.onSurface;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: itemColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: itemColor, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
