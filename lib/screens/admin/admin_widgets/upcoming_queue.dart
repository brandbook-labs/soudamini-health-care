// lib/screens/admin/adminAppointments/widgets/upcoming_queue.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/screens/admin/adminAppointments/admin_appointments_screen.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/models/appointment_model.dart'; 
// 🚀 Added Details Screen Import
import 'package:my_new_app/screens/admin/adminAppointments/appointment_details_screen.dart';

class UpcomingQueue extends StatefulWidget {
  const UpcomingQueue({super.key});

  @override
  State<UpcomingQueue> createState() => _UpcomingQueueState();
}

class _UpcomingQueueState extends State<UpcomingQueue> {
  final ApiService _apiService = ApiService();

  List<Appointment> _queueList = [];
  List<Map<String, dynamic>> _availableDoctors = [];
  String _selectedDoctorId = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  Future<void> _fetchQueue() async {
    if (!mounted) return;
    if (_queueList.isEmpty) setState(() => _isLoading = true);

    try {
      final response = await _apiService.getAppointmentList(
        tokenKey: 'admin_token',
        type: 'upcoming',
        today: true,
      );

      if (response.statusCode == 200) {
        final List rawData = response.data['data']['appointments'] ?? response.data['data']['results'] ?? [];

        List<Appointment> parsedList = rawData.map((e) => Appointment.fromJson(e)).toList();

        parsedList = parsedList.where((appt) {
          return ['pending', 'confirmed', 'checked_in'].contains(appt.status);
        }).toList();

        final Set<String> docIds = {};
        final List<Map<String, dynamic>> docs = [];

        for (var appt in parsedList) {
          if (appt.doctorId.isNotEmpty && !docIds.contains(appt.doctorId)) {
            docIds.add(appt.doctorId);
            docs.add({'id': appt.doctorId, 'name': appt.doctorName});
          }
        }

        parsedList.sort((a, b) {
          int timeComp = a.dateTime.compareTo(b.dateTime);
          if (timeComp != 0) return timeComp;
          
          int slotA = int.tryParse(a.slotNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          int slotB = int.tryParse(b.slotNumber.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return slotA.compareTo(slotB);
        });

        if (mounted) {
          setState(() {
            _queueList = parsedList;
            _availableDoctors = docs;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String id, String currentStatus) async {
    String nextStatus;
    Future<dynamic> Function()? apiCall;

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

    setState(() {
      if (nextStatus == 'completed') {
        _queueList.removeWhere((item) => item.id == id);
      } else {
        final index = _queueList.indexWhere((item) => item.id == id);
        if (index != -1) {
          final oldAppt = _queueList[index];
          List<Appointment> updatedList = List.from(_queueList);
          
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
            status: nextStatus,           
            type: oldAppt.type,
            clinicPhone: oldAppt.clinicPhone,
            slotNumber: oldAppt.slotNumber,
            totalCost: oldAppt.totalCost,
            paymentMethod: oldAppt.paymentMethod,
            patient: oldAppt.patient,
            extraServices: oldAppt.extraServices,
            bookedBy: oldAppt.bookedBy,
          );
          
          _queueList = updatedList;
        }
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marking as ${nextStatus.toUpperCase()}..."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    try {
      if (apiCall != null) await apiCall();
      _fetchQueue(); 
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update: $e"), backgroundColor: Colors.red));
      _fetchQueue(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredQueue = _selectedDoctorId == 'all'
        ? _queueList
        : _queueList.where((q) => q.doctorId == _selectedDoctorId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Upcoming Queue",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminAppointmentsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        "View All",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(LucideIcons.arrowRight, size: 14, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- DOCTOR FILTER CHIPS ---
        if (!_isLoading && _availableDoctors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Doctors', theme),
                  ..._availableDoctors.map(
                    (doc) => _buildFilterChip(doc['id'], doc['name'], theme),
                  ),
                ],
              ),
            ),
          ),

        // --- UNIFIED LIST CONTAINER ---
        if (_isLoading)
          _buildLoadingState(theme)
        else if (filteredQueue.isEmpty)
          _buildEmptyState(theme)
        else
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero, 
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredQueue.length > 5 ? 5 : filteredQueue.length,
                separatorBuilder: (ctx, index) => Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.15),
                ),
                itemBuilder: (context, index) {
                  final appt = filteredQueue[index];
                  return _QueueRow(
                    appointment: appt, 
                    isNext: index == 0,
                    onAction: () => _handleAction(appt.id, appt.status),
                    // 🚀 Added onTap to navigate to Details Screen
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AppointmentDetailsScreen(appointment: appt),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String id, String label, ThemeData theme) {
    final isSelected = _selectedDoctorId == id;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedDoctorId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label.startsWith('Dr.') ? label : (id == 'all' ? label : 'Dr. $label'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : theme.hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(LucideIcons.calendarCheck, size: 32, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            "Queue is clear",
            style: TextStyle(
              color: theme.hintColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: List.generate(
          3,
          (i) => Column(
            children: [
              Container(height: 70, color: theme.cardColor.withValues(alpha: 0.5)),
              if (i < 2) Divider(height: 1, thickness: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 🚀 SAAS-LEVEL QUEUE ROW
// ==========================================
class _QueueRow extends StatelessWidget {
  final Appointment appointment; 
  final bool isNext;
  final VoidCallback onAction;
  final VoidCallback onTap; // 🚀 Added Tap callback

  const _QueueRow({
    required this.appointment,
    required this.onAction,
    required this.onTap, // 🚀 Required
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // UI Config based on status
    Color statusColor;
    IconData actionIcon;
    String statusText; // 🚀 Added Status Text

    if (appointment.status == 'pending') {
      statusColor = Colors.orange.shade600;
      actionIcon = LucideIcons.check; 
      statusText = "PENDING";
    } else if (appointment.status == 'confirmed') {
      statusColor = Colors.blue.shade600; 
      actionIcon = LucideIcons.mapPin; 
      statusText = "CONFIRMED";
    } else if (appointment.status == 'checked_in') {
      statusColor = theme.colorScheme.primary; 
      actionIcon = LucideIcons.checkCheck; 
      statusText = "CHECKED IN";
    } else {
      statusColor = Colors.grey; 
      actionIcon = LucideIcons.info; 
      statusText = appointment.status.toUpperCase();
    }

    final isPaid = appointment.paymentMethod.toLowerCase().contains('paid');

    // 🚀 Only show Start Time parsing
    String timeNumber = "";
    String timeMeridian = "";
    try {
       // Since startTime is like "9:00 AM"
       final timeParts = appointment.startTime.split(' ');
       timeNumber = timeParts[0];
       timeMeridian = timeParts.length > 1 ? timeParts[1] : '';
    } catch (_) {}

    return GestureDetector(
      onTap: onTap, // 🚀 Makes the whole row clickable
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- 1. MINIMALIST TIME & SLOT ---
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: timeNumber,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (timeMeridian.isNotEmpty)
                            TextSpan(
                              text: " $timeMeridian",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: theme.hintColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "SLOT ${appointment.slotNumber}",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: theme.hintColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Separator line
              Container(
                height: 36, 
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: theme.dividerColor.withValues(alpha: 0.2),
              ),

              // --- 2. PATIENT INFO & STATUS ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            appointment.patient.name, 
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // 🚀 New: Dynamic Status Badge next to name
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: statusColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 6),
                        
                        // Payment Badge
                        if (isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PAID',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${appointment.patient.age != '-' ? '${appointment.patient.age} Yrs • ' : ''}${appointment.doctorName}",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.hintColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // --- 3. ACTION BUTTON ---
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  // 🚀 Prevent row tap from firing when action button is tapped
                  onAction();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Icon(actionIcon, size: 16, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}