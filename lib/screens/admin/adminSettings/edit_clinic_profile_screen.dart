import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_new_app/services/api_service.dart';

// --- CONSTANTS ---
const List<String> commonFacilities = [
  "24/7 Emergency / Trauma Center",
  "ICU (Intensive Care Unit)",
  "NICU (Neonatal Intensive Care)",
  "PICU (Pediatric Intensive Care)",
  "CCU (Cardiac Care Unit)",
  "Operation Theatre (Modular OT)",
  "Blood Bank (24/7)",
  "Dialysis Unit",
  "Burn Ward",
  "Isolation Wards (Infectious Diseases)",
  "Labour & Delivery Suites",
  "Advanced Life Support Ambulance (ALS)",
  "Air Ambulance Support",
  "In-House Pharmacy (24/7)",
  "Pathology Lab (NABL Accredited)",
  "Radiology Center (CT/MRI/X-Ray)",
  "Sample Collection Center",
  "Telemedicine Kiosk",
  "Private Rooms (Deluxe/Suite)",
  "Semi-Private Wards",
  "General Wards",
  "Day Care Center",
  "Patient Waiting Lounge",
  "Wheelchair Accessible Ramps & Lifts",
  "Stretcher Service",
  "Cafeteria / Canteen",
  "Pharmacy Delivery Service",
  "Security & Surveillance (CCTV)",
];

const List<String> labEquipmentList = [
  "Hematology Analyzer (3-Part)",
  "Hematology Analyzer (5-Part)",
  "Biochemistry Analyzer",
  "Electrolyte Analyzer",
  "ABG Analyzer",
  "Urine Analyzer",
  "Microscope",
  "Centrifuge",
  "Incubator",
  "Autoclave",
  "Digital X-Ray System (DR)",
  "Ultrasound Machine",
  "CT Scanner",
  "MRI Machine",
];

const List<String> accreditationsList = [
  "NABL",
  "CAP",
  "ISO 15189",
  "CLIA",
  "JCI",
  "NABH",
];

const List<String> daysOfWeek = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

// --- UTILS ---
String slugify(String text) {
  return text
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^\w\-]+'), '');
}

class EditClinicProfileScreen extends StatefulWidget {
  final String clinicId;
  const EditClinicProfileScreen({super.key, required this.clinicId});

  @override
  State<EditClinicProfileScreen> createState() =>
      _EditClinicProfileScreenState();
}

