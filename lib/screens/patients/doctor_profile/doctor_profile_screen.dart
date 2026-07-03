import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:my_new_app/screens/patients/booking/appointment_booking_screen.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:my_new_app/screens/patients/booking/booking_bottom_sheet.dart';
import 'package:my_new_app/controllers/language_controller.dart';
import '../../../models/doctor_model.dart';
import 'package:my_new_app/models/clinic_availability_model.dart';

import '../../../models/booking_models.dart';

// 🚀 IMPORT OUR NEW MODULAR WIDGETS
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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching doctor details via Provider: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==========================================
  // 🚀 DYNAMIC GETTERS (Unchanged)
  // ==========================================
  Map<String, dynamic> get _currentLocationData {
    if (_doctor == null || _doctor!.locations.isEmpty) return {};
    if (_selectedLocationIndex >= _doctor!.locations.length)
      return _doctor!.locations[0];
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
    final availability = _currentAvailability;

    if (availability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOdia
                ? "ଏହି କ୍ଲିନିକ୍ ରେ ସ୍ଲଟ୍ ଉପଲବ୍ଧ ନାହିଁ"
                : "No available slots for this clinic right now.",
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDarkMode
        ? const Color(0xFF121212)
        : const Color(0xFFF8FAFC);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_doctor == null) {
      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: const Center(child: Text("Error loading data")),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      bottomNavigationBar: DoctorBottomBar(
        currentPrice: _currentPrice,
        appointmentType: _selectedAppointmentType,
        onBookPressed: () => _showBookingSheet(context, isOdia),
        isOdia: isOdia,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          DoctorSliverAppBar(imageUrl: _doctor!.image),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DOCTOR INFO HEADER
                  DoctorInfoHeader(
                    doctor: _doctor!,
                    currentClinicName: _currentClinicName,
                    isOdia: isOdia,
                  ),
                  const SizedBox(height: 32),

                  // 2. CLINIC & MAP SECTION
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

                  // 3. APPOINTMENT TYPE & FEES
                  AppointmentFeeSection(
                    selectedType: _selectedAppointmentType,
                    onTypeChanged: (type) =>
                        setState(() => _selectedAppointmentType = type),
                    consultationFee: _consultationFee,
                    followUpFee: _followUpFee,
                    isOdia: isOdia,
                  ),

                  const Divider(height: 48),

                  // 4. ABOUT, EDUCATION, LANGUAGES
                  DoctorAboutSection(doctor: _doctor!, isOdia: isOdia),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
