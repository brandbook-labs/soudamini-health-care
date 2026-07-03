import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AdvancedSearchField extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> selectedItems;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final bool multiSelect;
  final ThemeData theme;
  final String displayKey;
  final bool showPrice;

  const AdvancedSearchField({
    super.key,
    required this.label,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.multiSelect,
    required this.theme,
    this.displayKey = 'name',
    this.showPrice = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showSearchModal(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedItems.isEmpty
                    ? label
                    : selectedItems
                          .map((e) => e[displayKey] ?? e['name'] ?? '')
                          .join(", "),
                style: TextStyle(
                  color: selectedItems.isEmpty
                      ? theme.disabledColor
                      : theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(LucideIcons.chevronDown, size: 18, color: theme.disabledColor),
          ],
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scroll) => ListView.builder(
          controller: scroll,
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];

            // Dynamic Key Matching
            final name =
                item[displayKey] ?? item['name'] ?? item['department'] ?? '';
            final id = item['_id'] ?? item['value'] ?? name;

            final isSelected = selectedItems.any(
              (e) => (e['_id'] ?? e['value'] ?? e[displayKey]) == id,
            );

            return ListTile(
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: showPrice && item['price'] != null
                  ? Text(
                      "₹${item['price']}",
                      style: TextStyle(color: theme.colorScheme.primary),
                    )
                  : (item['city'] != null ? Text(item['city']) : null),
              trailing: isSelected
                  ? Icon(
                      LucideIcons.checkCircle,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () {
                if (multiSelect) {
                  final list = List<Map<String, dynamic>>.from(selectedItems);
                  if (isSelected) {
                    list.removeWhere(
                      (e) => (e['_id'] ?? e['value'] ?? e[displayKey]) == id,
                    );
                  } else {
                    list.add(item);
                  }
                  onChanged(list);
                } else {
                  onChanged([item]);
                  Navigator.pop(ctx);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
