import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/screens/patients/booking/appointment_booking_screen.dart';
import 'package:my_new_app/screens/patients/path/to/doctor_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

// 🚀 flutter_map ଏବଂ latlong2
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../controllers/language_controller.dart';
import '../../models/clinic_model.dart';
import '../../models/doctor_model.dart';
import '../../models/booking_models.dart';
import 'providers/clinic_provider.dart'; 

class ClinicDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> clinicData;

  const ClinicDetailsScreen({super.key, required this.clinicData});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  // 🚀 Selected Services Cart
  final List<Map<String, dynamic>> _selectedServices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? slug = widget.clinicData['slug'];
      if (slug != null && slug.isNotEmpty) {
        context.read<ClinicProvider>().fetchSingleClinicProfile(slug);
      }
    });
  }

  void _toggleService(Map<String, dynamic> service) {
    setState(() {
      final serviceId = service['id'] ?? service['_id'];
      final existingIndex = _selectedServices.indexWhere((s) => (s['id'] ?? s['_id']) == serviceId);
      
      if (existingIndex >= 0) {
        _selectedServices.removeAt(existingIndex); 
      } else {
        _selectedServices.add(service); 
      }
    });
  }

  void _openDateTimeSelectionSheet(Clinic clinic, bool isOdia, bool isDarkMode, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClinicTimeSelectorSheet(
        clinic: clinic,
        isOdia: isOdia,
        isDarkMode: isDarkMode,
        primaryColor: primaryColor,
        onTimeSelected: (DateTime date, String time) {
          Navigator.pop(ctx); 
          _proceedToBooking(clinic, date, time); 
        },
      ),
    );
  }

  void _proceedToBooking(Clinic clinic, DateTime date, String time) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    
    final selection = BookingSelection(
      slotId: clinic.id, 
      date: formattedDate, 
      slotTime: time, 
    );

    final dummyDoctor = Doctor(
      id: clinic.id,
      slug: clinic.slug,
      name: clinic.name,
      specialty: "Clinic Services",
      clinicName: clinic.name,
      image: clinic.image,
      rating: double.tryParse(clinic.rating) ?? 4.5,
      reviews: 120,
      experience: "N/A",
      location: clinic.address,
      city: clinic.location,
      isVerified: true,
      isSuspended: true,
      nextAvailable: "Selected",
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentBookingScreen(
          doctor: dummyDoctor,
          clinicLocation: clinic.fullData,
          clinicServices: _selectedServices, 
          selection: selection,
          initialAppointmentType: 'service_only', 
        ),
      ),
    );
  }

  // =========================================================================
  // 🚀 [SUPER SENIOR LOGIC]: Real-time Operating Hours Checker
  // =========================================================================
  Map<String, dynamic> _getRealTimeClinicStatus(Map<String, dynamic> fullData, bool isOdia) {
    final opHours = fullData['operating_hours'];
    
    // Default ଫଲବ୍ୟାକ୍ (ବନ୍ଦ ଅଛି)
    Map<String, dynamic> closedStatus = {
      'text': isOdia ? "ବନ୍ଦ ଅଛି" : "Closed", 
      'color': Colors.redAccent
    };

    if (opHours == null) return closedStatus;

    // ଯଦି 24/7 ଅଛି, ସିଧା ରିଟର୍ଣ୍ଣ କରନ୍ତୁ
    if (opHours['is24h'] == true) {
      return {'text': isOdia ? "24/7 ଖୋଲା ଅଛି" : "24/7 Open", 'color': const Color(0xFF16A34A)};
    }

    final timings = opHours['timings'];
    if (timings == null) return closedStatus;

    final now = DateTime.now();
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayStr = days[now.weekday - 1]; // ବର୍ତ୍ତମାନର ଦିନ ବାହାର କରନ୍ତୁ

    final todayTimings = timings[todayStr];

    if (todayTimings != null && todayTimings['open'] != null && todayTimings['close'] != null) {
      try {
        final openParts = todayTimings['open'].toString().split(':');
        final closeParts = todayTimings['close'].toString().split(':');

        final openTime = TimeOfDay(hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));
        final closeTime = TimeOfDay(hour: int.parse(closeParts[0]), minute: int.parse(closeParts[1]));
        final currentTime = TimeOfDay.fromDateTime(now);

        // TimeOfDay କୁ double ରେ କନଭର୍ଟ କରି ତୁଳନା କରିବା
        double toDouble(TimeOfDay myTime) => myTime.hour + myTime.minute / 60.0;

        if (toDouble(currentTime) >= toDouble(openTime) && toDouble(currentTime) <= toDouble(closeTime)) {
          return {'text': isOdia ? "ଖୋଲା ଅଛି" : "Open Now", 'color': const Color(0xFF16A34A)};
        }
      } catch (e) {
        debugPrint("Status Time Parse Error: $e");
      }
    }

    return closedStatus;
  }

  @override
  Widget build(BuildContext context) {
    final isOdia = context.watch<LanguageController>().currentLocale.languageCode == 'or';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final bgColor = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    final primaryColor = const Color.fromARGB(255, 22, 96, 255);

    return Scaffold(
      backgroundColor: bgColor,
      bottomNavigationBar: _buildStickyBottomBar(isOdia, isDarkMode, primaryColor),
      body: Consumer<ClinicProvider>(
        builder: (context, provider, child) {
          if (provider.isProfileLoading) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          final Clinic? clinic = provider.selectedClinic;
          if (clinic == null) {
            return Center(child: Text("Failed to load clinic data", style: TextStyle(color: textColor)));
          }

          final fullData = clinic.fullData;
          final String type = (fullData['facility_type'] ?? 'Clinic').toString().toUpperCase();
          final String about = fullData['notes'] ?? fullData['about'] ?? "No description available.";
          
          final double lat = double.tryParse(fullData['lat']?.toString() ?? '0') ?? 0.0;
          final double lng = double.tryParse(fullData['lng']?.toString() ?? '0') ?? 0.0;

          // 🚀 Real-time Status Data
          final statusData = _getRealTimeClinicStatus(fullData, isOdia);
          
          // 🚀 Safe Phone Checker
          final bool hasPhone = clinic.phone.isNotEmpty && clinic.phone != "null" && clinic.phone.length > 5;

          final List<dynamic> servicesList = provider.clinicServices.where((s) => s['is_doctor_package'] == false).toList();
          final List<Doctor> doctorsList = provider.clinicDoctors;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- HEADER IMAGE ---
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                backgroundColor: bgColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: const [
                  SizedBox(width: 8), // Bookmark removed for clean UI
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: clinic.image.isNotEmpty && !clinic.image.contains("ui-avatars")
                      ? CachedNetworkImage(
                          imageUrl: clinic.image,
                          fit: BoxFit.cover,
                          errorWidget: (c, o, s) => Container(color: isDarkMode ? Colors.black26 : Colors.blue.shade50),
                        )
                      : Container(
                          color: isDarkMode ? Colors.black26 : Colors.blue.shade50,
                          child: Icon(LucideIcons.building, size: 80, color: primaryColor.withValues(alpha: 0.3)),
                        ),
                ),
              ),

              // --- BODY CONTENT ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- 1. BASIC INFO ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(type, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor)),
                      ),
                      const SizedBox(height: 12),
                      Text(clinic.name, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, height: 1.2)),
                      const SizedBox(height: 8),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(LucideIcons.mapPin, size: 14, color: subTextColor),
                          const SizedBox(width: 6),
                          Expanded(child: Text(clinic.address, style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4))),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      Divider(color: borderColor),
                      const SizedBox(height: 24),

                      // --- 2. CONTACT & STATUS GRID (SMART VISIBILITY) ---
                      Row(
                        children: [
                          if (hasPhone) ...[
                            _buildInfoItem(LucideIcons.phone, isOdia ? "ଯୋଗାଯୋଗ" : "Contact", clinic.phone, textColor, subTextColor, cardColor, borderColor, primaryColor),
                            const SizedBox(width: 12),
                          ],
                          _buildInfoItem(
                            LucideIcons.clock, 
                            isOdia ? "ସ୍ଥିତି" : "Status", 
                            statusData['text'], 
                            statusData['color'], 
                            subTextColor, cardColor, borderColor, 
                            statusData['color']
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- 3. SERVICES (TOP FOR BETTER UX) ---
                      if (servicesList.isNotEmpty) ...[
                        Text(isOdia ? "ସେବା ବାଛନ୍ତୁ" : "Clinic Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 12),
                        
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: servicesList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final Map<String, dynamic> s = servicesList[index];
                            final String serviceName = s['name'] ?? "Medical Service";
                            final double price = (s['price'] ?? 0).toDouble();
                            final double discountPrice = (s['discount_price'] ?? price).toDouble();
                            final int discountPercent = (s['discount_percentage'] ?? 0).toInt();
                            
                            final serviceId = s['id'] ?? s['_id'];
                            final isSelected = _selectedServices.any((item) => (item['id'] ?? item['_id']) == serviceId);

                            return _buildInteractiveServiceCard(
                              name: serviceName, price: price, discountPrice: discountPrice, discountPercent: discountPercent,
                              isSelected: isSelected, isDarkMode: isDarkMode, cardColor: cardColor, borderColor: borderColor,
                              primaryColor: primaryColor, textColor: textColor, subTextColor: subTextColor,
                              onTap: () => _toggleService(s),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // --- 4. DOCTORS (TOP FOR BETTER UX) ---
                      if (doctorsList.isNotEmpty) ...[
                        Text("Specialists at Clinic", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 310, 
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: doctorsList.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return DoctorCardWidget(doctor: doctorsList[index], isOdia: isOdia, isVertical: true);
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Divider(color: borderColor),
                      const SizedBox(height: 32),

                      // --- 5. ABOUT FACILITY ---
                      Text("About Facility", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                      const SizedBox(height: 12),
                      Text(about, style: TextStyle(fontSize: 14, color: subTextColor, height: 1.6)),
                      const SizedBox(height: 32),

                      // --- 6. MAP ---
                      if (lat != 0.0 && lng != 0.0) ...[
                        Text("Location & Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(lat, lng),
                              initialZoom: 15.0,
                              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.drag),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: isDarkMode 
                                  ? 'https://tiles.stadiamaps.com/tiles/alidade_smooth_dark/{z}/{x}/{y}{r}.png' 
                                  : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.jivan.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(lat, lng),
                                    width: 140, height: 140,
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on, color: Colors.redAccent, size: 45),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // --- 7. FACILITIES (TAGS) ---
                      if (clinic.tags.isNotEmpty) ...[
                        Text("Facilities", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: clinic.tags.map((s) => _buildChip(s, isDarkMode, borderColor, textColor)).toList(),
                        ),
                      ],
                        
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🚀 Interactive Service Card (Add/Remove)
  Widget _buildInteractiveServiceCard({
    required String name, required double price, required double discountPrice, required int discountPercent,
    required bool isSelected, required bool isDarkMode, required Color cardColor, required Color borderColor,
    required Color primaryColor, required Color textColor, required Color subTextColor, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.05) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? primaryColor : borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text("₹${discountPrice.toInt()}", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w900)),
                      if (price > discountPrice) ...[
                        const SizedBox(width: 8),
                        Text("₹${price.toInt()}", style: TextStyle(color: subTextColor, fontSize: 12, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (discountPercent > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text("$discountPercent% OFF", style: const TextStyle(color: Color(0xFF16A34A), fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.redAccent.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? Colors.redAccent.withValues(alpha: 0.5) : primaryColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                isSelected ? "REMOVE" : "ADD",
                style: TextStyle(color: isSelected ? Colors.redAccent : primaryColor, fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 Sticky Bottom Bar
  Widget _buildStickyBottomBar(bool isOdia, bool isDarkMode, Color primaryColor) {
    if (_selectedServices.isEmpty) return const SizedBox.shrink();

    double totalDiscountedPrice = 0;
    for (var s in _selectedServices) {
      totalDiscountedPrice += (double.tryParse(s['discount_price']?.toString() ?? s['price']?.toString() ?? '0') ?? 0.0);
    }

    final cardColor = isDarkMode ? const Color(0xFF191919) : Colors.white;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: borderColor),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${_selectedServices.length} ${isOdia ? 'ସେବା ବଛାଯାଇଛି' : 'Services Selected'}", 
                  style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 2),
                Text("₹${totalDiscountedPrice.toInt()}", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black87)),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  final provider = context.read<ClinicProvider>();
                  if (provider.selectedClinic != null) {
                    _openDateTimeSelectionSheet(provider.selectedClinic!, isOdia, isDarkMode, primaryColor);
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  isOdia ? "ବୁକ୍ କରନ୍ତୁ" : "Book ${_selectedServices.length} Services",
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, bool isDarkMode, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, Color textColor, Color subTextColor, Color cardColor, Color borderColor, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: subTextColor, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// =====================================================================
// 🚀 SUPER SENIOR COMPONENT: SMART DATE & TIME SELECTOR BOTTOM SHEET
// =====================================================================
class _ClinicTimeSelectorSheet extends StatefulWidget {
  final Clinic clinic;
  final bool isOdia;
  final bool isDarkMode;
  final Color primaryColor;
  final Function(DateTime, String) onTimeSelected;

  const _ClinicTimeSelectorSheet({
    required this.clinic, required this.isOdia, required this.isDarkMode, 
    required this.primaryColor, required this.onTimeSelected,
  });

  @override
  State<_ClinicTimeSelectorSheet> createState() => _ClinicTimeSelectorSheetState();
}

class _ClinicTimeSelectorSheetState extends State<_ClinicTimeSelectorSheet> {
  late DateTime _selectedDate;
  String? _selectedTime;
  List<String> _generatedTimeSlots = [];
  final List<DateTime> _next7Days = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));

  @override
  void initState() {
    super.initState();
    _selectedDate = _next7Days[0];
    _generateTimeSlotsForDate(_selectedDate);
  }

  void _generateTimeSlotsForDate(DateTime date) {
    _generatedTimeSlots.clear();
    
    final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final String dayName = days[date.weekday - 1]; 

    final dynamic opHours = widget.clinic.fullData['operating_hours'];
    bool is24h = false;
    int openHour = 9;  
    int closeHour = 17; 
    bool isClosed = false;

    if (opHours != null) {
      is24h = opHours['is24h'] == true;
      
      if (is24h) {
        openHour = 0; closeHour = 24;
      } else if (opHours['timings'] != null) {
        final dayTimings = opHours['timings'][dayName];
        if (dayTimings != null && dayTimings['open'] != null && dayTimings['close'] != null) {
          try {
            openHour = int.parse(dayTimings['open'].toString().split(':')[0]);
            closeHour = int.parse(dayTimings['close'].toString().split(':')[0]);
          } catch (_) {}
        } else {
          isClosed = true; 
        }
      }
    }

    if (!isClosed) {
      DateTime now = DateTime.now();
      bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;

      for (int h = openHour; h < closeHour; h++) {
        if (isToday && h <= now.hour) continue; // 🚀 Past time logic

        String startAmPm = h >= 12 && h < 24 ? "PM" : "AM";
        String endAmPm = (h + 1) >= 12 && (h + 1) < 24 ? "PM" : "AM";
        
        int displayStart = h > 12 ? h - 12 : (h == 0 ? 12 : h);
        int displayEnd = (h + 1) > 12 ? (h + 1) - 12 : ((h + 1) == 0 ? 12 : (h + 1));

        String startStr = "${displayStart.toString().padLeft(2, '0')}:00 $startAmPm";
        String endStr = "${displayEnd.toString().padLeft(2, '0')}:00 $endAmPm";

        _generatedTimeSlots.add("$startStr - $endStr");
      }
    }
    
    _selectedTime = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
    final borderColor = widget.isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 48, height: 5,
              decoration: BoxDecoration(color: widget.isDarkMode ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2.5)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.isOdia ? "ସମୟ ବାଛନ୍ତୁ" : "Select Schedule", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(LucideIcons.x, size: 20, color: textColor),
                  style: IconButton.styleFrom(backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade100),
                ),
              ],
            ),
          ),

          // 🚀 HORIZONTAL DATE SCRUBBER 🚀
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(_next7Days.length, (index) {
                final date = _next7Days[index];
                final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = date);
                    _generateTimeSlotsForDate(date);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? widget.primaryColor : (widget.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isSelected ? widget.primaryColor : borderColor, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Text(DateFormat('MMM').format(date).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white70 : subTextColor)),
                        const SizedBox(height: 6),
                        Text("${date.day}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isSelected ? Colors.white : textColor)),
                        const SizedBox(height: 6),
                        Text(DateFormat('E').format(date).toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : textColor)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 20),
          Divider(height: 1, thickness: 1, color: borderColor),
          const SizedBox(height: 16),

          // 🚀 TIME SLOTS CHIPS 🚀
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: _generatedTimeSlots.isNotEmpty
                  ? Wrap(
                      spacing: 12, runSpacing: 12,
                      children: _generatedTimeSlots.map((time) {
                        final isSelected = _selectedTime == time;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedTime = time),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? widget.primaryColor.withValues(alpha: 0.1) : (widget.isDarkMode ? const Color(0xFF252525) : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? widget.primaryColor : borderColor, width: isSelected ? 1.5 : 1),
                            ),
                            child: Text(time, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isSelected ? widget.primaryColor : textColor)),
                          ),
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(LucideIcons.store, color: subTextColor, size: 40),
                          const SizedBox(height: 16),
                          Text(widget.isOdia ? "ଆଜି କ୍ଲିନିକ୍ ବନ୍ଦ ଅଛି।" : "Clinic is closed for this date.", style: TextStyle(color: subTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
            ),
          ),

          // 🚀 CONFIRM BUTTON 🚀
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bgColor, border: Border(top: BorderSide(color: borderColor))),
            child: SafeArea(
              top: false,
              child: FilledButton(
                onPressed: _selectedTime == null ? null : () => widget.onTimeSelected(_selectedDate, _selectedTime!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: widget.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey.shade300,
                ),
                child: Text(widget.isOdia ? "ସମୟ ନିଶ୍ଚିତ କରନ୍ତୁ" : "Confirm Time Slot", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}