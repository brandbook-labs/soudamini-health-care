import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
// 🚀 API Service ବଦଳରେ ଏବେ ସିଧା DoctorProvider କୁ ଇମ୍ପୋର୍ଟ କରିବା
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart'; 

// --- FILTER STATE MODEL ---
class FilterState {
  String query;
  String sortBy;
  String clinic;
  String specialty;
  bool isAvailableToday;
  bool isAvailableTomorrow;

  FilterState({
    this.query = '',
    this.sortBy = 'relevance',
    this.clinic = 'All',
    this.specialty = 'All',
    this.isAvailableToday = false,
    this.isAvailableTomorrow = false,
  });

  bool get hasActiveFilters {
    return query.isNotEmpty ||
        sortBy != 'relevance' ||
        clinic != 'All' ||
        specialty != 'All' ||
        isAvailableToday ||
        isAvailableTomorrow;
  }

  FilterState copyWith({
    String? query,
    String? sortBy,
    String? clinic,
    String? specialty,
    bool? isAvailableToday,
    bool? isAvailableTomorrow,
  }) {
    return FilterState(
      query: query ?? this.query,
      sortBy: sortBy ?? this.sortBy,
      clinic: clinic ?? this.clinic,
      specialty: specialty ?? this.specialty,
      isAvailableToday: isAvailableToday ?? this.isAvailableToday,
      isAvailableTomorrow: isAvailableTomorrow ?? this.isAvailableTomorrow,
    );
  }
}

// --- MAIN WIDGET ---
class DoctorFilters extends StatefulWidget {
  final FilterState currentFilters;
  final Function(FilterState) onFilterChanged;
  final List<String> clinics;

  const DoctorFilters({
    super.key,
    required this.currentFilters,
    required this.onFilterChanged,
    this.clinics = const [], 
  });

  @override
  State<DoctorFilters> createState() => _DoctorFiltersState();
}

class _DoctorFiltersState extends State<DoctorFilters> {
  
