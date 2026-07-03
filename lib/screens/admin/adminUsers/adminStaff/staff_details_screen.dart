import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/models/patient_model.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/patientProfile/patient_profile_screen.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminPatients/widgets/patient_list_card.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/admin/adminUsers/adminStaff/add_staff_screen.dart'; 
import 'package:my_new_app/models/staff_model.dart';

class StaffDetailsScreen extends StatefulWidget {
  final Staff staff;

  const StaffDetailsScreen({super.key, required this.staff});

  @override
  State<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends State<StaffDetailsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService(); 

  late TabController _tabController;
  late List<String> _tabs;
  
  late String _roleType;
  late String _roleDisplay;
  late String _clinicName;
  late String _departmentName;
  late String _joinedDate;

  late Staff currentStaff; 
  bool _isFetchingDetails = false;

  // 🚀 APIs State
  bool _isLoadingAnalytics = false;
  Map<String, dynamic>? _analyticsData;
  
  bool _isLoadingPatients = false;
  List<dynamic> _patientsList = [];

  // 🚀 [NEW REQUIREMENT]: Analytics Date Filter State
  DateTime _analyticsDate = DateTime.now();
  String _analyticsViewType = 'daily'; // 'daily' or 'monthly'

  @override
  void initState() {
    super.initState();
    currentStaff = widget.staff; 
    _normalizeData();

    if (_roleType == 'doctor') {
      _tabs = ["Overview", "Analytics", "Patients", "Info"]; 
    } else {
      _tabs = ["Overview", "Info"]; 
    }
    _tabController = TabController(length: _tabs.length, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStaffDetails();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabs[_tabController.index] == "Analytics" && _analyticsData == null) {
          _fetchAnalytics();
        } else if (_tabs[_tabController.index] == "Patients" && _patientsList.isEmpty) {
          _fetchPatients();
        }
      }
    });
  }

  Future<void> _fetchStaffDetails() async {
    setState(() => _isFetchingDetails = true);
    try {
      final String editId = currentStaff.mappingId.isNotEmpty ? currentStaff.mappingId : currentStaff.id;
      final Staff fetchedStaff = await _apiService.getAdminStaffDetails(editId);
      
      if (mounted) {
        setState(() {
          currentStaff = fetchedStaff;
          _normalizeData(); 
          _isFetchingDetails = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
      if (mounted) setState(() => _isFetchingDetails = false);
    }
  }
                               
 // 🚀 [UPDATED REQUIREMENT]: Fetch Analytics with Date/Month Params & Staff ID
  Future<void> _fetchAnalytics() async {
    setState(() => _isLoadingAnalytics = true);
    
    try {
      String? dateParam;
      String? monthParam;

      // Format logic for API
      final String yyyy = _analyticsDate.year.toString();
      final String mm = _analyticsDate.month.toString().padLeft(2, '0');
      final String dd = _analyticsDate.day.toString().padLeft(2, '0');

      if (_analyticsViewType == 'daily') {
        dateParam = "$yyyy-$mm-$dd";
      } else {
        monthParam = "$yyyy-$mm";
      }

      // 🚀 SENIOR FIX: ସର୍ବଦା କେବଳ ଗ୍ଲୋବାଲ୍ Staff/Doctor ID ପଠାନ୍ତୁ (No Mapping ID)
      final String targetDoctorId = currentStaff.id;

      // ଯଦି କୌଣସି କାରଣରୁ ID ଖାଲି ଥାଏ, ତେବେ API କଲ୍ ନକରି ଫେରିଯାଆନ୍ତୁ
      if (targetDoctorId.isEmpty) {
        if (mounted) {
          setState(() {
            _analyticsData = null;
            _isLoadingAnalytics = false;
          });
        }
        return;
      }

      final response = await _apiService.getAnalytics(
        date: dateParam,
        month: monthParam,
        doctorId: targetDoctorId, 
      ); 

      if (mounted) {
        setState(() {
          // 🚀 Safe Data Handling: ଯଦି API ସଫଳ ହୁଏ ତେବେ ଡାଟା ନିଅନ୍ତୁ, ନଚେତ୍ null ରଖନ୍ତୁ
          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
            _analyticsData = response.data['data'];
          } else {
            _analyticsData = null; // UI ରେ "No Data" ଦେଖାଇବ
          }
          _isLoadingAnalytics = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
      if (mounted) {
        setState(() {
          _analyticsData = null; // Error ଆସିଲେ ବି ଖାଲି ଛାଡିଦେବୁ ଯାହାଦ୍ୱାରା ଆପ୍ କ୍ରାସ୍ ହେବନି
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoadingPatients = true);
    
    try {
      // 🚀 SENIOR FIX: ସର୍ବଦା କେବଳ ଗ୍ଲୋବାଲ୍ Staff/Doctor ID ପଠାନ୍ତୁ
      final String targetDoctorId = currentStaff.id;

      // ଯଦି କୌଣସି କାରଣରୁ ID ଖାଲି ଥାଏ, ତେବେ API କଲ୍ ନକରି ଫେରିଯାଆନ୍ତୁ
      if (targetDoctorId.isEmpty) {
        if (mounted) {
          setState(() {
            _patientsList = [];
            _isLoadingPatients = false;
          });
        }
        return;
      }

      final response = await _apiService.getActualPatients(
        doctorId: targetDoctorId, 
      ); 

      if (mounted) {
        setState(() {
          // 🚀 Safe Data Handling: ଲିଷ୍ଟ୍ କୁ ସୁରକ୍ଷିତ ଭାବେ ଏକ୍ସଟ୍ରାକ୍ଟ୍ (Extract) କରନ୍ତୁ
          if (response.statusCode == 200 && response.data != null && response.data['data'] != null) {
            final data = response.data['data'];
            _patientsList = data is List ? data : (data['patients'] ?? []);
          } else {
            _patientsList = []; // ଖାଲି ଲିଷ୍ଟ୍ ରହିବ
          }
          _isLoadingPatients = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching patients: $e");
      if (mounted) {
        setState(() {
          _patientsList = []; // Error ଆସିଲେ ଖାଲି ଲିଷ୍ଟ୍ ଦେଖାଇବୁ
          _isLoadingPatients = false;
        });
      }
    }
  }

  void _normalizeData() {
    final staffModel = currentStaff; 
    _clinicName = staffModel.clinicName.isNotEmpty ? staffModel.clinicName : "Main Branch";
    _departmentName = staffModel.specialty.isNotEmpty ? staffModel.specialty : "General";
    _roleType = staffModel.role.toLowerCase();
    _roleDisplay = _roleType.isNotEmpty ? _roleType[0].toUpperCase() + _roleType.substring(1) : "Staff";
    
    String rawDate = staffModel.joinedAt.isNotEmpty ? staffModel.joinedAt : staffModel.createdAt;
    _joinedDate = rawDate.isNotEmpty ? rawDate.split('T')[0] : "Recently";
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == "N/A" || phoneNumber == "No Phone") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number not available."), backgroundColor: Colors.red));
      return;
    }
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(callUri)) await launchUrl(callUri);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open dialer."), backgroundColor: Colors.red));
    }
  }

  Future<void> _handleSuspend() async {
    final bool currentlySuspended = currentStaff.isSuspended || currentStaff.status.toLowerCase() == 'suspended';
    final bool newStatus = !currentlySuspended;
    
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      final response = await _apiService.updateAdminStaffStatus(
        currentStaff.mappingId, 
        {'isSuspended': newStatus}
      );
      
      Navigator.pop(context); 

      if (response.statusCode == 200) {
        final bool updatedSuspendStatus = response.data['data']?['isSuspended'] ?? newStatus;

        setState(() {
          currentStaff = currentStaff.copyWith( 
            isSuspended: updatedSuspendStatus,
            status: updatedSuspendStatus ? 'suspended' : 'active'
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(updatedSuspendStatus ? "Staff Suspended Successfully" : "Staff Activated Successfully"), backgroundColor: Colors.green));
      }
    } catch(e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;
    final primaryColor = colorScheme.primary;
    final textColor = theme.colorScheme.onSurface;
    
    final staff = currentStaff; 
    
    final bool isSuspended = staff.isSuspended || staff.status.toLowerCase() == 'suspended';
    final String displayStatus = staff.isArchived ? "Archived" : (isSuspended ? "Suspended" : (staff.status.isNotEmpty ? staff.status : "Active"));
    final Color badgeColor = staff.isArchived ? Colors.orange : (isSuspended ? Colors.red : Colors.green);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, currentStaff); 
        return false;
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320.0,
              pinned: true,
              backgroundColor: theme.cardColor,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.9),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => Navigator.pop(context, currentStaff),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: isDark ? Colors.black54 : Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: Icon(LucideIcons.pencil, color: primaryColor, size: 20),
                      onPressed: () {
                        final editId = staff.mappingId.isNotEmpty ? staff.mappingId : staff.id;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AddStaffScreen(staffId: editId)))
                        .then((value) {
                           if(value == true) _fetchStaffDetails(); 
                        });
                      },
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    staff.image.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: staff.image, fit: BoxFit.cover, alignment: Alignment.topCenter,
                            errorWidget: (context, url, error) => _buildFallbackImage(primaryColor),
                          )
                        : _buildFallbackImage(primaryColor),

                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.transparent, bgColor.withValues(alpha: 0.8), bgColor],
                          stops: const [0.0, 0.4, 0.85, 1.0],
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 20, left: 20, right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        staff.name, 
                                        style: TextStyle(
                                          fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5,
                                          decoration: isSuspended || staff.isArchived ? TextDecoration.lineThrough : TextDecoration.none,
                                        ),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (staff.isAdminApproved) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                                    ]
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildStatusBadge(displayStatus, badgeColor), 
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text("$_roleDisplay  •  $_departmentName", style: TextStyle(fontSize: 15, color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(LucideIcons.mapPin, size: 14, color: primaryColor), const SizedBox(width: 6),
                              Text(_clinicName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textColor.withValues(alpha: 0.6))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController, labelColor: primaryColor, unselectedLabelColor: theme.disabledColor,
                  indicatorColor: primaryColor, indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
                bgColor,
              ),
              pinned: true,
            ),

            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  if (tab == "Overview") return _isFetchingDetails ? const Center(child: CircularProgressIndicator()) : _buildOverviewTab(theme, primaryColor, staff);
                  if (tab == "Analytics") return _buildAnalyticsTab(theme, primaryColor); // 🚀 Separated Loading internally
                  if (tab == "Patients") return _isLoadingPatients ? const Center(child: CircularProgressIndicator()) : _buildPatientsTab(theme);
                  if (tab == "Info") return _isFetchingDetails ? const Center(child: CircularProgressIndicator()) : _buildInfoTab(theme, primaryColor, staff);
                  return const SizedBox();
                }).toList(),
              ),
            ),
          ],
        ),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)))),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(staff.phone), 
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(LucideIcons.phone, size: 18, color: Colors.blue), label: Text("Call", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSuspend, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuspended ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                      foregroundColor: isSuspended ? Colors.green : Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(isSuspended ? LucideIcons.checkCircle : LucideIcons.ban, size: 18), label: Text(isSuspended ? "Activate" : "Suspend", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= TABS (Premium Flat Look) =================

  Widget _buildOverviewTab(ThemeData theme, Color primary, Staff staff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(theme, "Experience", "${staff.experience.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty ? staff.experience.replaceAll(RegExp(r'[^0-9]'), '') : '0'} Yrs", LucideIcons.briefcase, iconColor: Colors.blueAccent),
                const SizedBox(width: 12),
                if (staff.role.toLowerCase() == 'doctor') ...[
                  _buildStatCard(theme, "Consult Fee", "₹${staff.consultationFees}", LucideIcons.indianRupee, iconColor: Colors.indigo),
                  const SizedBox(width: 12),
                  _buildStatCard(theme, "Follow-up", "₹${staff.followUpFees}", LucideIcons.repeat, iconColor: Colors.deepPurpleAccent),
                ] else ...[
                  _buildStatCard(theme, "Salary", staff.salary.isNotEmpty ? "₹${staff.salary}" : "N/A", LucideIcons.wallet, iconColor: Colors.teal),
                ]
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (staff.highlights.isNotEmpty) ...[
            _buildSectionHeader("Highlights", theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: staff.highlights.map((h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: primary.withValues(alpha: 0.1))),
                child: Text(h, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
              )).toList(),
            ),
            const SizedBox(height: 32),
          ],

          _buildSectionHeader("About", theme),
          const SizedBox(height: 12),
          Text(
            staff.bio.isNotEmpty ? staff.bio : "No professional biography provided yet.",
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), height: 1.6),
          ),

          if (staff.availableSlots.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader("Available Slots", theme),
            const SizedBox(height: 16),
            ...staff.availableSlots.map((slotData) {
               final dateLabel = slotData['label'] ?? '';
               final status = slotData['status'] ?? '';
               final List slots = slotData['slots'] ?? [];
               
               if(slots.isEmpty) return const SizedBox();

               return Container(
                 margin: const EdgeInsets.only(bottom: 12),
                 decoration: BoxDecoration(
                   color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                           Text(status, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ),
                     Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
                     Padding(
                       padding: const EdgeInsets.all(12),
                       child: Wrap(
                         spacing: 8, runSpacing: 8,
                         children: slots.map((s) {
                           final start = s['start'] ?? '';
                           final end = s['end'] ?? '';
                           return Container(
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                             decoration: BoxDecoration(
                               color: theme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.primaryColor.withValues(alpha: 0.1)),
                             ),
                             child: Text("$start - $end", style: TextStyle(color: theme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                           );
                         }).toList(),
                       ),
                     )
                   ],
                 ),
               );
            }).toList(),
          ]
        ],
      ),
    );
  }

  // 🚀 [NEW FEATURE]: Analytics Header with View Toggle and Date Picker
  Widget _buildAnalyticsFilter(ThemeData theme) {
    String getMonthName(int m) {
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return months[m - 1];
    }

    final String dateLabel = _analyticsViewType == 'daily' 
        ? "${_analyticsDate.day} ${getMonthName(_analyticsDate.month)} ${_analyticsDate.year}"
        : "${getMonthName(_analyticsDate.month)} ${_analyticsDate.year}";

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSectionHeader("Overview", theme),
        Row(
          children: [
            // Daily / Monthly Toggle
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  _buildToggleTab("Daily", 'daily', theme),
                  _buildToggleTab("Monthly", 'monthly', theme),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Date Picker Button
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _analyticsDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: theme.colorScheme.copyWith(primary: theme.primaryColor),
                      ),
                      child: child!,
                    );
                  }
                );
                if (picked != null && picked != _analyticsDate) {
                  setState(() => _analyticsDate = picked);
                  _fetchAnalytics();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.calendar, size: 14, color: theme.primaryColor),
                    const SizedBox(width: 6),
                    Text(dateLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryColor)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleTab(String label, String value, ThemeData theme) {
    final isSelected = _analyticsViewType == value;
    return GestureDetector(
      onTap: () {
        if (_analyticsViewType != value) {
          setState(() => _analyticsViewType = value);
          _fetchAnalytics();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.onSurface.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? theme.colorScheme.onSurface : theme.disabledColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(ThemeData theme, Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsFilter(theme), // 🚀 Custom Header added here
          const SizedBox(height: 16),
          
          if (_isLoadingAnalytics)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_analyticsData == null)
            Center(child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text("No Analytics Data Found", style: TextStyle(color: theme.disabledColor)),
            ))
          else ...[
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3,
              children: [
                _buildMetricBox(theme, "Total Patients", "${_analyticsData!['totalPatients'] ?? 0}", Colors.blue, "Stats"),
                _buildMetricBox(theme, "Revenue", "${_analyticsData!['revenue'] ?? '₹0'}", Colors.green, "Stats"),
                _buildMetricBox(theme, "Avg Wait Time", "${_analyticsData!['avgWaitTime'] ?? '0'}", Colors.orange, "Mins"),
                _buildMetricBox(theme, "Retention Rate", "${_analyticsData!['retentionRate'] ?? 0}%", Colors.purple, "Good"),
              ],
            ),
            const SizedBox(height: 32),

            _buildSectionHeader("Appointments Overview", theme),
            const SizedBox(height: 16),
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1))),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                 children: [
                   _buildApptStat("Total", "${_analyticsData!['appointments']?['total'] ?? 0}", Colors.blue),
                   _buildApptStat("Completed", "${_analyticsData!['appointments']?['completed'] ?? 0}", Colors.green),
                   _buildApptStat("Canceled", "${_analyticsData!['appointments']?['cancelled'] ?? 0}", Colors.red),
                 ],
               ),
            ),
            
            const SizedBox(height: 32),
            _buildSectionHeader("Patient Demographics", theme),
            const SizedBox(height: 16),
            if (_analyticsData!['demographics']?['age'] != null) ...[
               Wrap(
                 spacing: 8, runSpacing: 8,
                 children: (_analyticsData!['demographics']['age'] as List).map<Widget>((d) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.user, size: 12, color: theme.primaryColor),
                          const SizedBox(width: 6),
                          Text("${d['label']} : ${d['value']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    );
                 }).toList(),
               )
            ]
          ]
        ],
      ),
    );
  }

  Widget _buildApptStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPatientsTab(ThemeData theme) {
    if (_patientsList.isEmpty) {
      return Center(child: Text("No Patients Found", style: TextStyle(color: theme.disabledColor)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _patientsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final Map<String, dynamic> rawPatient = _patientsList[index];
        
        // 🚀 SENIOR FIX: ଆପଣଙ୍କ ନୂଆ Patient Model ର fromJson() କୁ ସିଧା ବ୍ୟବହାର କରନ୍ତୁ
        // ଏହାଦ୍ୱାରା ବାରମ୍ବାର ମାନୁଆଲି ମ୍ୟାପିଂ କରିବାର ଝମେଲା ରହିବ ନାହିଁ।
        Patient patientModel;
        try {
          patientModel = Patient.fromJson(rawPatient);
        } catch (e) {
          debugPrint("Patient Parsing Error: $e");
          // Fallback if API data structure is totally broken
          patientModel = Patient(
            id: '',
            name: 'Unknown',
            phone: '',
            age: '',
            gender: '',
            lastVisit: '',
            lastVisitDate: DateTime.now(),
            status: 'unknown',
            bookingId: '',
          );
        }

        // 🚀 ଏବେ ଆପଣଙ୍କର ଅରିଜିନାଲ୍ PatientListCard ବ୍ୟବହାର କରନ୍ତୁ
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: PatientListCard(
            patient: patientModel,
            onCall: () => _makePhoneCall(patientModel.phone), 
            onChat: () async {
              // WhatsApp Chat Logic
              if (patientModel.phone.isEmpty) return;
              final String cleanPhone = patientModel.phone.replaceAll(RegExp(r'\D'), '');
              final Uri whatsappUri = Uri.parse("whatsapp://send?phone=+91$cleanPhone");
              try {
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri);
                } else {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("WhatsApp not installed.")));
                }
              } catch (e) {
                debugPrint("WhatsApp Error: $e");
              }
            },
            onTap: () {
              // 🚀 [THE FIX]: ସଠିକ୍ ଡାଟା ସହ ରୋଗୀଙ୍କ ପ୍ରୋଫାଇଲ୍ ଖୋଲନ୍ତୁ
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientProfileScreen(
                    phone: patientModel.phone, 
                    name: patientModel.name,   
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(ThemeData theme, Color primary, Staff staff) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Contact Information", theme),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)), // Flat border
            ),
            child: Column(
              children: [
                _buildContactRow(theme, LucideIcons.mail, "Email", staff.email.isNotEmpty ? staff.email : "N/A"),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                _buildContactRow(theme, LucideIcons.phone, "Phone", staff.phone.isNotEmpty ? staff.phone : "N/A"),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                _buildContactRow(theme, LucideIcons.calendar, "Joined", _joinedDate),
              ],
            ),
          ),

          if (staff.educations.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader("Education", theme),
            const SizedBox(height: 16),
            ...staff.educations.map((edu) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.graduationCap, color: primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(edu['degree'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(edu['institution'] ?? '', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13)),
                      ],
                    ),
                  ),
                  Text(edu['year_of_completion'] ?? '', style: TextStyle(color: theme.disabledColor, fontSize: 12)),
                ],
              ),
            )),
          ],

          if (staff.languages.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSectionHeader("Languages Spoken", theme),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: staff.languages.map((lang) => Chip(
                label: Text(lang, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                backgroundColor: theme.scaffoldBackgroundColor,
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              )).toList(),
            ),
          ]
        ],
      ),
    );
  }

  // ================= HELPERS (Flat UI matched to Screenshot) =================

  Widget _buildFallbackImage(Color primary) {
    return Container(
      color: primary.withValues(alpha: 0.1),
      child: Center(child: Icon(LucideIcons.user, size: 80, color: primary.withValues(alpha: 0.3))),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface));
  }

  Widget _buildStatCard(ThemeData theme, String label, String value, IconData icon, {Color? iconColor}) {
    final color = iconColor ?? theme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)), 
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: theme.disabledColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(ThemeData theme, String title, String value, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor, 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.barChart3, color: color, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(trend, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: color)),
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
              Text(title, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(ThemeData theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)), 
          ),
          child: Icon(icon, size: 18, color: theme.primaryColor),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: theme.disabledColor)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;
  _SliverAppBarDelegate(this._tabBar, this._bgColor);
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))), 
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}