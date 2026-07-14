// lib/screens/admin/adminAppointments/appointment_details_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/models/appointment_model.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late Appointment _appt;
  final ApiService _apiService = ApiService();
  bool _isLoadingAction = false;

  // --- PREMIUM LIGHT THEME PALETTE ---
  final Color _bgMain = const Color(0xFFF8FAFC);
  final Color _bgCard = const Color(0xFFFFFFFF);
  final Color _border = const Color(0xFFE2E8F0);
  final Color _textMain = const Color(0xFF0F172A);
  final Color _textSub = const Color(0xFF64748B);
  final Color _primary = const Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
  }

  // --- 🚀 MASTER API CALLER FOR STATUS UPDATES ---
  Future<void> _updateStatusViaApi(String newStatus) async {
    setState(() => _isLoadingAction = true);

    try {
      Future<dynamic> Function()? apiCall;
      
      // ୧. ସଠିକ୍ API ନିର୍ଦ୍ଧାରଣ
      if (newStatus == 'confirmed') {
        apiCall = () => _apiService.markPatientReached(tokenKey: 'admin_token', appointmentId: _appt.id);
      } else if (newStatus == 'checked_in') {
        apiCall = () => _apiService.startConsultation(tokenKey: 'admin_token', appointmentId: _appt.id);
      } else if (newStatus == 'completed') {
        apiCall = () => _apiService.completeConsultation(tokenKey: 'admin_token', appointmentId: _appt.id);
      } else if (newStatus == 'cancelled') {
        apiCall = () => _apiService.cancelAppointment(tokenKey: 'admin_token', appointmentId: _appt.id, cancelReason: "Cancelled by Admin");
      }

      // ୨. API ଏକ୍ସିକ୍ୟୁଟ୍
      if (apiCall != null) {
        await apiCall();
      }

      // ୩. Local ଷ୍ଟେଟ୍ ଅପଡେଟ୍ ଯାହାଦ୍ୱାରା UI ତୁରନ୍ତ ବଦଳିବ
      setState(() {
        _appt = Appointment(
          id: _appt.id,
          doctorId: _appt.doctorId,
          doctorName: _appt.doctorName,
          doctorImage: _appt.doctorImage,
          doctorPhone: _appt.doctorPhone, // 🚀 Retain doctor phone
          clinicName: _appt.clinicName,
          clinicAddress: _appt.clinicAddress,
          clinicLat: _appt.clinicLat,
          clinicLng: _appt.clinicLng,
          specialty: _appt.specialty,
          dateTime: _appt.dateTime,
          startTime: _appt.startTime,
          endTime: _appt.endTime,
          status: newStatus, // 👈 ନୂଆ ଷ୍ଟାଟସ୍!
          type: _appt.type,
          clinicPhone: _appt.clinicPhone,
          slotNumber: _appt.slotNumber,
          totalCost: _appt.totalCost,
          paymentMethod: _appt.paymentMethod,
          patient: _appt.patient,
          extraServices: _appt.extraServices,
          bookedBy: _appt.bookedBy,
        );
      });

      // ୪. କ୍ୟାନ୍ସଲ୍ ହୋଇଥିଲେ, ରୋଗୀଙ୍କୁ WhatsApp ମେସେଜ୍ ଯିବ
      if (newStatus == 'cancelled') {
        _openWhatsAppPatient(template: 'cancelled');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully marked as ${newStatus.toUpperCase()}"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingAction = false);
    }
  }

  // --- ACTIONS (PHONE & WHATSAPP) ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  // Patient WhatsApp
  Future<void> _openWhatsAppPatient({String? template}) async {
    if (_appt.patient.phone.isEmpty) return;
    final cleanPhone = _appt.patient.phone.replaceAll(RegExp(r'\D'), '');
    final phoneWithCode = cleanPhone.length == 10 ? "91$cleanPhone" : cleanPhone;

    String text = "";
    if (template == 'cancelled') {
      text = "Hi ${_appt.patient.name}, your appointment with ${_appt.doctorName} on ${DateFormat('MMM dd, yyyy').format(_appt.dateTime)} has been CANCELLED. We apologize for the inconvenience.";
    } else {
      text = "Hi ${_appt.patient.name}, this is regarding your appointment at ${_appt.clinicName}.";
    }

    final Uri launchUri = Uri.parse("https://wa.me/$phoneWithCode?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  // 🚀 Doctor WhatsApp (Send Details to Doctor's Number)
  Future<void> _openWhatsAppDoctor() async {
    // Check doctor phone first, fallback to clinic phone if empty
    final targetPhone = _appt.doctorPhone.isNotEmpty ? _appt.doctorPhone : _appt.clinicPhone;
    
    if (targetPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doctor/Clinic phone number not available")));
      return;
    }
    
    final cleanPhone = targetPhone.replaceAll(RegExp(r'\D'), '');
    final phoneWithCode = cleanPhone.length == 10 ? "91$cleanPhone" : cleanPhone;

    String text = "Hello ${_appt.doctorName},\n\nHere are the details for an upcoming appointment:\n\n"
        "🏥 *Clinic:* ${_appt.clinicName}\n"
        "📅 *Date:* ${DateFormat('MMM dd, yyyy').format(_appt.dateTime)}\n"
        "⏰ *Time:* ${_appt.startTime} - ${_appt.endTime}\n"
        "🎫 *Slot:* ${_appt.slotNumber}\n\n"
        "👤 *Patient:* ${_appt.patient.name}\n"
        "📞 *Phone:* ${_appt.patient.phone}\n"
        "🔢 *Age/Gender:* ${_appt.patient.age} / ${_appt.patient.gender}\n\n"
        "Please confirm if you are available. Thank you!";

    final Uri launchUri = Uri.parse("https://wa.me/$phoneWithCode?text=${Uri.encodeComponent(text)}");
    if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
  }

  // --- 🚀 3-DOTS ACTION MENU ---
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bgCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final isActive = ['pending', 'confirmed', 'checked_in'].contains(_appt.status);

        return Padding(
          padding: const EdgeInsets.only(bottom: 32, top: 12, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5, width: 40,
                decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 24),
              Text("Actions", style: TextStyle(color: _textMain, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
              const SizedBox(height: 16),
              Divider(color: _border, height: 1),
              const SizedBox(height: 8),

              // Menu Item: View Details
              _buildMenuAction(LucideIcons.info, "View Details", _textMain, () => Navigator.pop(context)),

              if (isActive) ...[
                // 🚀 Menu Item: Confirm Appointment (If Pending)
                if (_appt.status == 'pending')
                  _buildMenuAction(
                    LucideIcons.checkCircle2,
                    "Confirm Booking",
                    Colors.blue.shade600,
                    () { Navigator.pop(context); _updateStatusViaApi('confirmed'); },
                  ),
                  
                // 🚀 Menu Item: Cancel Booking
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: _border, height: 1),
                ),
                _buildMenuAction(
                  LucideIcons.ban,
                  "Cancel Booking",
                  Colors.red.shade600,
                  () {
                    Navigator.pop(context);
                    _updateStatusViaApi('cancelled');
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color == _textMain ? _border.withValues(alpha: 0.5) : color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color == _textMain ? _textSub : color, size: 18),
      ),
      title: Text(label, style: TextStyle(color: color == _textMain ? _textMain : color, fontSize: 15, fontWeight: FontWeight.w600)),
      onTap: onTap,
      dense: true,
      horizontalTitleGap: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic Status Display
    Color statusColor;
    IconData statusIcon;
    String statusMsg;

    switch (_appt.status) {
      case 'pending':
        statusColor = Colors.orange.shade600;
        statusIcon = LucideIcons.clock;
        statusMsg = "Pending Confirmation";
        break;
      case 'confirmed':
        statusColor = Colors.blue.shade600;
        statusIcon = LucideIcons.calendarCheck;
        statusMsg = "Appointment Confirmed";
        break;
      case 'checked_in':
        statusColor = Colors.purple.shade600;
        statusIcon = LucideIcons.arrowRightCircle;
        statusMsg = "Patient Checked In";
        break;
      case 'completed':
        statusColor = Colors.green.shade600;
        statusIcon = LucideIcons.checkCircle;
        statusMsg = "Consultation Complete";
        break;
      case 'cancelled':
        statusColor = Colors.red.shade600;
        statusIcon = LucideIcons.ban;
        statusMsg = "Booking Cancelled";
        break;
      case 'no_show':
        statusColor = Colors.grey.shade600;
        statusIcon = LucideIcons.userX;
        statusMsg = "Patient No-Show";
        break;
      default:
        statusColor = _primary;
        statusIcon = LucideIcons.info;
        statusMsg = "Unknown Status";
    }

    return Scaffold(
      backgroundColor: _bgMain,
      appBar: AppBar(
        backgroundColor: _bgMain,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: _textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Booking Details",
          style: TextStyle(color: _textMain, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        ),
        centerTitle: true,
        actions: [
          // 🚀 3 Dots Menu Button
          IconButton(
            onPressed: _showActionMenu,
            icon: Icon(LucideIcons.moreVertical, color: _textMain, size: 24),
          ),
        ],
      ),
      body: _isLoadingAction 
        ? Center(child: CircularProgressIndicator(color: _primary)) 
        : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // --- 1. STATUS CARD ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: statusColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(statusMsg, style: TextStyle(color: _textMain, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _bgMain, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
                    child: Text("Token #${_appt.slotNumber}", style: TextStyle(color: _textSub, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 2. PATIENT INFO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("PATIENT DETAILS", style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text(_appt.patient.name.isNotEmpty ? _appt.patient.name[0].toUpperCase() : "U", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _primary))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_appt.patient.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text("${_appt.patient.age} Years • ${_appt.patient.phone}", style: TextStyle(color: _textSub, fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _border, height: 1),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildActionButton(LucideIcons.phone, "Call Patient", Colors.green.shade600, () => _makePhoneCall(_appt.patient.phone))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildActionButton(LucideIcons.messageCircle, "WhatsApp", Colors.teal.shade600, () => _openWhatsAppPatient())),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 3. DOCTOR INFO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DOCTOR DETAILS", style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Center(child: Text(_appt.doctorName.isNotEmpty ? _appt.doctorName.replaceAll('Dr. ', '')[0].toUpperCase() : "D", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.indigo))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_appt.doctorName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _textMain, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(_appt.clinicName, style: TextStyle(color: _textSub, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: _border, height: 1),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // 🚀 Calls doctor phone directly (or fallback to clinic phone)
                      Expanded(child: _buildActionButton(LucideIcons.phone, "Call Doctor", Colors.indigo.shade600, () => _makePhoneCall(_appt.doctorPhone.isNotEmpty ? _appt.doctorPhone : _appt.clinicPhone))),
                      const SizedBox(width: 12),
                      // 🚀 Sends full details to doctor's WhatsApp
                      Expanded(child: _buildActionButton(LucideIcons.send, "Send Details", Colors.blue.shade600, () => _openWhatsAppDoctor())),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- 4. SCHEDULE INFO ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("SCHEDULE INFO", style: TextStyle(color: _textSub, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                  _buildDetailRow(LucideIcons.calendarDays, "Date", DateFormat('MMM dd, yyyy').format(_appt.dateTime)), 
                  _buildDetailRow(LucideIcons.clock, "Time", "${_appt.startTime} - ${_appt.endTime}"),
                  if (_appt.extraServices.isNotEmpty)
                    _buildDetailRow(LucideIcons.activity, "Services", _appt.extraServices.map((e) => e.name).join(", ")),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),

      // --- 🚀 DYNAMIC BOTTOM ACTION BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _bgCard, border: Border(top: BorderSide(color: _border)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: SafeArea(
          child: Row(
            children: [
              // 🚀 If Pending -> Confirm Appointment
              if (_appt.status == 'pending')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatusViaApi('confirmed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Confirm Appointment", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              // 🚀 If Confirmed -> Check In
              if (_appt.status == 'confirmed')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatusViaApi('checked_in'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade600, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Check In Patient", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              // 🚀 If Checked In -> Mark Completed
              if (_appt.status == 'checked_in')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatusViaApi('completed'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Mark Completed", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              // 🚀 If action is complete/cancelled, do not show bottom bar (or you can show "View Invoice" etc. later)
              if (['completed', 'cancelled', 'no_show'].contains(_appt.status))
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context), // Go back
                    style: ElevatedButton.styleFrom(backgroundColor: _border.withValues(alpha: 0.5), foregroundColor: _textMain, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: const Text("Close", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPONENTS ---
  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color.withValues(alpha: 0.15)), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _bgMain, borderRadius: BorderRadius.circular(8), border: Border.all(color: _border)),
            child: Icon(icon, size: 16, color: _textSub),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _textSub, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: _textMain, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}