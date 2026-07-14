import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/patients/doctor_profile/doctor_profile_screen.dart';

import 'package:my_new_app/services/api_service.dart'; 
import 'package:my_new_app/screens/patients/booking/appointment_details_screen.dart'; 
import 'package:my_new_app/models/appointment_model.dart'; 

// --- CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF1E1E1E);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _currentTabType = 'upcoming'; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; 
      
      final newType = _tabController.index == 0 ? 'upcoming' : 'history';
      if (_currentTabType != newType) {
        setState(() {
          _currentTabType = newType;
          _appointments = []; 
        });
        _fetchAppointments();
      }
    });

    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getAppointmentList(
        tokenKey: 'auth_token',
        type: _currentTabType, 
        page: 1,
        limit: 20, 
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> list = response.data['data']['results']; 
        if (mounted) {
          setState(() {
            _appointments = list.map((e) => Appointment.fromJson(e)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Fetch Appointments Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? kDarkBg : kLightBg,
      appBar: AppBar(
        title: const Text("My Appointments", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? kDarkCard : kLightCard,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(_appointments, isDark, isHistory: false),
              _buildList(_appointments, isDark, isHistory: true),
            ],
          ),
    );
  }

  Widget _buildList(List<Appointment> list, bool isDark, {required bool isHistory}) {
    if (list.isEmpty) return Center(child: Text("No ${isHistory ? 'history' : 'upcoming'} appointments", style: const TextStyle(color: Colors.grey)));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => AppointmentCard(
        appointment: list[i], 
        isHistoryTab: isHistory,
        onUpdate: _refreshData,
        apiService: _apiService,
      ),
    );
  }
}

// =============================================================================
// 3. CARD DESIGN (Using the New Model & Extension)
// =============================================================================
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool isHistoryTab;
  final VoidCallback onUpdate;
  final ApiService apiService;

  const AppointmentCard({
    super.key, 
    required this.appointment, 
    required this.isHistoryTab,
    required this.onUpdate,
    required this.apiService,
  });

  Future<void> _updateStatus(BuildContext context, String status) async {
    try {
      if (status == "checked_in") {
        await apiService.markPatientReached(
          tokenKey: 'auth_token', 
          appointmentId: appointment.id
        );
      }
      
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text("Success"), backgroundColor: appointment.statusColor));
        onUpdate();
      }
    } catch (e) {
      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update"), backgroundColor: Colors.red));
    }
  }

  void _onReachedClinic(BuildContext context) {
    if (!appointment.isCheckInAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appointment.checkInDisabledMessage))
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.mapPin, size: 40, color: kPrimaryColor),
            const SizedBox(height: 16),
            const Text("Are you at the clinic?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text("No"))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _updateStatus(context, "checked_in"); 
                  }, 
                  child: const Text("Yes, I'm Here"),
                )),
              ],
            )
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? kDarkCard : kLightCard;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade200;

    // --- BUTTON LOGIC ---
    Widget? actionButton;
    
    if (!isHistoryTab) {
      if (appointment.status == "pending") {
        actionButton = _buildBtn(
          label: appointment.checkInDisabledMessage, 
          icon: appointment.isCheckInAllowed ? LucideIcons.mapPin : LucideIcons.lock, 
          color: appointment.isCheckInAllowed ? kPrimaryColor : Colors.grey, 
          onTap: () => _onReachedClinic(context)
        );
      } else if (appointment.status == "confirmed") {
        actionButton = _buildBtn(
          label: "Waiting at Clinic", 
          icon: LucideIcons.clock, 
          color: appointment.statusColor, 
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Clinic has been notified.")))
        );
      } else if (appointment.status == "checked_in") {
        actionButton = _buildBtn(
          label: "In Session", 
          icon: LucideIcons.stethoscope, 
          color: appointment.statusColor, 
          onTap: () {}
        );
      }
    } else {
      // 🚀 "Book Again" Button with Navigation Logic
      actionButton = _buildBtn(
        label: "Book Again", 
        icon: LucideIcons.repeat, 
        color: Colors.grey, 
        isOutline: true,
        onTap: () {
          // ଯଦି ଆପଣ ମଡେଲ୍ ରେ doctorId ଯୋଡିଛନ୍ତି (ତଳେ ଦେଖନ୍ତୁ)
          // ଆପଣ ଏହାକୁ ଏହିପରି ବ୍ୟବହାର କରିବେ:
          if (appointment.doctorId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorProfileScreen(doctorId: appointment.doctorId),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Doctor information not available."))
            );
          }
        }
      );
      // When reschedule comes then delete this action and comment out below appointment.status == "no_show" || appointment.status == "cancelled"
      // if (appointment.status == "no_show" || appointment.status == "cancelled") {
      //   actionButton = _buildBtn(
      //     label: "Reschedule", 
      //     icon: LucideIcons.calendarClock, 
      //     color: kPrimaryColor, 
      //     onTap: () {} // TODO: Add reschedule
      //   );
      // } else {
      //    actionButton = _buildBtn(
      //     label: "Book Again", 
      //     icon: LucideIcons.repeat, 
      //     color: Colors.grey, 
      //     isOutline: true,
      //     onTap: () {}
      //   );
      // }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(appointment.doctorImage),
                    fit: BoxFit.cover,
                    onError: (e, s) {}, 
                  ),
                  color: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctorName,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(LucideIcons.building2, size: 14, color: kPrimaryColor.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            appointment.clinicName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor.withValues(alpha: 0.9)),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(LucideIcons.calendar, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          appointment.formattedDateTime, 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kOrangeColor), 
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: appointment.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(appointment.status.toUpperCase(), style: TextStyle(color: appointment.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          if (actionButton != null) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailsScreen(appointmentId: appointment.id)));
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    side: BorderSide.none,
                  ),
                  child: Text("View Details", style: TextStyle(color: textColor.withValues(alpha: 0.7))),
                )),
                Container(width: 1, height: 24, color: borderColor),
                const SizedBox(width: 12),
                Expanded(child: actionButton),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildBtn({required String label, required IconData icon, required Color color, required VoidCallback onTap, bool isOutline = false}) {
    if (isOutline) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(label, style: TextStyle(color: color, fontSize: 13)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}