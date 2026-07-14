import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/admin_layout.dart';
import 'package:my_new_app/screens/super_admin/super_admin_layout.dart';
import 'package:my_new_app/screens/auth/partner_register_screen.dart';
import 'package:my_new_app/screens/auth/login_screen.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSetup();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── NAVIGATION ───────────────────────────────────────────────────────────

  void _navigateBasedOnRole(String role) {
    if (!mounted) return;
    final Widget nextScreen = (role == 'super_admin' || role == 'SuperAdmin')
        ? const AdminLayout() // const SuperAdminLayout()
        : const AdminLayout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
      (route) => false,
    );
  }

  void _handleBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // ── BIOMETRIC ────────────────────────────────────────────────────────────

  Future<void> _checkBiometricSetup() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false;
    if (!isEnabled) return;

    final bool canCheck = await _localAuth.canCheckBiometrics;
    final bool isSupported = await _localAuth.isDeviceSupported();

    if (canCheck && isSupported) {
      setState(() => _isBiometricAvailable = true);
      _attemptBiometricLogin();
    }
  }

  Future<void> _attemptBiometricLogin() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Verify identity to access Dashboard',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) return;

      setState(() => _isLoading = true);
      final String? token = await _storage.read(key: 'admin_token');
      final String? role = await _storage.read(key: 'admin_role');

      if (!mounted) return;

      if (token != null && token.isNotEmpty) {
        JivanToast.show(
          context,
          title: "Welcome Back",
          message: "Biometric Login Successful",
          type: ToastType.success,
        );
        _navigateBasedOnRole(role ?? 'clinic');
      } else {
        JivanToast.show(
          context,
          title: "Session Expired",
          message: "Please login with password first.",
          type: ToastType.warning,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', false);
        setState(() {
          _isBiometricAvailable = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Biometric Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── API ──────────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    context.closeKeyboard();
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.adminLogin(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final dataSection = response.data['data'];
        if (dataSection != null && dataSection['token'] != null) {
          final String token = dataSection['token'];
          final String rawRole = dataSection['role'] ?? 'Admin';
          final String internalRole = rawRole == 'SuperAdmin'
              ? 'super_admin'
              : 'admin';

          await _storage.write(key: 'admin_token', value: token);
          await _storage.write(key: 'admin_role', value: internalRole);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('biometric_enabled', true);

          if (mounted) {
            JivanToast.show(
              context,
              title: "Success",
              message: "Login Successful",
              type: ToastType.success,
            );
            _navigateBasedOnRole(internalRole);
          }
        } else {
          JivanToast.show(
            context,
            title: "Error",
            message: "Invalid Response: Token missing",
            type: ToastType.error,
          );
        }
      } else {
        JivanToast.show(
          context,
          title: "Failed",
          message: response.data['msg'] ?? "Authentication Failed",
          type: ToastType.error,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      JivanToast.show(
        context,
        title: "Error",
        message:
            e.response?.data['msg'] ??
            e.response?.data['error'] ??
            "Connection Timeout",
        type: ToastType.error,
      );
    } catch (_) {
      if (!mounted) return;
      JivanToast.show(
        context,
        title: "Error",
        message: "An unexpected error occurred",
        type: ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
            onPressed: _handleBack,
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── HEADER ────────────────────────────────────────────
                    Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.5,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          LucideIcons.stethoscope,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),

                    context.gapLg,

                    Text(
                      "Partner Access",
                      textAlign: TextAlign.center,
                      style: context.headlineMd?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    context.gapXs,

                    Text(
                      "Manage your clinic, patients & appointments",
                      textAlign: TextAlign.center,
                      style: context.bodyMd?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    context.gapXxl,

                    // ── EMAIL FIELD ───────────────────────────────────────
                    JivanTextField(
                      label: "Email or Partner ID",
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(LucideIcons.mail),
                      validator: (v) => v!.isEmpty ? "Enter email or ID" : null,
                    ),

                    context.gapLg,

                    // ── PASSWORD FIELD ────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: context.bodyLg?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(LucideIcons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? "Minimum 6 characters" : null,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),

                    context.gapMd,

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          JivanToast.show(
                            context,
                            title: "Info",
                            message: "Contact support to reset password",
                            type: ToastType.info,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          "Forgot Password?",
                          style: context.labelMd?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    context.gapXl,

                    // ── LOGIN BUTTON ──────────────────────────────────────
                    JivanButton(
                      text: "Secure Login",
                      isLoading: _isLoading,
                      isFullWidth: true,
                      type: ButtonType.primary,
                      icon: LucideIcons.logIn,
                      onPressed: _handleLogin,
                    ),

                    // ── BIOMETRIC ─────────────────────────────────────────
                    if (_isBiometricAvailable) ...[
                      context.gapXl,
                      const JivanDivider(text: "OR"),
                      context.gapXl,
                      SizedBox(
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _attemptBiometricLogin,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: context.roundedMd,
                            ),
                            backgroundColor: colorScheme.surface,
                          ),
                          icon: Icon(
                            LucideIcons.fingerprint,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            "Login with Biometrics",
                            style: context.labelLg?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    context.gapXxl,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
