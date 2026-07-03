import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cached_network_image/cached_network_image.dart'; 

import '../../../../services/api_service.dart';
import 'widgets/staff_roles.dart';
import 'package:my_new_app/models/staff_model.dart'; // 🚀 Staff Model

class AddStaffScreen extends StatefulWidget {
  final String? staffId; // 🚀 ନୋଟ୍: ଏଠାରେ Edit Mode ରେ ସବୁବେଳେ 'mappingId' ଆସିବ
  const AddStaffScreen({super.key, this.staffId});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  // --- STATE ---
  bool _isSaving = false;
  bool _isLoadingInit = true;
  bool _isFetchingSlots = false; 
  bool _isSuperAdmin = false;
  XFile? _avatarFile;
  String? _currentImageUrl; 
  
  // 🚀 [THE MASTER FIX]: Update ପାଇଁ ମୂଳ Staff ID ରଖିବା
  String? _coreStaffIdForUpdate; 

  // --- DYNAMIC DATA LISTS ---
  List<dynamic> _clinicsList = [];
  List<dynamic> _availableDepartments = []; 
  List<dynamic> _availableServices = []; 
  List<dynamic> _availableSlots = []; 

  // --- CONTROLLERS ---
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _experienceController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _languagesController = TextEditingController();
  final _bioController = TextEditingController();

  final _consultFeeController = TextEditingController();
  final _followUpFeeController = TextEditingController();

  final _salaryController = TextEditingController();
  String _selectedShiftType = 'full_time';
  String _selectedSalaryType = 'monthly';

  // --- SELECTIONS ---
  String _selectedRole = 'doctor';
  Map<String, dynamic>? _selectedClinic;

  // MULTI-SELECT STORAGE
  List<Map<String, dynamic>> _selectedDepartments = [];
  List<Map<String, dynamic>> _selectedServices = [];
  final List<String> _selectedSlotValues = [];

