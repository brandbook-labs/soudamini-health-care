// lib/screens/patients/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// 🚀 [NEW]: Provider ଇମ୍ପୋର୍ଟ କରନ୍ତୁ
import 'package:provider/provider.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:my_new_app/screens/patients/providers/clinic_provider.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';

// --- API SERVICE ---
import 'package:my_new_app/services/api_service.dart';

// --- WIDGET IMPORTS ---
import 'widgets/guest_view.dart';
import 'widgets/logged_in_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- STATE VARIABLES ---
  bool _isLoading = true;
  bool _isLoggedIn = false;

  // Biometrics
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricEnabled = false;

  // Services
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    // 🚀 ପୃଥକ API କଲ୍ ବଦଳରେ କେବଳ Auth ସ୍ଟାଟସ୍ ଚେକ୍ କରାଯାଉଛି
    _checkAuthStatus();
    _loadBiometricPreference();
  }

  // --- 1. CHECK AUTH STATUS & SYNC WITH PROVIDER ---
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _storage.read(key: 'auth_token');

      if (token != null && token.isNotEmpty) {
        if (mounted) {
          setState(() {
            _isLoggedIn = true;
            _isLoading = false;
          });
          // 🚀 ପ୍ରୋଭାଇଡର୍ କୁ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍ ରେ ଫ୍ରେସ୍ (Fresh) ଡାଟା ଆଣିବାକୁ କୁହନ୍ତୁ
          context.read<UserProvider>().fetchUserProfile();
        }
      } else {
        _handleGuestState();
      }
    } catch (e) {
      _handleGuestState();
    }
  }

  // --- 2. BIOMETRIC LOGIC ---
  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    final theme = Theme.of(context);
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      try {
        final bool canCheck = await auth.canCheckBiometrics;
        final bool isSupported = await auth.isDeviceSupported();

        if (!canCheck || !isSupported) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Biometrics not supported on this device."),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
          return;
        }

        final bool didAuth = await auth.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (didAuth) {
          await prefs.setBool('biometric_enabled', true);
          setState(() => _isBiometricEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("Biometric Login Enabled"),
                backgroundColor: theme.colorScheme.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint("Biometric Error: $e");
      }
    } else {
      await prefs.setBool('biometric_enabled', false);
      setState(() => _isBiometricEnabled = false);
    }
  }

  void _handleGuestState() {
    if (mounted) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  // --- 3. HARD LOGOUT (Bottom Sheet) ---
  void _showHardLogoutSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.logOut,
                    color: colorScheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Log Out?",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You will miss out on appointment reminders and health updates if you log out.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "No, Stay Here",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _performLogout();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text(
                    "Yes, Log Out",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performLogout() async {
    try {
      // ୧. ସୁରକ୍ଷିତ ଷ୍ଟୋରେଜ୍ ରୁ କେବଳ ୟୁଜର୍ ଟୋକେନ୍ ହଟାନ୍ତୁ
      await _storage.delete(key: 'auth_token');

      if (mounted) {
        // ୨. 🚀 ସମସ୍ତ ସେନସିଟିଭ୍ (Sensitive) Provider ଡାଟା କ୍ଲିୟର୍ କରନ୍ତୁ
        context.read<UserProvider>().clearData();
        context.read<DoctorProvider>().clearData();
        context.read<ClinicProvider>().clearData();

        // ୩. UI କୁ Guest ମୋଡ୍ କୁ ଆଣନ୍ତୁ
        _handleGuestState();

        // ୪. ସଫଳତା ମେସେଜ୍ ଦେଖାନ୍ତୁ
        final colorScheme = Theme.of(context).colorScheme;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // 🚀 [THE FIX]: ଟେକ୍ସଟ୍ ର ରଙ୍ଗକୁ 'onSurface' କରାଗଲା
            content: Text(
              "Logged out successfully",
              style: TextStyle(
                color: colorScheme.onSurface, // ଡାଇନାମିକ୍ କଳା/ଧଳା ରଙ୍ଗ
                fontWeight: FontWeight.w500,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor:
                colorScheme.surface, // ଆପଣଙ୍କର ଡାଇନାମିକ୍ ବ୍ୟାକଗ୍ରାଉଣ୍ଡ୍
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                8,
              ), // ଟିକେ ସୁନ୍ଦର ରାଉଣ୍ଡେଡ୍ କର୍ଣ୍ଣର୍ ପାଇଁ (Optional)
              side: BorderSide(
                color: colorScheme.outline.withValues(
                  alpha: 0.2,
                ), // ହାଲୁକା ବର୍ଡର୍
              ),
            ),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: colorScheme.primary,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Logout Failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 🚀 ପ୍ରୋଭାଇଡର୍ ରୁ ଡାଟା ଲିସିନ୍ କରାଯାଉଛି
    final userProvider = context.watch<UserProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoggedIn
            ? LoggedInView(
                userProvider: userProvider,
                isBiometricEnabled: _isBiometricEnabled,
                onToggleBiometrics: _toggleBiometrics,
                onLogout: _showHardLogoutSheet,
                onProfileUpdated: () =>
                    context.read<UserProvider>().fetchUserProfile(),
              )
            : GuestView(onLoginSuccess: _checkAuthStatus),
      ),
    );
  }
}
