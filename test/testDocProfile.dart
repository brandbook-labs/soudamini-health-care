import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// ---------------------------------------------------------------------------
// 1. DATA MODELS
// ---------------------------------------------------------------------------

class Doctor {
  final String id;
  final String name;
  final String bio;
  final String specialization;
  final String clinicName;
  final String address;
  final String imageUrl;
  final double consultationFee;
  final String experience;

  Doctor({
    required this.id,
    required this.name,
    required this.bio,
    required this.specialization,
    required this.clinicName,
    required this.address,
    required this.imageUrl,
    required this.consultationFee,
    required this.experience,
  });
}

class WeeklyAvailability {
  final String label; // e.g., "Sat, Jan 31"
  final String status; // "Available" or "Unavailable"
  final List<TimeSlot> slots;

  WeeklyAvailability({
    required this.label,
    required this.status,
    required this.slots,
  });
}

class TimeSlot {
  final String start; // "10:00"
  final String end; // "13:00"
  final String value; // "wk-24-sun-10am-1pm"

  TimeSlot({required this.start, required this.end, required this.value});
}

// ---------------------------------------------------------------------------
// 2. PARSER LOGIC (The "Old Code" Logic Handler)
// ---------------------------------------------------------------------------

class DoctorScheduleParser {
  /// Consolidates backend snapshots and fallback rules into a clean calendar list.
  static List<WeeklyAvailability> generateCalendar({
    required List<dynamic> weeklySnapshots,
    required List<dynamic> recurrenceRules,
  }) {
    List<WeeklyAvailability> calendar = [];

    // 1. Prioritize explicit snapshots (weeklyAvailability from API)
    if (weeklySnapshots.isNotEmpty) {
      for (var daySnapshot in weeklySnapshots) {
        List<TimeSlot> daySlots = [];

        if (daySnapshot['slots'] != null) {
          daySlots = (daySnapshot['slots'] as List).map((s) {
            return TimeSlot(
              start: s['start'] ?? '00:00',
              end: s['end'] ?? '00:00',
              value: s['value'] ?? '',
            );
          }).toList();
        }

        calendar.add(
          WeeklyAvailability(
            label: daySnapshot['label'] ?? 'Unknown Date',
            status: daySnapshot['status'] ?? 'Unavailable',
            slots: daySlots,
          ),
        );
      }
    }
    // 2. Fallback: If no snapshots, try to generate generic days from recurrenceRules (optional)
    else if (recurrenceRules.isNotEmpty) {
      // This is a fallback to show *something* if the weekly array is empty
      // In a real app, you might loop through the next 7 days and check the rules manually.
      // For now, we return empty to avoid showing incorrect "available" days.
    }

    return calendar;
  }
}

// ---------------------------------------------------------------------------
// 3. MAIN SCREEN
// ---------------------------------------------------------------------------

class TestDoctorProfileScreen extends StatefulWidget {
  final String doctorId; // Pass the ID here (e.g. "6935ff281920a299e029f791")

  const TestDoctorProfileScreen({Key? key, required this.doctorId})
    : super(key: key);

  @override
  State<TestDoctorProfileScreen> createState() => _TestDoctorProfileScreenState();
}