  @override
  void initState() {
    super.initState();
    // 🚀 ସ୍କ୍ରିନ୍ ଲୋଡ୍ ହେବା ମାତ୍ରେ Provider କୁ କହିବା: "ଯଦି ଡାଟା ନାହିଁ ତେବେ ଆଣ!"
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().fetchDepartmentsOnce();
    });
  }

  void _update(FilterState newState) => widget.onFilterChanged(newState);
  
  void _resetFilters() {
    _update(widget.currentFilters.copyWith(
      sortBy: 'relevance',
      clinic: 'All',
      isAvailableToday: false,
      isAvailableTomorrow: false,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isOdia = context.watch<LanguageController>().currentLocale.languageCode == 'or';
    
    // 🚀 Provider ରୁ କ୍ୟାସ୍ (Cached) ଡାଟା ଆଣିବା
    final doctorProvider = context.watch<DoctorProvider>();
    final departmentsList = doctorProvider.departments;
    final isLoadingDepartments = doctorProvider.isLoadingDepartments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ୧. 🚀 SQUARE DEPARTMENT CARDS (Cached Data)
        _buildSquareDepartmentCards(isOdia, isLoadingDepartments, departmentsList),

        context.gapXs,

        // ୨. 🚀 TECHNICAL FILTERS ROW
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.spaceMd, vertical: 8),
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFilterButton(
                context,
                label: widget.currentFilters.sortBy == 'relevance' ? (isOdia ? "ସଜାନ୍ତୁ" : "Sort") : (isOdia ? "ସଜା ହୋଇଛି" : "Sorted"),
                icon: Icons.sort_rounded,
                isActive: widget.currentFilters.sortBy != 'relevance',
                onTap: () => _showSortSheet(context, isOdia),
              ),
              context.gapXs,
              
              _buildFilterButton(
                context,
                label: widget.currentFilters.clinic == 'All' ? (isOdia ? "କ୍ଲିନିକ" : "Clinic") : widget.currentFilters.clinic,
                icon: Icons.apartment_rounded,
                isActive: widget.currentFilters.clinic != 'All',
                onTap: () => _showSelectionSheet(context, isOdia ? "କ୍ଲିନିକ ବାଛନ୍ତୁ" : "Select Clinic", widget.clinics, (val) => _update(widget.currentFilters.copyWith(clinic: val)), isOdia, widget.currentFilters.clinic),
              ),
              context.gapXs,
              
              _buildToggleChip(
                context: context,
                label: isOdia ? "ଆଜି ଉପଲବ୍ଧ" : "Available Today",
                isSelected: widget.currentFilters.isAvailableToday,
                onSelected: (val) => _update(widget.currentFilters.copyWith(isAvailableToday: val, isAvailableTomorrow: val ? false : widget.currentFilters.isAvailableTomorrow)),
              ),
              context.gapXs,

              _buildToggleChip(
                context: context,
                label: isOdia ? "ଆସନ୍ତାକାଲି ଉପଲବ୍ଧ" : "Available Tomorrow",
                isSelected: widget.currentFilters.isAvailableTomorrow,
                onSelected: (val) => _update(widget.currentFilters.copyWith(isAvailableTomorrow: val, isAvailableToday: val ? false : widget.currentFilters.isAvailableToday)),
              ),
              context.gapXs,

              if (widget.currentFilters.hasActiveFilters && (widget.currentFilters.sortBy != 'relevance' || widget.currentFilters.clinic != 'All' || widget.currentFilters.isAvailableToday || widget.currentFilters.isAvailableTomorrow))
                IconButton(
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.error),
                  onPressed: _resetFilters,
                  style: IconButton.styleFrom(backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.2), padding: const EdgeInsets.all(8)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 🚀 HELPER: BUILD SQUARE DEPARTMENT CARDS
  // =========================================================================
  Widget _buildSquareDepartmentCards(bool isOdia, bool isLoading, List<dynamic> departments) {
    if (isLoading) {
      return const SizedBox(height: 110, child: Center(child: CircularProgressIndicator()));
    }

    if (departments.isEmpty) return const SizedBox.shrink();

    final List<Color> uniqueColors = [
      Colors.blueAccent, Colors.purple, Colors.teal, Colors.orange,
      Colors.indigo, Colors.redAccent, Colors.green,
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: context.spaceMd, vertical: 8),
        itemCount: departments.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = widget.currentFilters.specialty == "All";
            return _buildSingleSquareCard(
              title: isOdia ? "ସମସ୍ତ" : "All",
              iconData: LucideIcons.layoutGrid,
              isSelected: isSelected,
              onTap: () => _update(widget.currentFilters.copyWith(specialty: "All")),
            );
          }

          final deptData = departments[index - 1];
          final String rawDepartment = deptData['department']?.toString() ?? "";
          final String iconString = deptData['department_icon']?.toString() ?? "";
          
          final String formattedName = rawDepartment.split('-').map((word) {
            if (word.isEmpty) return "";
            if (word == "&") return "&"; 
            return word[0].toUpperCase() + word.substring(1);
          }).join(' ');

          final bool isSelected = widget.currentFilters.specialty.toLowerCase() == formattedName.toLowerCase();

          return _buildSingleSquareCard(
            title: formattedName,
            iconData: _getLucideIconFromString(iconString),
            isSelected: isSelected,
            onTap: () => _update(widget.currentFilters.copyWith(specialty: formattedName)),
          );
        },
      ),
    );
  }

  Widget _buildSingleSquareCard({required String title, required IconData iconData, required bool isSelected, required VoidCallback onTap}) {
    final bgColor = isSelected ? const Color(0xFF0A4FE5) : context.theme.cardColor; 
    final iconColor = isSelected ? Colors.white : context.colorScheme.primary;
    final textColor = isSelected ? Colors.white : context.colorScheme.onSurface;
    final borderColor = isSelected ? Colors.transparent : context.colorScheme.outlineVariant.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF0A4FE5).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.2) : context.colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: textColor, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLucideIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'flower-2': return LucideIcons.flower; 
      case 'dna': return LucideIcons.dna;
      case 'ear': return LucideIcons.ear;
      case 'heart-pulse': return LucideIcons.heartPulse;
      case 'bone': return LucideIcons.bone;
      case 'eye': return LucideIcons.eye;
      case 'droplet': return LucideIcons.droplet;
      case 'brain': return LucideIcons.brain;
      case 'wind': return LucideIcons.wind;
      case 'droplet-filled': return LucideIcons.droplet; 
      case 'smile': return LucideIcons.smile;
      case 'stethoscope': return LucideIcons.stethoscope;
      case 'ribbon': return LucideIcons.award; 
      case 'apple': return LucideIcons.apple;
      case 'brain-circuit': return LucideIcons.brainCircuit;
      case 'sparkles': return LucideIcons.sparkles;
      case 'utensils': return LucideIcons.utensils;
      case 'filter': return LucideIcons.filter;
      case 'activity': return LucideIcons.activity;
      case 'baby': return LucideIcons.baby;
      case 'scissors': return LucideIcons.scissors;
      case 'scan': return LucideIcons.scan;
      case 'flask-conical': return LucideIcons.flaskConical;
      case 'leaf': return LucideIcons.leaf;
      case 'heart': return LucideIcons.heart;
      default: return LucideIcons.stethoscope; 
    }
  }

  // --- REUSABLE TOGGLE CHIP (For Today/Tomorrow) ---
  Widget _buildToggleChip({required BuildContext context, required String label, required bool isSelected, required Function(bool) onSelected}) {
    final colorScheme = context.colorScheme;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      avatar: Icon(Icons.today_rounded, size: 16, color: isSelected ? Colors.white : Colors.green),
      backgroundColor: context.theme.cardColor,
      selectedColor: Colors.green,
      showCheckmark: false,
      labelStyle: context.text.labelMedium?.copyWith(color: isSelected ? Colors.white : colorScheme.onSurface, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      side: BorderSide(color: isSelected ? Colors.green : colorScheme.outline.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: context.roundedSm),
    );
  }

  // --- THEMED FILTER BUTTON ---
  Widget _buildFilterButton(BuildContext context, {required String label, required IconData icon, required bool isActive, required VoidCallback onTap}) {
    final colorScheme = context.colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary.withValues(alpha: 0.1) : context.theme.cardColor,
          borderRadius: context.roundedSm,
          border: Border.all(color: isActive ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: context.text.labelMedium?.copyWith(color: isActive ? colorScheme.primary : colorScheme.onSurface, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  // --- SELECTION SHEET (For Clinics) ---
  void _showSelectionSheet(BuildContext context, String title, List<String> options, Function(String) onSelect, bool isOdia, String currentSelection) {
    showModalBottomSheet(
      context: context, backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5, maxChildSize: 0.9, minChildSize: 0.3, expand: false,
        builder: (_, scrollController) => Padding(
          padding: EdgeInsets.all(context.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.text.titleMedium), context.gapLg, 
              Expanded(
                child: ListView.builder(
                  controller: scrollController, itemCount: options.length + 1,
                  itemBuilder: (_, index) {
                    if (index == 0) return _buildSheetOption(isOdia ? "ସବୁ" : "All", 'All', currentSelection, (val) => onSelect('All'), context);
                    return _buildSheetOption(options[index - 1], options[index - 1], currentSelection, (val) => onSelect(val), context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SORT SHEET ---
  void _showSortSheet(BuildContext context, bool isOdia) {
    showModalBottomSheet(
      context: context, backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(4))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(context.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isOdia ? "ଏହି ଅନୁସାରେ ସଜାନ୍ତୁ" : "Sort By", style: context.text.titleMedium), context.gapLg, 
              _buildSheetOption(isOdia ? "ପ୍ରାସଙ୍ଗିକତା" : "Relevance", 'relevance', widget.currentFilters.sortBy, (val) => _update(widget.currentFilters.copyWith(sortBy: val)), context),
              _buildSheetOption(isOdia ? "ମୂଲ୍ୟ: କମ୍ ରୁ ଅଧିକ" : "Price: Low to High", 'price_low', widget.currentFilters.sortBy, (val) => _update(widget.currentFilters.copyWith(sortBy: val)), context),
              _buildSheetOption(isOdia ? "ଅଭିଜ୍ଞତା: ଅଧିକ ରୁ କମ୍" : "Experience: High to Low", 'experience', widget.currentFilters.sortBy, (val) => _update(widget.currentFilters.copyWith(sortBy: val)), context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOption(String label, String value, String currentValue, Function(String) onTap, BuildContext context) {
    final isSelected = value == currentValue;
    return ListTile(
      onTap: () { onTap(value); Navigator.pop(context); },
      leading: isSelected ? Icon(Icons.check, color: context.colorScheme.primary) : const SizedBox(width: 24),
      title: Text(label, style: context.text.bodyMedium?.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? context.colorScheme.primary : context.colorScheme.onSurface)),
    );
  }
}