  final List<Map<String, String>> _educationList = [
    {'degree': '', 'institution': '', 'year_of_completion': ''},
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_updateSlug);
    _lastNameController.addListener(_updateSlug);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _languagesController.dispose();
    _consultFeeController.dispose();
    _followUpFeeController.dispose();
    _salaryController.dispose(); 
    _bioController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateSlug() {
    if (_slugController.text.isEmpty || !_slugController.text.startsWith('manual-')) {
      final full = "${_firstNameController.text} ${_lastNameController.text}";
      final slug = full.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      if (full.isNotEmpty) _slugController.text = slug;
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoadingInit = true);

    try {
      String? token = await _storage.read(key: 'admin_token');
      String? role = await _storage.read(key: 'admin_role');

      setState(() {
        _isSuperAdmin = (role == 'SuperAdmin');
      });

      // 1. Get Departments
      try {
        final depResponse = await _apiService.getRogDepartments();
        if (depResponse.statusCode == 200 && depResponse.data['data'] != null) {
          setState(() {
            _availableDepartments = depResponse.data['data'];
          });
        }
      } catch (e) {
        debugPrint("Error fetching departments: $e");
      }

      // 2. Get Clinics
      if (token != null) {
        final response = await _apiService.getAdminClinics();
        if (response.statusCode == 200) {
          final data = response.data;
          List<dynamic> fetchedClinics = [];
          if (data is Map && data.containsKey('data')) {
            if(data['data'] is Map && data['data']['clinics'] != null) {
               fetchedClinics = data['data']['clinics'];
            } else if (data['data'] is List) {
               fetchedClinics = data['data'];
            }
          } else if (data is List) {
            fetchedClinics = data;
          }

          setState(() {
            _clinicsList = fetchedClinics;
          });
        }
      }

      // 3. Edit Mode
      if (widget.staffId != null) {
        await _fetchStaffDetailsForEdit();
      } else {
        if (_clinicsList.length == 1) {
          _onClinicSelected(_clinicsList[0]);
        } else if (!_isSuperAdmin && _clinicsList.isNotEmpty) {
          _onClinicSelected(_clinicsList[0]);
        }
      }

    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingInit = false);
    }
  }

  Future<void> _fetchStaffDetailsForEdit() async {
    try {
      // 🚀 ଆପଣଙ୍କ ରୁଲ୍ ଅନୁଯାୟୀ: Fetch କରିବା ବେଳେ mappingId (widget.staffId) ବ୍ୟବହାର ହେବ
      final Staff staff = await _apiService.getAdminStaffDetails(widget.staffId!);

      setState(() {
        // 🚀 ଆପଣଙ୍କ ରୁଲ୍ ଅନୁଯାୟୀ: Update ପାଇଁ ପ୍ରକୃତ ମଣିଷର ID (staff.id) କୁ ସେଭ୍ କରନ୍ତୁ
        _coreStaffIdForUpdate = staff.id;

        // 1. Name parsing
        final nameParts = staff.name.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }

        // 2. Text Fields
        _slugController.text = staff.slug;
        _emailController.text = staff.email;
        _phoneController.text = staff.phone;
        _experienceController.text = staff.experience.replaceAll(RegExp(r'[^0-9]'), '');
        _bioController.text = staff.bio;
        _addressController.text = staff.address;
        _cityController.text = staff.city;
        _pincodeController.text = staff.pincode;
        
        _currentImageUrl = staff.image;
        _languagesController.text = staff.languages.join(', ');

        // 3. Role & Employment
        _selectedRole = staff.role.toLowerCase();
        _consultFeeController.text = staff.consultationFees.toString();
        _followUpFeeController.text = staff.followUpFees.toString();
        _salaryController.text = staff.salary;
        
        if (staff.shiftType.isNotEmpty) _selectedShiftType = staff.shiftType;
        if (staff.salaryType.isNotEmpty) _selectedSalaryType = staff.salaryType;

        // 4. Clinic Matching
        if (staff.clinicName.isNotEmpty && _clinicsList.isNotEmpty) {
           final matchedClinic = _clinicsList.firstWhere(
              (c) => (c['name']?.toString().toLowerCase() ?? '') == staff.clinicName.toLowerCase(), 
              orElse: () => null
           );
           if (matchedClinic != null) {
              _selectedClinic = matchedClinic;
              _availableServices = matchedClinic['services'] != null ? List.from(matchedClinic['services']) : [];
           }
        }

        // 5. Departments Matching
        if (staff.rawDepartments.isNotEmpty) {
           _selectedDepartments = [];
           for (var d in staff.rawDepartments) {
               final String dName = d is Map ? d['department'] ?? d['name'] : d.toString();
               final matched = _availableDepartments.firstWhere(
                  (ad) => (ad['department'] ?? ad['name']).toString().toLowerCase() == dName.toLowerCase(),
                  orElse: () => null
               );
               if (matched != null) _selectedDepartments.add(matched);
           }
        }

        // 6. Services Matching
        if (staff.rawServices.isNotEmpty) {
           _selectedServices = [];
           for(var s in staff.rawServices) {
               final String sId = s is Map ? (s['service_id'] != null ? s['service_id']['_id'] : s['_id']) : s.toString();
               final matched = _availableServices.firstWhere(
                   (as) {
                       final String asId = as['service_id'] != null ? as['service_id']['_id'] : as['_id'];
                       return asId == sId;
                   },
                   orElse: () => null
               );
               if (matched != null) _selectedServices.add(matched);
           }
        }

        // 7. Slots Setup
        if (staff.rawSlots.isNotEmpty) {
           _selectedSlotValues.clear();
           for(var slot in staff.rawSlots) {
               _selectedSlotValues.add(slot.toString());
           }
        }

        // 8. Educations Parsing
        if (staff.educations.isNotEmpty) {
           _educationList.clear();
           for (var e in staff.educations) {
               _educationList.add({
                   'degree': e['degree'] ?? '',
                   'institution': e['institution'] ?? '',
                   'year_of_completion': e['year_of_completion'] ?? '',
               });
           }
        }
      });

      if (_selectedClinic != null) {
        await _fetchClinicSlotsFromApi();
      }
      
    } catch (e) {
      debugPrint("Error fetching staff for edit: $e");
    }
  }

  Future<void> _fetchClinicSlotsFromApi() async {
    setState(() => _isFetchingSlots = true);
    try {
      final String? clinicId = _isSuperAdmin 
          ? (_selectedClinic?['_id'] ?? _selectedClinic?['id'])?.toString() 
          : null;

      final response = await _apiService.getSlots(tokenKey: 'admin_token', clinicId: clinicId);

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> fetchedSlots = [];
        if (data is Map && data['data'] != null) {
          fetchedSlots = data['data'] is List ? data['data'] : [];
        } else if (data is List) {
          fetchedSlots = data;
        }
        setState(() { _availableSlots = fetchedSlots; });
      }
    } catch (e) {
      debugPrint("Error fetching clinic slots: $e");
    } finally {
      if (mounted) setState(() => _isFetchingSlots = false);
    }
  }

  void _onClinicSelected(Map<String, dynamic> clinic) {
    setState(() {
      _selectedClinic = clinic;
      _selectedServices.clear();
      _selectedSlotValues.clear();

      if (_selectedRole == 'doctor') {
        _addressController.text = clinic['address'] ?? '';
        _cityController.text = clinic['city'] ?? '';
        _pincodeController.text = clinic['pincode']?.toString() ?? '';
      } else {
        _addressController.clear();
        _cityController.clear();
        _pincodeController.clear();
      }

      if (clinic['services'] != null) {
        _availableServices = List.from(clinic['services']);
        if (_selectedRole == 'doctor') {
          for (var svc in _availableServices) {
            if (svc['is_doctor_package'] == true) _selectedServices.add(svc);
          }
        }
      } else {
        _availableServices = [];
      }
    });

    _fetchClinicSlotsFromApi();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClinic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a clinic."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      List<String> languagesList = _languagesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
          
      List<Map<String, String>> validEducation = _educationList
          .where((e) => e['degree']!.isNotEmpty && e['institution']!.isNotEmpty)
          .toList();

      final Map<String, dynamic> staffData = {
        'clinic_id': _selectedClinic?['_id'] ?? _selectedClinic?['id'],
        'name': "${_firstNameController.text} ${_lastNameController.text}",
        'slug': _slugController.text,
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'experience': _experienceController.text.trim(),
        'bio': _bioController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'educations': jsonEncode(validEducation),
        'languages': jsonEncode(languagesList),
      };

      if (_selectedRole == 'doctor') {
        List<String> departmentPayload = _selectedDepartments.map((e) => e['_id'].toString()).toList();
        List<String> servicePayload = _selectedServices.map((e) {
           return e['service_id'] != null ? e['service_id']['_id'].toString() : e['_id'].toString();
        }).toList();

        staffData['departments'] = jsonEncode(departmentPayload);
        staffData['services'] = jsonEncode(servicePayload);
        staffData['doctor_slots'] = jsonEncode(_selectedSlotValues); 
        staffData['consultation_fees'] = _consultFeeController.text.trim();
        staffData['follow_up_fees'] = _followUpFeeController.text.trim();
      } else {
        staffData['shift_type'] = _selectedShiftType;
        staffData['salary'] = _salaryController.text.trim();
        staffData['salary_type'] = _selectedSalaryType;
      }

      Response response;

      if (widget.staffId != null && _coreStaffIdForUpdate != null) {
        // 🚀 UPDATE MODE: Update API କୁ ମୂଳ staff_id ପଠାଯିବ
        staffData['id'] = _coreStaffIdForUpdate; 
        response = await _apiService.updateAdminStaff(_coreStaffIdForUpdate!, staffData, _avatarFile);
      } else {
        // 🚀 ADD MODE
        response = await _apiService.addAdminStaff(staffData, _avatarFile);
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.staffId != null ? "Staff Updated Successfully!" : "Staff Added Successfully!"), 
            backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = e.response?.data['message'] ?? e.response?.data['error'] ?? "Failed to save staff.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An error occurred: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ================= UTILS & HELPERS =================

  String _formatTime(String timeStr) {
    if (timeStr.isEmpty) return "";
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final suffix = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return "$hour12:$minute $suffix";
    } catch (e) {
      return timeStr;
    }
  }

  String _formatDepartmentName(String slug) {
     if(slug.isEmpty) return "";
     return slug.split('-').map((word) {
        if (word.isEmpty) return "";
        return "${word[0].toUpperCase()}${word.substring(1)}";
     }).join(" ");
  }

  IconData _getDepartmentIcon(String? iconName) {
    final name = iconName?.toLowerCase() ?? "";
    switch (name) {
      case 'heart': return LucideIcons.heart;
      case 'brain': return LucideIcons.brain;
      case 'bone': return LucideIcons.bone;
      case 'eye': return LucideIcons.eye;
      case 'baby': return LucideIcons.baby;
      case 'ear': return LucideIcons.ear;
      case 'activity': return LucideIcons.activity;
      default: return LucideIcons.stethoscope;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _avatarFile = picked);
  }

  ImageProvider? _getImageProvider() {
    if (_avatarFile != null) {
      if (kIsWeb) return NetworkImage(_avatarFile!.path);
      return FileImage(File(_avatarFile!.path));
    }
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(_currentImageUrl!);
    }
    return null;
  }

  void _openDepartmentsPopup(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Select Departments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        IconButton(icon: Icon(LucideIcons.x, color: theme.disabledColor), onPressed: () => Navigator.pop(ctx))
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: _availableDepartments.isEmpty
                          ? Center(child: Text("No departments available.", style: TextStyle(color: theme.disabledColor)))
                          : Wrap(
                              spacing: 10, runSpacing: 10,
                              children: _availableDepartments.map((dept) {
                                final String deptId = dept['_id'].toString();
                                final String rawName = dept['department'] ?? dept['name'] ?? "";
                                final String readableName = _formatDepartmentName(rawName);
                                final IconData dIcon = _getDepartmentIcon(dept['department_icon']); 
                                final isSelected = _selectedDepartments.any((d) => d['_id'].toString() == deptId);

                                return FilterChip(
                                  avatar: Icon(dIcon, size: 16, color: isSelected ? theme.colorScheme.primary : theme.disabledColor),
                                  label: Text(readableName),
                                  selected: isSelected,
                                  onSelected: (valState) {
                                    setModalState(() {
                                      if (valState) {
                                        _selectedDepartments.add(dept);
                                      } else {
                                        _selectedDepartments.removeWhere((d) => d['_id'].toString() == deptId);
                                      }
                                    });
                                    setState(() {}); 
                                  },
                                  selectedColor: theme.colorScheme.primaryContainer,
                                  checkmarkColor: theme.colorScheme.primary,
                                  backgroundColor: theme.cardColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  }

  void _openServicesPopup(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Select Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        IconButton(icon: Icon(LucideIcons.x, color: theme.disabledColor), onPressed: () => Navigator.pop(ctx))
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _availableServices.isEmpty
                        ? Center(child: Text("No services available.", style: TextStyle(color: theme.disabledColor)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _availableServices.length,
                            itemBuilder: (context, index) {
                              final svc = _availableServices[index];
                              final serviceIdData = svc['service_id'] ?? {};
                              final name = serviceIdData['name'] ?? 'Unknown Service';
                              final sId = serviceIdData['_id'] ?? svc['_id'].toString();
                              final price = svc['price'] ?? 0;
                              final discount = svc['discount_price'];
                              
                              final isSelected = _selectedServices.any((s) {
                                 final selId = s['service_id'] != null ? s['service_id']['_id'] : s['_id'];
                                 return selId.toString() == sId;
                              });

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.dividerColor),
                                ),
                                child: CheckboxListTile(
                                  value: isSelected,
                                  activeColor: theme.colorScheme.primary,
                                  checkColor: Colors.white,
                                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  subtitle: Row(
                                     children: [
                                       Text("₹$price", style: TextStyle(
                                         color: discount != null ? theme.disabledColor : theme.colorScheme.primary,
                                         fontWeight: discount != null ? FontWeight.normal : FontWeight.bold,
                                         decoration: discount != null ? TextDecoration.lineThrough : TextDecoration.none,
                                       )),
                                       if (discount != null) ...[
                                          const SizedBox(width: 8),
                                          Text("₹$discount", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                       ]
                                     ],
                                  ),
                                  onChanged: (bool? val) {
                                     setModalState(() {
                                       if (val == true) {
                                         _selectedServices.add(svc);
                                       } else {
                                         _selectedServices.removeWhere((s) {
                                            final curId = s['service_id'] != null ? s['service_id']['_id'] : s['_id'];
                                            return curId.toString() == sId;
                                         });
                                       }
                                     });
                                     setState(() {}); 
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDoctor = _selectedRole == 'doctor';
    final isEditMode = widget.staffId != null; 

    if (_isLoadingInit) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Profile" : "Add New Staff"),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        centerTitle: false,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(isEditMode ? "Update Staff Profile" : "Create Staff Member", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              _buildSectionHeader("Identity & Role", theme),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.dividerColor),
                        image: _getImageProvider() != null 
                             ? DecorationImage(image: _getImageProvider()!, fit: BoxFit.cover) 
                             : null,
                      ),
                      child: _getImageProvider() == null ? Icon(LucideIcons.camera, color: theme.disabledColor) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildCleanTextField("First Name", _firstNameController, theme),
                        const SizedBox(height: 12),
                        _buildCleanTextField("Last Name", _lastNameController, theme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text("Select Role", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: STAFF_ROLES.map((roleItem) {
                    final isSelected = _selectedRole == roleItem['value'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRole = roleItem['value'];
                          if (_selectedRole != 'doctor') {
                            _selectedDepartments.clear();
                            _selectedServices.clear();
                            _selectedSlotValues.clear();
                            _addressController.clear();
                            _cityController.clear();
                            _pincodeController.clear();
                          } else {
                            if (_selectedClinic != null) _onClinicSelected(_selectedClinic!);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? Colors.transparent : theme.dividerColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(roleItem['icon'], color: isSelected ? Colors.white : theme.disabledColor, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              roleItem['label'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.disabledColor,
                                fontSize: 10, fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              _buildCleanTextField("Experience (e.g. 5 Years)", _experienceController, theme, isOptional: true),

              const SizedBox(height: 24),
              _buildCleanTextField("Email Address", _emailController, theme, type: TextInputType.emailAddress, icon: LucideIcons.mail),
              const SizedBox(height: 16),
              _buildCleanTextField("Phone Number", _phoneController, theme, type: TextInputType.phone, icon: LucideIcons.phone),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              _buildSectionHeader("Contact & Location", theme),
              const SizedBox(height: 8),
              if (isDoctor)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Address is auto-synced with the selected clinic.",
                    style: TextStyle(color: theme.colorScheme.primary, fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ),
              _buildCleanTextField("Address", _addressController, theme, readOnly: isDoctor, isOptional: true),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildCleanTextField("City", _cityController, theme, readOnly: isDoctor, isOptional: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildCleanTextField("Pincode", _pincodeController, theme, type: TextInputType.number, readOnly: isDoctor, isOptional: true)),
                ],
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              _buildSectionHeader("Work & Availability", theme),
              const SizedBox(height: 16),

              if (_isSuperAdmin && _clinicsList.length > 1) 
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Select Main Clinic", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Map<String, dynamic>>(
                          value: _selectedClinic,
                          hint: const Text("Choose a Clinic"),
                          isExpanded: true,
                          icon: Icon(LucideIcons.chevronDown, color: theme.disabledColor),
                          items: _clinicsList.map((clinic) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: clinic,
                              child: Row(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(LucideIcons.building2, size: 16, color: theme.colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      clinic['name'] ?? "Unknown",
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) _onClinicSelected(val);
                          },
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.lock, size: 16, color: theme.disabledColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Assigned Clinic".toUpperCase(), style: TextStyle(fontSize: 10, color: theme.disabledColor)),
                          const SizedBox(height: 2),
                          Text(
                            _selectedClinic != null ? _selectedClinic!['name'] : "Loading...",
                            style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              if (isDoctor) ...[
                Text("Available Slots (Fetched from Server)", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor)),
                const SizedBox(height: 8),
                if (_selectedClinic == null)
                  Text("Select a clinic first.", style: TextStyle(color: theme.disabledColor, fontSize: 12, fontStyle: FontStyle.italic))
                else if (_isFetchingSlots)
                  const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                else if (_availableSlots.isEmpty)
                  Text("No slots configured in this clinic.", style: TextStyle(color: theme.disabledColor, fontSize: 12))
                else
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: _availableSlots.map((slot) {
                      final String val = slot['_id'] ?? slot['value'] ?? 'unknown';
                      final String label = slot['label'] ?? "Slot";
                      final String timeRange = "${_formatTime(slot['start'] ?? '')} - ${_formatTime(slot['end'] ?? '')}";
                      final isSelected = _selectedSlotValues.contains(val);

                      return FilterChip(
                        label: Text("$label ($timeRange)"),
                        selected: isSelected,
                        onSelected: (valState) => setState(
                          () => valState ? _selectedSlotValues.add(val) : _selectedSlotValues.remove(val),
                        ),
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                _buildSectionHeader("Medical Profile", theme),
                const SizedBox(height: 16),

                if (_selectedClinic == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.errorContainer),
                    ),
                    child: Column(
                      children: [
                        Icon(LucideIcons.alertCircle, color: theme.colorScheme.error),
                        const SizedBox(height: 8),
                        Text("Select a Clinic First", style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
                        Text(
                          "You must assign a clinic to configure medical profile and services.",
                          style: TextStyle(color: theme.colorScheme.error.withOpacity(0.8), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text("Departments", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openDepartmentsPopup(theme),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.stethoscope, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDepartments.isEmpty 
                                      ? "Select Departments" 
                                      : "${_selectedDepartments.length} Departments Selected",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                if (_selectedDepartments.isNotEmpty)
                                  Text(
                                    _selectedDepartments.map((d) => _formatDepartmentName(d['department'] ?? d['name'] ?? "")).join(", "),
                                    style: TextStyle(color: theme.disabledColor, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, color: theme.disabledColor, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text("Services Offered", style: theme.textTheme.labelLarge?.copyWith(color: theme.disabledColor)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _openServicesPopup(theme),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.syringe, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedServices.isEmpty 
                                      ? "Select Services" 
                                      : "${_selectedServices.length} Services Selected",
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                if (_selectedServices.isNotEmpty)
                                  Text(
                                    _selectedServices.map((s) => (s['service_id'] != null ? s['service_id']['name'] : 'Service')).join(", "),
                                    style: TextStyle(color: theme.disabledColor, fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  )
                              ],
                            ),
                          ),
                          Icon(LucideIcons.chevronRight, color: theme.disabledColor, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildCleanTextField("Consult Fee (₹)", _consultFeeController, theme, type: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCleanTextField("Follow-up (₹)", _followUpFeeController, theme, type: TextInputType.number, isOptional: true)),
                    ],
                  ),
                ],
              ] else ...[
                _buildSectionHeader("Employment Details", theme),
                const SizedBox(height: 16),
                _buildCleanTextField("Salary (₹)", _salaryController, theme, type: TextInputType.number, icon: LucideIcons.indianRupee, isOptional: true),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSalaryType,
                        decoration: _cleanInputDecoration("Salary Type", theme),
                        items: const [
                          DropdownMenuItem(value: 'monthly', child: Text("Monthly")),
                          DropdownMenuItem(value: 'weekly', child: Text("Weekly")),
                          DropdownMenuItem(value: 'daily', child: Text("Daily")),
                          DropdownMenuItem(value: 'hourly', child: Text("Hourly")),
                        ],
                        onChanged: (val) {
                          if(val != null) setState(() => _selectedSalaryType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedShiftType,
                        decoration: _cleanInputDecoration("Shift Type", theme),
                        items: const [
                          DropdownMenuItem(value: 'full_time', child: Text("Full Time")),
                          DropdownMenuItem(value: 'morning_shift', child: Text("Morning Shift")),
                          DropdownMenuItem(value: 'evening_shift', child: Text("Evening Shift")),
                          DropdownMenuItem(value: 'night_shift', child: Text("Night Shift")),
                        ],
                        onChanged: (val) {
                          if(val != null) setState(() => _selectedShiftType = val);
                        },
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              _buildSectionHeader("Bio & Education", theme),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: _cleanInputDecoration("Professional Biography", theme),
              ),

              const SizedBox(height: 16),
              _buildCleanTextField("Languages (e.g. English, Hindi)", _languagesController, theme, isOptional: true),

              const SizedBox(height: 24),

              ..._educationList.asMap().entries.map((entry) {
                int idx = entry.key;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                    color: theme.cardColor.withOpacity(0.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCleanTextField(
                              "Degree (e.g. MD)",
                              TextEditingController(text: entry.value['degree'])
                                ..addListener(() => _educationList[idx]['degree'] = entry.value['degree']!),
                              theme,
                              onChanged: (val) => _educationList[idx]['degree'] = val,
                              isOptional: true, 
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _buildCleanTextField(
                              "Year",
                              TextEditingController(text: entry.value['year_of_completion']),
                              theme, type: TextInputType.number,
                              onChanged: (val) => _educationList[idx]['year_of_completion'] = val,
                              isOptional: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCleanTextField(
                              "Institution (e.g. CTC Medical)",
                              TextEditingController(text: entry.value['institution']),
                              theme,
                              onChanged: (val) => _educationList[idx]['institution'] = val,
                              isOptional: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.grey),
                            onPressed: () => setState(() => _educationList.removeAt(idx)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              TextButton.icon(
                onPressed: () => setState(() => _educationList.add({'degree': '', 'institution': '', 'year_of_completion': ''})),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text("Add Qualification"),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildCleanTextField(
    String label, TextEditingController controller, ThemeData theme,
    {TextInputType type = TextInputType.text, IconData? icon, Function(String)? onChanged, bool readOnly = false, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: type,
      readOnly: readOnly, 
      validator: (v) {
        if (isOptional || label.contains("Languages") || label.contains("Salary") || label.contains("Follow-up")) return null;
        return (v == null || v.isEmpty) ? "Required" : null;
      },
      decoration: _cleanInputDecoration(label, theme, icon: icon, readOnly: readOnly),
    );
  }

  InputDecoration _cleanInputDecoration(String label, ThemeData theme, {IconData? icon, bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      prefixIcon: icon != null ? Icon(icon, size: 18, color: theme.disabledColor) : null,
      filled: true,
      fillColor: readOnly ? theme.disabledColor.withOpacity(0.1) : theme.cardColor, 
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
    );
  }
}