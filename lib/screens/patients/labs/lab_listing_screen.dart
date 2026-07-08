import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For checking login
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dio/dio.dart'; // For API call
import 'package:my_new_app/screens/auth/partner_register_screen.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 15, 75, 206);
const Color kDarkBg = Color.fromARGB(255, 14, 14, 14);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kDarkCard = Color(0xFF191919);

class LabListingScreen extends StatefulWidget {
  const LabListingScreen({super.key});

  @override
  State<LabListingScreen> createState() => _LabListingScreenState();
}

class _LabListingScreenState extends State<LabListingScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isNotifying = false;

  // --- 1. CORE LOGIC ---
  Future<void> _handleNotifyMe() async {
    setState(() => _isNotifying = true);

    try {
      // Step A: Check if user is already logged in
      final String? token = await _storage.read(key: 'auth_token');
      final String? userPhone = await _storage.read(key: 'user_phone');
      // ^ Assuming you store phone on login. If not, check token.

      if (token != null && userPhone != null) {
        // User exists -> Auto Record
        await _submitInterest(phone: userPhone, source: "Logged In User");
      } else {
        // User doesn't exist -> Open Bottom Sheet
        if (mounted) _showPhoneCollectionSheet(context);
      }
    } catch (e) {
      debugPrint("Error checking user: $e");
    } finally {
      if (mounted) setState(() => _isNotifying = false);
    }
  }

  // --- 2. API CALL ---
  Future<void> _submitInterest({
    required String phone,
    required String source,
  }) async {
    // Simulate API Call
    // Replace with: await Dio().post('/api/record-interest', data: {'phone': phone, 'feature': 'labs'});
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Success! We will notify $phone when Labs are live."),
        backgroundColor: kGreenColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- 3. BOTTOM SHEET FOR GUESTS ---
  void _showPhoneCollectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Needed for keyboard handling
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GuestNotifySheet(
        onSubmit: (phone) async {
          Navigator.pop(context); // Close sheet
          await _submitInterest(phone: phone, source: "Guest");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kDarkBg : kLightBg;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // VISUAL
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryColor.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.flaskConical,
                    size: 45,
                    color: kPrimaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // TEXT
              Text(
                "Pathology Labs\nComing Soon",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "We are currently onboarding the top certified labs in your area to ensure 100% accurate reports and home sample collection.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textColor, height: 1.5),
              ),

              const SizedBox(height: 20),

              // ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isNotifying ? null : _handleNotifyMe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isNotifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.bellRing, size: 20),
                  label: Text(
                    _isNotifying ? "Recording..." : "Notify Me When Live",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // INFO PILL
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? kDarkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.info, size: 14, color: subTextColor),
                    const SizedBox(width: 8),
                    Text(
                      "Estimated Launch: Next Month",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: subTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 4. GUEST NOTIFY BOTTOM SHEET ---
class _GuestNotifySheet extends StatefulWidget {
  final Function(String) onSubmit;
  const _GuestNotifySheet({required this.onSubmit});

  @override
  State<_GuestNotifySheet> createState() => _GuestNotifySheetState();
}

class _GuestNotifySheetState extends State<_GuestNotifySheet> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _isValid = _phoneController.text.length == 10;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Bottom padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? kDarkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Get Notified",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: isDark ? Colors.grey : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your WhatsApp number to receive an update when labs are live in your area.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Phone Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? kDarkBg : kLightBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Text(
                  "+91",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Mobile Number",
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      counterText: "",
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _isValid
                  ? () => widget.onSubmit(_phoneController.text)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: isDark
                    ? Colors.white10
                    : Colors.grey.shade200,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Submit",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Re-defining constants here just for safety within this file scope,
// usually you import them from your theme file.
const Color kGreenColor = Color(0xFF16A34A);
