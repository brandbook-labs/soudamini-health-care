import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// 🚀 ଆପଣଙ୍କ ପ୍ରୋଜେକ୍ଟର ଫାଇଲ୍ ପାଥ୍ ଅନୁଯାୟୀ ଇମ୍ପୋର୍ଟ କରିବେ
import '../../../services/api_service.dart';
import 'package:my_new_app/screens/patients/booking/booking_success_screen.dart';
import 'package:my_new_app/screens/patients/providers/user_provider.dart'; // 🚀 ୟୁଜର୍ ପ୍ରୋଭାଇଡର୍

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kOrangeColor = Color(0xFFEA580C);

// --- UTILS ---
final currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

class LabTheme {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color text;
  final Color subText;
  final Color border;
  final Color field;
  final Color muted;

  const LabTheme._({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.text,
    required this.subText,
    required this.border,
    required this.field,
    required this.muted,
  });

  factory LabTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LabTheme._(
      isDark: dark,
      bg: dark ? kDarkBg : kLightBg,
      card: dark ? kDarkCard : kLightCard,
      text: dark ? Colors.white : const Color(0xFF0F172A),
      subText: dark ? Colors.grey.shade400 : Colors.grey.shade500,
      border: dark ? Colors.white10 : Colors.grey.shade200,
      field: dark ? Colors.grey.shade900 : Colors.grey.shade100,
      muted: dark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF1F5F9),
    );
  }
}

// --- MAIN SCREEN ---
class LabListingScreen extends StatefulWidget {
  final String clinicSlug;

  const LabListingScreen({
    super.key,
    this.clinicSlug = 'soudamini-health-care',
  });

  @override
  State<LabListingScreen> createState() => _LabListingScreenState();
}

class _LabListingScreenState extends State<LabListingScreen> {
  final ApiService _apiService = ApiService();

  final Set<String> _cartIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  bool _isLoading = true;
  String? _errorMessage;
  
  // 🚀 SENIOR DEV LOGIC: Split Lists for Premium UI
  List<Map<String, dynamic>> _packages = []; // is_doctor_package = true
  List<Map<String, dynamic>> _individualTests = []; // is_doctor_package = false

  String? _clinicId;
  Map<String, dynamic>? _operatingHours;

  @override
  void initState() {
    super.initState();
    _fetchClinicServices();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClinicServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getAdminClinicServices();

      if (response.statusCode == 200 && response.data?['data'] != null) {
        final data = response.data?['data'];

        _clinicId = data['clinic_id'];
        _operatingHours = data['operating_hours'];

        final List rawServices = data['services'] ?? [];
        
        final List<Map<String, dynamic>> tempPackages = [];
        final List<Map<String, dynamic>> tempTests = [];

        for (var s in rawServices) {
          if (s['isActive'] != true || s['status'] != 'approved') continue;

          double mrp = (s['price'] ?? 0).toDouble();
          double discountPrice = s['discount_price'] != null
              ? (s['discount_price']).toDouble()
              : mrp;
          double currentPrice = discountPrice > 0 ? discountPrice : mrp;

          int discountPercentage = 0;
          if (mrp > currentPrice) {
            discountPercentage = (((mrp - currentPrice) / mrp) * 100).round();
          }

          final mappedItem = {
            'id': s['_id'],
            'name': s['name'],
            'price': currentPrice,
            'mrp': mrp,
            'discount': discountPercentage,
            'is_doctor_package': s['is_doctor_package'] ?? false,
            'fasting': "Consult Clinic",
            'reportTime': "24 Hrs",
            'features': <String>["Consultation", "Report"], // Dummy features for UI
            'tags': s['is_doctor_package'] == true ? ["bestseller"] : [],
          };

          // 🚀 Split data for Premium UI rendering
          if (s['is_doctor_package'] != true) {
            tempPackages.add(mappedItem);
          } else {
            tempTests.add(mappedItem);
          }
        }

        setState(() {
          _packages = tempPackages;
          _individualTests = tempTests;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to load services");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Something went wrong. Please try again.";
        _isLoading = false;
      });
      debugPrint("Error fetching lab services: $e");
    }
  }

