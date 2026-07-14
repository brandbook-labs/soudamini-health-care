import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/provider_model.dart';

class LinkedProviderSelector extends StatefulWidget {
  final Function(ProviderModel?) onProviderSelected;
  final ProviderModel? initialProvider;

  const LinkedProviderSelector({
    super.key,
    required this.onProviderSelected,
    this.initialProvider,
  });

  @override
  State<LinkedProviderSelector> createState() => _LinkedProviderSelectorState();
}

class _LinkedProviderSelectorState extends State<LinkedProviderSelector> {
  ProviderModel? _selectedProvider;
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.initialProvider;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleCustomEntry(String text) {
    if (text.trim().isEmpty) {
      widget.onProviderSelected(null);
      setState(() => _selectedProvider = null);
      return;
    }

    // Seamlessly create a non-Jivan provider on the fly
    final customProvider = ProviderModel(
      id: "custom_${DateTime.now().millisecondsSinceEpoch}",
      name: text.trim(),
      isJivanVerified: false,
    );

    widget.onProviderSelected(customProvider);
    setState(() {
      _selectedProvider = customProvider;
      _isSearching = false;
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);

    // If a provider is selected, show it as a beautiful, dismissible chip
    if (_selectedProvider != null) {
      final isJivan = _selectedProvider!.isJivanVerified;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isJivan
              ? primary.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isJivan ? primary.withValues(alpha: 0.2) : borderCol,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isJivan ? LucideIcons.scale3d : LucideIcons.user,
              color: isJivan ? primary : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedProvider!.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isJivan ? primary : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  if (isJivan)
                    const Text(
                      "Jivan Platform Doctor",
                      style: TextStyle(fontSize: 11, color: primary),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, size: 18, color: Colors.black54),
              onPressed: () {
                setState(() => _selectedProvider = null);
                widget.onProviderSelected(null);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    // Default State: A smart search/entry field
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _isSearching = val.isNotEmpty),
          onSubmitted: _handleCustomEntry,
          style: const TextStyle(color: Colors.black87, fontSize: 15),
          decoration: InputDecoration(
            hintText: "Search doctor name or type a new one...",
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
            prefixIcon: const Icon(
              LucideIcons.search,
              size: 18,
              color: Colors.black45,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderCol),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderCol),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primary, width: 2),
            ),
          ),
        ),

        // Show "Add as new" option dynamically when typing
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: InkWell(
              onTap: () => _handleCustomEntry(_searchController.text),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Add '${_searchController.text}' as new provider",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
