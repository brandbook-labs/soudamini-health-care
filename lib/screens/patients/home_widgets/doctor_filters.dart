import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';

// --- FILTER STATE MODEL ---
class FilterState {
  String query;
  String sortBy;
  // 🚀 Clinic property removed
  String specialty;
  bool isAvailableToday;
  bool isAvailableTomorrow;

  FilterState({
    this.query = '',
    this.sortBy = 'relevance',
    this.specialty = 'All',
    this.isAvailableToday = false,
    this.isAvailableTomorrow = false,
  });

  bool get hasActiveFilters {
    return query.isNotEmpty ||
        sortBy != 'relevance' ||
        specialty != 'All' ||
        isAvailableToday ||
        isAvailableTomorrow;
  }

  FilterState copyWith({
    String? query,
    String? sortBy,
    String? specialty,
    bool? isAvailableToday,
    bool? isAvailableTomorrow,
  }) {
    return FilterState(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      specialty: specialty ?? this.specialty,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      isAvailableTomorrow: isAvailableTomorrow ?? this.isAvailableTomorrow,
    );
  }
}

// --- MAIN WIDGET ---
class DoctorFilters extends StatefulWidget {
  final FilterState currentFilters;
  final List<String> departments; // 🚀 Now accepts raw Strings from parent
  final Function(FilterState) onFilterChanged;

  const DoctorFilters({
    super.key,
    required this.currentFilters,
    required this.departments, 
    required this.onFilterChanged,
  });

  @override
  State<DoctorFilters> createState() => _DoctorFiltersState();
}

class _DoctorFiltersState extends State<DoctorFilters> {
  // 🚀 API Call for departments removed completely from initState

  void _update(FilterState newState) => widget.onFilterChanged(newState);

  bool get _hasTechnicalFilters =>
      widget.currentFilters.sortBy != 'relevance' ||
      widget.currentFilters.isAvailableToday ||
      widget.currentFilters.isAvailableTomorrow;

