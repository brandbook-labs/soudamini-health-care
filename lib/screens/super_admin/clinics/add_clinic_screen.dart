import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/api_service.dart';

// --- CONSTANTS ---
const List<String> COMMON_FACILITIES = [
  "24/7 Emergency",
  "ICU",
  "Pharmacy",
  "Pathology Lab",
  "Radiology",
  "Wifi",
  "Parking",
  "Cafeteria",
  "Wheelchair Access",
];

const List<String> AVAILABLE_SERVICES = [
  "General Consultation",
  "Blood Test",
  "X-Ray",
  "MRI",
  "CT Scan",
];

const List<String> LAB_EQUIPMENT_LIST = [
  "Hematology Analyzer",
  "Digital X-Ray",
  "Ultrasound Machine",
];

const List<String> ACCREDITATIONS_LIST = [
  "NABL",
  "CAP",
  "ISO 15189",
  "CLIA",
  "JCI",
  "NABH",
];

// --- MAIN SCREEN ---
class AddClinicScreen extends StatefulWidget {
  final String? clinicId; // If provided, Edit Mode is enabled
  const AddClinicScreen({super.key, this.clinicId});

  @override
  State<AddClinicScreen> createState() => _AddClinicScreenState();
}

class _AddClinicScreenState extends State<AddClinicScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // --- STATE ---
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditMode = false;
  XFile? _logoFile;

  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _websiteController = TextEditingController();
  final _licenseController = TextEditingController();
  final _notesController = TextEditingController();

  // Address
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // --- COMPLEX DATA MODELS ---
  LatLng _selectedLocation = const LatLng(
    20.2961,
    85.8245,
  ); // Default Bhubaneswar
  List<String> _selectedFacilities = [];
  List<String> _selectedAccreditations = [];
  List<Map<String, dynamic>> _selectedEquipments = [];
  List<Map<String, dynamic>> _selectedServices = [];
  List<Map<String, dynamic>> _availableSlots = [];

  // New Schema Fields
  bool _isServicesAvailable = false;
  String _facilityType = "clinic";
  String _status = "active";
  List<String> _bookingType = ["in-clinic"];

  // Operating Hours (Default Structure)
  Map<String, dynamic> _operatingHours = {
    "isOpen": true,
    "is24h": false,
    "timings": {
      "Monday": {"open": "09:00", "close": "21:00"},
      "Tuesday": {"open": "09:00", "close": "21:00"},
      "Wednesday": {"open": "09:00", "close": "21:00"},
      "Thursday": {"open": "09:00", "close": "21:00"},
      "Friday": {"open": "09:00", "close": "21:00"},
      "Saturday": {"open": "09:00", "close": "21:00"},
      "Sunday": {"open": "10:00", "close": "14:00"},
    },
  };

  // --- SERVICE INPUT TEMP STATE ---
  String _serviceSearch = "";
  String _servicePrice = "";
  String _serviceDiscount = "";
  bool _isDoctorPackage = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.clinicId != null;

    // If ID is passed, Fetch Data
    if (_isEditMode) {
      _fetchClinicDetails();
    }
  }

  // --- API: FETCH DETAILS (Fixed) ---
  Future<void> _fetchClinicDetails() async {
    setState(() => _isLoading = true);
    try {
      // Ensure your ApiService.getClinicDetails accepts (id, token)
      final response = await _apiService.getClinicDetails(widget.clinicId!);

      if (response.statusCode == 200) {
        // Handle response structure (check if data is inside 'data' key)
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;

        _populateFields(data);
      } else {
        throw Exception("Failed to load data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching clinic: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to fetch details: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- POPULATE FIELDS FROM API ---
  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? "";
    _emailController.text = data['email'] ?? "";
    _phoneController.text = data['phone'] ?? "";
    _emergencyContactController.text = data['emergency_contact'] ?? "";
    _websiteController.text = data['website'] ?? "";
    _licenseController.text = data['licenseNumber'] ?? "";
    _notesController.text = data['notes'] ?? "";

    _addressController.text = data['address'] ?? "";
    _cityController.text = data['city'] ?? "";
    _stateController.text = data['state'] ?? "";
    _pincodeController.text = data['pincode'] ?? "";

    _facilityType = data['facility_type'] ?? "clinic";
    _status = data['status'] ?? "active";
    _isServicesAvailable = data['isServicesAvailable'] ?? false;

    if (data['lat'] != null && data['lng'] != null) {
      _selectedLocation = LatLng(
        double.tryParse(data['lat'].toString()) ?? 0,
        double.tryParse(data['lng'].toString()) ?? 0,
      );
    }

    if (data['facilities'] != null)
      _selectedFacilities = List<String>.from(data['facilities']);
    if (data['accreditations'] != null)
      _selectedAccreditations = List<String>.from(data['accreditations']);

    if (data['equipments'] != null)
      _selectedEquipments = List<Map<String, dynamic>>.from(data['equipments']);
    if (data['services'] != null)
      _selectedServices = List<Map<String, dynamic>>.from(data['services']);
    if (data['available_slots'] != null)
      _availableSlots = List<Map<String, dynamic>>.from(
        data['available_slots'],
      );

    if (data['operating_hours'] != null)
      _operatingHours = data['operating_hours'];
    if (data['booking_type'] != null)
      _bookingType = List<String>.from(data['booking_type']);
  }

  // --- SAVE / UPDATE LOGIC ---
  Future<void> _saveClinic() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final token = await _storage.read(key: 'admin_token');

      // Construct Payload
      final Map<String, dynamic> payload = {
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneController.text.trim(),
        "emergency_contact": _emergencyContactController.text.trim(),
        "website": _websiteController.text.trim(),
        "licenseNumber": _licenseController.text.trim(),
        "notes": _notesController.text.trim(),

        "facility_type": _facilityType,
        "status": _status,
        "isServicesAvailable": _isServicesAvailable,
        "booking_type": _bookingType, // ["in-clinic"]

        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "state": _stateController.text.trim(),
        "country": "India",
        "pincode": _pincodeController.text.trim(),
        "lat": _selectedLocation.latitude.toString(),
        "lng": _selectedLocation.longitude.toString(),

        // Arrays & Objects
        "facilities": _selectedFacilities,
        "accreditations": _selectedAccreditations,
        "equipments": _selectedEquipments,
        "services": _selectedServices,
        "available_slots": _availableSlots,
        "operating_hours": _operatingHours,
      };

      Response response;
      if (_isEditMode) {
        // UPDATE (Pass Clinic ID)
        response = await _apiService.updateAdminClinic(
          widget.clinicId!,
          payload,
          _logoFile,
        );
      } else {
        // CREATE
        response = await _apiService.addAdminClinic(payload, _logoFile);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditMode ? "Clinic Updated!" : "Clinic Created!",
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to refresh list
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- SERVICE HANDLER ---
  void _addService() {
    if (_serviceSearch.trim().isEmpty || _servicePrice.trim().isEmpty) return;

    final newService = {
      'name': _serviceSearch.trim(),
      'value': _serviceSearch.trim().toLowerCase().replaceAll(' ', '-'),
      'price': int.tryParse(_servicePrice) ?? 0,
      'discount_price': int.tryParse(_serviceDiscount) ?? 0,
      'is_doctor_package': _isDoctorPackage,
    };

    setState(() {
      _selectedServices.add(newService);
      _serviceSearch = "";
      _servicePrice = "";
      _serviceDiscount = "";
      _isDoctorPackage = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _logoFile = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? "Edit Clinic" : "Add New Clinic"),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveClinic,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    _isEditMode
                        ? "Update Clinic Profile"
                        : "Save Clinic Profile",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BASIC DETAILS
              _ExpandableSection(
                title: "Basic Details",
                icon: LucideIcons.building2,
                isOpen: true,
                theme: theme,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.cardColor,
                        backgroundImage: _logoFile != null
                            ? FileImage(File(_logoFile!.path))
                            : null,
                        child: _logoFile == null
                            ? Icon(
                                LucideIcons.camera,
                                color: theme.disabledColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    "Clinic Name",
                    _nameController,
                    theme,
                    icon: LucideIcons.building,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    "Email Address",
                    _emailController,
                    theme,
                    icon: LucideIcons.mail,
                    type: TextInputType.emailAddress,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          "Phone",
                          _phoneController,
                          theme,
                          icon: LucideIcons.phone,
                          type: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // FIXED: Replaced LucideIcons.ambulance with LucideIcons.alertCircle
                      Expanded(
                        child: _buildInput(
                          "Emergency",
                          _emergencyContactController,
                          theme,
                          icon: LucideIcons.alertCircle,
                          type: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    "Website URL",
                    _websiteController,
                    theme,
                    icon: LucideIcons.globe,
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    "License Number",
                    _licenseController,
                    theme,
                    icon: LucideIcons.fileBadge,
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    "Notes / Tagline",
                    _notesController,
                    theme,
                    icon: LucideIcons.stickyNote,
                  ),
                ],
              ),

              // 2. LOCATION
              _ExpandableSection(
                title: "Location & Map",
                icon: LucideIcons.mapPin,
                theme: theme,
                children: [
                  _buildInput("Street Address", _addressController, theme),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput("City", _cityController, theme),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput("State", _stateController, theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInput(
                    "Pincode",
                    _pincodeController,
                    theme,
                    type: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  // Map View
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 13.0,
                              onTap: (_, point) =>
                                  setState(() => _selectedLocation = point),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      LucideIcons.mapPin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${_selectedLocation.latitude.toStringAsFixed(4)}, ${_selectedLocation.longitude.toStringAsFixed(4)}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // 3. OPERATING HOURS
              _ExpandableSection(
                title: "Operating Hours",
                icon: LucideIcons.clock,
                theme: theme,
                children: [
                  SwitchListTile(
                    title: const Text(
                      "Clinic is Open",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _operatingHours['isOpen'],
                    onChanged: (v) =>
                        setState(() => _operatingHours['isOpen'] = v),
                    activeColor: theme.colorScheme.primary,
                  ),
                  SwitchListTile(
                    title: const Text(
                      "Open 24 Hours",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _operatingHours['is24h'],
                    onChanged: (v) =>
                        setState(() => _operatingHours['is24h'] = v),
                    activeColor: theme.colorScheme.primary,
                  ),
                  const Divider(),
                  if (!_operatingHours['is24h'])
                    ...[
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday',
                    ].map((day) {
                      final timing = _operatingHours['timings'][day];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: theme.disabledColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _TimeInput(
                                      value: timing['open'],
                                      onChanged: (v) =>
                                          setState(() => timing['open'] = v),
                                      theme: theme,
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text("to"),
                                  ),
                                  Expanded(
                                    child: _TimeInput(
                                      value: timing['close'],
                                      onChanged: (v) =>
                                          setState(() => timing['close'] = v),
                                      theme: theme,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),

              // 4. FACILITIES & CONFIG
              _ExpandableSection(
                title: "Facilities & Config",
                icon: LucideIcons.settings,
                theme: theme,
                children: [
                  // Booking Type (Multi-select)
                  Text(
                    "BOOKING TYPE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ["in-clinic", "online", "emergency"].map((type) {
                      final isSelected = _bookingType.contains(type);
                      return FilterChip(
                        label: Text(type.toUpperCase()),
                        selected: isSelected,
                        onSelected: (val) => setState(
                          () => val
                              ? _bookingType.add(type)
                              : _bookingType.remove(type),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Facilities
                  Text(
                    "FACILITIES",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: COMMON_FACILITIES.map((item) {
                      final isSelected = _selectedFacilities.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: isSelected,
                        onSelected: (val) => setState(
                          () => val
                              ? _selectedFacilities.add(item)
                              : _selectedFacilities.remove(item),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Accreditations
                  Text(
                    "ACCREDITATIONS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ACCREDITATIONS_LIST.map((item) {
                      final isSelected = _selectedAccreditations.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: isSelected,
                        onSelected: (val) => setState(
                          () => val
                              ? _selectedAccreditations.add(item)
                              : _selectedAccreditations.remove(item),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 5. SERVICES & EQUIPMENT
              _ExpandableSection(
                title: "Services & Equipment",
                icon: LucideIcons.stethoscope,
                theme: theme,
                children: [
                  SwitchListTile(
                    title: const Text(
                      "Services Available?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _isServicesAvailable,
                    onChanged: (v) => setState(() => _isServicesAvailable = v),
                  ),
                  if (_isServicesAvailable) ...[
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        children: [
                          Autocomplete<String>(
                            optionsBuilder: (val) => val.text.isEmpty
                                ? const Iterable.empty()
                                : AVAILABLE_SERVICES.where(
                                    (opt) => opt.toLowerCase().contains(
                                      val.text.toLowerCase(),
                                    ),
                                  ),
                            onSelected: (val) =>
                                setState(() => _serviceSearch = val),
                            fieldViewBuilder: (ctx, controller, focusNode, _) {
                              controller.addListener(
                                () => _serviceSearch = controller.text,
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: _inputDecoration(
                                  "Service Name",
                                  theme,
                                  icon: LucideIcons.search,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: _servicePrice,
                                  onChanged: (v) => _servicePrice = v,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration("Price", theme),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: _serviceDiscount,
                                  onChanged: (v) => _serviceDiscount = v,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    "Discount",
                                    theme,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _isDoctorPackage,
                                onChanged: (v) =>
                                    setState(() => _isDoctorPackage = v!),
                                activeColor: theme.colorScheme.primary,
                              ),
                              const Text("Doctor Pkg?"),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: _addService,
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedServices.asMap().entries.map((entry) {
                        final s = entry.value;
                        return Chip(
                          label: Text("${s['name']} - ₹${s['price']}"),
                          deleteIcon: const Icon(LucideIcons.x, size: 14),
                          onDeleted: () => setState(
                            () => _selectedServices.removeAt(entry.key),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Equipment
                  Text(
                    "LAB EQUIPMENT",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LAB_EQUIPMENT_LIST.map((item) {
                      final isSelected = _selectedEquipments.any(
                        (e) => e['label'] == item,
                      );
                      return FilterChip(
                        label: Text(item),
                        selected: isSelected,
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _selectedEquipments.add({
                                'label': item,
                                'value': item.toLowerCase().replaceAll(
                                  ' ',
                                  '-',
                                ),
                                'status': 'active',
                              });
                            } else {
                              _selectedEquipments.removeWhere(
                                (e) => e['label'] == item,
                              );
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),

              // 6. SLOTS
              _ExpandableSection(
                title: "Availability Slots",
                icon: LucideIcons.calendar,
                theme: theme,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text("Add Slot"),
                    onPressed: () {
                      setState(() {
                        _availableSlots.add({
                          "label": "General Shift",
                          "value":
                              "gen-shift-${DateTime.now().millisecondsSinceEpoch}",
                          "start": "09:00",
                          "end": "17:00",
                          "type": "weekly",
                          "recurrence": {
                            "weeks": [1, 2, 3, 4, 5],
                            "days": ["Mon", "Tue", "Wed", "Thu", "Fri"],
                          },
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ..._availableSlots.asMap().entries.map((entry) {
                    final slot = entry.value;
                    final rec = slot['recurrence'];
                    return ListTile(
                      title: Text(slot['label'] ?? "Slot"),
                      subtitle: Text(
                        "${slot['start']} - ${slot['end']} (${rec != null ? rec['days'].join(',') : 'All'})",
                      ),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.trash2, size: 16),
                        onPressed: () =>
                            setState(() => _availableSlots.removeAt(entry.key)),
                      ),
                      tileColor: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildInput(
    String label,
    TextEditingController controller,
    ThemeData theme, {
    IconData? icon,
    TextInputType type = TextInputType.text,
    bool required = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      validator: required ? (v) => v!.isEmpty ? "Required" : null : null,
      decoration: _inputDecoration(label, theme, icon: icon),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    ThemeData theme, {
    IconData? icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: theme.disabledColor)
          : null,
      filled: true,
      fillColor: theme.cardColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
    );
  }
}

// --- SUB COMPONENTS (Same as previous) ---
class _TimeInput extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final ThemeData theme;

  const _TimeInput({
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final parts = value.split(":");
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          ),
        );
        if (t != null) {
          final h = t.hour.toString().padLeft(2, '0');
          final m = t.minute.toString().padLeft(2, '0');
          onChanged("$h:$m");
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final ThemeData theme;
  final bool isOpen;

  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.children,
    required this.theme,
    this.isOpen = false,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _isOpen;
  @override
  void initState() {
    super.initState();
    _isOpen = widget.isOpen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor.withOpacity(0.5),
        border: Border.all(color: widget.theme.dividerColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: widget.theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    color: widget.theme.disabledColor,
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  ...widget.children,
                ],
              ),
            ),
        ],
      ),
    );
  }
}
