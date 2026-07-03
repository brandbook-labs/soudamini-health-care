// lib/screens/medical_records/provider_care_details_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

// --- IMPORTS ---
import 'models/past_consultation_model.dart';
import 'models/record_model.dart';
import 'widgets/record_list_card.dart';
import 'widgets/add_edit_record_screen.dart';
import 'record_details_screen.dart';

// MOCK VISIT MODEL for the Timeline
class MockVisit {
  final DateTime date;
  final String type; // e.g., Initial Consult, Follow-up
  final String status;
  final String? doctorNote;

  MockVisit(this.date, this.type, this.status, {this.doctorNote});
}

class ProviderCareDetailsScreen extends StatefulWidget {
  final PastConsultationModel doctor;

  const ProviderCareDetailsScreen({super.key, required this.doctor});

  @override
  State<ProviderCareDetailsScreen> createState() =>
      _ProviderCareDetailsScreenState();
}

class _ProviderCareDetailsScreenState extends State<ProviderCareDetailsScreen> {
  bool _isLoading = true;
  List<MedicalRecordModel> _doctorRecords = [];
  List<MockVisit> _visitHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchCareDetails();
  }

  // 🚀 API INTEGRATION: Fetch records AND visit history for this doctor
  Future<void> _fetchCareDetails() async {
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      // 1. Mocking Visit History based on the doctor's last visit date
      _visitHistory = [
        MockVisit(
          widget.doctor.lastVisitDate,
          "Follow-up Consultation",
          "Completed",
          doctorNote: "Patient responding well to new medication.",
        ),
        if (widget.doctor.totalVisits > 1)
          MockVisit(
            widget.doctor.lastVisitDate.subtract(const Duration(days: 14)),
            "Lab Results Review",
            "Completed",
          ),
        if (widget.doctor.totalVisits > 2)
          MockVisit(
            widget.doctor.lastVisitDate.subtract(const Duration(days: 30)),
            "Initial Consultation",
            "Completed",
            doctorNote: "Complained of mild chest pain. Prescribed ECG.",
          ),
      ];

      // 2. Mocking Medical Records
      if (widget.doctor.prescriptionsCount > 0 ||
          widget.doctor.labReportsCount > 0) {
        _doctorRecords = [
          MedicalRecordModel(
            id: "mr_101",
            type: MedicalRecordType.prescription,
            title: "Post-Consultation Prescription",
            date: widget.doctor.lastVisitDate,
            fileUrl: "prescription_${widget.doctor.id}.pdf",
            linkedProviderId: widget.doctor.id,
            linkedProviderName: widget.doctor.doctorName,
          ),
          if (widget.doctor.labReportsCount > 0)
            MedicalRecordModel(
              id: "mr_102",
              type: MedicalRecordType.labReport,
              title: "Blood Work Results",
              date: widget.doctor.lastVisitDate.subtract(
                const Duration(days: 16),
              ),
              fileUrl: "labs_${widget.doctor.id}.pdf",
              linkedProviderId: widget.doctor.id,
              linkedProviderName: widget.doctor.doctorName,
            ),
        ];
      }
      _isLoading = false;
    });
  }

  void _openAddRecord() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          onSave: (payload) {
            setState(() => _doctorRecords.insert(0, payload));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Record successfully added!')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    const bgMain = Colors.white;

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: borderCol, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Care History",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. PROVIDER SUMMARY ---
                  _buildProviderHeader(primary, borderCol),

                  // --- 2. ACTION BAR ---
                  _buildActionBar(primary, borderCol),

                  const Divider(color: borderCol, height: 1),

                  // --- 3. VISIT TIMELINE ---
                  _buildVisitTimeline(primary, borderCol),

                  const Divider(color: borderCol, height: 1),

                  // --- 4. DOCUMENTS VAULT ---
                  _buildRecordsVault(borderCol),
                ],
              ),
            ),
    );
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  Widget _buildProviderHeader(Color primary, Color borderCol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(widget.doctor.imageUrl),
            backgroundColor: const Color(0xFFF8FAFC),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.doctorName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      widget.doctor.isJivanVerified
                          ? LucideIcons.user
                          : LucideIcons.user,
                      size: 14,
                      color: widget.doctor.isJivanVerified
                          ? primary
                          : Colors.black45,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.doctor.specialty.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.doctor.isJivanVerified
                            ? primary
                            : Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(Color primary, Color borderCol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          if (widget.doctor.isJivanVerified)
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  /* Book Follow up */
                },
                icon: const Icon(LucideIcons.calendarPlus, size: 16),
                label: const Text(
                  "Book Visit",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          if (widget.doctor.isJivanVerified) const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openAddRecord,
              icon: const Icon(
                LucideIcons.uploadCloud,
                size: 16,
                color: Colors.black87,
              ),
              label: const Text(
                "Add Record",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: borderCol, width: 1.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              /* Review Logic */
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(12),
              side: BorderSide(color: borderCol, width: 1.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Icon(
              LucideIcons.star,
              size: 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitTimeline(Color primary, Color borderCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "VISIT HISTORY",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),

          if (_visitHistory.isEmpty)
            const Text(
              "No past visits recorded.",
              style: TextStyle(color: Colors.black54, fontSize: 14),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _visitHistory.length,
              itemBuilder: (context, index) {
                final visit = _visitHistory[index];
                final isLast = index == _visitHistory.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline Track
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: index == 0 ? primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index == 0 ? primary : borderCol,
                              width: 2,
                            ),
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: visit.doctorNote != null
                                ? 80
                                : 50, // Dynamic line height
                            color: borderCol,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Visit Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(visit.date),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  visit.status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ), // Emerald Green
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              visit.type,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (visit.doctorNote != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderCol),
                                ),
                                child: Text(
                                  '"${visit.doctorNote}"',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRecordsVault(Color borderCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "SAVED DOCUMENTS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.black45,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                "${_doctorRecords.length} Files",
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_doctorRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.folderOpen,
                    size: 28,
                    color: Colors.black26,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "No documents saved yet.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _openAddRecord,
                    child: const Text(
                      "Upload First Record",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._doctorRecords.map(
              (record) => RecordListCard(
                record: record,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordDetailsScreen(record: record),
                    ),
                  );
                },
                onEdit: () {
                  /* Edit Route */
                },
                onDelete: () {
                  setState(
                    () => _doctorRecords.removeWhere((r) => r.id == record.id),
                  );
                },
              ),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
