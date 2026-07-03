import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pinput/pinput.dart';
import 'package:intl/intl.dart';
import 'booking_success_screen.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kSlate900 = Color(0xFF0F172A);

class LabBookingScreen extends StatefulWidget {
  final Map<String, dynamic> package; // The selected package/test

  const LabBookingScreen({super.key, required this.package});

  @override
  State<LabBookingScreen> createState() => _LabBookingScreenState();
}

class _LabBookingScreenState extends State<LabBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;

  // Form Data
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _addressCtrl =
      TextEditingController(); // Specific to Labs (Home Sample)

  // OTP State
  bool _isPhoneVerified = false;

  // Date Selection
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = "07:00 AM - 08:00 AM";

  final List<String> _timeSlots = [
    "06:00 AM - 07:00 AM",
    "07:00 AM - 08:00 AM",
    "08:00 AM - 09:00 AM",
    "09:00 AM - 10:00 AM",
  ];

  @override
  Widget build(BuildContext context) {
    // 1. Detect Theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    final inputFillColor = isDarkMode ? kDarkBg : kLightBg;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.chevronLeft, color: textColor),
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
                color: subTextColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _currentStep == 0
                  ? "Patient Details"
                  : _currentStep == 1
                  ? "Schedule Visit"
                  : "Confirm Booking",
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? kPrimaryColor
                      : isDarkMode
                      ? Colors.white24
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 1. PACKAGE SUMMARY CARD
                  _buildPackageSummary(
                    cardColor,
                    textColor,
                    subTextColor,
                    borderColor,
                  ),
                  const SizedBox(height: 24),

                  // 2. DYNAMIC STEPS
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0
                        ? _buildStep0Form(
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                            inputFillColor,
                          )
                        : _currentStep == 1
                        ? _buildStep1Schedule(
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                            isDarkMode,
                          )
                        : _buildStep2Review(
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                            isDarkMode,
                          ),
                  ),
                ],
              ),
            ),
          ),

          // 3. BOTTOM BAR
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: borderColor)),
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
                        color: subTextColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'en_IN',
                        symbol: '₹',
                        decimalDigits: 0,
                      ).format(widget.package['price']),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: textColor,
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
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
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
          ),
        ],
      ),
    );
  }

  // --- LOGIC ---

  void _handleNext() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty ||
          _phoneCtrl.text.isEmpty ||
          _addressCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill all details including address"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }
    setState(() => _currentStep = (_currentStep + 1).clamp(0, 2));
  }

  void _handleBack() {
    setState(() => _currentStep = (_currentStep - 1).clamp(0, 2));
  }

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

    // Mock Success Data
    final bookingData = {
      'bookingId':
          'LAB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      'doctorName': widget.package['name'], // Using package name as 'service'
      'doctorImage':
          "https://cdn-icons-png.flaticon.com/512/3063/3063823.png", // Generic Lab Icon
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

  void _showOtpBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? kDarkCard
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 32,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Verify Phone",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text("Enter code sent to ${_phoneCtrl.text}"),
            const SizedBox(height: 32),
            Pinput(
              length: 6,
              onCompleted: (pin) {
                Navigator.pop(ctx);
                setState(() => _isPhoneVerified = true);
                _finalizeBooking();
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildPackageSummary(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.flaskConical, color: kPrimaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.package['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.package['type'] == 'Package'
                      ? "Health Package"
                      : "Individual Test",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep0Form(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    Color inputFill,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PATIENT DETAILS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: subTextColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 20),
          _buildTextField(
            "Full Name",
            _nameCtrl,
            "e.g. Rahul Sharma",
            textColor,
            subTextColor,
            borderColor,
            inputFill,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildTextField(
                  "Mobile",
                  _phoneCtrl,
                  "9876543210",
                  textColor,
                  subTextColor,
                  borderColor,
                  inputFill,
                  isPhone: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  "Age",
                  _ageCtrl,
                  "25",
                  textColor,
                  subTextColor,
                  borderColor,
                  inputFill,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            "Home Address (For Collection)",
            _addressCtrl,
            "Flat 101, City Center...",
            textColor,
            subTextColor,
            borderColor,
            inputFill,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Schedule(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELECT DATE",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: subTextColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 70,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index + 1));
                final isSelected = _selectedDate.day == date.day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? kPrimaryColor
                          : (isDarkMode
                                ? Colors.white10
                                : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : borderColor,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : subTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textColor,
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
          Text(
            "SELECT TIME SLOT",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: subTextColor,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _timeSlots.map((slot) {
              final isSelected = _selectedSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedSlot = slot),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? kPrimaryColor
                        : (isDarkMode ? Colors.white10 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? kPrimaryColor : borderColor,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Review(
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDarkMode,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: kSlate900,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormat('dd MMM').format(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedSlot,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildReviewRow(
                      "Test Package",
                      widget.package['price'].toDouble(),
                      textColor,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: borderColor),
                    const SizedBox(height: 8),
                    _buildReviewRow(
                      "Home Collection",
                      0,
                      textColor,
                      isFree: true,
                    ),
                    const SizedBox(height: 8),
                    Divider(color: borderColor),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total Payable",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "₹${widget.package['price']}",
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
      ],
    );
  }

  Widget _buildReviewRow(
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
          isFree ? "FREE" : "₹$price",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isFree ? kGreenColor : textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String hint,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    Color inputFill, {
    bool isPhone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: borderColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
