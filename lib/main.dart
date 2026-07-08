import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --- CONTROLLERS & SCREENS ---
import 'package:my_new_app/controllers/language_controller.dart';
import 'package:my_new_app/screens/splash_screen.dart';

// --- NEW THEME SYSTEM (THE BRAIN) ---
import 'package:my_new_app/core/theme/app_theme.dart';

// 👇 ଏଠାରେ ଆପଣଙ୍କର ନୂଆ ପ୍ରୋଭାଇଡର୍ କୁ ଇମ୍ପୋର୍ଟ କରନ୍ତୁ (ପାଥ୍ ଆପଣଙ୍କ ଫୋଲ୍ଡର୍ ଅନୁସାରେ ଠିକ୍ କରିବେ) 👇
import 'package:my_new_app/screens/patients/providers/clinic_provider.dart';
import 'package:my_new_app/screens/patients/providers/doctor_provider.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  runApp(
    // 👇 ଏଠାରେ ChangeNotifierProvider ବଦଳରେ MultiProvider ବ୍ୟବହାର କରାଯାଇଛି 👇
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageController()), // ପୁରୁଣା
        ChangeNotifierProvider(create: (_) => ClinicProvider()), // ନୂଆ ଯୋଡାଗଲା
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Provider.of<LanguageController>(context);

    return MaterialApp(
      title: 'Soudamini Healthcare App',
      debugShowCheckedModeBanner: false,

      // --- 1. THEME CONFIGURATION (Clean & Atomic) ---
      themeMode: ThemeMode.light,
      theme: AppTheme.light, // <--- Uses your new Token-based Light Theme
      darkTheme: AppTheme.dark, // <--- Uses your new Token-based Dark Theme
      // --- 2. LOCALIZATION ---
      locale: languageController.currentLocale,
      supportedLocales: const [Locale('en', 'US'), Locale('or', 'IN')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(),
    );
  }
}