class _TestDoctorProfileScreenState extends State<TestDoctorProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Doctor? _doctor;
  List<WeeklyAvailability> _bookingCalendar = [];

  @override
  void initState() {
    super.initState();
    _fetchDoctorDetails();
  }

  // --- YOUR REQUESTED API LOGIC ---
  Future<void> _fetchDoctorDetails() async {
    try {
      BaseOptions options = BaseOptions(
        baseUrl: 'https://api-jivan.onrender.com/api/v1.1/',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );
      var dio = Dio(options);

      // Using the widget.doctorId to fetch specific doctor
      final response = await dio.get('staffs/${widget.doctorId}');

      if (response.statusCode == 200 && response.data['data'] != null) {
        final Map<String, dynamic> docData = response.data['data'];
        final Doctor parsedDoctor = _mapJsonToDoctorProfile(docData);

        // --- 1. SLOT MATCHING LOGIC (From your snippet) ---

        // A. Get Clinic's Master List of Slots
        List<dynamic> allClinicSlots = [];
        if (docData['clinic_id'] is Map &&
            docData['clinic_id']['available_slots'] != null) {
          allClinicSlots = docData['clinic_id']['available_slots'];
        }

        // B. Get Doctor's Selected IDs (e.g. ["wk-24-sun-10am-1pm"])
        List<String> docSelectedIds = [];
        if (docData['availability'] != null &&
            docData['availability']['slots'] != null) {
          docSelectedIds = List<String>.from(docData['availability']['slots']);
        }

        // C. Filter: Keep only clinic slots that match the doctor's selection
        List<dynamic> activeRules = allClinicSlots.where((rule) {
          final String val = rule['value'] ?? "N/A";
          return docSelectedIds.contains(val);
        }).toList();

        // D. Get Overrides (the 7-day array from API)
        List<dynamic> weeklySnapshots = docData['weeklyAvailability'] ?? [];

        // --- 2. CALL THE PARSER ---
        final List<WeeklyAvailability> calendar =
            DoctorScheduleParser.generateCalendar(
              weeklySnapshots: weeklySnapshots,
              recurrenceRules: activeRules,
            );

        if (mounted) {
          setState(() {
            _doctor = parsedDoctor;
            _bookingCalendar = calendar;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _errorMessage = "Failed to load data");
      }
    } catch (e) {
      debugPrint("Error fetching doctor details: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Network Error: $e";
        });
      }
    }
  }

  // Helper to map basic profile fields
  Doctor _mapJsonToDoctorProfile(Map<String, dynamic> json) {
    double fee = 0.0;
    if (json['consultation_fees'] != null &&
        json['consultation_fees'].toString().isNotEmpty) {
      fee = double.tryParse(json['consultation_fees'].toString()) ?? 0.0;
    }

    String specs = "General Physician";
    if (json['departments'] != null &&
        (json['departments'] as List).isNotEmpty) {
      specs = (json['departments'] as List)
          .join(", ")
          .toUpperCase()
          .replaceAll('-', ' ');
    }

    return Doctor(
      id: json['_id'] ?? '',
      name: json['name'] ?? 'Unknown Doctor',
      bio: json['bio'] ?? 'No biography available.',
      specialization: specs,
      clinicName: json['clinic_id']?['name'] ?? 'Unknown Clinic',
      address: json['address'] ?? '',
      imageUrl: json['profile'] ?? 'https://via.placeholder.com/150',
      consultationFee: fee,
      experience: json['experience'] ?? 'N/A',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null || _doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(child: Text(_errorMessage ?? "Something went wrong")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Doctor Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue[50],
                      image: _doctor!.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(_doctor!.imageUrl),
                              fit: BoxFit.cover,
                              onError: (e, s) {},
                            )
                          : null,
                    ),
                    child: _doctor!.imageUrl.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.blue)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _doctor!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctor!.specialization,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_doctor!.experience} Exp",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "About Doctor",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _doctor!.bio,
                    style: TextStyle(color: Colors.grey[700], height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Clinic Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Clinic Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _doctor!.clinicName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _doctor!.address,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _showBookingSheet(context);
              },
              child: const Text(
                "Book Appointment",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBookingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          BookingBottomSheet(doctor: _doctor!, calendar: _bookingCalendar),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. BOOKING BOTTOM SHEET
// ---------------------------------------------------------------------------

class BookingBottomSheet extends StatefulWidget {
  final Doctor doctor;
  final List<WeeklyAvailability> calendar;

  const BookingBottomSheet({
    Key? key,
    required this.doctor,
    required this.calendar,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _selectedDateIndex = -1;
  String? _selectedSlotValue;
  String? _selectedTimeLabel;

  @override
  void initState() {
    super.initState();
    // Auto-select first available date
    _selectedDateIndex = widget.calendar.indexWhere(
      (day) => day.status == "Available",
    );
  }

  @override
  Widget build(BuildContext context) {
    // If API returned empty schedule or everything is unavailable
    if (widget.calendar.isEmpty || _selectedDateIndex == -1) {
      return _buildNoSlotsView();
    }

    final selectedDay = widget.calendar[_selectedDateIndex];

    return Container(
      height: MediaQuery.of(context).size.height * 0.70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Select Time Slot",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Horizontal Date List
          SizedBox(
            height: 80,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: widget.calendar.length,
              separatorBuilder: (c, i) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final day = widget.calendar[index];
                final isSelected = index == _selectedDateIndex;
                final isAvailable = day.status == "Available";

                return GestureDetector(
                  onTap: isAvailable
                      ? () {
                          setState(() {
                            _selectedDateIndex = index;
                            _selectedSlotValue = null; // Reset slot
                          });
                        }
                      : null,
                  child: Container(
                    width: 65,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue
                          : (isAvailable ? Colors.white : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.label.split(',')[0], // Day Name
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isAvailable ? Colors.black : Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.label.split(',').length > 1
                              ? day.label.split(',')[1].trim().split(' ')[1]
                              : '', // Date
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected
                                ? Colors.white
                                : (isAvailable ? Colors.black : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 40),

          // Slots Grid
          Expanded(
            child: selectedDay.slots.isEmpty
                ? const Center(child: Text("No slots available for this day"))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: selectedDay.slots.length,
                    itemBuilder: (context, index) {
                      final slot = selectedDay.slots[index];
                      final isSelected = _selectedSlotValue == slot.value;
                      final displayTime = "${slot.start} - ${slot.end}";

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedSlotValue = slot.value;
                            _selectedTimeLabel = displayTime;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            displayTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.blue[800]
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Proceed Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedSlotValue != null
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentBookingScreen(
                              doctor: widget.doctor,
                              dateLabel: selectedDay.label,
                              timeLabel: _selectedTimeLabel!,
                              fee: widget.doctor.consultationFee,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Proceed to Pay",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSlotsView() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "No availability found for this week.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. APPOINTMENT CONFIRMATION SCREEN
// ---------------------------------------------------------------------------

class AppointmentBookingScreen extends StatelessWidget {
  final Doctor doctor;
  final String dateLabel;
  final String timeLabel;
  final double fee;

  const AppointmentBookingScreen({
    Key? key,
    required this.doctor,
    required this.dateLabel,
    required this.timeLabel,
    required this.fee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Booking")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Booking Summary",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _infoRow("Doctor", doctor.name),
            _infoRow("Clinic", doctor.clinicName),
            const Divider(height: 32),
            _infoRow("Date", dateLabel),
            _infoRow("Time Slot", timeLabel),
            _infoRow("Consultation Fee", "₹${fee.toStringAsFixed(0)}"),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Booking Confirmed!")),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Confirm & Pay",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. MAIN ENTRY POINT (Example)
// ---------------------------------------------------------------------------

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TestDoctorProfileScreen(
        // Passing the ID of 'Dr. Debabrata Prusti' from your dataset as example
        doctorId: "6935ff281920a299e029f791",
      ),
    ),
  );
}
