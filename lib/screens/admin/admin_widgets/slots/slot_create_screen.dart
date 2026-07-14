// lib/screens/slots/slot_create_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 🚀 Role ପାଇବା ପାଇଁ ଆବଶ୍ୟକ ହୋଇପାରେ

// --- YOUR API SERVICES ---
import 'package:my_new_app/services/api_service.dart'; // Ensure path is correct

// --- NEW FILE IMPORTS ---
import 'models/slot_model.dart';
import 'widgets/slot_card.dart';

class SlotCreateScreen extends StatefulWidget {
  const SlotCreateScreen({super.key});

  @override
  State<SlotCreateScreen> createState() => _SlotCreateScreenState();
}

class _SlotCreateScreenState extends State<SlotCreateScreen> {
  final ApiService _apiService = ApiService();

  final List<SlotModel> _slots = [];
  final List<String> _deletedSlotIds = []; 
  
  List<Map<String, dynamic>> _doctorList = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _clinicId;
  
  // 🚀 Admin Role ଭେରିଏବଲ୍ (ଏହାକୁ ଆପଣଙ୍କର Auth Storage ରୁ ଆଣିବେ)
  String _adminRole = 'clinic'; // ଉଦାହରଣ: 'SuperAdmin' ବା 'clinic'

  bool _isSlotsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // --- 1. FETCH DATA (Parallel Fetching) ---
  Future<void> _fetchData() async {
    try {
      // 🚀 (Optional) Fetch Role from Local Storage here if needed
      // final prefs = await SharedPreferences.getInstance();
      // _adminRole = prefs.getString('role') ?? 'clinic';

      final responses = await Future.wait([
        _apiService.getAdminDoctors(),
        _apiService.getSlots(tokenKey: 'admin_token'), 
      ]);

      final doctorResponse = responses[0];
      final slotResponse = responses[1];

      if (doctorResponse.statusCode == 200) {
        final data = doctorResponse.data['data'];
        final clinicData = data['clinic'] ?? {};
        final doctorsData = data['doctors'] as List? ?? [];

        _clinicId = clinicData['_id'];

        List<Map<String, dynamic>> processedDoctors = doctorsData.map<Map<String, dynamic>>((doc) {
          String img = doc['profile'] ?? "";
          if (img.isEmpty || img.contains("undefined")) {
            img = "https://ui-avatars.com/api/?name=${doc['name']}&background=random";
          }
          return {
            "id": doc['_id'],
            "name": doc['name'],
            "image": img,
            "availability_slots": doc['availability']?['slots'] ?? [],
          };
        }).toList();

        List rawSlots = [];
        if (slotResponse.statusCode == 200 && slotResponse.data['data'] != null) {
          rawSlots = slotResponse.data['data'];
        }

        List<SlotModel> loadedSlots = rawSlots.map<SlotModel>((json) {
          final recurrence = json['recurrence'] ?? {};
          final type = json['type'] ?? "weekly";
          final slotValue = json['value'] ?? "";

          List<String> linkedDoctorIds = [];
          if (json['doctor_ids'] != null && json['doctor_ids'] is List) {
            linkedDoctorIds = List<String>.from(json['doctor_ids'].map((id) => id.toString()));
          }

          return SlotModel(
            id: json['_id'] ?? "temp_${DateTime.now().millisecondsSinceEpoch}_$slotValue",
            value: slotValue,
            label: json['label'] ?? "",
            start: json['start'] ?? "09:00",
            end: json['end'] ?? "13:00",
            type: type,
            days: recurrence['days'] != null ? List<String>.from(recurrence['days']) : [],
            patternWeeks: recurrence['weeks'] != null ? List<int>.from(recurrence['weeks']) : [],
            patternDays: recurrence['days'] != null ? List<String>.from(recurrence['days']) : [],
            doctorIds: linkedDoctorIds,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _slots.clear();
            _slots.addAll(loadedSlots);
            _deletedSlotIds.clear(); 
            _doctorList = processedDoctors;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- DOCTOR TOGGLE ---
  void _handleDoctorToggle(String doctorId, SlotModel slot) {
    setState(() {
      if (slot.doctorIds.contains(doctorId)) {
        slot.doctorIds.remove(doctorId);
      } else {
        slot.doctorIds.add(doctorId);
      }
    });
  }

  // --- ADD SLOT ---
  void _addSlot() {
    String nextStart = "09:00";
    String nextEnd = "13:00";
    if (_slots.isNotEmpty) {
      nextStart = _slots.last.end;
      try {
        int h = int.parse(nextStart.split(":")[0]) + 3;
        if (h > 23) h = 23;
        nextEnd = "${h.toString().padLeft(2, '0')}:${nextStart.split(":")[1]}";
      } catch (_) {}
    }

    final newSlot = SlotModel(
      id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
      value: "slot-${DateTime.now().millisecondsSinceEpoch}",
      label: "",
      start: nextStart,
      end: nextEnd,
      doctorIds: [],
    );
    newSlot.generateLabel();
    
    setState(() {
      _slots.add(newSlot);
    });
  }

  // --- REMOVE SLOT ---
  void _removeSlot(SlotModel slot) {
    setState(() {
      _slots.remove(slot);
      if (!slot.id.startsWith('temp_') && slot.id.length == 24) {
        _deletedSlotIds.add(slot.id);
      }
    });
  }

  // --- UPDATE SLOT ---
  void _updateSlot(SlotModel slot, Function(SlotModel) updater) {
    setState(() {
      updater(slot);
      slot.generateLabel();
      if (slot.value.startsWith('slot-') || slot.value.isEmpty) {
        slot.value = slot.label
            .toLowerCase()
            .trim()
            .replaceAll(RegExp(r'\s+'), '-')
            .replaceAll(RegExp(r'[^\w\-]+'), '')
            .replaceAll(RegExp(r'\-\-+'), '-');
      }
    });
  }

  // ===========================================================================
  // 🚀 THE MASTER SUBMIT FUNCTION (Role Based Validations & Payload)
  // ===========================================================================
  Future<void> _handleSubmit() async {
    // ୧. ଯାଞ୍ଚ କରନ୍ତୁ ଯେ ୟୁଜର୍ SuperAdmin ଅଟନ୍ତି କି ନାହିଁ
    bool isSuperAdmin = _adminRole.toLowerCase() == 'superadmin' || _adminRole.toLowerCase() == 'super_admin';

    // ୨. 🚀 କେବଳ SuperAdmin ପାଇଁ Clinic ID ଯାଞ୍ଚ ହେବ ଏବଂ ଏରର୍ ଦେଖାଇବ
    if (isSuperAdmin && (_clinicId == null || _clinicId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Please select a clinic first."), 
          backgroundColor: Colors.red
        ),
      );
      return; // ଏଠାରୁ ବନ୍ଦ ହୋଇଯିବ
    }
    
    setState(() => _isSubmitting = true);

    try {
      // ୩. ସର୍ବପ୍ରଥମେ ଡିଲିଟ୍ ହୋଇଥିବା ସ୍ଲଟ୍ ଗୁଡିକୁ କାଢିବା
      if (_deletedSlotIds.isNotEmpty) {
        final deleteFutures = _deletedSlotIds.map((id) {
          return _apiService.deleteSlot(tokenKey: 'admin_token', slotId: id);
        });
        await Future.wait(deleteFutures);
        _deletedSlotIds.clear();
      }

      // ୪. ନୂଆ ଓ ପୁରୁଣା ସ୍ଲଟ୍ ଗୁଡିକୁ ସେଭ୍ ବା ଅପଡେଟ୍ କରିବା (Dynamic Payload)
      final saveFutures = _slots.map((slot) {
        
        // 🚀 ସାଧାରଣ ଡାଟା (ସମସ୍ତଙ୍କ ପାଇଁ)
        final Map<String, dynamic> payload = {
          "label": slot.label,
          "value": slot.value,
          "start": slot.start,
          "end": slot.end,
          "type": slot.type,
          "recurrence": slot.type == "pattern"
              ? {"weeks": slot.patternWeeks, "days": slot.patternDays}
              : {"weeks": [], "days": slot.days},
          "doctor_ids": slot.doctorIds, 
        };

        // 🚀 ଡାଇନାମିକ୍ ଇଞ୍ଜେକ୍ସନ୍: କେବଳ SuperAdmin ହୋଇଥିଲେ clinic_id ପଠାଇବା
        if (isSuperAdmin) {
          payload["clinic_id"] = _clinicId;
        }

        // API Call
        if (slot.id.startsWith('temp_')) {
          return _apiService.addSlot(tokenKey: 'admin_token', slotData: payload);
        } else {
          return _apiService.updateSlot(tokenKey: 'admin_token', slotId: slot.id, updateData: payload);
        }
      });

      await Future.wait(saveFutures); // Parallel execution for high speed

      // ୫. Legacy Array Update (ଯଦି clinic ମଡେଲ୍ ପାଇଁ ଦରକାର)
      if (_clinicId != null && _clinicId!.isNotEmpty) {
        final List<Map<String, dynamic>> legacyPayload = _slots.map((s) {
          return {
            "label": s.label,
            "value": s.value,
            "start": s.start,
            "end": s.end,
            "type": s.type,
            "recurrence": s.type == "pattern"
                ? {"weeks": s.patternWeeks, "days": s.patternDays}
                : {"weeks": [], "days": s.days},
          };
        }).toList();

        await _apiService.updateAdminClinic(
          _clinicId!, 
          {"available_slots": legacyPayload}, 
          null
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All Slots Saved Successfully!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // ଡାଟାବେସ୍ ରୁ ନୂଆ ଡାଟା ମଗାଇବା
        await _fetchData(); 
      }
    } catch (e) {
      debugPrint("Submit Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgMain = Color(0xFFF8FAFC);
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    const textDark = Color(0xFF1E293B);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgMain,
        body: Center(child: CircularProgressIndicator(color: primary)),
      );
    }

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: bgMain, 
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // --- STICKY BOTTOM BAR FOR SAVE ACTION ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderCol)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.save, size: 20),
            label: const Text(
              "Save Configurations",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- DASHBOARD HEADER ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Manage Booking Slots",
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 26,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Configure availability and assign doctors to specific time blocks.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- PREMIUM MASTER SWITCH CARD ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSlotsEnabled
                          ? primary.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.calendarCheck2,
                      color: _isSlotsEnabled ? primary : Colors.grey.shade500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Accept Bookings",
                          style: TextStyle(
                            color: _isSlotsEnabled
                                ? textDark
                                : Colors.grey.shade600,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isSlotsEnabled
                              ? "Patients can book doctor visits."
                              : "Booking is disabled globally.",
                          style: const TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isSlotsEnabled,
                    activeColor: Colors.white,
                    activeTrackColor: primary,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.shade300,
                    onChanged: (val) => setState(() => _isSlotsEnabled = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // --- SLOTS CONTENT ---
            Opacity(
              opacity: _isSlotsEnabled ? 1.0 : 0.4,
              child: IgnorePointer(
                ignoring: !_isSlotsEnabled,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                      // --- MAPPED SLOTS WITH SEPARATOR ---
                      ..._slots.asMap().entries.map((entry) {
                        final index = entry.key;
                        final slot = entry.value;
                        final isLast = index == _slots.length - 1;

                        return Column(
                          children: [
                            SlotCard(
                              slot: slot,
                              doctorList: _doctorList,
                              onRemove: () => _removeSlot(slot),
                              onUpdate: (fn) => _updateSlot(slot, fn),
                              onDoctorToggle: (docId) =>
                                  _handleDoctorToggle(docId, slot),
                            ),

                            // SEPARATOR
                            if (!isLast)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Divider(
                                        color: borderCol,
                                        thickness: 1.5,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: borderCol),
                                        ),
                                        child: const Text(
                                          "AND",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black45,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      child: Divider(
                                        color: borderCol,
                                        thickness: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox(height: 16),
                          ],
                        );
                      }),

                      // --- ADD NEW SLOT BUTTON ---
                      GestureDetector(
                        onTap: _addSlot,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.plusCircle,
                                color: primary,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Add New Slot",
                                style: TextStyle(
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}