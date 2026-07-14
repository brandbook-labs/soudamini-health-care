// lib/screens/admin/adminAppointments/admin_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/models/appointment_model.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_new_app/screens/admin/adminAppointments/appointment_details_screen.dart';
import 'package:my_new_app/services/api_service.dart';

import 'widgets/appointment_card.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState extends State<AdminAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  final Color _bg = const Color(0xFFF8FAFC);
  final Color _surface = const Color(0xFFFFFFFF);
  final Color _border = const Color(0xFFE2E8F0);
  final Color _primary = const Color(0xFF2563EB);
  final Color _textMain = const Color(0xFF0F172A);
  final Color _textSub = const Color(0xFF64748B);

  final ApiService _apiService = ApiService();

  List<Appointment> _appointments = [];
  bool _isLoading = true;
  String _activeTab = 'active';
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _fetchAppointments(type: 'upcoming');
  }

  Future<void> _fetchAppointments({required String type}) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAppointmentList(
        tokenKey: 'admin_token',
        type: type,
      );

      if (response.statusCode == 200) {
        final List rawData = response.data['data']['appointments'] ?? response.data['data']['results'] ?? [];
        if (mounted) {
          setState(() {
            _appointments = rawData.map((json) => Appointment.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 🚀 SENIOR LOGIC: MASTER ACTION HANDLER ---
  Future<void> _handleAction(String id, String currentStatus, {String? forceNextStatus}) async {
    String nextStatus;
    Future<dynamic> Function()? apiCall;

    // ୧. ଯଦି କୌଣସି ନିର୍ଦ୍ଦିଷ୍ଟ ଷ୍ଟାଟସ୍ ପଠାଯାଇଛି (ଯେମିତିକି ମେନୁ ରୁ cancel କିମ୍ବା confirm), ତାକୁ ନେବୁ
    if (forceNextStatus != null) {
      nextStatus = forceNextStatus;
      if (nextStatus == 'confirmed') {
        apiCall = () => _apiService.markPatientReached(tokenKey: 'admin_token', appointmentId: id);
      } else if (nextStatus == 'checked_in') {
        apiCall = () => _apiService.startConsultation(tokenKey: 'admin_token', appointmentId: id);
      } else if (nextStatus == 'completed') {
        apiCall = () => _apiService.completeConsultation(tokenKey: 'admin_token', appointmentId: id);
      } else if (nextStatus == 'cancelled') {
        apiCall = () => _apiService.cancelAppointment(tokenKey: 'admin_token', appointmentId: id, cancelReason: 'Admin Cancelled');
      }
    } 
    // ୨. ନଚେତ୍ ସାଧାରଣ Flow ଅନୁସାରେ ଚାଲିବ
    else {
      if (currentStatus == 'pending') {
        nextStatus = 'confirmed';
        apiCall = () => _apiService.markPatientReached(tokenKey: 'admin_token', appointmentId: id);
      } else if (currentStatus == 'confirmed') {
        nextStatus = 'checked_in';
        apiCall = () => _apiService.startConsultation(tokenKey: 'admin_token', appointmentId: id);
      } else {
        nextStatus = 'completed';
        apiCall = () => _apiService.completeConsultation(tokenKey: 'admin_token', appointmentId: id);
      }
    }

    // ୩. Optimistic UI Update (Fast UI Change)
    setState(() {
      if (nextStatus == 'completed' || nextStatus == 'cancelled') {
        _appointments.removeWhere((item) => item.id == id);
      } else {
        final index = _appointments.indexWhere((item) => item.id == id);
        if (index != -1) {
          final oldAppt = _appointments[index];
          List<Appointment> updatedList = List.from(_appointments);
          updatedList[index] = Appointment(
            id: oldAppt.id,
            doctorId: oldAppt.doctorId,
            doctorName: oldAppt.doctorName,
            doctorImage: oldAppt.doctorImage,
            doctorPhone: oldAppt.doctorPhone,
            clinicName: oldAppt.clinicName,
            clinicAddress: oldAppt.clinicAddress,
            clinicLat: oldAppt.clinicLat,
            clinicLng: oldAppt.clinicLng,
            specialty: oldAppt.specialty,
            dateTime: oldAppt.dateTime,
            startTime: oldAppt.startTime,
            endTime: oldAppt.endTime,
            status: nextStatus, // 🚀 New Status applied instantly
            type: oldAppt.type,
            clinicPhone: oldAppt.clinicPhone,
            slotNumber: oldAppt.slotNumber,
            totalCost: oldAppt.totalCost,
            paymentMethod: oldAppt.paymentMethod,
            patient: oldAppt.patient,
            extraServices: oldAppt.extraServices,
            bookedBy: oldAppt.bookedBy,
          );
          _appointments = updatedList;
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Marking as ${nextStatus.toUpperCase()}..."), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
      );
    }

    // ୪. Background API Call
    try {
      if (apiCall != null) await apiCall();
      _fetchAppointments(type: _activeTab == 'active' ? 'upcoming' : 'history');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.red));
      _fetchAppointments(type: _activeTab == 'active' ? 'upcoming' : 'history');
    }
  }

  Map<String, List<Appointment>> get _groupedAppointments {
    final filtered = _appointments.where((appt) {
      final isActive = ['confirmed', 'checked_in', 'pending'].contains(appt.status);
      final isArchive = ['completed', 'cancelled', 'no_show'].contains(appt.status);

      if (_activeTab == 'active' && !isActive) return false;
      if (_activeTab == 'archive' && !isArchive) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return appt.patient.name.toLowerCase().contains(q) || appt.doctorName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    filtered.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final groups = <String, List<Appointment>>{};
    for (var appt in filtered) {
      String formattedDate = "${appt.dateTime.year}-${appt.dateTime.month.toString().padLeft(2, '0')}-${appt.dateTime.day.toString().padLeft(2, '0')}";
      if (!groups.containsKey(formattedDate)) groups[formattedDate] = [];
      groups[formattedDate]!.add(appt);
    }
    return groups;
  }

  void _launchWhatsApp(String phone, String name) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) cleanPhone = "91$cleanPhone";
    final url = Uri.parse("https://wa.me/$cleanPhone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _launchCall(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _appointments.where((a) => ['pending', 'confirmed', 'checked_in'].contains(a.status)).length;
    final totalCount = _appointments.length;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _border)), color: _surface),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(LucideIcons.arrowLeft, color: _textMain),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Bookings", style: TextStyle(color: _textMain, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text("Manage queues & patients", style: TextStyle(color: _textSub, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildMiniStat("Active", "$activeCount", Colors.green),
                          const SizedBox(width: 12),
                          _buildMiniStat("Total", "$totalCount", Colors.blue),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 48,
                    decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(color: _textMain),
                      decoration: InputDecoration(
                        hintText: "Search patient, doctor, ID...",
                        hintStyle: TextStyle(color: _textSub, fontSize: 14),
                        prefixIcon: Icon(LucideIcons.search, color: _textSub, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. TABS
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: Row(
                children: [
                  _buildTab("Active Queue", 'active'),
                  _buildTab("Archive / History", 'archive'),
                ],
              ),
            ),

            // 3. LIST
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _primary))
                  : _groupedAppointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.calendarX, size: 48, color: _textSub.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text("No appointments found", style: TextStyle(color: _textSub, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _groupedAppointments.length,
                      itemBuilder: (context, index) {
                        final date = _groupedAppointments.keys.elementAt(index);
                        final appointments = _groupedAppointments[date]!;
                        return _buildDateGroup(date, appointments);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateGroup(String date, List<Appointment> appointments) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          color: _border.withValues(alpha: 0.3),
          child: Row(
            children: [
              Icon(LucideIcons.calendarDays, size: 14, color: _textSub),
              const SizedBox(width: 8),
              Text(date, style: TextStyle(color: _textSub, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        ...appointments.map(
          (appt) => AppointmentCard(
            appt: appt,
            bg: _bg,
            surface: _surface,
            border: _border,
            primary: _primary,
            textMain: _textMain,
            textSub: _textSub,
            statusColor: _getStatusColor(appt.status),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentDetailsScreen(appointment: appt)),
              );
            },
            onLongPress: () {
              HapticFeedback.mediumImpact();
              _showOptionsSheet(appt);
            },
            onCall: () => _launchCall(appt.patient.phone),
            onWhatsApp: () => _launchWhatsApp(appt.patient.phone, appt.patient.name),
            onOptions: () => _showOptionsSheet(appt),
            // onActionTap: () => _handleAction(appt.id, appt.status), // 🚀 Card action button logic
          ),
        ),
      ],
    );
  }

  // --- 🚀 SENIOR LOGIC: THE FULL ACTION MENU (BOTTOM SHEET) ---
  void _showOptionsSheet(Appointment appt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text("Manage Booking #${appt.slotNumber}", style: TextStyle(color: _textMain, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // 🚀 DYNAMIC MENU ITEMS BASED ON STATUS
            if (appt.status == 'pending')
              _buildActionTile(
                LucideIcons.checkCircle2,
                "Confirm Appointment",
                Colors.blue,
                () {
                  Navigator.pop(ctx);
                  _handleAction(appt.id, appt.status, forceNextStatus: 'confirmed');
                },
              ),

            if (appt.status == 'confirmed')
              _buildActionTile(
                LucideIcons.arrowRightCircle,
                "Check In",
                Colors.orange,
                () {
                  Navigator.pop(ctx);
                  _handleAction(appt.id, appt.status, forceNextStatus: 'checked_in');
                },
              ),

            if (appt.status == 'checked_in')
              _buildActionTile(
                LucideIcons.clipboardCheck,
                "Complete",
                Colors.green,
                () {
                  Navigator.pop(ctx);
                  _handleAction(appt.id, appt.status, forceNextStatus: 'completed');
                },
              ),

            // ALWAYS SHOW VIEW DETAILS
            _buildActionTile(LucideIcons.user, "View Details", _textSub, () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentDetailsScreen(appointment: appt)));
            }),
            
            // ALWAYS SHOW CANCEL (if not completed)
            if (['pending', 'confirmed', 'checked_in'].contains(appt.status)) ...[
              Divider(color: _border, height: 32),
              _buildActionTile(
                LucideIcons.ban,
                "Cancel Booking",
                Colors.red,
                () {
                  Navigator.pop(ctx);
                  _handleAction(appt.id, appt.status, forceNextStatus: 'cancelled');
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, String key) {
    final isActive = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeTab == key) return;
          setState(() {
            _activeTab = key;
            _appointments = []; 
          });
          _fetchAppointments(type: key == 'active' ? 'upcoming' : 'history');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: isActive ? _bg : Colors.transparent, borderRadius: BorderRadius.circular(10), border: Border.all(color: isActive ? _border : Colors.transparent)),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(color: isActive ? _primary : _textSub, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text("$value $label", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: TextStyle(color: _textMain, fontWeight: FontWeight.w600)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed': return Colors.blue;
      case 'checked_in': return Colors.orange;
      case 'pending': return Colors.orange.shade300;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}