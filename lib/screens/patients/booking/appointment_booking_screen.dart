import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

// 🚀 [SUPER SENIOR]: Razorpay Import
import 'package:razorpay_flutter/razorpay_flutter.dart'; 

import 'booking_success_screen.dart';
import '../../../models/doctor_model.dart';
import '../../../models/booking_models.dart';
import '../../../services/api_service.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF1E1E1E);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kSlate900 = Color(0xFF0F172A);
const Color kSlate50 = Color(0xFFF8FAFC);

class AppointmentBookingScreen extends StatefulWidget {
  final Doctor? doctor;
  final Map<String, dynamic> clinicLocation;
  final List<dynamic> clinicServices;
  final BookingSelection selection;
  final String initialAppointmentType;

  const AppointmentBookingScreen({
    super.key,
    this.doctor,
    required this.clinicLocation,
    required this.clinicServices,
    required this.selection,
    required this.initialAppointmentType,
  });

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isServicesLoading = true;
  bool _isPhoneVerified = false;

  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // 🚀 NEW: Razorpay & Payment State
  late Razorpay _razorpay;
  String _paymentMethod = "pay_at_clinic"; 
  String? _currentBookingId;
  Map<String, dynamic>? _successDataCache; 

  // Form Data
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController();

  String _selectedGender = "Male";

  // BUSINESS LOGIC STATE
  late String _appointmentType;

  // Services State
  List<dynamic> _bundledServices = [];
  List<dynamic> _additionalServices = [];
  final List<dynamic> _selectedExtraServices = [];

