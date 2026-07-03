import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/admin/admin_widgets/admin_payment_qr_screen.dart';
import '../../../services/api_service.dart';

class AdminWalkInScreen extends StatefulWidget {
  const AdminWalkInScreen({super.key});

  @override
  State<AdminWalkInScreen> createState() => _AdminWalkInScreenState();
}

class _AdminWalkInScreenState extends State<AdminWalkInScreen> {
  final ApiService _apiService = ApiService();

  // --- 1. ENHANCED BOOKING TYPES ---
  final List<Map<String, dynamic>> _bookingTypes = [
    {'title': 'Doctor', 'icon': LucideIcons.stethoscope, 'isComingSoon': false},
    {'title': 'Lab Test', 'icon': LucideIcons.microscope, 'isComingSoon': false}, 
    {'title': 'Hospital Bed', 'icon': LucideIcons.bed, 'isComingSoon': true},
  ];
  String _selectedBookingType = 'Doctor';

  // 🚀 SENIOR FIX: DOCTOR APPOINTMENT TYPE
  String _doctorAppointmentType = 'consultation'; 

  // --- LAB & CLINIC SERVICES STATE ---
  final Set<String> _selectedLabTests = {};
  String? _selectedLabSlot;
  bool _isLoadingInitialData = true; 
  List<dynamic> _labServicesList = []; 
  Map<String, dynamic>? _clinicOperatingHours;

  // --- DOCTOR STATE ---
  List<dynamic> _doctors = [];
  Map<String, dynamic>? _selectedDoctorObj;
  final Set<DateTime> _availableDates = {};
  String _doctorSearchQuery = '';
  List<String> _selectedDoctorAddons = []; 

  // --- COMMON STATE ---
  int _selectedTab = 0;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedSlot;

  bool _isSearching = false;
  Timer? _debounce;
  List<dynamic>? _foundPatientsList; 
  int? _selectedPatientIndex;
  String _selectedGender = 'Male';

  // 🚀 SUPER SENIOR PAYMENT STATE
  String _paymentStatus = 'pending';
  String _paymentMethod = 'pay_at_clinic'; // 'pay_at_clinic' ବା 'online_razorpay'

