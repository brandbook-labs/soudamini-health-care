import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../services/api_service.dart';
import 'cancel_appointment_screen.dart';
import '../../../models/appointment_model.dart'; 
import '../home_widgets/global_map_widget.dart'; // 🚀 Map Widget

const Color kGreenColor = Color(0xFF16A34A);
const Color kOrangeColor = Color(0xFFF59E0B);
const Color kRedColor = Color(0xFFEF4444);
const Color kBlueColor = Color(0xFF2563EB);

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;
  const AppointmentDetailsScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  Appointment? _appointment;
  bool _isCheckedIn = false;

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    try {
      final response = await _apiService.getAppointmentDetails(
        tokenKey: 'auth_token',
        appointmentId: widget.appointmentId,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        if (mounted) {
          setState(() {
            _appointment = Appointment.fromJson(response.data['data']);
            _isCheckedIn = (_appointment!.status == 'checked_in');
            _isLoading = false;
          });
        }
      } else {
        _handleError("Failed to load details");
      }
    } catch (e) {
      _handleError("Error: ${e.toString()}");
    }
  }

  void _handleError(String msg) {
    if (mounted) {
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
    }
  }

  void _showCheckInConfirmation() {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: kGreenColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.mapPin, color: kGreenColor, size: 32),
                ),
                const SizedBox(height: 16),
                Text("Have you reached?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(
                  "Please confirm only if you are physically present at the clinic.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Not yet"),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _performCheckIn();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: kGreenColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text("Yes, I'm here", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _performCheckIn() async {
    try {
      await _apiService.markPatientReached(tokenKey: 'auth_token', appointmentId: widget.appointmentId);
      setState(() => _isCheckedIn = true);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Checked in successfully!"), backgroundColor: kGreenColor, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to check in."), backgroundColor: kRedColor)
        );
      }
    }
  }

  void _handleCancel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CancelBottomSheet(
        appointmentId: widget.appointmentId,
        apiService: _apiService,
        onSuccess: () {
          Navigator.pop(ctx); // BottomSheet ବନ୍ଦ କରିବ
          Navigator.pop(context, true); // Details ପେଜ୍ ରୁ ବ୍ୟାକ୍ ଯାଇ ଲିଷ୍ଟ୍ ରିଫ୍ରେସ୍ କରିବ
        },
      ),
    );
  }

  void _launchDialer() {
    if (_appointment != null && _appointment!.clinicPhone.isNotEmpty) {
      launchUrl(Uri.parse("tel:+91${_appointment!.clinicPhone}"));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number not available.")));
    }
  }

  void _launchMaps() {
    if (_appointment != null && _appointment!.clinicLat != null && _appointment!.clinicLng != null) {
      final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${_appointment!.clinicLat},${_appointment!.clinicLng}");
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not available.")));
    }
  }

  // Helper for capitalize
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    final subTextColor = theme.colorScheme.onSurfaceVariant;
    final borderColor = theme.dividerColor.withValues(alpha: 0.1);

    if (_isLoading) {
      return Scaffold(backgroundColor: backgroundColor, appBar: AppBar(backgroundColor: backgroundColor, elevation: 0), body: Center(child: CircularProgressIndicator(color: primaryColor)));
    }

    if (_errorMessage != null || _appointment == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(backgroundColor: backgroundColor, elevation: 0, leading: BackButton(color: textColor)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(_errorMessage ?? "Something went wrong", style: TextStyle(color: textColor)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() { _isLoading = true; _errorMessage = null; });
                  _fetchAppointmentDetails();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final appt = _appointment!;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(LucideIcons.arrowLeft, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Booking Details", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. DOCTOR CARD ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(image: NetworkImage(appt.doctorImage), fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appt.doctorName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(capitalize(appt.specialty), style: TextStyle(color: subTextColor, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: appt.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(appt.status.toUpperCase(), style: TextStyle(color: appt.statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn("Date", DateFormat('MMM dd, yyyy').format(appt.dateTime), LucideIcons.calendar, textColor, subTextColor),
                            _buildInfoColumn("Time", DateFormat('h:mm a').format(appt.dateTime), LucideIcons.clock, textColor, subTextColor),
                            _buildInfoColumn("Token", appt.slotNumber, LucideIcons.ticket, primaryColor, subTextColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 2. ACTIONS ---
                  if (!appt.isFinished) ...[
                    Text("ACTIONS", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildActionButton(context, icon: LucideIcons.phone, label: "Call", color: Colors.blue, onTap: _launchDialer),
                        const SizedBox(width: 12),
                        _buildActionButton(context, icon: LucideIcons.mapPin, label: "Map", color: kOrangeColor, onTap: _launchMaps),
                        // 🚀 Reschedule Commented Out
                        // const SizedBox(width: 12),
                        // _buildActionButton(context, icon: LucideIcons.calendarClock, label: "Reschedule", color: Colors.purple, onTap: _handleReschedule, isDisabled: _isCheckedIn),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- 3. PATIENT DETAILS (NEW) ---
                  Text("PATIENT DETAILS", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      children: [
                        _buildRow("Name", appt.patient.name, textColor, subTextColor),
                        const SizedBox(height: 12),
                        _buildRow("Age / Gender", "${appt.patient.age} Yrs, ${appt.patient.gender}", textColor, subTextColor),
                        const SizedBox(height: 12),
                        _buildRow("Phone", "+91 ${appt.patient.phone}", textColor, subTextColor),
                        const SizedBox(height: 12),
                        _buildRow("Booked By", appt.bookedBy, textColor, subTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. CLINIC INFO & MAP (NEW) ---
                  Text("CLINIC DETAILS", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(LucideIcons.building2, size: 20, color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(appt.clinicName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(appt.clinicAddress, style: TextStyle(fontSize: 13, color: subTextColor, height: 1.4)),
                                ],
                              ),
                            )
                          ],
                        ),
                        // 🚀 Map Widget if location exists
                        if (appt.clinicLat != null && appt.clinicLng != null) ...[
                          const SizedBox(height: 16),
                          GlobalMapWidget(lat: appt.clinicLat!, lng: appt.clinicLng!, title: "Location Map"),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 5. BILLING & EXTRA SERVICES (NEW) ---
                  Text("BILLING SUMMARY", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // _buildRow("Consultation Fee", "₹${appt.totalCost - (appt.extraServices.length * 150)}", textColor, subTextColor), // Example calculation
                        
                        // Extra Services List
                        if (appt.extraServices.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(height: 1, color: borderColor),
                          const SizedBox(height: 12),
                          Text("Additional Services:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: subTextColor)),
                          const SizedBox(height: 8),
                          ...appt.extraServices.map((service) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(LucideIcons.checkCircle2, size: 14, color: kGreenColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text("${service.name} (x${service.count})", style: TextStyle(fontSize: 13, color: textColor))),
                              ],
                            ),
                          )),
                        ],
                        
                        const SizedBox(height: 12),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 12),
                        _buildRow("Total Amount", "₹${appt.totalCost}", primaryColor, subTextColor),
                        const SizedBox(height: 8),
                        _buildRow("Payment Mode", capitalize(appt.paymentMethod), kOrangeColor, subTextColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- 6. CANCEL BUTTON ---
                  if (!appt.isFinished)
                    Center(
                      child: TextButton.icon(
                        onPressed: _isCheckedIn ? null : _handleCancel,
                        icon: Icon(LucideIcons.xCircle, size: 18, color: _isCheckedIn ? subTextColor : kRedColor),
                        label: Text("Cancel Appointment", style: TextStyle(color: _isCheckedIn ? subTextColor : kRedColor, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // --- CHECK-IN BUTTON ---
          if (!appt.isFinished)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cardColor, border: Border(top: BorderSide(color: borderColor))),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isCheckedIn || !appt.isCheckInAllowed)
                      ? () {
                          if (!appt.isCheckInAllowed && !_isCheckedIn) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appt.checkInDisabledMessage)));
                          }
                        }
                      : _showCheckInConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCheckedIn ? kGreenColor : (!appt.isCheckInAllowed ? Colors.grey : primaryColor),
                    disabledBackgroundColor: kGreenColor.withValues(alpha: 0.8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isCheckedIn
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, color: Colors.white),
                            SizedBox(width: 8),
                            Text("You are Checked In", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        )
                      : Text(
                          appt.checkInDisabledMessage,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap, bool isDisabled = false}) {
    final theme = Theme.of(context);
    final effectiveColor = isDisabled ? theme.disabledColor : color;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: effectiveColor, size: 24),
                const SizedBox(height: 8),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: effectiveColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, Color valueColor, Color labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: labelColor),
            const SizedBox(width: 4),
            Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }

  Widget _buildRow(String label, String value, Color valueColor, Color labelColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}


// =============================================================================
// 🚀 CANCEL APPOINTMENT BOTTOM SHEET (Senior Level UX)
// =============================================================================
class _CancelBottomSheet extends StatefulWidget {
  final String appointmentId;
  final ApiService apiService;
  final VoidCallback onSuccess;

  const _CancelBottomSheet({
    required this.appointmentId,
    required this.apiService,
    required this.onSuccess,
  });

  @override
  State<_CancelBottomSheet> createState() => _CancelBottomSheetState();
}

class _CancelBottomSheetState extends State<_CancelBottomSheet> {
  String _selectedReason = "I have a scheduling conflict";
  final TextEditingController _otherReasonController = TextEditingController();
  bool _isLoading = false;

  // 🚀 ପ୍ରି-ଡିଫାଇନ୍ଡ୍ କାରଣ (Common Reasons)
  final List<String> _reasons = [
    "I have a scheduling conflict",
    "I am feeling better now",
    "Found another doctor/clinic",
    "Wait time was too long",
    "Financial issue",
    "Other"
  ];

  Future<void> _submitCancellation() async {
    // ଯଦି Other ବାଛିଛନ୍ତି, ତେବେ ଟେକ୍ସଟ୍ ବକ୍ସ ରୁ ଡାଟା ଆଣିବେ
    String finalReason = _selectedReason == "Other"
        ? _otherReasonController.text.trim()
        : _selectedReason;

    if (finalReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide a reason for cancellation."), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🚀 ଆପଣଙ୍କର ସଠିକ୍ API Call
      final response = await widget.apiService.cancelAppointment(
        tokenKey: 'auth_token', 
        appointmentId: widget.appointmentId,
        cancelReason: finalReason,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Appointment cancelled successfully."), backgroundColor: kGreenColor),
          );
          widget.onSuccess(); // ରିଫ୍ରେସ୍ କରିବାକୁ ପଛକୁ ଯିବ
        }
      }
    } catch (e) {
      // 🚀 BACKEND ERRORS (ଯେମିତିକି ୩-ଥର ଲିମିଟ୍ ପାର୍ ହୋଇଗଲେ)
      if (mounted) {
        String errorMsg = "Failed to cancel appointment.";
        if (e is DioException && e.response?.data != null) {
          errorMsg = e.response!.data['message'] ?? errorMsg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      // କିବୋର୍ଡ୍ (Keyboard) ଖୋଲିଲେ ଯେମିତି ଉପରକୁ ଉଠିବ ତାହାର ସେଟିଂ
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              "Cancel Appointment",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              "Please let us know why you are cancelling. This helps us improve our service.",
              style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // 🚀 Reason List (Radio Buttons)
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                activeColor: kRedColor, // କ୍ୟାନ୍ସଲ୍ ହେଉଛି ତେଣୁ ଲାଲ୍ ରଙ୍ଗ
                title: Text(reason, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (val) {
                  setState(() => _selectedReason = val!);
                },
              );
            }),

            // 🚀 ଯଦି 'Other' ସିଲେକ୍ଟ ହୁଏ, Text Field ଦେଖାନ୍ତୁ
            if (_selectedReason == "Other") ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherReasonController,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: "Type your reason...",
                  filled: true,
                  fillColor: isDark ? kDarkCard : Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // 🚀 Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCancellation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRedColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm Cancellation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}