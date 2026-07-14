import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_new_app/services/api_service.dart';

import 'widgets/quick_action_button.dart';
import 'widgets/patient_global_card.dart';
import 'widgets/current_visit_snapshot.dart';
import 'widgets/patient_tabbed_content.dart';

class PatientProfileScreen extends StatefulWidget {
  final String phone; 
  final String name;

  const PatientProfileScreen({super.key, required this.phone, required this.name});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  Map<String, dynamic>? _patientData;
  
  Map<String, dynamic>? _upcomingAppointment;
  List<dynamic> _clinicalHistory = [];
  List<dynamic> _billingHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
  }

  Future<void> _fetchPatientData() async {
    try {
      final response = await _apiService.getPatientDetails(widget.phone, name: widget.name);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        
        final List allAppointments = data['appointment_history'] ?? [];
        Map<String, dynamic>? upcoming;
        List<dynamic> history = [];

        if (allAppointments.isNotEmpty) {
          upcoming = allAppointments[0]; 
          if (allAppointments.length > 1) {
            history = allAppointments.sublist(1);
          }
        }

        if (mounted) {
          setState(() {
            _patientData = data;
            _upcomingAppointment = upcoming;
            _clinicalHistory = history;
            _billingHistory = data['billing'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching patient details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchDialer(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber, String name) async {
    if (phoneNumber.isEmpty) return;
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final fullNumber = cleanNumber.length == 10 ? "91$cleanNumber" : cleanNumber;
    final message = Uri.encodeComponent("Hello $name, this is regarding your appointment...");
    final Uri url = Uri.parse("https://wa.me/$fullNumber?text=$message");
    
    try {
      if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Patient Profile")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_patientData == null) {
      return Scaffold(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text("Patient Profile")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.userX, size: 48, color: context.colorScheme.outline),
              const SizedBox(height: 16),
              Text("Patient record not found.", style: context.text.titleMedium?.copyWith(color: context.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final pInfo = _patientData!['patient_info'] ?? {};
    final name = pInfo['name'] ?? widget.name; 
    final phone = pInfo['phone']?.toString() ?? widget.phone; 
    final age = pInfo['age']?.toString() ?? 'N/A';
    final gender = pInfo['gender'] ?? 'Unknown';
    final lastVisit = pInfo['last_visit'] ?? 'N/A';

    final demographicsStr = "$age Yrs  •  $gender  •  Last Visit: $lastVisit";
    final avatarUrlStr = "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=074EE7&color=fff&size=128";

    // 🚀 ଏକ୍ସଟ୍ରାକ୍ଟ Overview ଏବଂ Booked By
    final overviewData = _patientData!['overview'] ?? {};
    final bookedByData = _patientData!['booked_by'] ?? {};

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Patient Profile"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                QuickActionButton(icon: LucideIcons.messageSquare, label: "Message", onTap: () => _launchWhatsApp(phone, name)),
                const SizedBox(width: 8),
                QuickActionButton(icon: LucideIcons.phone, label: "Call", onTap: () => _launchDialer(phone)),
              ],
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          final globalCard = PatientGlobalCard(
            patientName: name,
            patientId: phone, 
            phoneNumber: phone,
            demographics: demographicsStr,
            avatarUrl: avatarUrlStr,
          );

          final visitSnapshotCard = _upcomingAppointment != null 
              ? CurrentVisitSnapshot(
                  appointmentData: _upcomingAppointment!,
                )
              : const SizedBox.shrink();

          // 🚀 ଟ୍ୟାବ୍ କୁ ନୂଆ ଡାଟା ପାସ୍
          final tabbedContent = PatientTabbedContent(
            overviewData: overviewData,     // 🚀 ପାସ୍ overview
            bookedByData: bookedByData,     // 🚀 ପାସ୍ bookedBy
            clinicalHistory: _clinicalHistory,
            billingHistory: _billingHistory,
          );

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: constraints.maxWidth * 0.3,
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        globalCard,
                        if (_upcomingAppointment != null) const SizedBox(height: 16),
                        visitSnapshotCard, 
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: context.colorScheme.outlineVariant))),
                    child: tabbedContent, 
                  ),
                ),
              ],
            );
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      globalCard,
                      if (_upcomingAppointment != null) const SizedBox(height: 16),
                      visitSnapshotCard, 
                    ],
                  ),
                ),
              ),
            ],
            body: tabbedContent,
          );
        },
      ),
    );
  }
}