import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:intl/intl.dart';
import 'booking_success_screen.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kPrimaryDark = Color(0xFF1E40AF);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kSlate900 = Color(0xFF0F172A);

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Centralised colour set (shared across lab screens).
class LabTheme {
  final bool isDark;
  final Color bg, card, text, subText, border, field;

  const LabTheme._({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.text,
    required this.subText,
    required this.border,
    required this.field,
  });

  factory LabTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LabTheme._(
      isDark: dark,
      bg: dark ? kDarkBg : kLightBg,
      card: dark ? kDarkCard : kLightCard,
      text: dark ? Colors.white : kSlate900,
      subText: dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      border: dark ? Colors.white10 : Colors.grey.shade200,
      field: dark ? const Color(0xFF0F0F0F) : kLightBg,
    );
  }
}

class LabBookingScreen extends StatefulWidget {
  final Map<String, dynamic> package;

  const LabBookingScreen({super.key, required this.package});

  @override
  State<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String _gender = "Male";

  // Inline validation errors
  String? _nameError, _phoneError, _ageError, _addressError;

  // OTP
  bool _isPhoneVerified = false;

  // Schedule
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = "07:00 AM - 08:00 AM";

  final List<String> _timeSlots = const [
    "06:00 AM - 07:00 AM",
    "07:00 AM - 08:00 AM",
    "08:00 AM - 09:00 AM",
    "09:00 AM - 10:00 AM",
  ];

  static const _stepTitles = [
    "Patient Details",
    "Schedule Visit",
    "Confirm Booking",
  ];

  int get _price => (widget.package['price'] ?? 0) as int;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------- LOGIC
  bool _validateStep0() {
    setState(() {
      _nameError = _nameCtrl.text.trim().isEmpty ? "Enter patient name" : null;
      final phone = _phoneCtrl.text.trim();
      _phoneError = phone.length != 10 ? "Enter a valid 10-digit number" : null;
      final age = int.tryParse(_ageCtrl.text.trim());
      _ageError = (age == null || age <= 0 || age > 120) ? "Age?" : null;
      _addressError = _addressCtrl.text.trim().isEmpty
          ? "Address is required"
          : null;
    });
    return _nameError == null &&
        _phoneError == null &&
        _ageError == null &&
        _addressError == null;
  }