class _EditClinicProfileScreenState extends State<EditClinicProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // --- STATE ---
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAddingService = false;
  XFile? _logoFile;
  String? _existingLogoUrl;

  // --- CONTROLLERS ---
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _licenseController = TextEditingController();
  final _emergencyController = TextEditingController();

  // --- ADVANCED DATA MODELS ---
  String _type = 'clinic';
  String _status = 'active';
  LatLng _selectedLocation = const LatLng(20.2961, 85.8245);

  List<String> _selectedFacilities = [];
  List<String> _selectedAccreditations = [];

  List<Map<String, dynamic>> _equipments = [];
  bool _isServicesAvailable = true;
  List<Map<String, dynamic>> _services = [];

  // MASTER DATA
  List<Map<String, dynamic>> _availableInsurances = [];
  List<Map<String, dynamic>> _selectedInsurances = [];
  List<Map<String, dynamic>> _availableServices = [];

  // Operating Hours
  bool _isOpen = true;
  bool _is24h = false;
  List<Map<String, dynamic>> _hours = daysOfWeek
      .map((d) => {"day": d, "start": "09:00", "end": "17:00", "closed": false})
      .toList();

  // --- SUB-FORM STATES ---
  final _newServiceNameCtrl = TextEditingController();
  final _newServicePriceCtrl = TextEditingController();
  final _newServiceDiscCtrl = TextEditingController();
  bool _newServiceIsDocPkg = false;

  String? _newEqName;
  String _newEqStatus = 'active';

  bool get isLab =>
      _type.toLowerCase() == 'lab' ||
      _type.toLowerCase() == 'laboratory' ||
      _type.toLowerCase() == 'pathology';

  @override
  void initState() {
    super.initState();
    _initializeData();

    _nameController.addListener(() {
      if (_slugController.text.isEmpty ||
          slugify(_nameController.text).startsWith(_slugController.text)) {
        _slugController.text = slugify(_nameController.text);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _licenseController.dispose();
    _emergencyController.dispose();
    _newServiceNameCtrl.dispose();
    _newServicePriceCtrl.dispose();
    _newServiceDiscCtrl.dispose();
    super.dispose();
  }

  // --- API INITIALIZATION ---
  Future<void> _initializeData() async {
    await Future.wait([
      _fetchMasterData(),
      _fetchClinicDetails(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMasterData() async {
    try {
      final insRes = await _apiService.getInsurances();
      if (insRes.statusCode == 200) {
        final data = insRes.data['data'] ?? insRes.data;
        if (data is List) {
          _availableInsurances = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("Failed to load insurances: $e");
    }

    try {
      final srvRes = await _apiService.getPartnerServices();
      if (srvRes.statusCode == 200) {
        final data = srvRes.data['data'] ?? srvRes.data;
        if (data is List) {
          _availableServices = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint("Failed to load services: $e");
    }
  }

  Future<void> _fetchClinicDetails() async {
    try {
      final response = await _apiService.getClinicDetails(widget.clinicId);
      if (response.statusCode == 200) {
        final data = response.data is Map && response.data.containsKey('data')
            ? response.data['data']
            : response.data;
        _populateFields(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['name'] ?? "";
    _slugController.text = data['slug'] ?? slugify(data['name'] ?? "");
    _type = (data['facility_type'] ?? 'clinic').toString().toLowerCase();
    _status = data['status'] ?? 'active';
    _emailController.text = data['email'] ?? "";

    if (data['phone'] is List) {
      _phoneController.text = (data['phone'] as List).join(", ");
    } else {
      _phoneController.text = data['phone'] ?? "";
    }

    _websiteController.text = data['website'] ?? "";
    _descriptionController.text = data['notes'] ?? "";
    _licenseController.text = data['licenseNumber'] ?? "";
    _emergencyController.text = data['emergency_contact'] ?? "";

    _addressController.text = data['address'] ?? "";
    _cityController.text = data['city'] ?? "";
    _districtController.text = data['district'] ?? "";
    _stateController.text = data['state'] ?? "";
    _pincodeController.text = data['pincode'] ?? "";
    _existingLogoUrl = data['logo'];

    if (data['lat'] != null && data['lng'] != null) {
      _selectedLocation = LatLng(
        double.tryParse(data['lat'].toString()) ?? 20.2961,
        double.tryParse(data['lng'].toString()) ?? 85.8245,
      );
    }

    _selectedFacilities = List<String>.from(data['facilities'] ?? []);
    _selectedAccreditations = List<String>.from(data['accreditations'] ?? []);

    if (data['equipments'] != null) {
      _equipments = List<Map<String, dynamic>>.from(data['equipments']);
    }

    if (data['accepted_insurances'] != null) {
      _selectedInsurances = List<Map<String, dynamic>>.from(
        data['accepted_insurances'],
      );
    }

    _isServicesAvailable = data['isServicesAvailable'] ?? true;
    
    // --- UPDATED NESTED PARSING FOR SERVICES ---
    if (data['services'] != null) {
      _services = (data['services'] as List).map((s) {
        final svcObj = s['service_id'];
        final isObj = svcObj is Map;
        
        return {
          "service_id": isObj ? svcObj['_id'] : svcObj,
          "name": isObj ? svcObj['name'] : (s['name'] ?? "Unknown Service"),
          "price": s['price']?.toString() ?? "",
          "discountPrice": s['discount_price']?.toString() ?? "",
          "isDoctorPackage": s['is_doctor_package'] ?? false,
        };
      }).toList();
    }

    if (data['operating_hours'] != null) {
      final oh = data['operating_hours'];
      _isOpen = oh['isOpen'] ?? true;
      _is24h = oh['is24h'] ?? false;

      if (oh['timings'] != null) {
        _hours = daysOfWeek.map((day) {
          final t = oh['timings'][day];
          bool closed =
              t == null || (t['open'] == '00:00' && t['close'] == '00:00');
          return {
            "day": day,
            "start": closed ? "09:00" : t['open'],
            "end": closed ? "17:00" : t['close'],
            "closed": closed,
          };
        }).toList();
      }
    }
  }

  // --- SMART ADD SERVICE LOGIC ---
  Future<void> _handleAddService() async {
    final srvName = _newServiceNameCtrl.text.trim();
    final price = _newServicePriceCtrl.text.trim();
    
    if (srvName.isEmpty || price.isEmpty) return;

    setState(() => _isAddingService = true);

    try {
      var existingService = _availableServices.where(
        (s) => s['name'].toString().toLowerCase() == srvName.toLowerCase()
      ).firstOrNull;

      String? newServiceId;

      if (existingService == null) {
        final res = await _apiService.addPartnerService(name: srvName);
        if (res.statusCode == 200 || res.statusCode == 201) {
          final newSrvData = res.data['data'] ?? res.data;
          newServiceId = newSrvData['_id'];
          
          _availableServices.add({
            "_id": newServiceId,
            "name": srvName, 
            "status": "pending"
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("New service registered successfully!"),
                backgroundColor: Colors.teal,
              ),
            );
          }
        }
      } else {
        newServiceId = existingService['_id'];
      }

      setState(() {
        _services.add({
          "service_id": newServiceId,
          "name": srvName,
          "price": price,
          "discountPrice": _newServiceDiscCtrl.text.trim(),
          "isDoctorPackage": _newServiceIsDocPkg,
        });
        _newServiceNameCtrl.clear();
        _newServicePriceCtrl.clear();
        _newServiceDiscCtrl.clear();
        _newServiceIsDocPkg = false;
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process service: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingService = false);
    }
  }

  // --- SAVE ---
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> timingsMap = {};
      for (var h in _hours) {
        timingsMap[h['day']] = {
          "open": h['closed'] ? "00:00" : h['start'],
          "close": h['closed'] ? "00:00" : h['end'],
        };
      }

      final Map<String, dynamic> payload = {
        "name": _nameController.text.trim(),
        "slug": _slugController.text.trim(),
        "facility_type": _type,
        "status": _status,
        "email": _emailController.text.trim(),
        "phone": _phoneController.text
            .split(",")
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
        "website": _websiteController.text.trim(),
        "notes": _descriptionController.text.trim(),
        "licenseNumber": _licenseController.text.trim(),
        "emergency_contact": _emergencyController.text.trim(),

        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "district": _districtController.text.trim(),
        "state": _stateController.text.trim(),
        "pincode": _pincodeController.text.trim(),
        "country": "India",
        "lat": _selectedLocation.latitude.toString(),
        "lng": _selectedLocation.longitude.toString(),

        "facilities": _selectedFacilities,
        "accreditations": _selectedAccreditations,
        "equipments": _equipments,
        "accepted_insurances": _selectedInsurances
            .map((i) => i['_id'] ?? i['id'])
            .toList(),

        "isServicesAvailable": _isServicesAvailable,
        "services": _services
            .map(
              (s) => {
                "service_id": s['service_id'], 
                "price": s['price'],
                "discount_price": s['discountPrice'],
                "is_doctor_package": s['isDoctorPackage'],
              },
            )
            .toList(),

        "operating_hours": {
          "isOpen": _isOpen,
          "is24h": _is24h,
          "timings": timingsMap,
        },
      };

      final response = await _apiService.updateAdminClinic(
        widget.clinicId,
        payload,
        _logoFile,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Clinic Profile Updated!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _logoFile = picked);
  }

  // --- BUILD UI (LIGHT THEME) ---
  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF4F4F5);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 80,
                left: 16,
                right: 16,
                bottom: 120,
              ),
              children: [
                _buildIdentitySection(),
                const SizedBox(height: 20),
                _buildServicesSection(),
                const SizedBox(height: 20),
                _buildInsurancesSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                
                if (isLab) ...[
                  _buildEquipmentsSection(),
                  const SizedBox(height: 20),
                  _buildAccreditationsSection(),
                ] else ...[
                  _buildFacilitiesSection(),
                ],
                
                const SizedBox(height: 20),
                _buildTimingsSection(),
              ],
            ),
          ),

          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.grey.shade800,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveChanges,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(LucideIcons.save, size: 18),
                          label: Text(
                            _isSaving ? "Saving..." : "Update Profile",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.9),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Edit Facility",
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "ID: ${widget.clinicId.substring(widget.clinicId.length - 6).toUpperCase()}",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return _SectionCard(
      title: "Clinic Identity",
      icon: LucideIcons.building2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  image: _logoFile != null
                      ? DecorationImage(
                          image: FileImage(File(_logoFile!.path)),
                          fit: BoxFit.cover,
                        )
                      : (_existingLogoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_existingLogoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
                child: (_logoFile == null && _existingLogoUrl == null)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.uploadCloud,
                            color: Colors.indigo.shade300,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Upload",
                            style: TextStyle(
                              color: Colors.indigo.shade400,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),
          _InputGroup(
            label: "Facility Name",
            controller: _nameController,
            icon: LucideIcons.building,
            required: true,
          ),
          const SizedBox(height: 16),
          _InputGroup(
            label: "URL Slug",
            controller: _slugController,
            icon: LucideIcons.link2,
            prefixText: "jivan.website/",
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SelectGroup(
                  label: "Type",
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'clinic', child: Text("Clinic")),
                    DropdownMenuItem(value: 'lab', child: Text("Lab")),
                    DropdownMenuItem(value: 'pharmacy', child: Text("Pharmacy")),
                  ],
                  onChanged: (v) => setState(() => _type = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SelectGroup(
                  label: "Status",
                  value: _status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text("Active")),
                    DropdownMenuItem(value: 'maintenance', child: Text("Maintenance")),
                    DropdownMenuItem(value: 'closed', child: Text("Closed")),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InputGroup(
            label: "License Number",
            controller: _licenseController,
            icon: LucideIcons.fileBadge,
          ),
          const SizedBox(height: 16),
          const Text(
            "ABOUT FACILITY",
            style: TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              hintText: "Brief description...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED SERVICES SECTION (MATCHES IMAGE) ---
  Widget _buildServicesSection() {
    return _SectionCard(
      title: "Services & Pricing",
      icon: isLab ? LucideIcons.flaskConical : LucideIcons.stethoscope,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Enable Service Listing",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isServicesAvailable,
                onChanged: (v) => setState(() => _isServicesAvailable = v),
                activeColor: const Color(0xFF6366F1),
                activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ],
          ),
          if (_isServicesAvailable) ...[
            Divider(color: Colors.grey.shade200, height: 32),
            
            // Selected Services Chips
            if (_services.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.asMap().entries.map((e) {
                  int idx = e.key;
                  Map<String, dynamic> s = e.value;
                  bool hasDiscount = s['discountPrice'] != null && s['discountPrice'].toString().isNotEmpty;
                  bool isDocPkg = s['isDoctorPackage'] == true;

                  return Container(
                    padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE), // Light purple from image
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDDD6FE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDocPkg)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(LucideIcons.packagePlus, size: 14, color: Colors.teal),
                          ),
                        // Display Name
                        Text(
                          s['name'].toString(),
                          style: TextStyle(color: Colors.indigo.shade900, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        if (hasDiscount && !isDocPkg)
                          Text(
                            "₹${s['price']}",
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (hasDiscount && !isDocPkg) const SizedBox(width: 6),
                        Text(
                          "₹${hasDiscount && !isDocPkg ? s['discountPrice'] : s['price']}",
                          style: TextStyle(
                            color: isDocPkg ? Colors.indigo.shade700 : Colors.teal.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _services.removeAt(idx)),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.x, size: 14, color: Colors.red.shade400),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Add Service Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Autocomplete Search
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _availableServices.map((e) => e['name'].toString());
                      }
                      return _availableServices
                          .map((e) => e['name'].toString())
                          .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      _newServiceNameCtrl.text = selection;
                    },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      controller.addListener(() {
                        _newServiceNameCtrl.text = controller.text;
                      });
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Blood Test",
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF6366F1)),
                          ),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: MediaQuery.of(context).size.width - 80,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option, style: const TextStyle(color: Colors.black87, fontSize: 14)),
                                  onTap: () => onSelected(option),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Inputs
                  Row(
                    children: [
                      Expanded(
                        child: _InputGroup(
                          label: "PRICE (₹)",
                          controller: _newServicePriceCtrl,
                          type: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _InputGroup(
                          label: "DISC. PRICE (₹)",
                          controller: _newServiceDiscCtrl,
                          type: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Checkbox and Add Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _newServiceIsDocPkg,
                              onChanged: (v) => setState(() => _newServiceIsDocPkg = v ?? false),
                              activeColor: const Color(0xFF6366F1),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Doctor Pkg",
                            style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isAddingService ? null : _handleAddService,
                        icon: _isAddingService
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(LucideIcons.plus, size: 16),
                        label: Text(_isAddingService ? "Adding..." : "Add"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF18181B), // Dark Button
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _openInsuranceBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Select Insurances",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(LucideIcons.x, color: Colors.black54),
                          )
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search insurances...",
                          prefixIcon: const Icon(LucideIcons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: _availableInsurances.length,
                          itemBuilder: (context, index) {
                            final ins = _availableInsurances[index];
                            final isSelected = _selectedInsurances.any(
                              (s) => (s['_id'] ?? s['id']) == (ins['_id'] ?? ins['id'])
                            );

                            return CheckboxListTile(
                              title: Text(
                                ins['name'].toString(),
                                style: const TextStyle(color: Colors.black87),
                              ),
                              value: isSelected,
                              activeColor: const Color(0xFF6366F1),
                              onChanged: (bool? val) {
                                setModalState(() {
                                  if (val == true) {
                                    _selectedInsurances.add(ins);
                                  } else {
                                    _selectedInsurances.removeWhere((s) => 
                                      (s['_id'] ?? s['id']) == (ins['_id'] ?? ins['id'])
                                    );
                                  }
                                });
                                setState(() {}); 
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Done",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildInsurancesSection() {
    return _SectionCard(
      title: "Accepted Insurances",
      icon: LucideIcons.shieldCheck,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openInsuranceBottomSheet,
              icon: const Icon(LucideIcons.listPlus, size: 18),
              label: const Text("Select Insurance Providers"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (_selectedInsurances.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedInsurances
                  .map(
                    (ins) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.shield,
                            size: 14,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ins['name'].toString(),
                            style: TextStyle(
                              color: Colors.teal.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(
                              () => _selectedInsurances.removeWhere(
                                (i) =>
                                    (i['_id'] ?? i['id']) ==
                                    (ins['_id'] ?? ins['id']),
                              ),
                            ),
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return _SectionCard(
      title: "Location & Contact",
      icon: LucideIcons.mapPin,
      child: Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _selectedLocation,
                  initialZoom: 14,
                  onTap: (_, pt) => setState(() => _selectedLocation = pt),
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
                        child: const Icon(
                          LucideIcons.mapPin,
                          color: Colors.redAccent,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InputGroup(
            label: "Full Address",
            controller: _addressController,
            icon: LucideIcons.mapPin,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputGroup(label: "City", controller: _cityController),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputGroup(
                  label: "District",
                  controller: _districtController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InputGroup(
                  label: "State",
                  controller: _stateController,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InputGroup(
                  label: "Pincode",
                  controller: _pincodeController,
                  type: TextInputType.number,
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade200, height: 32),
          _InputGroup(
            label: "Contact Numbers (Comma separated)",
            controller: _phoneController,
            icon: LucideIcons.phone,
          ),
          const SizedBox(height: 12),
          _InputGroup(
            label: "Emergency Contact",
            controller: _emergencyController,
            icon: LucideIcons.alertCircle,
          ),
          const SizedBox(height: 12),
          _InputGroup(
            label: "Email Address",
            controller: _emailController,
            icon: LucideIcons.mail,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _InputGroup(
            label: "Website URL",
            controller: _websiteController,
            icon: LucideIcons.globe,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    return _SectionCard(
      title: "Facilities",
      icon: LucideIcons.sparkles,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: commonFacilities.map((fac) {
          bool isSelected = _selectedFacilities.contains(fac);
          return FilterChip(
            label: Text(
              fac,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF6366F1)
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (v) {
              setState(() {
                v
                    ? _selectedFacilities.add(fac)
                    : _selectedFacilities.remove(fac);
              });
            },
            backgroundColor: Colors.grey.shade50,
            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF6366F1).withValues(alpha: 0.5)
                    : Colors.grey.shade200,
              ),
            ),
            showCheckmark: false,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEquipmentsSection() {
    return _SectionCard(
      title: "Lab Equipment",
      icon: LucideIcons.monitor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SelectGroup(
                  label: "Equipment Name",
                  value: _newEqName,
                  items: labEquipmentList
                      .map(
                        (e) => DropdownMenuItem<String>(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _newEqName = v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _SelectGroup(
                  label: "Status",
                  value: _newEqStatus,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'active',
                      child: Text("Active"),
                    ),
                    DropdownMenuItem<String>(
                      value: 'maintenance',
                      child: Text("Maintenance"),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _newEqStatus = v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: () {
                    if (_newEqName != null) {
                      setState(() {
                        _equipments.add({
                          "label": _newEqName,
                          "value": slugify(_newEqName!),
                          "status": _newEqStatus,
                        });
                        _newEqName = null;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Icon(LucideIcons.plus, size: 20),
                ),
              ),
            ],
          ),
          if (_equipments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              children: _equipments
                  .asMap()
                  .entries
                  .map(
                    (e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.value['label'].toString(),
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: e.value['status'] == 'active'
                                  ? Colors.green.shade50
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: e.value['status'] == 'active'
                                    ? Colors.green.shade200
                                    : Colors.amber.shade200,
                              )
                            ),
                            child: Text(
                              e.value['status'].toString().toUpperCase(),
                              style: TextStyle(
                                color: e.value['status'] == 'active'
                                    ? Colors.green.shade700
                                    : Colors.amber.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _equipments.removeAt(e.key)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                LucideIcons.trash2,
                                size: 16,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccreditationsSection() {
    return _SectionCard(
      title: "Accreditations",
      icon: LucideIcons.award,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: accreditationsList.map((acc) {
          bool isSelected = _selectedAccreditations.contains(acc);
          return FilterChip(
            label: Text(
              acc,
              style: TextStyle(
                color: isSelected ? Colors.teal.shade700 : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            selected: isSelected,
            onSelected: (v) {
              setState(() {
                v
                    ? _selectedAccreditations.add(acc)
                    : _selectedAccreditations.remove(acc);
              });
            },
            backgroundColor: Colors.grey.shade50,
            selectedColor: Colors.teal.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(
                color: isSelected ? Colors.teal.shade300 : Colors.grey.shade200,
              ),
            ),
            showCheckmark: false,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimingsSection() {
    return _SectionCard(
      title: "Operating Hours",
      icon: LucideIcons.clock,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Is Facility Open?",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _isOpen,
                onChanged: (v) => setState(() => _isOpen = v),
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade200, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Open 24/7?",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _is24h,
                onChanged: (v) => setState(() => _is24h = v),
                activeColor: const Color(0xFF6366F1),
              ),
            ],
          ),
          if (!_is24h && _isOpen) ...[
            const SizedBox(height: 16),
            ..._hours.map((h) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Switch(
                        value: !h['closed'],
                        onChanged: (v) => setState(() => h['closed'] = !v),
                        activeColor: Colors.teal.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        h['day'].toString().substring(0, 3),
                        style: TextStyle(
                          color: h['closed'] ? Colors.grey.shade400 : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!h['closed']) ...[
                      _TimeChip(
                        time: h['start'].toString(),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(h['start'].split(':')[0]),
                              minute: int.parse(h['start'].split(':')[1]),
                            ),
                          );
                          if (t != null) {
                            setState(
                              () => h['start'] =
                                  "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                            );
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text("-", style: TextStyle(color: Colors.grey.shade400)),
                      ),
                      _TimeChip(
                        time: h['end'].toString(),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                              hour: int.parse(h['end'].split(':')[0]),
                              minute: int.parse(h['end'].split(':')[1]),
                            ),
                          );
                          if (t != null) {
                            setState(
                              () => h['end'] =
                                  "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}",
                            );
                          }
                        },
                      ),
                    ] else ...[
                      Text(
                        "CLOSED",
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

// --- REUSABLE WIDGETS (LIGHT THEME) ---

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }
}

class _InputGroup extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final String? prefixText;
  final TextInputType type;
  final bool required;

  const _InputGroup({
    required this.label,
    required this.controller,
    this.icon,
    this.prefixText,
    this.type = TextInputType.text,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: label.toUpperCase(),
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: " *",
                  style: TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: icon != null
                ? Icon(icon, size: 18, color: Colors.grey.shade500)
                : null,
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Colors.black54, fontSize: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectGroup extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final void Function(String?) onChanged;

  const _SelectGroup({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: Colors.white,
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          icon: Icon(
            LucideIcons.chevronDown,
            color: Colors.grey.shade500,
            size: 16,
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          time,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}