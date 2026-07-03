import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

import '../../../services/api_service.dart';
import '../main_layout.dart';

class EditProfileScreen extends StatefulWidget {
  final String? initialPhone;

  const EditProfileScreen({super.key, this.initialPhone});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // --- Controllers ---
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _dobController;
  late TextEditingController _emgNameController;
  late TextEditingController _emgPhoneController;

  // --- State Variables ---
  bool _isLoading = true;
  bool _isUpdating = false;
  XFile? _selectedImageFile;
  String? _currentAvatarUrl;

  // --- Dropdown States ---
  String? _selectedGender;
  String? _selectedBloodGroup;
  String? _selectedEmgRelation; // 👈 NEW: Emergency Relation
  String? _selectedSmoking;
  String? _selectedAlcohol;
  String? _selectedDiet;

  // --- Dropdown Options ---
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
  final List<String> _relationOptions = [
    'Spouse',
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Sibling',
    'Friend',
    'Other',
  ]; // 👈 NEW: Relation Options
  final List<String> _habitOptions = ['Non-User', 'Occasional', 'Regular'];
  final List<String> _dietOptions = [
    'Vegetarian',
    'Non-Vegetarian',
    'Vegan',
    'Eggetarian',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _dobController = TextEditingController();
    _emgNameController = TextEditingController();
    _emgPhoneController = TextEditingController();

    String phoneText = "";
    if (widget.initialPhone != null) {
      phoneText = widget.initialPhone!.replaceAll("+91", "").trim();
    }
    _phoneController = TextEditingController(text: phoneText);

    _fetchUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _emgNameController.dispose();
    _emgPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    try {
      final response = await _apiService.getUserProfile();

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];

        setState(() {
          _nameController.text = data['name'] ?? "";
          _emailController.text = data['email'] ?? "";
          _addressController.text = data['address'] ?? "";
          _dobController.text = data['dob'] ?? "";
          _emgNameController.text = data['emergency_name'] ?? "";
          _emgPhoneController.text = data['emergency_phone'] ?? "";

          _currentAvatarUrl = data['profile'];

          if (data['gender'] != null && _genderOptions.contains(data['gender']))
            _selectedGender = data['gender'];
          if (data['blood_group'] != null &&
              _bloodGroups.contains(data['blood_group']))
            _selectedBloodGroup = data['blood_group'];
          if (data['emergency_relation'] != null &&
              _relationOptions.contains(data['emergency_relation']))
            _selectedEmgRelation = data['emergency_relation'];
          if (data['smoking'] != null &&
              _habitOptions.contains(data['smoking']))
            _selectedSmoking = data['smoking'];
          if (data['alcohol'] != null &&
              _habitOptions.contains(data['alcohol']))
            _selectedAlcohol = data['alcohol'];
          if (data['diet'] != null && _dietOptions.contains(data['diet']))
            _selectedDiet = data['diet'];

          if (widget.initialPhone == null && data['phone'] != null) {
            String p = data['phone'].toString();
            _phoneController.text = p.replaceAll("+91", "").trim();
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedImageFile = image);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(colorScheme: context.colorScheme),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handleUpdateProfile() async {
    context.closeKeyboard();
    setState(() => _isUpdating = true);

    try {
      bool isMultipart = false;

      final Map<String, dynamic> dataMap = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "email": _emailController.text.trim(),
        "address": _addressController.text.trim(),
        "dob": _dobController.text.trim(),
        "emergency_name": _emgNameController.text.trim(),
        "emergency_phone": _emgPhoneController.text.trim(),
        if (_selectedEmgRelation != null)
          "emergency_relation": _selectedEmgRelation, // 👈 Payload updated
        if (_selectedGender != null) "gender": _selectedGender,
        if (_selectedBloodGroup != null) "blood_group": _selectedBloodGroup,
        if (_selectedSmoking != null) "smoking": _selectedSmoking,
        if (_selectedAlcohol != null) "alcohol": _selectedAlcohol,
        if (_selectedDiet != null) "diet": _selectedDiet,
      };

      if (_selectedImageFile != null) {
        isMultipart = true;
        final bytes = await _selectedImageFile!.readAsBytes();
        dataMap["profile"] = MultipartFile.fromBytes(
          bytes,
          filename: _selectedImageFile!.name,
        );
      }

      final response = await _apiService.updateProfile(
        dataMap,
        isMultipart: isMultipart,
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        JivanToast.show(context, title: "Success", message: "Profile Updated!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      String msg = e.response?.data['message'] ?? "Update failed";
      JivanToast.show(context, title: "Error", message: msg);
    } catch (e) {
      if (!mounted) return;
      JivanToast.show(
        context,
        title: "Error",
        message: "Something went wrong!",
      );
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPhoneLocked =
        widget.initialPhone != null && widget.initialPhone!.isNotEmpty;
    final colorScheme = context.colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final canvasColor = isDark
        ? const Color(0xFF09090B)
        : const Color(0xFFF1F5F9);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: canvasColor,
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: const JivanAppBar(title: "Edit Profile", showBack: true),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECTION 1: Avatar + Personal Info (Merged, No Gap) ---
            Container(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              padding: const EdgeInsets.only(
                top: 32,
                bottom: 8,
              ), // Reduced bottom padding so it flows right into the form
              child: _buildAvatarSection(colorScheme),
            ),

            _buildFlatSection(
              title: "PERSONAL INFORMATION",
              isDark: isDark,
              children: [
                JivanTextField(
                  label: "Full Name",
                  controller: _nameController,
                  hintText: "e.g. Rajesh Kumar",
                  prefixIcon: const Icon(LucideIcons.user),
                ),
                const SizedBox(height: 16),
                JivanPhoneInput(
                  label: "Mobile Number",
                  controller: _phoneController,
                  readOnly: isPhoneLocked,
                ),
                if (isPhoneLocked)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Text(
                      "Linked to your verified account",
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                JivanTextField(
                  label: "Email Address",
                  controller: _emailController,
                  hintText: "rajesh@example.com",
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(LucideIcons.mail),
                ),
                const SizedBox(height: 16),
                JivanTextField(
                  label: "Address",
                  controller: _addressController,
                  hintText: "Plot 142, Unit 9, Bhubaneswar",
                  prefixIcon: const Icon(LucideIcons.mapPin),
                ),
              ],
            ),

            _buildSectionDivider(canvasColor),

            // --- SECTION 2: Demographics ---
            _buildFlatSection(
              title: "DEMOGRAPHICS & PHYSICAL",
              isDark: isDark,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: JivanTextField(
                            label: "Date of Birth",
                            controller: _dobController,
                            hintText: "DD/MM/YYYY",
                            prefixIcon: const Icon(LucideIcons.calendarDays),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: "Blood Group",
                        value: _selectedBloodGroup,
                        items: _bloodGroups,
                        icon: LucideIcons.droplet,
                        onChanged: (v) =>
                            setState(() => _selectedBloodGroup = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: "Gender",
                  value: _selectedGender,
                  items: _genderOptions,
                  icon: LucideIcons.users,
                  onChanged: (v) => setState(() => _selectedGender = v),
                ),
              ],
            ),

            _buildSectionDivider(canvasColor),

            // --- SECTION 3: Emergency Contact ---
            _buildFlatSection(
              title: "EMERGENCY CONTACT",
              isDark: isDark,
              children: [
                JivanTextField(
                  label: "Contact Name",
                  controller: _emgNameController,
                  hintText: "e.g. Sunita Kumar",
                  prefixIcon: const Icon(LucideIcons.userPlus),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: JivanTextField(
                        label: "Contact Phone",
                        controller: _emgPhoneController,
                        hintText: "e.g. 9876543210",
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(LucideIcons.phone),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex:
                          2, // 👈 NEW: Relation Dropdown integrated next to phone
                      child: _buildDropdown(
                        label: "Relation",
                        value: _selectedEmgRelation,
                        items: _relationOptions,
                        icon: LucideIcons.heartHandshake,
                        onChanged: (v) =>
                            setState(() => _selectedEmgRelation = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            _buildSectionDivider(canvasColor),

            // --- SECTION 4: Lifestyle Habits ---
            _buildFlatSection(
              title: "LIFESTYLE HABITS",
              isDark: isDark,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        label: "Smoking",
                        value: _selectedSmoking,
                        items: _habitOptions,
                        icon: LucideIcons.flame,
                        onChanged: (v) => setState(() => _selectedSmoking = v),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        label: "Alcohol",
                        value: _selectedAlcohol,
                        items: _habitOptions,
                        icon: LucideIcons.wine,
                        onChanged: (v) => setState(() => _selectedAlcohol = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: "Diet",
                  value: _selectedDiet,
                  items: _dietOptions,
                  icon: LucideIcons.utensils,
                  onChanged: (v) => setState(() => _selectedDiet = v),
                ),
              ],
            ),

            // --- SAVE BUTTON ---
            Container(
              color: isDark ? const Color(0xFF18181B) : Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  JivanButton(
                    text: "Save All Changes",
                    isLoading: _isUpdating,
                    isFullWidth: true,
                    size: ButtonSize.large,
                    onPressed: _handleUpdateProfile,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper: Section Rhythm Divider ---
  Widget _buildSectionDivider(Color canvasColor) {
    return Container(height: 12, color: canvasColor);
  }

  // --- Helper: Avatar Widget ---
  Widget _buildAvatarSection(ColorScheme colorScheme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.2),
                width: 4,
              ),
              color: colorScheme.surfaceContainerHighest,
              image: DecorationImage(
                fit: BoxFit.cover,
                image: _selectedImageFile != null
                    ? (kIsWeb
                              ? NetworkImage(_selectedImageFile!.path)
                              : FileImage(File(_selectedImageFile!.path)))
                          as ImageProvider
                    : (_currentAvatarUrl != null &&
                          _currentAvatarUrl!.isNotEmpty)
                    ? NetworkImage(_currentAvatarUrl!)
                    : const NetworkImage(
                            "https://ui-avatars.com/api/?name=User",
                          )
                          as ImageProvider,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  LucideIcons.camera,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      color: isDark ? const Color(0xFF18181B) : Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ), // Reduced top padding to flow better
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  // --- Helper: Custom Dropdown ---
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DropdownButtonFormField<String>(
      value: value,
      icon: Icon(
        LucideIcons.chevronDown,
        size: 16,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
        filled: true,
        // 👈 FIXED: Changed to pure white/dark surface to match text fields perfectly
        fillColor: isDark ? const Color(0xFF18181B) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        // 👈 FIXED: Stronger, crisper borders to match text fields
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      dropdownColor: isDark ? const Color(0xFF18181B) : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      items: items
          .map(
            (String val) =>
                DropdownMenuItem<String>(value: val, child: Text(val)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
