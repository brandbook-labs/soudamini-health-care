// lib/screens/admin/auth/partner_register_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/admin/admin_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:async';

import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/services/api_service.dart';

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  // ── CONTROLLERS ──────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneInputController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();

  // ── STATE ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _enableBiometrics = false;

  // Slug State
  bool _isSlugChecking = false;
  bool? _isSlugAvailable;
  bool _isSlugManuallyEdited = false;
  Timer? _debounceTimer;

  String _facilityType = "Clinic/Hospital/Medical";
  final List<String> _facilityOptions = const [
    "Clinic/Hospital/Medical",
    "Lab",
    "Pharmacy",
  ];

  final List<String> _phoneNumbers = [];

  String get _entityLabel {
    if (_facilityType == "Lab") return "Lab";
    if (_facilityType == "Pharmacy") return "Pharmacy";
    return "Clinic";
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (!_isSlugManuallyEdited && _nameController.text.isNotEmpty) {
        _autoGenerateSlug(_nameController.text);
      } else if (_nameController.text.isEmpty && !_isSlugManuallyEdited) {
        _slugController.clear();
        setState(() => _isSlugAvailable = null);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _emailController.dispose();
    _phoneInputController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── SLUG LOGIC (UNTOUCHED) ─────────────────────────────────────────────────
  void _autoGenerateSlug(String name) {
    String slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (_slugController.text != slug) {
      _slugController.text = slug;
      _checkSlugAvailability(slug);
    }
  }

  void _onSlugManuallyChanged(String value) {
    _isSlugManuallyEdited = true;
    final formatted = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    if (value != formatted) {
      _slugController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (formatted.isEmpty) {
      setState(() {
        _isSlugChecking = false;
        _isSlugAvailable = null;
      });
      return;
    }

    setState(() {
      _isSlugChecking = true;
      _isSlugAvailable = null;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _checkSlugAvailability(formatted);
    });
  }

  Future<void> _checkSlugAvailability(String slug) async {
    setState(() => _isSlugChecking = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final isAvailable = slug != 'apollo';

      if (mounted) {
        setState(() {
          _isSlugChecking = false;
          _isSlugAvailable = isAvailable;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSlugChecking = false;
          _isSlugAvailable = null;
        });
      }
    }
  }

  // ── PHONE NUMBERS (UNTOUCHED) ─────────────────────────────────────────────
  void _addPhoneNumber() {
    final num = _phoneInputController.text.trim();
    if (num.isEmpty) return;

    if (!_phoneNumbers.contains(num)) {
      setState(() {
        _phoneNumbers.add(num);
        _phoneInputController.clear();
      });
    } else {
      JivanToast.show(
        context,
        title: "Duplicate",
        message: "Number already added",
        type: ToastType.warning,
      );
    }
  }

  void _removePhoneNumber(String num) {
    setState(() => _phoneNumbers.remove(num));
  }

  // ── PASSWORD GENERATOR (UNTOUCHED) ────────────────────────────────────────
  void _generatePassword() {
    String password = "";
    final specialChars = ["@", "#", "\$", "&", "!"];
    final randomChar = specialChars[Random().nextInt(specialChars.length)];

    if (_nameController.text.isNotEmpty && _phoneNumbers.isNotEmpty) {
      final cleanName = _nameController.text.trim().replaceAll(
        RegExp(r'\s+'),
        '',
      );
      final namePart = cleanName.substring(0, min(4, cleanName.length));
      final phone = _phoneNumbers.first;
      final phonePart = phone.length > 4
          ? phone.substring(phone.length - 4)
          : phone;

      String typePrefix = "Clin";
      if (_facilityType == "Lab") typePrefix = "Lab";
      if (_facilityType == "Pharmacy") typePrefix = "Phar";

      password = "$typePrefix$randomChar$namePart$phonePart";
      if (RegExp(r'[a-zA-Z]').hasMatch(password[0])) {
        password = password[0].toUpperCase() + password.substring(1);
      }
    } else {
      const chars =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#\$&!';
      password = List.generate(
        12,
        (index) => chars[Random().nextInt(chars.length)],
      ).join();
    }

    if (password.length < 8) password += "123";

    setState(() {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
      _obscurePassword = false;
      _obscureConfirmPassword = false;
    });

    JivanToast.show(
      context,
      title: "Secure Password",
      message: "Password generated & applied.",
      type: ToastType.success,
    );
  }

  // ── OTP LOGIC (UNTOUCHED) ─────────────────────────────────────────────────
  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSlugAvailable == false) {
      JivanToast.show(
        context,
        title: "Invalid URL",
        message: "Please choose an available URL slug",
        type: ToastType.error,
      );
      return;
    }

    context.closeKeyboard();
    setState(() => _isSendingOtp = true);

    try {
      String apiFacilityType = "clinic";
      if (_facilityType == "Lab") apiFacilityType = "lab";
      if (_facilityType == "Pharmacy") apiFacilityType = "pharmacy";

      await _apiService.requestClinicOtp({
        "name": _nameController.text.trim(),
        "slug": _slugController.text.trim(),
        "email": _emailController.text.trim(),
        "phone": _phoneNumbers,
        "facility_type": apiFacilityType,
      });

      if (!mounted) return;
      JivanToast.show(
        context,
        title: "OTP Sent",
        message: "Check your email for OTP",
        type: ToastType.success,
      );
      _showOtpDialog();
    } catch (e) {
      if (!mounted) return;
      JivanToast.show(
        context,
        title: "Error",
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _handleVerifyOtp(StateSetter setModalState) async {
    if (_otpController.text.length < 4) {
      JivanToast.show(
        context,
        title: "Invalid",
        message: "Enter valid OTP",
        type: ToastType.error,
      );
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      JivanToast.show(
        context,
        title: "Mismatch",
        message: "Passwords do not match",
        type: ToastType.error,
      );
      return;
    }

    setModalState(() => _isVerifyingOtp = true);

    try {
      final response = await _apiService.verifyAndRegisterClinic({
        "email": _emailController.text.trim(),
        "otp": _otpController.text.trim(),
        "password": _passwordController.text.trim(),
      });

      // API Response ରୁ Data କାଢିବା
      final responseData = response.data['data'];
      final token = responseData != null ? responseData['token'] : null;
      final role = responseData != null ? responseData['role'] : null;

      // SharedPreferences ରେ ସେଭ୍ କରିବା
      final prefs = await SharedPreferences.getInstance();
      
      if (token != null) {
        await prefs.setString('admin_token', token.toString());
      }
      if (role != null) {
        await prefs.setString('role', role.toString());
      }

      if (_enableBiometrics) {
        await prefs.setBool('biometric_enabled', true);
      }

      if (!mounted) return;
      Navigator.pop(context); // Close bottom sheet

      JivanToast.show(
        context,
        title: "Welcome!",
        message: "$_entityLabel Registered Successfully!",
        type: ToastType.success,
      );

      // ସିଧାସଳଖ Admin Dashboard କୁ ଯିବା
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AdminLayout(isNewRegistration: true)),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      JivanToast.show(
        context,
        title: "Verification Failed",
        message: e.toString(),
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setModalState(() => _isVerifyingOtp = false);
      }
    }
  }

  void _showOtpDialog() {
    _otpController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return PopScope(
              canPop: false,
              child: Container(
                padding: EdgeInsets.only(
                  bottom:
                      MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
                  top: AppSpacing.lg,
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: context.roundedSheet,
                  boxShadow: context.shadowMd,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Verify Email",
                          style: context.headlineSm?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            LucideIcons.x,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    context.gapXs,
                    Text(
                      "Enter the OTP sent to ${_emailController.text}",
                      style: context.bodyMd?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    context.gapXl,
                    JivanTextField(
                      label: "OTP",
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(LucideIcons.key),
                      autoFocus: true,
                    ),
                    context.gapXl,
                    JivanButton(
                      text: "Verify & Register",
                      onPressed: () => _handleVerifyOtp(setModalState),
                      isLoading: _isVerifyingOtp,
                      type: ButtonType.primary,
                      isFullWidth: true,
                    ),
                    context.gapMd,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const bgColor = Colors.white;
    const borderColor = Color(0xFFE2E8F0); // Slate 200

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Register Partner",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: SafeArea(
          child: JivanButton(
            text: "Send Verification OTP",
            onPressed: _handleSendOtp,
            isLoading: _isSendingOtp,
            isFullWidth: true,
            type: ButtonType.primary,
            icon: LucideIcons.arrowRight,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // ── SECTION 1: BUSINESS PROFILE ──────────────────────────
              _buildFormSection(
                title: "Business Profile",
                icon: LucideIcons.building,
                showDivider: true,
                children: [
                  JivanDropdown<String>(
                    label: "Select Facility Type",
                    value: _facilityType,
                    items: _facilityOptions,
                    icon: LucideIcons.stethoscope,
                    onChanged: (val) {
                      setState(() {
                        _facilityType = val!;
                        if (_passwordController.text.isNotEmpty) {
                          _passwordController.clear();
                          _confirmPasswordController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  JivanTextField(
                    label: "$_entityLabel Name",
                    controller: _nameController,
                    prefixIcon: const Icon(LucideIcons.building),
                    validator: (v) => v!.isEmpty ? "Name is required" : null,
                    hintText: "e.g. Apollo $_entityLabel",
                  ),
                  const SizedBox(height: 20),

                  _buildSlugInput(theme),

                  const SizedBox(height: 20),
                  JivanTextField(
                    label: "Official Email",
                    controller: _emailController,
                    prefixIcon: const Icon(LucideIcons.mail),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        !v!.contains("@") ? "Invalid Email" : null,
                  ),
                ],
              ),

              // ── SECTION 2: CONTACT INFO ──────────────────────────────
              _buildFormSection(
                title: "Contact Lines",
                icon: LucideIcons.phone,
                showDivider: true,
                children: [
                  JivanPhoneInput(
                    label: "Contact Number",
                    controller: _phoneInputController,
                    suffixIcon: IconButton(
                      icon: Icon(
                        LucideIcons.plusCircle,
                        color: colorScheme.primary,
                      ),
                      tooltip: "Add Number",
                      onPressed: _addPhoneNumber,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add multiple numbers if your $_entityLabel has separate numbers.",
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_phoneNumbers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _phoneNumbers
                          .map(
                            (num) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    num,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removePhoneNumber(num),
                                    child: const Icon(
                                      LucideIcons.x,
                                      size: 14,
                                      color: Color(0xFF94A3B8),
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

              // ── SECTION 3: SECURITY ──────────────────────────────────
              _buildFormSection(
                title: "Security Setup",
                icon: LucideIcons.shieldCheck,
                showDivider: false,
                // --- NEW: Added action widget to the header ---
                action: TextButton.icon(
                  onPressed: _generatePassword,
                  icon: const Icon(LucideIcons.sparkles, size: 14),
                  label: const Text("Generate Password"),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                children: [
                  JivanTextField(
                    label: "Password",
                    controller: _passwordController,
                    prefixIcon: const Icon(LucideIcons.lock),
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 20),
                  JivanTextField(
                    label: "Confirm Password",
                    controller: _confirmPasswordController,
                    prefixIcon: const Icon(LucideIcons.lock),
                    obscureText: _obscureConfirmPassword,
                    validator: (v) {
                      if (v != _passwordController.text)
                        return "Passwords do not match";
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.fingerprint,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        "Enable Biometrics",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      subtitle: const Text(
                        "Use fingerprint/face ID for quick login",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      value: _enableBiometrics,
                      activeColor: colorScheme.primary,
                      activeTrackColor: colorScheme.primary.withValues(
                        alpha: 0.3,
                      ),
                      onChanged: (val) =>
                          setState(() => _enableBiometrics = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // --- PREMIUM FLAT SECTION HELPER (WITH EDGE-TO-EDGE DIVIDERS & ACTION) ---
  Widget _buildFormSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required bool showDivider,
    Widget? action, // Added optional action widget
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Action padded inward
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              if (action != null) action,
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Content padded inward
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        // Divider NOT padded - bleeds to the edges
        if (showDivider) ...[
          const SizedBox(height: 32),
          const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Widget _buildSlugInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Custom URL (Slug)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isSlugAvailable == false
                  ? Colors.red.shade300
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              // Domain Prefix
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(11),
                  ),
                  border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: const Center(
                  child: Text(
                    "jivan.website/",
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Input Field
              Expanded(
                child: TextField(
                  controller: _slugController,
                  onChanged: _onSlugManuallyChanged,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: "my-clinic",
                    hintStyle: TextStyle(color: Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              // Feedback Icon
              SizedBox(
                width: 48,
                child: Center(
                  child: _isSlugChecking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isSlugAvailable == true
                      ? Icon(
                          LucideIcons.checkCircle2,
                          color: Colors.green.shade600,
                          size: 18,
                        )
                      : _isSlugAvailable == false
                      ? Icon(
                          LucideIcons.xCircle,
                          color: Colors.red.shade600,
                          size: 18,
                        )
                      : const SizedBox(),
                ),
              ),
            ],
          ),
        ),
        if (_isSlugAvailable == false)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              "This URL is already taken.",
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else if (_isSlugAvailable == true)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              "URL is available!",
              style: TextStyle(
                color: Colors.green.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
