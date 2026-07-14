import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:my_new_app/core/components/index.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

import 'package:my_new_app/screens/main_layout.dart';
import 'package:my_new_app/screens/patients/edit_profile_screen.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/auth/partner_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _mobileErrorText;

  @override
  void initState() {
    super.initState();
    _mobileController.addListener(_onMobileChanged);
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // ── LISTENER LOGIC ───────────────────────────────────────────────────────

  void _onMobileChanged() {
    if (_mobileErrorText != null) {
      setState(() => _mobileErrorText = null);
    }
    final rawText = _mobileController.text.replaceAll(' ', '').trim();
    if (rawText.length == 10 && !_isOtpSent && !_isLoading) {
      _handleGetOtp();
    }
  }

  void _onOtpChanged() {
    if (_otpController.text.length == 6 && _isOtpSent && !_isLoading) {
      _handleVerifyOtp();
    }
  }

  void _resetFlow() {
    setState(() {
      _isOtpSent = false;
      _isLoading = false;
      _otpController.clear();
      _mobileErrorText = null;
    });
  }

  // ── API ACTIONS ──────────────────────────────────────────────────────────

  Future<void> _handleGetOtp() async {
    final rawNumber = _mobileController.text.replaceAll(' ', '').trim();
    if (rawNumber.length != 10) {
      setState(
        () => _mobileErrorText = "Please enter a valid 10-digit number.",
      );
      HapticFeedback.lightImpact();
      return;
    }

    context.closeKeyboard();
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.sendOtp(rawNumber);
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        final String? otp = data != null ? data['otp']?.toString() : null;
        setState(() {
          _isOtpSent = true;
          _isLoading = false;
        });
        if (otp != null) {
          JivanToast.show(
            context,
            title: "Code Sent",
            message: "Your OTP is $otp",
            type: ToastType.info,
          );
          await Future.delayed(const Duration(milliseconds: 200));
          _otpController.text = otp;
        }
        return;
      } else {
        JivanToast.show(
          context,
          title: "Error",
          message: "Failed to send OTP",
          type: ToastType.error,
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        JivanToast.show(
          context,
          title: "Error",
          message: e.response?.data['message'] ?? "Connection Error",
          type: ToastType.error,
        );
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleVerifyOtp() async {
    context.closeKeyboard();
    setState(() => _isLoading = true);

    try {
      final rawNumber = _mobileController.text.replaceAll(' ', '').trim();
      final response = await _apiService.verifyOtp(
        rawNumber,
        _otpController.text.trim(),
      );
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];
        if (data != null) {
          final String token = data['token'];
          final bool isEmpty = data['isEmpty'] ?? true;
          await _storage.write(key: 'auth_token', value: token);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => isEmpty
                    ? EditProfileScreen(initialPhone: rawNumber)
                    : const MainLayout(),
              ),
            );
          }
          return;
        }
      } else {
        JivanToast.show(
          context,
          title: "Invalid",
          message: "Incorrect OTP",
          type: ToastType.error,
        );
        _otpController.clear();
      }
    } on DioException catch (e) {
      if (mounted) {
        JivanToast.show(
          context,
          title: "Error",
          message: e.response?.data['message'] ?? "Invalid OTP",
          type: ToastType.error,
        );
        _otpController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);
  }

  // ── UI BUILD ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: AutofillGroup(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    context.gapLg,

                    // ── LOGO ─────────────────────────────────────────────
                    Center(
                      child: Container(
                        height: 100,
                        width: 100,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: context.shadowSm,
                        ),
                        child: Image.asset(
                          'assets/images/SoudaminiHealthcareLogo.png',
                          errorBuilder: (_, __, ___) => Icon(
                            LucideIcons.heartPulse,
                            size: 50,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),

                    context.gapXl,

                    // ── HEADLINE ─────────────────────────────────────────
                    Text(
                      "Let's get started",
                      textAlign: TextAlign.center,
                      style: context.headlineMd?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    context.gapSm,

                    Text(
                      "Bookings, prescriptions, and health records. All in one place.",
                      textAlign: TextAlign.center,
                      style: context.bodyMd?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    context.gapMd,

                    // ── MOBILE FIELD ─────────────────────────────────────
                    TextFormField(
                      controller: _mobileController,
                      readOnly: _isOtpSent,
                      autofocus: !_isOtpSent,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                        _PhoneNumberFormatter(),
                      ],
                      style: context.bodyLg,
                      decoration: InputDecoration(
                        labelText: "Mobile Number",
                        errorText: _mobileErrorText,
                        prefixIcon: const Icon(LucideIcons.phone),
                        suffixIcon: _isOtpSent
                            ? IconButton(
                                icon: Icon(
                                  LucideIcons.edit2,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                onPressed: _resetFlow,
                                tooltip: "Change Number",
                              )
                            : null,
                      ),
                    ),

                    // ── OTP FIELD ─────────────────────────────────────────
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: EdgeInsets.only(top: context.spaceSm),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.start,
                              autofocus: true,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(6),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: context.bodyLg?.copyWith(letterSpacing: 4),
                              decoration: const InputDecoration(
                                labelText: "Verification Code",
                                prefixIcon: Icon(LucideIcons.shieldCheck),
                              ),
                            ),
                            if (_isLoading) ...[
                              context.gapMd,
                              LinearProgressIndicator(
                                minHeight: 2,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                      crossFadeState: _isOtpSent
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),

                    context.gapMd,

                    // ── PRIMARY BUTTON ────────────────────────────────────
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : (_isOtpSent ? _handleVerifyOtp : _handleGetOtp),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: context.roundedMd,
                          ),
                          disabledBackgroundColor: colorScheme.primary
                              .withValues(alpha: 0.6),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _isOtpSent ? "Verify" : "Get OTP",
                                    style: context.labelLg?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                  context.gapSm,
                                  Icon(
                                    LucideIcons.arrowRight,
                                    size: 18,
                                    color: colorScheme.onPrimary,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // context.gapMd,

                    // ── DIVIDER ───────────────────────────────────────────
                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Divider(color: colorScheme.outlineVariant),
                    //     ),
                    //     Padding(
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: AppSpacing.md,
                    //       ),
                    //       child: Text(
                    //         "OR",
                    //         style: context.labelMd?.copyWith(
                    //           color: colorScheme.onSurfaceVariant,
                    //         ),
                    //       ),
                    //     ),
                    //     Expanded(
                    //       child: Divider(color: colorScheme.outlineVariant),
                    //     ),
                    //   ],
                    // ),

                    // context.gapXl,

                    // ── GOOGLE LOGIN ──────────────────────────────────────
                    // SizedBox(
                    //   height: 50,
                    //   child: OutlinedButton.icon(
                    //     onPressed: _handleGoogleLogin,
                    //     style: OutlinedButton.styleFrom(
                    //       backgroundColor: colorScheme.surface,
                    //       side: BorderSide(color: colorScheme.outlineVariant),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: context.roundedMd,
                    //       ),
                    //     ),
                    //     icon: Image.network(
                    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                    //       height: 20,
                    //       width: 20,
                    //       errorBuilder: (_, __, ___) => Icon(
                    //         LucideIcons.globe,
                    //         size: 20,
                    //         color: colorScheme.onSurface,
                    //       ),
                    //     ),
                    //     label: Text(
                    //       "Continue with Google",
                    //       style: context.labelLg?.copyWith(
                    //         color: colorScheme.onSurface,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    context.gapMd,

                    // ── SECONDARY LINKS ───────────────────────────────────
                    Column(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MainLayout(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.onSurfaceVariant,
                          ),
                          child: Text(
                            "Skip for now",
                            style: context.bodyMd?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),

                        context.gapXxl,

                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PartnerLoginScreen(),
                            ),
                          ),
                          child: RichText(
                            text: TextSpan(
                              text: "Are you a doctor or admin? ",
                              style: context.bodyMd?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: "Admin Login",
                                  style: context.bodyMd?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    context.gapLg,
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

// ── PHONE FORMATTER ──────────────────────────────────────────────────────────
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 11) return oldValue;

    StringBuffer buffer = StringBuffer();
    int nonSpaceCount = 0;

    for (int i = 0; i < text.length; i++) {
      if (text[i] != ' ') {
        buffer.write(text[i]);
        nonSpaceCount++;
        if (nonSpaceCount == 5 && i != text.length - 1) {
          buffer.write(' ');
        }
      }
    }

    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