  void _handleNext() {
    FocusScope.of(context).unfocus();
    if (_currentStep == 0 && !_validateStep0()) {
      HapticFeedback.mediumImpact();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 2));
  }

  void _handleBack() =>
      setState(() => _currentStep = (_currentStep - 1).clamp(0, 2));

  void _triggerBooking() {
    if (!_isPhoneVerified) {
      _showOtpBottomSheet();
    } else {
      _finalizeBooking();
    }
  }

  Future<void> _finalizeBooking() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    final bookingData = {
      'bookingId':
          'LAB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'doctorName': widget.package['name'],
      'doctorImage': "https://cdn-icons-png.flaticon.com/512/3063/3063823.png",
      'specialty': "Diagnostic Test",
      'patientName': _nameCtrl.text,
      'phone': _phoneCtrl.text,
      'date': DateFormat('dd MMM yyyy').format(_selectedDate),
      'time': _selectedSlot,
      'amount': (widget.package['price'] as num).toDouble(),
      'paymentMode': 'pay_at_home',
    };

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingSuccessScreen(appointmentDetails: bookingData),
      ),
    );
  }

  // --------------------------------------------------------------- BUILD
  @override
  Widget build(BuildContext context) {
    final t = LabTheme.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.card,
        surfaceTintColor: t.card,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: t.text),
          onPressed: _currentStep > 0
              ? _handleBack
              : () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LAB BOOKING",
              style: TextStyle(
                fontSize: 10,
                color: t.subText,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _stepTitles[_currentStep],
              style: TextStyle(
                color: t.text,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _StepProgress(currentStep: _currentStep, theme: t),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  _packageSummary(t),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(_currentStep),
                      child: _currentStep == 0
                          ? _stepForm(t)
                          : _currentStep == 1
                          ? _stepSchedule(t)
                          : _stepReview(t),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _safetyNote(t),
                ],
              ),
            ),
          ),
          _bottomBar(t),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ SECTIONS
  Widget _packageSummary(LabTheme t) {
    final isPackage = widget.package['type'] == 'Package';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.flaskConical, color: kPrimaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (widget.package['name'] ?? '').toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: t.text,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  isPackage ? "Health Package" : "Individual Test",
                  style: TextStyle(color: t.subText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _currency.format(_price),
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required LabTheme t, required Widget child}) => Container(
    width: double.infinity,

    decoration: BoxDecoration(),
    child: child,
  );

  Widget _label(String text, LabTheme t) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w900,
      color: t.subText,
      letterSpacing: 1,
    ),
  );

  // ---- STEP 0: FORM ----
  Widget _stepForm(LabTheme t) {
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("WHO IS THIS TEST FOR?", t),

          const SizedBox(height: 20),
          _field(
            label: "Full Name",
            ctrl: _nameCtrl,
            hint: "e.g. Rahul Sharma",
            icon: Icons.person_outline,
            error: _nameError,
            onChanged: (_) => _clearError('name'),
            t: t,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _field(
                  label: "Mobile",
                  ctrl: _phoneCtrl,
                  hint: "9876543210",
                  icon: Icons.phone_outlined,
                  prefixText: "+91  ",
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  error: _phoneError,
                  onChanged: (_) => _clearError('phone'),
                  t: t,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _field(
                  label: "Age",
                  ctrl: _ageCtrl,
                  hint: "25",
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  error: _ageError,
                  onChanged: (_) => _clearError('age'),
                  t: t,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _genderChip("Male", Icons.male, t),
              const SizedBox(width: 10),
              _genderChip("Female", Icons.female, t),
              const SizedBox(width: 10),
              _genderChip("Other", Icons.transgender, t),
            ],
          ),
          const SizedBox(height: 16),
          _field(
            label: "Home Address (for sample collection)",
            ctrl: _addressCtrl,
            hint: "Flat 101, City Center...",
            icon: Icons.location_on_outlined,
            error: _addressError,
            maxLines: 2,
            onChanged: (_) => _clearError('address'),
            t: t,
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              // Hook up geolocation here.
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.my_location, size: 16, color: kPrimaryColor),
                  SizedBox(width: 6),
                  Text(
                    "Use my current location",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearError(String field) {
    setState(() {
      switch (field) {
        case 'name':
          _nameError = null;
          break;
        case 'phone':
          _phoneError = null;
          break;
        case 'age':
          _ageError = null;
          break;
        case 'address':
          _addressError = null;
          break;
      }
    });
  }

  Widget _genderChip(String value, IconData icon, LabTheme t) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _gender = value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? kPrimaryColor.withValues(alpha: 0.1) : t.field,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kPrimaryColor : t.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? kPrimaryColor : t.subText),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: selected ? kPrimaryColor : t.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- STEP 1: SCHEDULE ----
  Widget _stepSchedule(LabTheme t) {
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("SELECT DATE", t),
          const SizedBox(height: 14),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index + 1));
                final selected = _isSameDay(_selectedDate, date);
                final isTomorrow = index == 0;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedDate = date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 62,
                    decoration: BoxDecoration(
                      color: selected ? kPrimaryColor : t.field,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? kPrimaryColor : t.border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isTomorrow
                              ? "TMRW"
                              : DateFormat('EEE').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white70 : t.subText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : t.text,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? Colors.white70 : t.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _label("SELECT TIME SLOT", t),
          const SizedBox(height: 6),
          Text(
            "Morning slots recommended for fasting tests.",
            style: TextStyle(fontSize: 11, color: t.subText),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
            children: _timeSlots.map((slot) {
              final selected = _selectedSlot == slot;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSlot = slot);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? kPrimaryColor.withValues(alpha: 0.1)
                        : t.field,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? kPrimaryColor : t.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 16,
                        color: selected ? kPrimaryColor : t.subText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          slot.replaceAll(" - ", "–"),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: selected ? kPrimaryColor : t.text,
                          ),
                        ),
                      ),
                      if (selected)
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: kPrimaryColor,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---- STEP 2: REVIEW ----
  Widget _stepReview(LabTheme t) {
    return Column(
      children: [
        // Schedule ticket header
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: t.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kSlate900, Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "SAMPLE COLLECTION",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('EEE, dd MMM').format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedSlot.split(" - ").first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _reviewRow("Test Package", _price.toDouble(), t.text),
                    const SizedBox(height: 8),
                    Divider(color: t.border),
                    const SizedBox(height: 8),
                    _reviewRow("Home Collection", 0, t.text, isFree: true),
                    const SizedBox(height: 8),
                    Divider(color: t.border),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Payable",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: t.text,
                          ),
                        ),
                        Text(
                          _currency.format(_price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Patient details recap with edit shortcut
        _reviewInfoCard(
          t,
          title: "Patient",
          onEdit: () => setState(() => _currentStep = 0),
          rows: [
            ["Name", _nameCtrl.text.isEmpty ? "—" : _nameCtrl.text],
            [
              "Contact",
              _phoneCtrl.text.isEmpty ? "—" : "+91 ${_phoneCtrl.text}",
            ],
            [
              "Age / Gender",
              "${_ageCtrl.text.isEmpty ? '—' : _ageCtrl.text} · $_gender",
            ],
            ["Address", _addressCtrl.text.isEmpty ? "—" : _addressCtrl.text],
          ],
        ),
      ],
    );
  }

  Widget _reviewInfoCard(
    LabTheme t, {
    required String title,
    required List<List<String>> rows,
    required VoidCallback onEdit,
  }) {
    return _card(
      t: t,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label(title.toUpperCase(), t),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onEdit();
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: kPrimaryColor),
                      SizedBox(width: 4),
                      Text(
                        "Edit",
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      r[0],
                      style: TextStyle(fontSize: 12.5, color: t.subText),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r[1],
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _reviewRow(
    String label,
    double price,
    Color textColor, {
    bool isFree = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          isFree ? "FREE" : _currency.format(price),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isFree ? kGreenColor : textColor,
          ),
        ),
      ],
    );
  }

  Widget _safetyNote(LabTheme t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 13, color: t.subText),
        const SizedBox(width: 6),
        Text(
          "Your details are private & secure",
          style: TextStyle(fontSize: 11, color: t.subText),
        ),
      ],
    );
  }

  // ---- BOTTOM BAR ----
  Widget _bottomBar(LabTheme t) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "TOTAL PAYABLE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: t.subText,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _currency.format(_price),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: t.text,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : (_currentStep == 2 ? _triggerBooking : _handleNext),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              disabledBackgroundColor: kPrimaryColor.withValues(alpha: 0.6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentStep == 2 ? "Confirm Booking" : "Proceed",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_currentStep != 2) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 18),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- HELPERS
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required LabTheme t,
    IconData? icon,
    String? prefixText,
    String? error,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: t.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          style: TextStyle(color: t.text),
          decoration: InputDecoration(
            hintText: hint,
            counterText: "",
            hintStyle: TextStyle(color: t.subText.withValues(alpha: 0.6)),
            prefixText: prefixText,
            prefixStyle: TextStyle(color: t.text, fontWeight: FontWeight.bold),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 18, color: t.subText),
            errorText: error,
            filled: true,
            fillColor: t.field,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : t.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : kPrimaryColor,
                width: 1.5,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: t.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------- OTP SHEET
  void _showOtpBottomSheet() {
    final t = LabTheme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _OtpSheet(
        theme: t,
        phone: _phoneCtrl.text,
        onVerified: () {
          Navigator.pop(ctx);
          setState(() => _isPhoneVerified = true);
          _finalizeBooking();
        },
        onChangeNumber: () {
          Navigator.pop(ctx);
          setState(() => _currentStep = 0);
        },
      ),
    );
  }
}