  void _toggleItem(String id) {
    setState(() {
      _cartIds.contains(id) ? _cartIds.remove(id) : _cartIds.add(id);
    });
  }

  int _priceOf(String id) {
    final allItems = [..._packages, ..._individualTests];
    final item = allItems.firstWhere((e) => e['id'] == id, orElse: () => {});
    if (item.isEmpty) return 0;
    final price = item['price'];
    return price is int ? price : (price as double).round();
  }

  double get _cartTotal => _cartIds.fold(0.0, (sum, id) => sum + _priceOf(id));

  List<Map<String, dynamic>> get _filteredPackages => _query.isEmpty 
    ? _packages 
    : _packages.where((item) => item['name'].toString().toLowerCase().contains(_query)).toList();

  List<Map<String, dynamic>> get _filteredTests => _query.isEmpty 
    ? _individualTests 
    : _individualTests.where((item) => item['name'].toString().toLowerCase().contains(_query)).toList();


  // 🚀 SMART HOURLY SLOTS GENERATOR (Filters past time for today)
  List<Map<String, String>> _generateHourlySlots(String openStr, String closeStr, DateTime selectedDate) {
    List<Map<String, String>> slots = [];
    try {
      final openTime = DateFormat("HH:mm").parse(openStr);
      final closeTime = DateFormat("HH:mm").parse(closeStr);
      
      DateTime current = openTime;
      final now = DateTime.now();
      
      // Check if selected date is today
      final isToday = selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;

      while (current.isBefore(closeTime)) {
        DateTime next = current.add(const Duration(hours: 1));
        if (next.isAfter(closeTime)) break;
        
        // 🚀 If today, only show slots that START in the future
        bool showSlot = true;
        if (isToday) {
           final slotStartDateTime = DateTime(now.year, now.month, now.day, current.hour, current.minute);
           if (slotStartDateTime.isBefore(now)) {
             showSlot = false;
           }
        }

        if (showSlot) {
          slots.add({
            "start": DateFormat("HH:mm").format(current),
            "end": DateFormat("HH:mm").format(next),
            "display": "${DateFormat("h:mm a").format(current)} - ${DateFormat("h:mm a").format(next)}"
          });
        }
        
        current = next;
      }
    } catch (e) {
      debugPrint("Error generating hourly slots: $e");
    }
    return slots;
  }

  // =========================================================================
  // 🚀 DYNAMIC 7-DAY BOOKING MODAL
  // =========================================================================
  void _showBookingModal(LabTheme theme) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String gender = "Male";

