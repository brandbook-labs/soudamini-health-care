// lib/screens/admin/adminUsers/adminPatients/admin_patients_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/patientProfile/patient_profile_screen.dart';

import 'models/patient_model.dart';
import 'widgets/patient_stat_card.dart';
import 'widgets/patient_list_card.dart';

class AdminPatientsScreen extends StatefulWidget {
  const AdminPatientsScreen({super.key});

  @override
  State<AdminPatientsScreen> createState() => _AdminPatientsScreenState();
}

class _AdminPatientsScreenState extends State<AdminPatientsScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Patient> _allPatients = [];
  List<Patient> _filteredPatients = [];
  bool _isLoading = true;

  int _displayCount = 20; 
  final int _chunkSize = 20; 

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchDialer(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      debugPrint("Could not launch dialer: $e");
    }
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final fullNumber = cleanNumber.length == 10 ? "91$cleanNumber" : cleanNumber;
    final Uri url = Uri.parse("https://wa.me/$fullNumber");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch WhatsApp: $e");
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPatients = _allPatients.where((p) {
        return p.name.toLowerCase().contains(query) || p.phone.contains(query);
      }).toList();
      _displayCount = _chunkSize; 
    });
  }

  Future<void> _fetchPatients() async {
    if (_allPatients.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _apiService.getActualPatients();

      if (response.statusCode == 200 && response.data != null) {
        final List data = response.data['data'] ?? [];
        List<Patient> processedList = [];

        for (var item in data) {
          processedList.add(Patient.fromJson(item)); 
        }

        processedList.sort(
          (a, b) => b.lastVisitDate.compareTo(a.lastVisitDate),
        );

        if (mounted) {
          setState(() {
            _allPatients = processedList;
            if (_searchController.text.isNotEmpty) {
              _onSearchChanged();
            } else {
              _filteredPatients = processedList;
              _displayCount = _chunkSize; 
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching actual patients: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification && notification.metrics.extentAfter == 0) {
      if (_displayCount < _filteredPatients.length) {
        setState(() {
          _displayCount += _chunkSize;
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final displayedPatients = _filteredPatients.take(_displayCount).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: RefreshIndicator(
          onRefresh: _fetchPatients,
          color: colorScheme.primary,
          backgroundColor: theme.cardColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Patient Directory",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Search, view, and manage registered patients.",
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "Search name, phone...",
                        hintStyle: textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                        prefixIcon: Icon(
                          LucideIcons.search,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: PatientStatCard(
                          title: "Total",
                          count: "${_allPatients.length}",
                          iconColor: colorScheme.primary,
                          icon: LucideIcons.users,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PatientStatCard(
                          title: "Month",
                          count: "${_allPatients.where((p) => p.lastVisitDate.month == DateTime.now().month && p.lastVisitDate.year == DateTime.now().year).length}",
                          iconColor: Colors.orange.shade600,
                          icon: LucideIcons.calendarDays,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: PatientStatCard(
                          title: "Today",
                          count: "${_allPatients.where((p) => p.lastVisitDate.year == DateTime.now().year && p.lastVisitDate.month == DateTime.now().month && p.lastVisitDate.day == DateTime.now().day).length}",
                          iconColor: Colors.blue.shade600, 
                          icon: LucideIcons.clock, 
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (_isLoading && _allPatients.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filteredPatients.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.users, size: 48, color: theme.dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          "No patients found",
                          style: TextStyle(color: theme.disabledColor, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final itemIndex = index ~/ 2;

                    if (index.isEven) {
                      final patient = displayedPatients[itemIndex];
                      return PatientListCard(
                        patient: patient,
                        onCall: () => _launchDialer(patient.phone),
                        onChat: () => _launchWhatsApp(patient.phone),
                        onTap: () {
                          // 🚀 [THE FIX]: ଏଠାରେ phone ଏବଂ name ପାସ୍ କରାଯାଉଛି 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PatientProfileScreen(
                                phone: patient.phone, // 🚀 Changed from patientId
                                name: patient.name,   // 🚀 Passed Name for Query
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return Divider(
                        height: 1,
                        thickness: 1,
                        color: theme.dividerColor.withValues(alpha: 0.2),
                      );
                    }
                  }, childCount: math.max(0, displayedPatients.length * 2 - 1)),
                ),

              if (_displayCount < _filteredPatients.length)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}