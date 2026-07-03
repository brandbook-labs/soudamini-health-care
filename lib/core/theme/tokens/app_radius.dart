import 'package:flutter/material.dart';

class AppRadius {
  // Pure Values
  static const double sm = 8.0;
  static const double md = 12.0; // Inputs, Buttons
  static const double lg = 16.0; // Cards
  static const double xl = 24.0; // Bottom Sheets
  static const double full = 999.0; // Pills / Circles

  // BorderRadius Objects (for convenience)
  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}