    // 🚀 ୧. Load User Data from Provider
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false); 
      nameCtrl.text = userProvider.userName ?? '';
      phoneCtrl.text = userProvider.userPhone ?? '';
      ageCtrl.text = userProvider.userAge ?? '';
      
      String fetchedGender = (userProvider.userGender ?? '').toString().toLowerCase();
      if (fetchedGender == 'male' || fetchedGender == 'female' || fetchedGender == 'other') {
         gender = fetchedGender[0].toUpperCase() + fetchedGender.substring(1);
      }
    } catch (e) {
      debugPrint("Provider Data Load Error: $e");
    }

    final List<DateTime> next7Days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
    DateTime selectedDateObj = next7Days.first;
    Map<String, String>? selectedSlot;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final String dateStr = DateFormat('yyyy-MM-dd').format(selectedDateObj);
          final String dayName = DateFormat('EEEE').format(selectedDateObj);

          String openTime = "06:00";
          String closeTime = "22:00";
          
          if (_operatingHours != null && _operatingHours!['timings'] is Map) {
            final timingsMap = _operatingHours!['timings'] as Map<String, dynamic>;
            if (timingsMap.containsKey(dayName) && timingsMap[dayName] is Map) {
              final dayTiming = timingsMap[dayName] as Map<String, dynamic>;
              openTime = dayTiming['open']?.toString() ?? "06:00";
              closeTime = dayTiming['close']?.toString() ?? "22:00";
            }
          }

          // 🚀 Pass selected date to filter past times if today
          final hourlySlots = _generateHourlySlots(openTime, closeTime, selectedDateObj);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(color: theme.card, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Patient Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.text)),
                        IconButton(icon: Icon(Icons.close, color: theme.text), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(nameCtrl, "Patient Name", LucideIcons.user, theme),
                    const SizedBox(height: 12),
                    _buildTextField(phoneCtrl, "Phone Number", LucideIcons.phone, theme, isNumber: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(ageCtrl, "Age", LucideIcons.calendar, theme, isNumber: true)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(color: theme.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.border)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: gender, dropdownColor: theme.card, style: TextStyle(color: theme.text, fontWeight: FontWeight.w500), isExpanded: true,
                                items: ["Male", "Female", "Other"].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                                onChanged: (val) => setModalState(() => gender = val!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text("Select Date (Next 7 Days)", style: TextStyle(fontWeight: FontWeight.bold, color: theme.text)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(), itemCount: next7Days.length,
                        itemBuilder: (context, i) {
                          final d = next7Days[i];
                          final isSel = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(selectedDateObj);
                          return GestureDetector(
                            onTap: () => setModalState(() { selectedDateObj = d; selectedSlot = null; }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(color: isSel ? kPrimaryColor : theme.field, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSel ? kPrimaryColor : theme.border)),
                              alignment: Alignment.center,
                              child: Text(i == 0 ? "Today" : DateFormat('E, d MMM').format(d), style: TextStyle(color: isSel ? Colors.white : theme.text, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text("Select Time Slot", style: TextStyle(fontWeight: FontWeight.bold, color: theme.text)),
                    const SizedBox(height: 12),
                    if (hourlySlots.isEmpty)
                       Text("No slots available for today.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: hourlySlots.map((slot) {
                        final isSel = selectedSlot?['start'] == slot['start'];
                        return GestureDetector(
                          onTap: () => setModalState(() { selectedSlot = slot; }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: isSel ? kPrimaryColor.withValues(alpha: 0.1) : theme.field, borderRadius: BorderRadius.circular(10), border: Border.all(color: isSel ? kPrimaryColor : theme.border, width: isSel ? 2 : 1)),
                            child: Text(slot['display']!, style: TextStyle(color: isSel ? kPrimaryColor : theme.text, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: isSubmitting || hourlySlots.isEmpty
                            ? null
                            : () async {
                                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty || ageCtrl.text.isEmpty || selectedSlot == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details & select a time slot!")));
                                  return;
                                }

                                setModalState(() => isSubmitting = true);

                                final allItems = [..._packages, ..._individualTests];
                                List<Map<String, dynamic>> extraServices = _cartIds.map((id) {
                                  final item = allItems.firstWhere((e) => e['id'] == id);
                                  return { "service_id": id, "name": item['name'], "count": 1 };
                                }).toList();

                                final finalPayload = {
                                  "clinic_id": _clinicId,
                                  "appointment_type": "service_only",
                                  "patient": {
                                    "name": nameCtrl.text.trim(),
                                    "phone": phoneCtrl.text.trim(),
                                    "age": ageCtrl.text.trim(),
                                    "gender": gender,
                                  },
                                  "date": dateStr,
                                  "start": selectedSlot!['start'],
                                  "end": selectedSlot!['end'],
                                  "total_cost": _cartTotal,
                                  "extra_services": extraServices,
                                };

                                try {
                                  final response = await _apiService.bookAppointment(tokenKey: 'auth_token', bookingData: finalPayload);

                                  if (response.statusCode == 200 && response.data?['data'] != null) {
                                    final respData = response.data?['data'];
                                    final appointmentId = respData['appointment_id'];

                                    final detailsResponse = await _apiService.getAppointmentDetails(
                                      tokenKey: 'auth_token',
                                      appointmentId: appointmentId,
                                    );

                                    if (detailsResponse.statusCode == 200 && detailsResponse.data?['data'] != null) {
                                      final fullDetails = detailsResponse.data?['data'];

                                      final Map<String, dynamic> successDetails = {
                                        "patientName": fullDetails['patient']?['name'] ?? nameCtrl.text.trim(),
                                        "phone": fullDetails['patient']?['phone'] ?? phoneCtrl.text.trim(),
                                        "bookingId": fullDetails['booking_id'] ?? respData['display_booking_id'],
                                        "date": fullDetails['date'] ?? dateStr,
                                        "time": selectedSlot!['display'], 
                                        "amount": fullDetails['total_cost'] ?? respData['total_amount'],
                                        "slotNumber": fullDetails['slot_number'] ?? "N/A", 
                                        "paymentMode": fullDetails['payment_method'] ?? "pay_at_clinic",
                                        "doctorName": fullDetails['clinic_id']?['name'] ?? "Clinic Service", 
                                        "specialty": "Medical Services",
                                        "doctorImage": fullDetails['clinic_id']?['logo'] ?? "", 
                                      };

                                      if (mounted) {
                                        Navigator.pop(context); 
                                        setState(() { _cartIds.clear(); }); 
                                        
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BookingSuccessScreen(appointmentDetails: successDetails),
                                          ),
                                        );
                                      }
                                    } else {
                                      throw Exception("Could not fetch detailed booking receipt.");
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Booking Error: $e"), backgroundColor: Colors.red));
                                  }
                                } finally {
                                  setModalState(() => isSubmitting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Confirm Booking", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, IconData icon, LabTheme theme, {bool isNumber = false}) {
    return TextField(
      controller: ctrl, keyboardType: isNumber ? TextInputType.number : TextInputType.name, style: TextStyle(color: theme.text),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: theme.subText, fontSize: 14),
        prefixIcon: Icon(icon, color: theme.subText, size: 20), filled: true, fillColor: theme.field,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kPrimaryColor)),
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LabTheme.of(context);
    final hasResults = _filteredPackages.isNotEmpty || _filteredTests.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      appBar: AppBar(
        backgroundColor: t.bg, elevation: 0,
        title: TextField(
          controller: _searchController, style: TextStyle(color: t.text),
          decoration: InputDecoration(
            hintText: "Search services...", hintStyle: TextStyle(color: t.subText),
            prefixIcon: Icon(LucideIcons.search, color: t.subText), filled: true, fillColor: t.field,
            contentPadding: EdgeInsets.zero, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: kPrimaryColor)))
              else if (_errorMessage != null)
                SliverFillRemaining(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.error_outline, color: kOrangeColor, size: 48), const SizedBox(height: 16), Text(_errorMessage!, style: TextStyle(color: t.text)), TextButton(onPressed: _fetchClinicServices, child: const Text("Retry"))])))
              else if (!hasResults)
                SliverFillRemaining(hasScrollBody: false, child: _EmptyResults(theme: t))
              else ...[
                // 🚀 ୩. PREMIUM UI FOR PACKAGES
                if (_filteredPackages.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _sectionHeader("Health Packages", t.text),
                        const SizedBox(height: 12),
                        for (final pkg in _filteredPackages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: PackageCard(item: pkg, isAdded: _cartIds.contains(pkg['id']), onToggle: () => _toggleItem(pkg['id']), theme: t),
                          ),
                      ]),
                    ),
                  ),

                // 🚀 ୪. STANDARD UI FOR INDIVIDUAL TESTS
                if (_filteredTests.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _sectionHeader("Individual Services", t.text),
                        const SizedBox(height: 12),
                        for (final test in _filteredTests)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TestRow(item: test, isAdded: _cartIds.contains(test['id']), onToggle: () => _toggleItem(test['id']), theme: t),
                          ),
                      ]),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
          if (!_isLoading)
            Positioned(
                bottom: 0, left: 0, right: 0,
                child: _BookingBar(theme: t, count: _cartIds.length, total: _cartTotal, onBookPress: () => _showBookingModal(t))),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// 🚀 WIDGET DETAILS (PackageCard, TestRow, _EmptyResults, _BookingBar)
// --------------------------------------------------------------------------

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> item; final bool isAdded; final VoidCallback onToggle; final LabTheme theme;
  const PackageCard({super.key, required this.item, required this.isAdded, required this.onToggle, required this.theme});

  @override
  Widget build(BuildContext context) {
    final features = (item['features'] as List).cast<String>();
    final tags = (item['tags'] as List).cast<String>();

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: isAdded ? kPrimaryColor : theme.border), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(LucideIcons.activity, color: kPrimaryColor, size: 20)),
                if (tags.contains('bestseller')) const _Badge(),
              ],
            ),
            const SizedBox(height: 12),
            Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.text), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text("Includes ${features.join(', ')}", style: TextStyle(fontSize: 11, color: theme.subText), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.muted, borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [Icon(LucideIcons.flaskConical, size: 12, color: Colors.grey), const SizedBox(width: 4), Text("Package", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.text))]),
                  Row(children: [Icon(LucideIcons.clock, size: 12, color: Colors.grey), const SizedBox(width: 4), Text(item['reportTime'], style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: theme.text))]),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("₹${item['mrp']}", style: const TextStyle(fontSize: 10, decoration: TextDecoration.lineThrough, color: Colors.grey)),
                        const SizedBox(width: 4),
                        Text("${item['discount']}% OFF", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kGreenColor)),
                      ],
                    ),
                    Text(currencyFormat.format(item['price']), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: theme.text)),
                  ],
                ),
                ElevatedButton(
                  onPressed: onToggle,
                  style: ElevatedButton.styleFrom(backgroundColor: isAdded ? Colors.grey.withValues(alpha: 0.2) : kPrimaryColor, foregroundColor: isAdded ? theme.text : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16), minimumSize: const Size(84, 38), elevation: 0),
                  child: Text(isAdded ? "Added ✓" : "Book"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: kOrangeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: const Text("BESTSELLER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kOrangeColor)),
    );
  }
}

