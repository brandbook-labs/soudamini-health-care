import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  // Default to English
  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  LanguageController() {
    _loadLanguage();
  }

  // --- FIX: Public method to change language (Called by LanguageScreen) ---
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;

    _currentLocale = locale;
    notifyListeners(); // Updates the UI instantly

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  // Helper for the Toggle Button in AppBar
  void toggleLanguage() {
    if (_currentLocale.languageCode == 'en') {
      changeLanguage(const Locale('or', 'IN')); // Switch to Odia
    } else {
      changeLanguage(const Locale('en', 'US')); // Switch to English
    }
  }

  // Load saved language on startup
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('language_code');

    if (savedCode != null) {
      if (savedCode == 'or') {
        _currentLocale = const Locale('or', 'IN');
      } else {
        _currentLocale = const Locale('en', 'US');
      }
      notifyListeners();
    }
  }
}