  final _phoneSearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _dateController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateText();
    _fetchInitialData(); 
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneSearchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    _dateController.text = DateFormat('MMM dd, yyyy').format(_selectedDate);
  }

  // --- API CALLS ---
  Future<void> _fetchInitialData() async {
    try {
      final results = await Future.wait([
        _apiService.getAdminDoctors(),
        _apiService.getAdminClinicServices(),
      ]);

      final doctorsRes = results[0];
      final clinicRes = results[1];

      if (mounted) {
        setState(() {
          if (doctorsRes.statusCode == 200) {
            _doctors = doctorsRes.data['data']['doctors'] ?? [];
            if (_doctors.isNotEmpty) _selectDoctor(_doctors[0]);
          }

          if (clinicRes.statusCode == 200) {
            final data = clinicRes.data['data'] ?? {};
            _clinicOperatingHours = data['operating_hours'];
            final allServices = data['services'] as List<dynamic>? ?? [];
            _labServicesList = allServices.where((s) => s['is_doctor_package'] == false).toList();
          }

          _isLoadingInitialData = false;
        });
      }
    } catch (e) {
      debugPrint("Init Data Error: $e");
      if (mounted) setState(() => _isLoadingInitialData = false);
    }
  }

  // --- DOCTOR LOGIC (Unchanged) ---
  void _selectDoctor(Map<String, dynamic> doctor) {
    setState(() {
      _selectedDoctorObj = doctor;
      _selectedSlot = null;
      _parseAvailableDates(doctor);
    });
  }

  void _parseAvailableDates(Map<String, dynamic> doctor) {
    _availableDates.clear();
    final availability = doctor['availability_week'] as List<dynamic>? ?? [];
    final apiFormat = DateFormat("EEE, MMM dd");
    final now = DateTime.now();

    for (var dayData in availability) {
      if (dayData['status'] == 'Available' && dayData['label'] != null) {
        try {
          DateTime parsed = apiFormat.parse(dayData['label']);
          int year = now.year;
          if (parsed.month < now.month && (now.month - parsed.month) > 6) year++;
          _availableDates.add(DateUtils.dateOnly(DateTime(year, parsed.month, parsed.day)));
        } catch (e) {}
      }
    }

    if (!_availableDates.contains(DateUtils.dateOnly(_selectedDate)) && _availableDates.isNotEmpty) {
      final sortedDates = _availableDates.toList()..sort();
      _selectedDate = sortedDates.firstWhere((d) => !d.isBefore(DateUtils.dateOnly(now)), orElse: () => sortedDates.first);
      _updateDateText();
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: _selectedBookingType == 'Doctor' 
          ? (DateTime day) => _availableDates.contains(DateUtils.dateOnly(day))
          : null, 
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
        _selectedLabSlot = null; 
        _updateDateText();
      });
    }
  }

  List<dynamic> _getDoctorSlotsForSelectedDate() {
    if (_selectedDoctorObj == null) return [];
    final availability = _selectedDoctorObj!['availability_week'] as List<dynamic>? ?? [];
    final currentLabel = DateFormat("EEE, MMM dd").format(_selectedDate);
    final index = availability.indexWhere((d) => d['label'] == currentLabel);
    if (index == -1) return [];
    final dayData = availability[index];
    if (dayData['status'] != 'Available') return [];
    return dayData['slots'] as List<dynamic>? ?? [];
  }

  List<String> _generateLabTimeSlots() {
    if (_clinicOperatingHours == null) return [];
    final bool is24h = _clinicOperatingHours!['is24h'] ?? false;
    final bool isOpen = _clinicOperatingHours!['isOpen'] ?? false;
    
    if (!isOpen) return [];

    List<String> generatedSlots = [];
    if (is24h) {
      for (int i = 0; i < 24; i++) {
        String start = '${i.toString().padLeft(2, '0')}:00';
        String end = '${(i + 1).toString().padLeft(2, '0')}:00';
        generatedSlots.add('$start - $end');
      }
    } else {
      String dayName = DateFormat('EEEE').format(_selectedDate); 
      final timings = _clinicOperatingHours!['timings'];
      
      if (timings != null && timings[dayName] != null) {
        String openStr = timings[dayName]['open']; 
        String closeStr = timings[dayName]['close']; 
        
        int openHour = int.tryParse(openStr.split(':')[0]) ?? 7;
        int closeHour = int.tryParse(closeStr.split(':')[0]) ?? 22;
        if(closeHour == 24) closeHour = 24; 
        
        for (int i = openHour; i < closeHour; i++) {
           String start = '${i.toString().padLeft(2, '0')}:00';
           String end = '${(i + 1).toString().padLeft(2, '0')}:00';
           generatedSlots.add('$start - $end');
        }
      }
    }
    return generatedSlots;
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.length < 10) {
      setState(() { _isSearching = false; _foundPatientsList = null; _selectedPatientIndex = null; });
      return;
    }
    
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final response = await _apiService.searchDatabaseForBooking(query);
        if (mounted && response.statusCode == 200 && response.data != null) {
          final data = response.data['data'];
          if ((data['is_existing'] ?? false) && (data['patients'] ?? []).isNotEmpty) {
            setState(() { _foundPatientsList = data['patients']; _selectedPatientIndex = 0; _isSearching = false; });
          } else {
            setState(() { _isSearching = false; _foundPatientsList = null; _selectedPatientIndex = null; _selectedTab = 0; _phoneController.text = query; });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("New patient! Please fill details."), backgroundColor: Colors.blue));
          }
        } else {
          if (mounted) setState(() => _isSearching = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  // =========================================================
  // 🚀 SUPER SENIOR API CALL (WITH SAFE PAYMENT ROUTING)
  // =========================================================
  Future<void> _submitBooking() async {
    Map<String, dynamic> patientData;
    String? linkedUserId;

    if (_selectedTab == 0) {
      if (_nameController.text.trim().isEmpty || _phoneController.text.trim().length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide valid Name & Phone"), backgroundColor: Colors.red));
        return;
      }
      patientData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "age": _ageController.text.trim(),
        "gender": _selectedGender,
      };
    } else {
      if (_foundPatientsList == null || _selectedPatientIndex == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a patient"), backgroundColor: Colors.red));
        return;
      }
      final selectedPatient = _foundPatientsList![_selectedPatientIndex!];
      patientData = {
        "name": selectedPatient['name'],
        "phone": selectedPatient['phone'],
        "age": selectedPatient['age']?.toString() ?? '',
        "gender": selectedPatient['gender'] ?? 'Unknown',
      };
      linkedUserId = selectedPatient['user_id']; 
    }

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      // Common Master Payload Format
      Map<String, dynamic> payload = {
        "patient": patientData,
        "date": DateFormat('yyyy-MM-dd').format(_selectedDate),
        "total_cost": _totalPrice,
        "payment_status": _paymentStatus,
        "payment_method": _paymentMethod, // 🚀 NEW: Sending the secure payment method
        "notes": _notesController.text.trim(),
      };
      if (linkedUserId != null) payload["user_id"] = linkedUserId; 

      if (_selectedBookingType == 'Doctor') {
          // ❌ ପୁରୁଣା ଭୁଲ୍ ଉପାୟ: final slotStr = _selectedSlot!['value'] as String; (ଏହାକୁ କାଢି ଦିଅନ୍ତୁ)

          List<Map<String, dynamic>> extraServicesPayload = [];

          if (_selectedDoctorObj != null && _selectedDoctorObj!['services'] != null) {
            for (var docService in (_selectedDoctorObj!['services'] as List)) {
              if (docService['is_doctor_package'] == true) {
                extraServicesPayload.add({"service_id": docService['service_id'], "name": docService['name'], "count": 1});
              }
            }
          }
          for (String sVal in _selectedDoctorAddons) {
            final index = _labServicesList.indexWhere((s) => s['_id'] == sVal);
            if (index != -1) {
              final service = _labServicesList[index];
              extraServicesPayload.add({"service_id": service['_id'], "name": service['name'], "count": 1});
            }
          }
          
          // 🚀 SUPER SENIOR FIX: ସିଧାସଳଖ Object ରୁ _id ଏବଂ ସମୟ ଆଣିବା
          payload.addAll({
            "appointment_type": _doctorAppointmentType, 
            "doctor_id": _selectedDoctorObj!['doctor_id'] ?? _selectedDoctorObj!['_id'],
            "mapping_id": _selectedDoctorObj!['mapping_id'], 

            // 🎯 ଏହି ୩ଟି ଲାଇନ୍ ହେଉଛି ଆପଣଙ୍କର ମେନ୍ ସମାଧାନ:
            "slot": _selectedSlot!['_id'],       // MongoDB Object ID (e.g. 69d519ebe56...)
            "start": _selectedSlot!['start'],    // "8:00 AM" ବା "6:30 PM"
            "end": _selectedSlot!['end'],        // "10:00 AM" ବା "9:00 PM"
            
            "extra_services": extraServicesPayload, 
          });

      } else if (_selectedBookingType == 'Lab Test') {
          List<Map<String, dynamic>> extraServicesPayload = [];
          for (String testId in _selectedLabTests) {
            final index = _labServicesList.indexWhere((s) => s['_id'] == testId);
            if (index != -1) {
               final test = _labServicesList[index];
               extraServicesPayload.add({
                  "service_id": test['_id'],
                  "name": test['name'],
                  "count": 1
               });
            }
          }
          final parts = _selectedLabSlot!.split(' - ');

          payload.addAll({
            "appointment_type": "service_only", 
            "start": parts[0].trim(),
            "end": parts[1].trim(),
            "extra_services": extraServicesPayload, 
          });
      }

      print("🚀 Final Perfect Booking Payload: $payload");
      final response = await _apiService.bookAppointment(tokenKey: "admin_token", bookingData: payload); 
      
      if (mounted) {
        Navigator.pop(context); // ୧. ଲୋଡିଂ ଡାଏଲଗ୍ କୁ ବନ୍ଦ କରିବେ

        if (response.statusCode == 200 || response.statusCode == 201) {
          
          // 🚀 THE MAGIC ROUTING
          if (_paymentMethod == 'online_razorpay') {
             
             final bookingData = response.data['data'];
             // ବ୍ୟାକଏଣ୍ଡ୍ ରୁ ମିଳିଥିବା ସଠିକ୍ database _id ଧରନ୍ତୁ
             final bookingId = bookingData['appointment_id'] ?? bookingData['_id']; 
             
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Booking Saved! Generating QR..."), backgroundColor: Colors.blue));
             
             // ୨. 🚀 ସିଧାସଳଖ QR ସ୍କ୍ରିନ୍ କୁ ଯାଆନ୍ତୁ
             Navigator.pushReplacement(
               context, 
               MaterialPageRoute(
                 builder: (context) => AdminPaymentQRScreen(
                   appointmentId: bookingId.toString(),
                   amount: _totalPrice, // ଟଙ୍କା ପଠାନ୍ତୁ ଯାହାଦ୍ୱାରା QR ସ୍କ୍ରିନ୍ ରେ ଦେଖାଯିବ
                 ),
               ),
             );

          } else {
             // ୩. ଯଦି କ୍ୟାସ୍ ରେ ବୁକିଂ ହୋଇଛି, ତେବେ ସିଧା ଫେରିଯାଆନ୍ତୁ
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$_selectedBookingType Booking Confirmed!"), backgroundColor: Colors.green));
             Navigator.pop(context); 
          }
          
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${response.data['msg'] ?? 'Error'}"), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking Failed: $e"), backgroundColor: Colors.red));
      }
    }
  }

  // --- PRICING LOGIC (Unchanged) ---
  double get _totalPrice {
    double total = 0.0;
    final isLockedFeature = _bookingTypes.firstWhere((t) => t['title'] == _selectedBookingType)['isComingSoon'] as bool;
    if (isLockedFeature) return 0.0;

    if (_selectedBookingType == 'Doctor' && _selectedDoctorObj != null) {
      final feeKey = _doctorAppointmentType == 'consultation' ? 'consultation_fees' : 'follow_up_fees';
      final fee = _selectedDoctorObj![feeKey]?.toString() ?? '0';
      total += double.tryParse(fee) ?? 0.0;

      final docServices = _selectedDoctorObj!['services'] as List<dynamic>? ?? [];
      for (var sVal in docServices) {
        if (sVal['is_doctor_package'] == true) total += double.tryParse(sVal['price']?.toString() ?? '0') ?? 0.0;
      }
      for (String sVal in _selectedDoctorAddons) {
        final index = _labServicesList.indexWhere((s) => s['_id'] == sVal);
        if (index != -1) total += double.tryParse(_labServicesList[index]['discount_price']?.toString() ?? _labServicesList[index]['price']?.toString() ?? '0') ?? 0.0;
      }
    } else if (_selectedBookingType == 'Lab Test') {
      for (String testId in _selectedLabTests) {
        final index = _labServicesList.indexWhere((s) => s['_id'] == testId);
        if (index != -1) total += double.tryParse(_labServicesList[index]['discount_price']?.toString() ?? _labServicesList[index]['price']?.toString() ?? '0') ?? 0.0;
      }
    }
    return total;
  }

  void _toggleDoctorAddon(String serviceId) {
    setState(() {
      _selectedDoctorAddons.contains(serviceId) ? _selectedDoctorAddons.remove(serviceId) : _selectedDoctorAddons.add(serviceId);
    });
  }

  void _toggleLabTest(String id) {
    setState(() {
      _selectedLabTests.contains(id) ? _selectedLabTests.remove(id) : _selectedLabTests.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final filteredDoctors = _doctors.where((doc) {
      return (doc['name']?.toString().toLowerCase() ?? '').contains(_doctorSearchQuery.toLowerCase());
    }).toList();

    final isCurrentFeatureLocked = _bookingTypes.firstWhere((t) => t['title'] == _selectedBookingType)['isComingSoon'] as bool;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(LucideIcons.x, color: theme.appBarTheme.foregroundColor), onPressed: () => Navigator.pop(context)),
        title: Text("Admin Booking", style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingInitialData
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- MULTI-BOOKING TYPE SELECTOR (Unchanged) ---
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: _bookingTypes.map((typeObj) {
                              final type = typeObj['title'] as String;
                              final icon = typeObj['icon'] as IconData;
                              final isComingSoon = typeObj['isComingSoon'] as bool;
                              final isSelected = _selectedBookingType == type;

                              return GestureDetector(
                                onTap: () => setState(() { _selectedBookingType = type; _selectedSlot = null; _selectedLabSlot = null; }),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      decoration: BoxDecoration(
                                        color: isSelected ? colorScheme.primary : theme.cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: isSelected ? colorScheme.primary : theme.dividerColor.withOpacity(0.5), width: 1.5),
                                        boxShadow: isSelected ? [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(icon, size: 18, color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                                          const SizedBox(width: 10),
                                          Text(type, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: isSelected ? colorScheme.onPrimary : theme.textTheme.bodyMedium?.color)),
                                        ],
                                      ),
                                    ),
                                    if (isComingSoon)
                                      Positioned(
                                        top: -5, right: 5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.amber.shade700, borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.scaffoldBackgroundColor, width: 2)),
                                          child: const Text("SOON", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- PATIENT DETAILS (Unchanged) ---
                        _buildSectionHeader("PATIENT DETAILS", theme),
                        Container(
                          padding: const EdgeInsets.all(4),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [_buildSegmentTab("New Patient", 0, theme), _buildSegmentTab("Database Search", 1, theme)]),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: _selectedTab == 0 ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: _buildNewPatientForm(theme),
                          secondChild: _buildReturningPatientSearch(theme),
                        ),
                        const SizedBox(height: 32),

                        // --- DYNAMIC SECTION: DOCTOR (Unchanged) ---
                        if (_selectedBookingType == 'Doctor') ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader("SELECT SPECIALIST", theme),
                              SizedBox(width: 140, height: 30, child: TextField(onChanged: (val) => setState(() => _doctorSearchQuery = val), style: const TextStyle(fontSize: 12), decoration: InputDecoration(hintText: "Filter...", prefixIcon: const Icon(LucideIcons.search, size: 14), contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (filteredDoctors.isEmpty)
                            const Center(child: Text("No doctors found"))
                          else
                            SizedBox(
                              height: 140,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                itemCount: filteredDoctors.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildDoctorCard(
                                    doctorObj: filteredDoctors[index],
                                    name: filteredDoctors[index]['name'] ?? "Unknown",
                                    specialty: (filteredDoctors[index]['departments'] as List).isNotEmpty ? filteredDoctors[index]['departments'][0].toString().toUpperCase() : "DOCTOR",
                                    color: index % 2 == 0 ? Colors.blue : Colors.purple,
                                    theme: theme,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          _buildSectionHeader("APPOINTMENT TYPE", theme),
                          const SizedBox(height: 12),
                          _buildAppointmentTypeSelector(theme),
                          const SizedBox(height: 24),

                          _buildDateSelector(theme),
                          const SizedBox(height: 32),
                          
                          if (_selectedDoctorObj != null) _buildDoctorPackagesBox(theme, _selectedDoctorObj!['services'] ?? []),

                          if (_labServicesList.isNotEmpty) ...[
                            _buildSectionHeader("ADD-ON / CLINIC SERVICES", theme),
                            const SizedBox(height: 12),
                            _buildDoctorAddonSection(theme),
                            const SizedBox(height: 32),
                          ],

                          _buildSectionHeader("AVAILABLE DOCTOR SLOTS", theme),
                          const SizedBox(height: 12),
                          _buildDoctorSlotsSection(theme),
                          const SizedBox(height: 24),
                        ],

                        // --- DYNAMIC SECTION: LAB TEST (Unchanged) ---
                        if (_selectedBookingType == 'Lab Test') ...[
                          _buildDateSelector(theme),
                          const SizedBox(height: 24),
                          
                          _buildSectionHeader("SELECT TIME SLOT (OPERATING HOURS)", theme),
                          const SizedBox(height: 12),
                          _buildLabTimeSlots(theme),
                          const SizedBox(height: 32),

                          _buildSectionHeader("CLINIC INDIVIDUAL TESTS", theme),
                          const SizedBox(height: 12),
                          if (_labServicesList.isEmpty)
                             const Center(child: Text("No lab services available."))
                          else
                             _buildDynamicLabServicesSection(theme),
                          const SizedBox(height: 32),
                        ],

                        // --- DYNAMIC SECTION: HOSPITAL BED (Unchanged) ---
                        if (_selectedBookingType == 'Hospital Bed') ...[
                          // (Hospital Bed UI kept exactly same as your code)
                          Container(
                            height: 350, 
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.1,
                                    child: Icon(LucideIcons.bedDouble, size: 150, color: theme.colorScheme.primary),
                                  ),
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.scaffoldBackgroundColor.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(LucideIcons.lock, size: 32, color: Colors.amber.shade800),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            "Hospital Bed Booking",
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade700,
                                              borderRadius: BorderRadius.circular(20)
                                            ),
                                            child: const Text("Coming Soon", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        // --- ADMIN NOTES (Unchanged) ---
                        _buildSectionHeader("INTERNAL NOTES (ADMIN ONLY)", theme),
                        const SizedBox(height: 12),
                        TextField(controller: _notesController, maxLines: 3, decoration: InputDecoration(hintText: "Add specific requirements...", filled: true, fillColor: theme.cardColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)))),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // =========================================================
                // 🚀 SUPER SENIOR UI: ENHANCED BOTTOM BAR WITH PAYMENT OPTIONS
                // =========================================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: theme.cardColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 🚀 NEW: Payment Method Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Payment Mode:", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                            Container(
                              decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  GestureDetector(onTap: () => setState(() => _paymentMethod = 'pay_at_clinic'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _paymentMethod == 'pay_at_clinic' ? theme.colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text("Cash", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _paymentMethod == 'pay_at_clinic' ? Colors.white : Colors.grey)))),
                                  // GestureDetector(onTap: () => setState(() => _paymentMethod = 'online_razorpay'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _paymentMethod == 'online_razorpay' ? Colors.purple.shade600 : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(LucideIcons.qrCode, size: 12, color: _paymentMethod == 'online_razorpay' ? Colors.white : Colors.grey), const SizedBox(width: 4), Text("QR Link", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _paymentMethod == 'online_razorpay' ? Colors.white : Colors.grey))]))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Existing Status Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Payment Status:", style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                            Container(
                              decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  GestureDetector(onTap: () => setState(() => _paymentStatus = 'pending'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _paymentStatus == 'pending' ? Colors.orange.shade700 : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text("Pending", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _paymentStatus == 'pending' ? Colors.white : Colors.grey)))),
                                  GestureDetector(onTap: () => setState(() => _paymentStatus = 'paid'), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: _paymentStatus == 'paid' ? Colors.green.shade600 : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text("Paid", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _paymentStatus == 'paid' ? Colors.white : Colors.grey)))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("Total to Pay", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12, color: Colors.grey)),
                                Text(isCurrentFeatureLocked ? "₹--" : "₹$_totalPrice", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isCurrentFeatureLocked ? Colors.grey : colorScheme.primary)),
                              ],
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: isCurrentFeatureLocked || 
                                         (_selectedBookingType == 'Doctor' && _selectedSlot == null) ||
                                         (_selectedBookingType == 'Lab Test' && (_selectedLabTests.isEmpty || _selectedLabSlot == null))
                                  ? null
                                  : _submitBooking,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCurrentFeatureLocked ? Colors.grey.shade400 : theme.textTheme.bodyLarge?.color,
                                foregroundColor: isCurrentFeatureLocked ? Colors.white : theme.scaffoldBackgroundColor,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                                disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                              ),
                              child: Row(
                                children: [
                                  Text(isCurrentFeatureLocked ? "Locked" : (_paymentMethod == 'online_razorpay' ? "Create & Show QR" : "Confirm Booking"), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(isCurrentFeatureLocked ? LucideIcons.lock : LucideIcons.arrowRight, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // --- SUB WIDGETS (All sub-widgets remain 100% UNCHANGED) ---
  Widget _buildAppointmentTypeSelector(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [_buildApptTypeTab("Consultation", 'consultation', theme), _buildApptTypeTab("Follow-up", 'follow_up', theme)]),
    );
  }

  Widget _buildApptTypeTab(String title, String value, ThemeData theme) {
    final isSelected = _doctorAppointmentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _doctorAppointmentType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? theme.cardColor : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.colorScheme.primary : Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildNewPatientForm(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(LucideIcons.userPlus, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 8), Text("Register New Patient", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.colorScheme.primary))]),
          const SizedBox(height: 20),
          _buildMinimalField(controller: _nameController, label: "Full Name", icon: LucideIcons.user, theme: theme),
          const SizedBox(height: 16),
          Row(children: [Expanded(flex: 3, child: _buildMinimalField(controller: _phoneController, label: "Phone Number", icon: LucideIcons.phone, inputType: TextInputType.phone, theme: theme)), const SizedBox(width: 16), Expanded(flex: 2, child: _buildMinimalField(controller: _ageController, label: "Age", icon: LucideIcons.calendar, inputType: TextInputType.number, theme: theme))]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGender, isExpanded: true, icon: Icon(LucideIcons.chevronDown, color: Colors.grey.shade400, size: 18),
                items: ['Male', 'Female', 'Other'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (newValue) => setState(() => _selectedGender = newValue!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({required Map<String, dynamic> doctorObj, required String name, required String specialty, required Color color, required ThemeData theme}) {
    final isSelected = _selectedDoctorObj == doctorObj;
    final String imageUrl = doctorObj['profile'] ?? '';
    return GestureDetector(
      onTap: () => _selectDoctor(doctorObj),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), width: 160, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: isSelected ? color : theme.cardColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : theme.dividerColor, width: 2), boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))] : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CircleAvatar(radius: 18, backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : theme.dividerColor, backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null, child: imageUrl.isEmpty ? Icon(LucideIcons.user, size: 18, color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color) : null), if (isSelected) const Icon(LucideIcons.checkCircle, color: Colors.white, size: 18)]),
            const Spacer(),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color)),
            const SizedBox(height: 2),
            Text(specialty, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabTimeSlots(ThemeData theme) {
    final slots = _generateLabTimeSlots();
    if (slots.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.2))), child: const Center(child: Text("Clinic is closed on this date.", style: TextStyle(color: Colors.grey))));
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: slots.map((slot) {
        final isSelected = _selectedLabSlot == slot;
        return GestureDetector(
          onTap: () => setState(() => _selectedLabSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : theme.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor), boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
            child: Text(slot, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDynamicLabServicesSection(ThemeData theme) {
    return Column(
      children: _labServicesList.map((service) {
        final id = service['_id'];
        final isSelected = _selectedLabTests.contains(id);
        final price = service['discount_price'] ?? service['price'] ?? 0;
        return GestureDetector(
          onTap: () => _toggleLabTest(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: isSelected ? 1.5 : 1)),
            child: Row(
              children: [
                Icon(isSelected ? LucideIcons.checkSquare : LucideIcons.square, color: isSelected ? theme.colorScheme.primary : Colors.grey, size: 20),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(service['name'] ?? "Unknown Test", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Row(children: const [Icon(LucideIcons.activity, size: 12, color: Colors.grey), SizedBox(width: 4), Text("Clinic Service", style: TextStyle(fontSize: 11, color: Colors.grey))])])),
                Text("₹$price", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDoctorAddonSection(ThemeData theme) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, clipBehavior: Clip.none, itemCount: _labServicesList.length,
        itemBuilder: (context, index) {
          final service = _labServicesList[index];
          final id = service['_id'];
          final isSelected = _selectedDoctorAddons.contains(id);
          final finalPrice = service['discount_price'] ?? service['price'];
          return GestureDetector(
            onTap: () => _toggleDoctorAddon(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200), width: 150, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.5)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(LucideIcons.activity, size: 14, color: theme.colorScheme.primary)), if (isSelected) Icon(LucideIcons.checkCircle, size: 16, color: theme.colorScheme.primary)]),
                  const SizedBox(height: 8),
                  Text(service['name'] ?? "Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.colorScheme.primary : null), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text("+₹$finalPrice", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDoctorSlotsSection(ThemeData theme) {
    final slots = _getDoctorSlotsForSelectedDate();
    if (slots.isEmpty) return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.withOpacity(0.2))), child: Center(child: Text(_availableDates.contains(DateUtils.dateOnly(_selectedDate)) ? "No time slots configured for this day" : "Doctor unavailable on this date", style: const TextStyle(color: Colors.grey))));
    return Column(
      children: slots.map((slotData) {
        final isSelected = _selectedSlot != null && _selectedSlot!['value'] == slotData['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slotData),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary : theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: 1.5), boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : []),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("${slotData['start']} - ${slotData['end']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color)), if (isSelected) Icon(LucideIcons.checkCircle, color: theme.colorScheme.onPrimary, size: 20)]),
                const SizedBox(height: 4),
                Text(slotData['label'] ?? "Slot", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isSelected ? theme.colorScheme.onPrimary.withOpacity(0.9) : theme.textTheme.bodyMedium?.color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReturningPatientSearch(ThemeData theme) {
    return Column(
      children: [
        Container(decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Row(children: [Icon(LucideIcons.search, color: theme.colorScheme.primary), const SizedBox(width: 12), Expanded(child: TextField(controller: _phoneSearchController, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: "Enter Phone Number", border: InputBorder.none), onChanged: _onSearchChanged)), if (_isSearching) SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary))])),
        if (_foundPatientsList != null && _foundPatientsList!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16), constraints: const BoxConstraints(maxHeight: 280), 
            child: ListView.separated(
              shrinkWrap: true, physics: const BouncingScrollPhysics(), itemCount: _foundPatientsList!.length, separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final patient = _foundPatientsList![index];
                final isSelected = _selectedPatientIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPatientIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: isSelected ? theme.colorScheme.primary.withOpacity(0.05) : theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.5), width: isSelected ? 1.5 : 1)),
                    child: Row(children: [CircleAvatar(backgroundColor: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.dividerColor.withOpacity(0.3), child: Text(patient['name']?[0]?.toUpperCase() ?? 'U', style: TextStyle(color: isSelected ? theme.colorScheme.primary : Colors.grey, fontWeight: FontWeight.bold))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(patient['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text("${patient['phone']}  •  ${patient['age'] ?? 'N/A'} Yrs", style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), fontWeight: FontWeight.w500))])), Icon(isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle, color: isSelected ? theme.colorScheme.primary : Colors.grey.shade400)]),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMinimalField({required TextEditingController controller, required String label, required IconData icon, required ThemeData theme, TextInputType inputType = TextInputType.text}) {
    return Container(decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: TextField(controller: controller, keyboardType: inputType, decoration: InputDecoration(icon: Icon(icon, color: Colors.grey.shade400, size: 18), labelText: label, border: InputBorder.none)));
  }

  Widget _buildDateSelector(ThemeData theme) {
    return GestureDetector(onTap: _pickDate, child: Container(decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [Icon(LucideIcons.calendarCheck, color: theme.colorScheme.primary, size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Date of Visit", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)), Text(_dateController.text, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold))]), const Spacer(), const Icon(LucideIcons.chevronDown, size: 16, color: Colors.grey)])));
  }

  Widget _buildDoctorPackagesBox(ThemeData theme, List<dynamic> docServices) {
    final packages = docServices.where((s) => s['is_doctor_package'] == true).toList();
    if (packages.isEmpty) return const SizedBox.shrink();
    return Container(margin: const EdgeInsets.only(bottom: 24), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), border: Border.all(color: Colors.blue.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(LucideIcons.packagePlus, size: 16, color: Colors.blue.shade700), const SizedBox(width: 8), Text("Auto-Included Packages", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade800))]), const SizedBox(height: 8), ...packages.map((pkg) => Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("• ${pkg['name']}", style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color)), Text("+₹${pkg['price']}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700))]))).toList()]));
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: theme.brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade500, letterSpacing: 1.2));
  }

  Widget _buildSegmentTab(String title, int index, ThemeData theme) {
    final isSelected = _selectedTab == index;
    return Expanded(child: GestureDetector(onTap: () => setState(() { _selectedTab = index; if(index == 0) { _foundPatientsList = null; _selectedPatientIndex = null; } }), child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? theme.cardColor : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : []), alignment: Alignment.center, child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isSelected ? theme.textTheme.bodyLarge?.color : Colors.grey)))));
  }
}