class TestRow extends StatelessWidget {
  final Map<String, dynamic> item; final bool isAdded; final VoidCallback onToggle; final LabTheme theme;
  const TestRow({super.key, required this.item, required this.isAdded, required this.onToggle, required this.theme});

  @override
  Widget build(BuildContext context) {
    final fastingNotRequired = item['fasting'].toString().toLowerCase().contains('not');
    return Container(
      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: theme.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: isAdded ? kPrimaryColor : theme.border)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: kPrimaryColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(LucideIcons.activity, color: kPrimaryColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.text), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(LucideIcons.clock, size: 10, color: Colors.grey), const SizedBox(width: 4),
                  Text(item['reportTime'], style: const TextStyle(fontSize: 10, color: Colors.grey)), const SizedBox(width: 8),
                  Text(item['fasting'], style: TextStyle(fontSize: 10, color: fastingNotRequired ? kGreenColor : kOrangeColor, fontWeight: FontWeight.bold))
                ])
              ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(currencyFormat.format(item['price']), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.text)),
            const SizedBox(height: 4),
            InkWell(
                onTap: onToggle, borderRadius: BorderRadius.circular(4),
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isAdded ? Colors.grey.withValues(alpha: 0.2) : kPrimaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: isAdded ? Colors.transparent : kPrimaryColor.withValues(alpha: 0.3))),
                    child: Text(isAdded ? "ADDED" : "ADD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isAdded ? Colors.grey : kPrimaryColor))))
          ]),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final LabTheme theme; const _EmptyResults({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 48, color: theme.subText), const SizedBox(height: 16), Text("No services found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.text))]));
  }
}

class _BookingBar extends StatelessWidget {
  final LabTheme theme; final int count; final double total; final VoidCallback onBookPress;
  const _BookingBar({required this.theme, required this.count, required this.total, required this.onBookPress});

  @override
  Widget build(BuildContext context) {
    final visible = count > 0;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250), curve: Curves.easeOut, offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200), opacity: visible ? 1 : 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(color: theme.card, border: Border(top: BorderSide(color: theme.border)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                  crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                  children: [Text("$count ${count == 1 ? 'item' : 'items'} selected", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.subText)), Text(currencyFormat.format(total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.text))]),
              ElevatedButton.icon(
                  onPressed: onBookPress, icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white), label: const Text("Book Now", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
      ),
    );
  }
}