  @override
  void initState() {
    super.initState();

    if (widget.doctor == null) {
      _appointmentType = "service_only";
    } else {
      _appointmentType = widget.initialAppointmentType;
    }

    if (widget.clinicServices.isNotEmpty) {
      _selectedExtraServices.addAll(widget.clinicServices);
    }

    // 🚀 INITIALIZE RAZORPAY
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // 🚀 AUTO-FETCH USER DATA FROM PROVIDER
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserDataFromProvider();
    });

    _fetchClinicServices();
  }

  @override
  void dispose() {
    _razorpay.clear(); // Prevent Memory Leaks
    super.dispose();
  }

  void _loadUserDataFromProvider() {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false); 
      
      setState(() {
        _nameCtrl.text = userProvider.userName ?? '';
        _phoneCtrl.text = userProvider.userPhone ?? '';
        _ageCtrl.text = userProvider.userAge ?? '';
        
        String fetchedGender = (userProvider.userGender ?? '').toString().toLowerCase();
        if (fetchedGender == 'male' || fetchedGender == 'female' || fetchedGender == 'other') {
           _selectedGender = fetchedGender[0].toUpperCase() + fetchedGender.substring(1);
        }
        
        if (_phoneCtrl.text.isNotEmpty && _phoneCtrl.text.length >= 10) {
           _isPhoneVerified = true;
        }
      });
    } catch (e) {
      debugPrint("Provider Data Load Error: $e");
    }
  }

  bool get _isServiceOnly => _appointmentType == "service_only";

  bool get _skipStep1 {
    if (!_isServicesLoading &&
        _bundledServices.isEmpty &&
        _additionalServices.isEmpty) {
      return true;
    }
    return false;
  }

  String get _clinicId =>
      widget.clinicLocation['_id']?.toString() ??
      widget.clinicLocation['clinic']?['_id']?.toString() ??
      '';
  String get _displayClinicName =>
      widget.clinicLocation['name']?.toString() ??
      widget.clinicLocation['clinic']?['name']?.toString() ??
      widget.doctor?.clinicName ??
      "Clinic";

  Future<void> _fetchClinicServices() async {
    if (_clinicId.isEmpty) {
      setState(() => _isServicesLoading = false);
      return;
    }

    try {
      final response = await _apiService.getClinicServicesForUser(
        slug: _clinicId,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> allClinicServices = response.data['data'];

        if (mounted) {
          setState(() {
            if (widget.doctor != null && !_isServiceOnly) {
              // 🚀 SUPER SENIOR LOGIC: Correct Data Mapping
              // is_doctor_package == true -> Doctor's included/bundled services (Top)
              _bundledServices = allClinicServices
                  .where((s) => s['is_doctor_package'] == true)
                  .toList();

              // is_doctor_package == false -> Clinic Services to select (Bottom)
              _additionalServices = allClinicServices
                  .where((s) => s['is_doctor_package'] == false)
                  .toList();
            } else {
              _bundledServices = [];
              _additionalServices = allClinicServices
                  .where((s) => s['is_doctor_package'] == false)
                  .toList();
            }

            _isServicesLoading = false;
          });
        }
      } else {
        setState(() => _isServicesLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching services: $e");
      setState(() => _isServicesLoading = false);
    }
  }

  double get _baseFee {
    if (_isServiceOnly) return 0.0;

    if (_appointmentType == "follow_up") {
      double fFee =
          double.tryParse(
            widget.clinicLocation['follow_up_fees']?.toString() ?? '0',
          ) ??
          0.0;
      return fFee > 0 ? fFee : (widget.doctor?.originalPrice ?? 0).toDouble();
    }

    double cFee =
        double.tryParse(
          widget.clinicLocation['consultation_fees']?.toString() ?? '0',
        ) ??
        0.0;
    return cFee > 0 ? cFee : (widget.doctor?.price ?? 0).toDouble();
  }

  double get _totalPrice {
    double total = _baseFee;
    for (var s in _bundledServices) {
      total +=
          double.tryParse(
            s['discount_price']?.toString() ?? s['price']?.toString() ?? '0',
          ) ??
          0.0;
    }
    for (var s in _selectedExtraServices) {
      total +=
          double.tryParse(
            s['discount_price']?.toString() ?? s['price']?.toString() ?? '0',
          ) ??
          0.0;
    }
    return total;
  }

  void _toggleExtraService(dynamic service) {
    setState(() {
      final serviceId = service['id'] ?? service['_id'];
      final existingIndex = _selectedExtraServices.indexWhere(
        (s) => (s['id'] ?? s['_id']) == serviceId,
      );
      if (existingIndex >= 0) {
        _selectedExtraServices.removeAt(existingIndex);
      } else {
        _selectedExtraServices.add(service);
      }
    });
  }

  String _getReadableError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map && data.containsKey('msg')) {
          return data['msg'].toString();
        }
      }
      return "Network Error. Please check your internet connection.";
    }
    return e.toString().replaceAll("Exception: ", "");
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_nameCtrl.text.isEmpty ||
          _phoneCtrl.text.isEmpty ||
          _ageCtrl.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please fill all details"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _currentStep = _skipStep1 ? 2 : 1);
    } else if (_currentStep == 1) {
      if (_isServiceOnly && _selectedExtraServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select at least one service."),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _handleBack() {
    if (_currentStep == 2 && _skipStep1) {
      setState(() => _currentStep = 0);
    } else {
      setState(() => _currentStep = (_currentStep - 1).clamp(0, 2));
    }
  }

  Future<void> _triggerBooking() async {
    if (_totalPrice <= 0 && _selectedExtraServices.isEmpty && _isServiceOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a valid service to book."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'auth_token');

      if (token != null && token.isNotEmpty) {
        await _finalizeBooking();
      } else {
        final res = await _apiService.sendOtp(_phoneCtrl.text.trim());
        if (res.statusCode == 200) {
          String extractedOtp = "123456";
          if (res.data != null) {
            if (res.data['otp'] != null) {
              extractedOtp = res.data['otp'].toString();
            } else if (res.data['data'] != null &&
                res.data['data']['otp'] != null) {
              extractedOtp = res.data['data']['otp'].toString();
            }
          }

          if (mounted) {
            setState(() => _isLoading = false);
            _showOtpBottomSheet();
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _pinCtrl.text = extractedOtp;
            });
          }
        } else {
          throw Exception("Failed to send OTP. Please try again.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getReadableError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _finalizeBooking() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String finalDate = widget.selection.date;
      String finalTime = widget.selection.slotTime;

      final timeParts = finalTime.split('-');
      final startTime = timeParts.isNotEmpty ? timeParts.first.trim() : finalTime;
      final endTime = timeParts.length > 1 ? timeParts.last.trim() : finalTime;

      List<dynamic> allServicesToBook = [];
      if (!_isServiceOnly) {
        allServicesToBook.addAll(_bundledServices);
      }
      allServicesToBook.addAll(_selectedExtraServices);

      final Map<String, dynamic> appointmentData = {
        "appointment_type": _appointmentType,
        "clinic_id": _clinicId,
        "payment_method": _paymentMethod, 
        "date": finalDate,
        "start": startTime,
        "end": endTime,
        "patient": {
          "name": _nameCtrl.text.trim(),
          "phone": _phoneCtrl.text.trim(),
          "age": _ageCtrl.text.trim(),
          "gender": _selectedGender,
        },
        "total_cost": _totalPrice,
        "extra_services": allServicesToBook.map((s) => {
                "service_id": s['id'] ?? s['_id'],
                "name": s['name'],
                "count": 1,
              }).toList(),
      };

      if (widget.doctor != null && !_isServiceOnly) {
        appointmentData["doctor_id"] = widget.doctor!.id;
        appointmentData["slot"] = widget.selection.slotId;
      }

      final response = await _apiService.bookAppointment(
        tokenKey: 'auth_token', 
        bookingData: appointmentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = response.data ?? {};
        final responseData = responseBody['data'] ?? responseBody;

        // 🚀 SUPER SENIOR FIX: ନିଶ୍ଚିତ କରନ୍ତୁ ଯେ 'appointment_id' ହିଁ MongoDB ର ପ୍ରକୃତ ID ଅଟେ।
        final String bookingId = responseData['appointment_id']?.toString() ?? 
                                 responseData['_id']?.toString() ?? '';
                                 
        final String displayId = responseData['display_booking_id']?.toString() ?? 
                                 responseData['booking_id']?.toString() ?? bookingId;

        final dynamic patientData = responseData['patient'];
        final String pName = patientData != null ? patientData['name'] ?? _nameCtrl.text : _nameCtrl.text;
        final String pPhone = patientData != null ? patientData['phone'] ?? _phoneCtrl.text : _phoneCtrl.text;

        _successDataCache = {
          'bookingId': displayId,
          'patientName': pName,
          'phone': pPhone,
          'doctorName': widget.doctor?.name ?? _displayClinicName,
          'doctorImage': widget.doctor?.image ?? widget.clinicLocation['logo'] ?? widget.clinicLocation['clinic']?['logo'] ?? "",
          'specialty': _isServiceOnly ? "Medical Service" : widget.doctor?.specialty ?? "",
          'date': responseData['date'] ?? finalDate,
          'time': "${responseData['start'] ?? startTime} - ${responseData['end'] ?? endTime}",
          'amount': responseData['total_cost'] ?? _totalPrice,
          'paymentMode': responseData['payment_method'] ?? _paymentMethod,
        };

        if (_paymentMethod == 'online_razorpay') {
           _currentBookingId = bookingId; 
           
           String razorpayOrderId = responseData['razorpay_order_id']?.toString() ?? '';
           
           if(razorpayOrderId.isEmpty) {
              throw Exception("Razorpay Order ID missing from backend.");
           }

           int amountInPaise = (responseData['amount_in_paise'] ?? (_totalPrice * 100)).toInt();

           var options = {
             'key': 'rzp_test_Sg3EOvsynXxvMp', // ⚠️ REPLACE WITH REAL KEY
             'amount': amountInPaise,
             'name': _displayClinicName,
             'description': 'Appointment Booking',
             'order_id': razorpayOrderId,
             'prefill': {
               'contact': _phoneCtrl.text.trim(),
               'name': _nameCtrl.text.trim(),
             },
             'theme': { 'color': '#1660FF' }
           };

           if (mounted) setState(() => _isLoading = false);

           try {
             _razorpay.open(options);
           } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error opening payment gateway: $e")));
           }
        } else {
           if (mounted) setState(() => _isLoading = false);
           if (!mounted) return;
           Navigator.pushReplacement(
             context,
             MaterialPageRoute(
               builder: (context) => BookingSuccessScreen(appointmentDetails: _successDataCache!),
             ),
           );
        }

      } else {
        throw Exception("Failed to book appointment.");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getReadableError(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } 
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentBookingId == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final verifyRes = await _apiService.verifyAppointmentPayment(
        tokenKey: 'auth_token',
        bookingId: _currentBookingId!, 
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (mounted) setState(() => _isLoading = false);

      if (verifyRes.statusCode == 200 || verifyRes.statusCode == 201) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BookingSuccessScreen(appointmentDetails: _successDataCache!),
          ),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Verification Failed!"), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Cancelled."),
          backgroundColor: Colors.red,
        )
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _isLoading = false);
  }

  void _showOtpBottomSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDarkMode ? kDarkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : kSlate900;
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;
    final inputFill = isDarkMode ? kDarkBg : kLightBg;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade300;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetColor,
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Security Check",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Auto-verifying the code sent to ${_phoneCtrl.text}...",
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Pinput(
              length: 6,
              controller: _pinCtrl,
              autofocus: true,
              onCompleted: (pin) async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final verifyRes = await _apiService.verifyOtp(
                    _phoneCtrl.text.trim(),
                    pin,
                  );
                  if (verifyRes.statusCode == 200) {
                    final String newToken =
                        verifyRes.data['token'] ??
                        verifyRes.data['data']?['token'] ??
                        '';
                    if (newToken.isNotEmpty)
                      await _storage.write(key: 'auth_token', value: newToken);
                    if (mounted) {
                      _isPhoneVerified = true;
                      _finalizeBooking();
                    }
                  } else {
                    throw Exception("Invalid OTP Code");
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getReadableError(e)),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              defaultPinTheme: PinTheme(
                width: 56,
                height: 56,
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: inputFill,
                ),
              ),
              focusedPinTheme: PinTheme(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(color: kPrimaryColor, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: sheetColor,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppPalette.neutralWhite,
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
              "PROCESS",
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              _currentStep == 0
                  ? "Patient Info"
                  : _currentStep == 1
                  ? "Care Options"
                  : "Confirmation",
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
            children: List.generate(_skipStep1 ? 2 : 3, (index) {
              int logicalStep = _currentStep == 2 && _skipStep1
                  ? 1
                  : _currentStep;
              return Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: index <= logicalStep
                      ? kPrimaryColor
                      : isDarkMode
                      ? Colors.white24
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
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
                  _buildHeaderCard(
                    cardColor,
                    textColor,
                    subTextColor,
                    borderColor,
                  ),
                  const SizedBox(height: 24),

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
                        ? _buildStep1Services(
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                          )
                        : _buildStep2Review(
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                          ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              border: Border(top: BorderSide(color: borderColor)),
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
                      "₹${_totalPrice.toStringAsFixed(0)}",
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
                              _currentStep == 2 
                                  ? (_paymentMethod == 'online_razorpay' ? "Pay Online" : "Confirm Booking") 
                                  : "Proceed",
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

  Widget _buildHeaderCard(Color c, Color t, Color st, Color b) => widget.doctor != null && !_isServiceOnly ? _buildDoctorCard(c, t, st, b) : _buildClinicCard(c, t, st, b);
  Widget _buildDoctorCard(Color c, Color t, Color st, Color b) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppPalette.success100, borderRadius: BorderRadius.circular(12), border: Border.all(color: b)), child: Row(children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: AppPalette.neutralWhite, borderRadius: BorderRadius.circular(12), image: widget.doctor!.image.isNotEmpty && !widget.doctor!.image.contains("ui-avatars") ? DecorationImage(image: NetworkImage(widget.doctor!.image), fit: BoxFit.cover) : null), child: widget.doctor!.image.isEmpty || widget.doctor!.image.contains("ui-avatars") ? Icon(LucideIcons.stethoscope, color: kPrimaryColor.withValues(alpha: 0.8), size: 30) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppPalette.success200, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppPalette.success200)), child: Text(_appointmentType.toUpperCase().replaceAll('_', ' '), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: st, letterSpacing: 0.5))), const Spacer(), const Icon(Icons.star, size: 14, color: Colors.amber), Text(" ${widget.doctor!.rating}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: t))]), const SizedBox(height: 6), Text(widget.doctor!.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: t)), Text("${widget.doctor!.specialty} • $_displayClinicName", style: TextStyle(color: st, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)]))]));
  Widget _buildClinicCard(Color c, Color t, Color st, Color b) {
    String cImage = widget.clinicLocation['logo'] ?? widget.clinicLocation['clinic']?['logo'] ?? "";
    bool hasImg = cImage.isNotEmpty && !cImage.contains("ui-avatars") && !cImage.contains("placeholder");
    String cPhone = "";
    final dynamic pData = widget.clinicLocation['phone'] ?? widget.clinicLocation['clinic']?['phone'];
    if (pData is List && pData.isNotEmpty) cPhone = pData[0].toString();
    else if (pData != null) cPhone = pData.toString();
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16), border: Border.all(color: b)), child: Row(children: [Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), image: hasImg ? DecorationImage(image: NetworkImage(cImage), fit: BoxFit.cover) : null), child: !hasImg ? Icon(LucideIcons.building, color: kPrimaryColor.withValues(alpha: 0.5), size: 30) : null), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kSlate50, borderRadius: BorderRadius.circular(6), border: Border.all(color: b)), child: Text("CLINIC", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: st, letterSpacing: 0.5))), const SizedBox(height: 6), Text(_displayClinicName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: t), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), if (cPhone.isNotEmpty) Row(children: [Icon(LucideIcons.phone, size: 12, color: st), const SizedBox(width: 4), Text(cPhone, style: TextStyle(color: st, fontSize: 12, fontWeight: FontWeight.w600))])]))]));
  }
  Widget _buildStep0Form(Color c, Color t, Color st, Color b, Color iFill) => Container(decoration: BoxDecoration(color: c), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("PATIENT DETAILS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: st, letterSpacing: 1)), const SizedBox(height: 20), _buildTextField("Full Legal Name", _nameCtrl, "e.g. Sritam Sharma", t, st, b, iFill), const SizedBox(height: 20), Row(children: [Expanded(flex: 2, child: _buildTextField("Mobile Number", _phoneCtrl, "9692664009", t, st, b, iFill, isPhone: true)), const SizedBox(width: 8), Expanded(child: _buildTextField("Age", _ageCtrl, "27", t, st, b, iFill, isNumber: true))]), const SizedBox(height: 20), Text("Gender", style: TextStyle(fontSize: 13, color: t, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Row(children: ["Male", "Female", "Other"].map((g) => Expanded(child: Padding(padding: EdgeInsets.only(right: g != "Other" ? 0.0 : 0), child: ChoiceChip(label: Text(g), labelStyle: TextStyle(fontSize: 12, fontWeight: _selectedGender == g ? FontWeight.bold : FontWeight.normal, color: _selectedGender == g ? kPrimaryColor : t), selected: _selectedGender == g, onSelected: (v) => setState(() => _selectedGender = g), backgroundColor: iFill, selectedColor: kPrimaryColor.withValues(alpha: 0.1), showCheckmark: false, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: _selectedGender == g ? kPrimaryColor : b)))))).toList()), const SizedBox(height: 24), Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppPalette.success50, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppPalette.success100)), child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(shape: BoxShape.circle), child: const Icon(LucideIcons.clock, size: 24, color: kPrimaryColor)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Slot Reserved", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppPalette.neutralBlack)), const SizedBox(height: 2), Text("${widget.selection.date}, ${widget.selection.slotTime}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kSlate900))]))]))]));
  Widget _buildTextField(String l, TextEditingController c, String h, Color t, Color st, Color b, Color iF, {bool isNumber = false, bool isPhone = false}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: TextStyle(fontSize: 13, color: t, fontWeight: FontWeight.bold)), const SizedBox(height: 8), TextField(controller: c, keyboardType: isNumber || isPhone ? TextInputType.number : TextInputType.text, style: TextStyle(fontWeight: FontWeight.w600, color: t), decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: st.withValues(alpha: 0.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), filled: true, fillColor: iF, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: b)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: b)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: kPrimaryColor, width: 2)), suffixIcon: isPhone && _isPhoneVerified ? const Icon(LucideIcons.checkCircle, color: kGreenColor, size: 20) : null))]);
  
  // 🚀 GOAL 2: PREMIUM SERVICE LIST UI
  Widget _buildStep1Services(Color c, Color t, Color st, Color b) {
    if (_isServicesLoading) return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!_isServiceOnly) ...[
        Text("APPOINTMENT TYPE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: st, letterSpacing: 1)), const SizedBox(height: 12), 
        Row(children: [Expanded(child: _buildTypeToggle("Consultation", "consultation", t, c, b)), const SizedBox(width: 12), Expanded(child: _buildTypeToggle("Follow-up", "follow_up", t, c, b))]), 
        const SizedBox(height: 32)
      ], 
      
      // 🚀 Top Section: DOCTOR SERVICES (is_doctor_package == true)
      if (_bundledServices.isNotEmpty && !_isServiceOnly) ...[
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Row(children: [const Icon(LucideIcons.stethoscope, size: 16, color: kPrimaryColor), const SizedBox(width: 8), Text("DOCTOR SERVICES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: t))])), 
        Container(clipBehavior: Clip.hardEdge, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(16), border: Border.all(color: b)), child: Column(children: [
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: kSlate900), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(LucideIcons.package, color: Colors.white, size: 18)), const SizedBox(width: 12), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Doctor Package", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), Text("Includes Consultation + Checkups", style: TextStyle(fontSize: 11, color: Colors.white70))])]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text("BASE PRICE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54)), Text("₹${_baseFee + _bundledServices.fold(0.0, (sum, item) => sum + (double.tryParse(item['discount_price']?.toString() ?? item['price']?.toString() ?? '0') ?? 0.0))}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))])])), 
          Padding(padding: const EdgeInsets.all(20), child: Column(children: [
            _buildPackageItem(_appointmentType == "consultation" ? "Doctor Consultation" : "Doctor Follow-up", _baseFee, isBase: true, textColor: t), const SizedBox(height: 4), Divider(color: b), const SizedBox(height: 4), 
            ..._bundledServices.map((s) => _buildPackageItem(s['name'] ?? '', double.tryParse(s['discount_price']?.toString() ?? s['price']?.toString() ?? '0') ?? 0, isBase: false, textColor: t, originalPrice: double.tryParse(s['price']?.toString() ?? '0') ?? 0))
          ]))
        ])), 
        const SizedBox(height: 32)
      ], 

      // 🚀 Bottom Section: CLINIC SERVICES (is_doctor_package == false) - Selectable
      if (_additionalServices.isNotEmpty) Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Row(children: [const Icon(LucideIcons.building, size: 16, color: Colors.amber), const SizedBox(width: 8), Text("CLINIC SERVICES (Select 1 or more)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1, color: t))])), 
        ..._additionalServices.map((s) {
          bool isSelected = _selectedExtraServices.any((ext) => (ext['id'] ?? ext['_id']) == (s['id'] ?? s['_id']));
          double price = double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
          double discountPrice = double.tryParse(s['discount_price']?.toString() ?? price.toString()) ?? 0.0;
          double discountPercentage = double.tryParse(s['discount_percentage']?.toString() ?? '0') ?? 0.0;
          
          return GestureDetector(onTap: () => _toggleExtraService(s), child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isSelected ? kPrimaryColor.withValues(alpha: 0.1) : c, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? kPrimaryColor : b, width: isSelected ? 1.5 : 1)), child: Row(children: [
            Icon(isSelected ? LucideIcons.checkCircle : LucideIcons.circle, color: isSelected ? kPrimaryColor : st, size: 22), const SizedBox(width: 16), 
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? kPrimaryColor : t)),
                if (discountPercentage > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: kGreenColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: kGreenColor.withValues(alpha: 0.3))),
                    child: Text("${discountPercentage.toInt()}% OFF", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kGreenColor)),
                  )
                ]
              ],
            )), 
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(discountPrice == 0 ? "FREE" : "₹${discountPrice.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: t)), 
              if (price > discountPrice) Text("₹${price.toInt()}", style: TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: st, fontWeight: FontWeight.bold))
            ])
          ])));
        })
      ])
    ]);
  }
  Widget _buildTypeToggle(String l, String v, Color t, Color c, Color b) {
    bool isSelected = _appointmentType == v;
    return GestureDetector(onTap: () => setState(() => _appointmentType = v), child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isSelected ? kPrimaryColor : c, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? kPrimaryColor : b)), alignment: Alignment.center, child: Text(l, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : t))));
  }
  Widget _buildPackageItem(String n, double p, {required bool isBase, required Color textColor, double originalPrice = 0}) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Row(children: [Icon(isBase ? LucideIcons.checkCircle2 : LucideIcons.plusCircle, size: 18, color: isBase ? kPrimaryColor : kGreenColor), const SizedBox(width: 12), Expanded(child: Text(n, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor), overflow: TextOverflow.ellipsis))])), Row(children: [if (originalPrice > p && p != 0) Padding(padding: const EdgeInsets.only(right: 6.0), child: Text("₹${originalPrice.toInt()}", style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey, fontWeight: FontWeight.bold))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kGreenColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)), child: Text(isBase ? "₹${p.toInt()}" : "+ ₹${p.toInt()}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kGreenColor)))])]));
  
  Widget _buildStep2Review(Color cardColor, Color textColor, Color subTextColor, Color borderColor) {
    return Column(children: [
      Container(decoration: BoxDecoration(), child: Column(children: [
        Container(decoration: const BoxDecoration(color: AppPalette.neutralWhite), child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("Appointment Details", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)), 
              const SizedBox(height: 6), 
              Text(widget.selection.date, style: const TextStyle(color: AppPalette.neutralBlack, fontSize: 22, fontWeight: FontWeight.bold))
            ]), 
            Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(border: Border.all(color: AppPalette.neutralBlack.withValues(alpha: 0.5), width: 1), borderRadius: BorderRadius.circular(12)), child: Text(widget.selection.slotTime, style: const TextStyle(color: AppPalette.neutralBlack, fontWeight: FontWeight.bold, fontSize: 13)))
          ]), 
          const SizedBox(height: 8), 
          const Divider(color: Colors.black12), 
          const SizedBox(height: 16), 
          Row(children: [Text(_nameCtrl.text, style: const TextStyle(color: AppPalette.neutralBlack, fontSize: 22, fontWeight: FontWeight.w900))])
        ])), 
        Padding(padding: const EdgeInsets.fromLTRB(0, 10, 0, 0), child: Column(children: [
          if (!_isServiceOnly) ...[_buildReviewRow(_appointmentType == "consultation" ? "Doctor Consultation" : "Doctor Follow-up", _baseFee, textColor: textColor), const SizedBox(height: 8), Divider(color: borderColor), const SizedBox(height: 8)], 
          if (_bundledServices.isNotEmpty && !_isServiceOnly) ...[Align(alignment: Alignment.centerLeft, child: Text("DOCTOR SERVICES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: subTextColor))), const SizedBox(height: 12), ..._bundledServices.map((s) => _buildReviewRow(s['name'] ?? '', double.tryParse(s['discount_price']?.toString() ?? s['price']?.toString() ?? '0') ?? 0, isIncluded: true, textColor: textColor)), const SizedBox(height: 8), Divider(color: borderColor), const SizedBox(height: 8)], 
          if (_selectedExtraServices.isNotEmpty) ...[Align(alignment: Alignment.centerLeft, child: Text("CLINIC SERVICES", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: subTextColor, letterSpacing: 0.5))), const SizedBox(height: 12), ..._selectedExtraServices.map((s) => _buildReviewRow(s['name'] ?? '', double.tryParse(s['discount_price']?.toString() ?? s['price']?.toString() ?? '0') ?? 0, textColor: textColor)), const SizedBox(height: 8), Divider(color: borderColor), const SizedBox(height: 8)], 
          const SizedBox(height: 8), 
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total Payable", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: textColor)), Text("₹${_totalPrice.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: kPrimaryColor))])
        ]))
      ])), 
      const SizedBox(height: 24), 
      Text("SELECT PAYMENT METHOD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: subTextColor, letterSpacing: 1.5)), 
      const SizedBox(height: 12), 
      
      Row(children: [
        // କେବଳ "Pay at Clinic" ଅପସନ୍ ଖୋଲା ଅଛି
        Expanded(child: GestureDetector(onTap: () => setState(() => _paymentMethod = "pay_at_clinic"), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: _paymentMethod == "pay_at_clinic" ? const Color(0xFFEFF6FF) : cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentMethod == "pay_at_clinic" ? kPrimaryColor : borderColor, width: _paymentMethod == "pay_at_clinic" ? 2 : 1)), child: Column(children: [Icon(LucideIcons.store, color: _paymentMethod == "pay_at_clinic" ? kPrimaryColor : subTextColor), const SizedBox(height: 8), Text("Pay at Clinic", style: TextStyle(fontWeight: FontWeight.bold, color: _paymentMethod == "pay_at_clinic" ? kPrimaryColor : textColor, fontSize: 13))])))), 
        
        // 🚀 ଏଠାରୁ "Pay Online" କୁ କମେଣ୍ଟ୍ (Comment out) କରାଯାଇଛି
        /* 
        const SizedBox(width: 16), 
        Expanded(child: GestureDetector(onTap: () => setState(() => _paymentMethod = "online_razorpay"), child: Container(padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(color: _paymentMethod == "online_razorpay" ? const Color(0xFFFDF4FF) : cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: _paymentMethod == "online_razorpay" ? Colors.purple.shade600 : borderColor, width: _paymentMethod == "online_razorpay" ? 2 : 1)), child: Column(children: [Icon(LucideIcons.creditCard, color: _paymentMethod == "online_razorpay" ? Colors.purple.shade600 : subTextColor), const SizedBox(height: 8), Text("Pay Online", style: TextStyle(fontWeight: FontWeight.bold, color: _paymentMethod == "online_razorpay" ? Colors.purple.shade600 : textColor, fontSize: 13))])))) 
        */
      ]), 
      
      const SizedBox(height: 20)
    ]);
  }
  Widget _buildReviewRow(String l, double p, {bool isIncluded = false, required Color textColor}) => Padding(padding: const EdgeInsets.only(bottom: 12.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(l, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500))), if (isIncluded) const Text("INCLUDED", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: kGreenColor)) else Text("₹${p.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor))]));
}