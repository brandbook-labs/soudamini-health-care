import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_new_app/screens/patients/booking/appointment_booking_screen.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:shimmer/shimmer.dart';

import 'package:my_new_app/screens/patients/booking/booking_bottom_sheet.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import '../../../models/doctor_model.dart';
import 'package:my_new_app/models/clinic_availability_model.dart';

import '../../../models/booking_models.dart';

// 🚀 MODULAR WIDGETS
import 'widgets/doctor_sliver_app_bar.dart';
import 'widgets/doctor_info_header.dart';
import 'widgets/clinic_location_card.dart';
import 'widgets/appointment_fee_section.dart';
import 'widgets/doctor_about_section.dart';
import 'widgets/doctor_bottom_bar.dart';

class DoctorProfileScreen extends StatefulWidget {
  final String doctorId;
  const DoctorProfileScreen({super.key, required this.doctorId});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Doctor? _doctor;

  int _selectedLocationIndex = 0;
  String _selectedAppointmentType = "consultation";

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDoctorDetails();
    });
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final provider = context.read<DoctorProvider>();
      await provider.fetchSingleDoctorProfile(widget.doctorId);

      if (mounted) {
        setState(() {
          _doctor = provider.selectedDoctorProfile;
          _hasError = _doctor == null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching doctor details via Provider: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _fetchDoctorDetails();
  }

  Future<void> _refresh() async {
    final provider = context.read<DoctorProvider>();
    await provider.fetchSingleDoctorProfile(widget.doctorId);
    if (mounted) {
      setState(() => _doctor = provider.selectedDoctorProfile);
    }
  }

  // ==========================================
  // DYNAMIC GETTERS (unchanged)
  // ==========================================
  Map<String, dynamic> get _currentLocationData {
    if (_doctor == null || _doctor!.locations.isEmpty) return {};
    if (_selectedLocationIndex >= _doctor!.locations.length) {
      return _doctor!.locations[0];
    }
    return _doctor!.locations[_selectedLocationIndex] as Map<String, dynamic>;
  }

  Map<String, dynamic> get _currentClinic {
    return _currentLocationData['clinic'] is Map
        ? _currentLocationData['clinic']
        : {};
  }

  String get _currentClinicName =>
      _currentClinic['name']?.toString() ?? _doctor!.clinicName;
  String get _currentClinicAddress =>
      _currentClinic['address']?.toString() ?? _doctor!.location;

  double get _currentLat =>
      double.tryParse(_currentClinic['lat']?.toString() ?? '0') ?? 0.0;
  double get _currentLng =>
      double.tryParse(_currentClinic['lng']?.toString() ?? '0') ?? 0.0;
  String get _currentDistance =>
      _currentLocationData['distance']?.toString() ?? "";

  double get _consultationFee =>
      double.tryParse(
        _currentLocationData['consultation_fees']?.toString() ?? '0',
      ) ??
      0.0;
  double get _followUpFee =>
      double.tryParse(
        _currentLocationData['follow_up_fees']?.toString() ?? '0',
      ) ??
      0.0;

  int get _currentPrice {
    if (_selectedAppointmentType == "follow_up") {
      return _followUpFee > 0 ? _followUpFee.toInt() : _doctor!.originalPrice;
    } else {
      return _consultationFee > 0 ? _consultationFee.toInt() : _doctor!.price;
    }
  }

  List<Map<String, dynamic>> get _currentAvailability {
    if (_currentLocationData['availability'] is List) {
      return List<Map<String, dynamic>>.from(
        _currentLocationData['availability'],
      );
    }
    return [];
  }

  List<WeeklyAvailability> _convertToWeeklyAvailability(
    List<Map<String, dynamic>> calendarData,
  ) {
    return calendarData.map((dayData) {
      DateTime? parsedDateObj;
      if (dayData['date'] != null) {
        parsedDateObj = DateTime.tryParse(dayData['date'].toString());
      }
      final primaryId = dayData['_id']?.toString();

      return WeeklyAvailability(
        label: dayData['label'] ?? "",
        status: dayData['status'] ?? "Unavailable",
        parsedDate: parsedDateObj,
        slots: (dayData['slots'] as List? ?? []).map((slotStr) {
          if (slotStr is Map) {
            final backupId = slotStr['_id']?.toString();
            final finalSlotId =
                primaryId ?? backupId ?? slotStr['value']?.toString() ?? "";

            return ClinicSlot(
              label: slotStr['label']?.toString() ?? "",
              value: finalSlotId,
              type: slotStr['type']?.toString() ?? "regular",
              start: slotStr['start']?.toString() ?? "",
              end: slotStr['end']?.toString() ?? "",
            );
          } else {
            final parts = slotStr.toString().split(' - ');
            return ClinicSlot(
              label: slotStr.toString(),
              value: primaryId ?? slotStr.toString(),
              type: "regular",
              start: parts.isNotEmpty ? parts.first : "",
              end: parts.length > 1 ? parts.last : "",
            );
          }
        }).toList(),
      );
    }).toList();
  }

  void _showBookingSheet(BuildContext context, bool isOdia) async {
    HapticFeedback.selectionClick();
    final colorScheme = Theme.of(context).colorScheme;
    final availability = _currentAvailability;

    if (availability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOdia
                ? "ଏହି କ୍ଲିନିକ୍ ରେ ସ୍ଲଟ୍ ଉପଲବ୍ଧ ନାହିଁ"
                : "No available slots for this clinic right now.",
            style: TextStyle(color: colorScheme.onError),
          ),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final structuredAvailability = _convertToWeeklyAvailability(availability);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingBottomSheet(
        doctorName: _doctor!.name,
        clinicName: _currentClinicName,
        weeklyAvailability: structuredAvailability,
        isOdia: isOdia,
      ),
    );

    if (result != null && mounted) {
      final slotId = result['slot_id']?.toString() ?? '';
      final slotDate = result['date']?.toString() ?? '';
      final slotTime = result['slotTime']?.toString() ?? '';

      final selection = BookingSelection(
        slotId: slotId,
        date: slotDate,
        slotTime: slotTime,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppointmentBookingScreen(
            doctor: _doctor!,
            clinicLocation: _currentLocationData,
            selection: selection,
            clinicServices: const [],
            initialAppointmentType: _selectedAppointmentType,
          ),
        ),
      );
    }
  }

  void _onClinicChanged(int index) {
    if (_selectedLocationIndex != index) {
      setState(() => _selectedLocationIndex = index);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (_currentLat != 0.0 && _currentLng != 0.0) {
          _mapController.move(LatLng(_currentLat, _currentLng), 16.5);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOdia =
        context.watch<LanguageController>().currentLocale.languageCode == 'or';
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: _LoadingView(onBack: () => Navigator.maybePop(context)),
      );
    }

    if (_hasError || _doctor == null) {
      return Scaffold(
        backgroundColor: bg,
        body: _ErrorView(
          isOdia: isOdia,
          onRetry: _retry,
          onBack: () => Navigator.maybePop(context),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      bottomNavigationBar: DoctorBottomBar(
        currentPrice: _currentPrice,
        appointmentType: _selectedAppointmentType,
        onBookPressed: () => _showBookingSheet(context, isOdia),
        isOdia: isOdia,
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            DoctorSliverAppBar(
              imageUrl: _doctor!.image,
              isVerified: _doctor!.isVerified,
            ),

            // Content sheet — pulled up to overlap the hero image with a
            // rounded top for a premium, layered feel.
            SliverToBoxAdapter(
              child: Container(
                transform: Matrix4.translationValues(0, -26, 0),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small grab-handle accent for the sheet
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    DoctorInfoHeader(
                      doctor: _doctor!,
                      currentClinicName: _currentClinicName,
                      isOdia: isOdia,
                    ),
                    const SizedBox(height: 32),
                    ClinicLocationCard(
                      doctor: _doctor!,
                      selectedIndex: _selectedLocationIndex,
                      onClinicChanged: _onClinicChanged,
                      mapController: _mapController,
                      currentLat: _currentLat,
                      currentLng: _currentLng,
                      currentClinicName: _currentClinicName,
                      currentClinicAddress: _currentClinicAddress,
                      currentDistance: _currentDistance,
                      isOdia: isOdia,
                    ),
                    const SizedBox(height: 32),
                    AppointmentFeeSection(
                      selectedType: _selectedAppointmentType,
                      onTypeChanged: (type) =>
                          setState(() => _selectedAppointmentType = type),
                      consultationFee: _consultationFee,
                      followUpFee: _followUpFee,
                      isOdia: isOdia,
                    ),
                    const SizedBox(height: 32),
                    DoctorAboutSection(doctor: _doctor!, isOdia: isOdia),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// LOADING SKELETON (mirrors the real layout)
// ===========================================================================
class _LoadingView extends StatelessWidget {
  final VoidCallback onBack;
  const _LoadingView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.onSurface.withValues(alpha: 0.08);
    final highlight = scheme.onSurface.withValues(alpha: 0.16);

    Widget box(double w, double h, {double r = 8}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Stack(
      children: [
        Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Container(height: 280, color: Colors.white),
              Transform.translate(
                offset: const Offset(0, -26),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      box(220, 26, r: 6),
                      const SizedBox(height: 12),
                      box(150, 16, r: 6),
                      const SizedBox(height: 14),
                      box(120, 16, r: 6),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          box(90, 30, r: 999),
                          const SizedBox(width: 10),
                          box(110, 30, r: 999),
                        ],
                      ),
                      const SizedBox(height: 22),
                      box(double.infinity, 78, r: 18),
                      const SizedBox(height: 28),
                      box(double.infinity, 190, r: 20),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(child: box(double.infinity, 120, r: 18)),
                          const SizedBox(width: 14),
                          Expanded(child: box(double.infinity, 120, r: 18)),
                        ],
                      ),
                      const SizedBox(height: 28),
                      box(140, 18, r: 6),
                      const SizedBox(height: 12),
                      box(double.infinity, 14, r: 6),
                      const SizedBox(height: 8),
                      box(double.infinity, 14, r: 6),
                      const SizedBox(height: 8),
                      box(240, 14, r: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _CircleBackButton(onTap: onBack),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// ERROR STATE
// ===========================================================================
class _ErrorView extends StatelessWidget {
  final bool isOdia;
  final VoidCallback onRetry;
  final VoidCallback onBack;
  const _ErrorView({
    required this.isOdia,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_off_rounded,
                    size: 44,
                    color: scheme.error,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isOdia
                      ? "ପ୍ରୋଫାଇଲ୍ ଲୋଡ୍ ହେଲା ନାହିଁ"
                      : "Couldn't load profile",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isOdia
                      ? "ଦୟାକରି ଆପଣଙ୍କ ଇଣ୍ଟରନେଟ୍ ଯାଞ୍ଚ କରି ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ।"
                      : "Please check your connection and try again.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(isOdia ? "ପୁଣି ଚେଷ୍ଟା କରନ୍ତୁ" : "Try Again"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _CircleBackButton(onTap: onBack),
          ),
        ),
      ],
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, color: scheme.onSurface, size: 22),
        ),
      ),
    );
  }
}