  void _resetFilters() {
    _update(
      widget.currentFilters.copyWith(
        sortBy: 'relevance',
        isAvailableToday: false,
        isAvailableTomorrow: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. DEPARTMENT CARDS (Dynamic from Doctor List)
        _buildSquareDepartmentCards(widget.departments),

        context.gapXs,

        // 2. TECHNICAL FILTERS ROW
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: context.spaceMd,
            vertical: 8,
          ),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterButton(
                context,
                label: widget.currentFilters.sortBy == 'relevance'
                    ? "Sort"
                    : "Sorted",
                icon: Icons.sort_rounded,
                isActive: widget.currentFilters.sortBy != 'relevance',
                onTap: () => _showSortSheet(context),
              ),
              // 🚀 Clinic Filter Button Removed
              context.gapXs,
              _buildToggleChip(
                context: context,
                label: "Available Today",
                icon: Icons.event_available_rounded,
                isSelected: widget.currentFilters.isAvailableToday,
                onSelected: (val) => _update(
                  widget.currentFilters.copyWith(
                    isAvailableToday: val,
                    isAvailableTomorrow: val
                        ? false
                        : widget.currentFilters.isAvailableTomorrow,
                  ),
                ),
              ),
              context.gapXs,
              _buildToggleChip(
                context: context,
                label: "Available Tomorrow",
                icon: Icons.event_rounded,
                isSelected: widget.currentFilters.isAvailableTomorrow,
                onSelected: (val) => _update(
                  widget.currentFilters.copyWith(
                    isAvailableTomorrow: val,
                    isAvailableToday: val
                        ? false
                        : widget.currentFilters.isAvailableToday,
                  ),
                ),
              ),
              if (_hasTechnicalFilters) ...[
                context.gapXs,
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.error),
                  tooltip: "Clear filters",
                  onPressed: _resetFilters,
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.errorContainer.withValues(
                      alpha: 0.2,
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 🚀 DYNAMIC DEPARTMENT CARDS
  // =========================================================================
  Widget _buildSquareDepartmentCards(List<String> departments) {
    if (departments.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: context.spaceMd, vertical: 8),
        itemCount: departments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSingleSquareCard(
              title: "All",
              iconData: LucideIcons.layoutGrid,
              isSelected: widget.currentFilters.specialty == "All",
              onTap: () =>
                  _update(widget.currentFilters.copyWith(specialty: "All")),
            );
          }

          final String rawDepartment = departments[index - 1];

          final String formattedName = rawDepartment
              .split('-')
              .map((word) {
                if (word.isEmpty) return "";
                if (word == "&") return "&";
                return word[0].toUpperCase() + word.substring(1);
              })
              .join(' ');

          final bool isSelected =
              widget.currentFilters.specialty.toLowerCase() ==
              formattedName.toLowerCase();

          return _buildSingleSquareCard(
            title: formattedName,
            iconData: _getLucideIconFromString(rawDepartment), // Fallback to Stethoscope if not matched
            isSelected: isSelected,
            onTap: () => _update(
              widget.currentFilters.copyWith(specialty: formattedName),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSingleSquareCard({
    required String title,
    required IconData iconData,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;
    final primary = colorScheme.primary;

    final bgColor = isSelected ? primary : context.theme.cardColor;
    final iconColor = isSelected ? colorScheme.onPrimary : primary;
    final textColor = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final borderColor = isSelected
        ? Colors.transparent
        : colorScheme.outlineVariant.withValues(alpha: 0.4);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 86,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.onPrimary.withValues(alpha: 0.2)
                    : primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: textColor,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLucideIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'flower-2':
        return LucideIcons.flower;
      case 'dna':
        return LucideIcons.dna;
      case 'ear':
        return LucideIcons.ear;
      case 'heart-pulse':
      case 'cardiology': // Added mapping for common department string
        return LucideIcons.heartPulse;
      case 'bone':
      case 'orthopedics':
        return LucideIcons.bone;
      case 'eye':
      case 'ophthalmology':
        return LucideIcons.eye;
      case 'droplet':
        return LucideIcons.droplet;
      case 'brain':
      case 'neurology':
        return LucideIcons.brain;
      case 'wind':
        return LucideIcons.wind;
      case 'droplet-filled':
        return LucideIcons.droplet;
      case 'smile':
        return LucideIcons.smile;
      case 'stethoscope':
      case 'general-medicine':
        return LucideIcons.stethoscope;
      case 'ribbon':
        return LucideIcons.award;
      case 'apple':
        return LucideIcons.apple;
      case 'brain-circuit':
        return LucideIcons.brainCircuit;
      case 'sparkles':
        return LucideIcons.sparkles;
      case 'utensils':
        return LucideIcons.utensils;
      case 'filter':
        return LucideIcons.filter;
      case 'activity':
        return LucideIcons.activity;
      case 'baby':
      case 'pediatrics':
        return LucideIcons.baby;
      case 'scissors':
      case 'surgery':
        return LucideIcons.scissors;
      case 'scan':
        return LucideIcons.scan;
      case 'flask-conical':
      case 'pathology':
        return LucideIcons.flaskConical;
      case 'leaf':
        return LucideIcons.leaf;
      case 'heart':
        return LucideIcons.heart;
      default:
        // Default icon if no specific match is found for the department string
        return LucideIcons.stethoscope;
    }
  }

  // --- TOGGLE CHIP (Today / Tomorrow) ---
  Widget _buildToggleChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Function(bool) onSelected,
  }) {
    final colorScheme = context.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
      ),
      backgroundColor: context.theme.cardColor,
      selectedColor: colorScheme.primary,
      showCheckmark: false,
      labelStyle: context.text.labelMedium?.copyWith(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outline.withValues(alpha: 0.2),
      ),
      shape: RoundedRectangleBorder(borderRadius: context.roundedSm),
    );
  }

  // --- THEMED FILTER BUTTON ---
  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? colorScheme.primary.withValues(alpha: 0.1)
              : context.theme.cardColor,
          borderRadius: context.roundedSm,
          border: Border.all(
            color: isActive
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(
                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 _showSelectionSheet (Clinic Sheet) Removed Completely

  // --- SORT SHEET ---
  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.spaceLg,
            12,
            context.spaceLg,
            context.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(context),
              context.gapMd,
              Text("Sort By", style: context.text.titleMedium),
              context.gapMd,
              _buildSheetOption(
                "Relevance",
                'relevance',
                widget.currentFilters.sortBy,
                (val) => _update(widget.currentFilters.copyWith(sortBy: val)),
                context,
              ),
              _buildSheetOption(
                "Price: Low to High",
                'price_low',
                widget.currentFilters.sortBy,
                (val) => _update(widget.currentFilters.copyWith(sortBy: val)),
                context,
              ),
              _buildSheetOption(
                "Experience: High to Low",
                'experience',
                widget.currentFilters.sortBy,
                (val) => _update(widget.currentFilters.copyWith(sortBy: val)),
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildSheetOption(
    String label,
    String value,
    String currentValue,
    Function(String) onTap,
    BuildContext context,
  ) {
    final isSelected = value == currentValue;
    final primary = context.colorScheme.primary;
    return ListTile(
      onTap: () {
        onTap(value);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isSelected ? Icons.check_rounded : Icons.circle_outlined,
          size: 20,
          color: isSelected
              ? primary
              : context.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),
      title: Text(
        label,
        style: context.text.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primary : context.colorScheme.onSurface,
        ),
      ),
    );
  }
}