// -------------------------------------------------------- STEP PROGRESS
class _StepProgress extends StatelessWidget {
  final int currentStep;
  final LabTheme theme;
  const _StepProgress({required this.currentStep, required this.theme});

  static const _labels = ["Details", "Schedule", "Confirm"];
  static const _icons = [
    Icons.person_outline,
    Icons.calendar_today_outlined,
    Icons.check,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.card,
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[_node(i), if (i < 2) _connector(i)],
        ],
      ),
    );
  }

  Widget _node(int i) {
    final done = i < currentStep;
    final active = i == currentStep;
    final on = done || active;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: on ? kPrimaryColor : theme.field,
            shape: BoxShape.circle,
            border: Border.all(
              color: on ? kPrimaryColor : theme.border,
              width: 1.5,
            ),
          ),
          child: Icon(
            done ? Icons.check : _icons[i],
            size: 15,
            color: on ? Colors.white : theme.subText,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _labels[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: on ? kPrimaryColor : theme.subText,
          ),
        ),
      ],
    );
  }

  Widget _connector(int i) {
    final filled = i < currentStep;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 2,
          color: filled ? kPrimaryColor : theme.border,
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- OTP SHEET
class _OtpSheet extends StatefulWidget {
  final LabTheme theme;
  final String phone;
  final VoidCallback onVerified;
  final VoidCallback onChangeNumber;

  const _OtpSheet({
    required this.theme,
    required this.phone,
    required this.onVerified,
    required this.onChangeNumber,
  });

  @override
  State<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends State<_OtpSheet> {
  int _seconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds == 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;

    final defaultPin = PinTheme(
      width: 48,
      height: 54,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: t.text,
      ),
      decoration: BoxDecoration(
        color: t.field,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.border),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sms_outlined,
              color: kPrimaryColor,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Verify your number",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: t.subText),
              children: [
                const TextSpan(text: "Enter the 6-digit code sent to "),
                TextSpan(
                  text: "+91 ${widget.phone}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: t.text),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: widget.onChangeNumber,
            child: const Text(
              "Change number",
              style: TextStyle(fontSize: 12, color: kPrimaryColor),
            ),
          ),
          const SizedBox(height: 12),
          Pinput(
            length: 6,
            autofocus: true,
            defaultPinTheme: defaultPin,
            focusedPinTheme: defaultPin.copyWith(
              decoration: defaultPin.decoration!.copyWith(
                border: Border.all(color: kPrimaryColor, width: 1.5),
              ),
            ),
            onCompleted: (_) {
              HapticFeedback.mediumImpact();
              widget.onVerified();
            },
          ),
          const SizedBox(height: 24),
          _seconds > 0
              ? Text(
                  "Resend code in ${_seconds}s",
                  style: TextStyle(fontSize: 13, color: t.subText),
                )
              : TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _startTimer();
                  },
                  child: const Text(
                    "Resend Code",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
