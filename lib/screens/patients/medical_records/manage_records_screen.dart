// lib/screens/medical_records/manage_records_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:my_new_app/screens/patients/medical_records/record_details_screen.dart';

// --- IMPORT MODELS/WIDGETS ---
import 'models/record_model.dart';
import 'widgets/record_list_card.dart';
import 'widgets/add_edit_record_screen.dart'; // Make sure to update the import name!
import 'widgets/empty_records_state.dart';

class ManageRecordsScreen extends StatefulWidget {
  const ManageRecordsScreen({super.key});

  @override
  State<ManageRecordsScreen> createState() => _ManageRecordsScreenState();
}

class _ManageRecordsScreenState extends State<ManageRecordsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<MedicalRecordModel> _records = [];

  @override
  void initState() {
    super.initState();
    _fetchMedicalRecords();
  }

  // --- 1. FETCH RECORDS (Highly Optimized & Safe API Integration) ---
  Future<void> _fetchMedicalRecords() async {
    try {
      // ପ୍ରଥମରୁ ଯଦି ଲୋଡ୍ ହୋଇସାରିଛି ତେବେ ଦ୍ଵିତୀୟ ଥର ଅଯଥା API କଲ୍ ହେବନାହିଁ
      if (!_isLoading && _records.isNotEmpty) return;

      setState(() => _isLoading = true);

      // 🚀 Real API Call (Safe Execution)
      final res = await _apiService.getAllInvoices(tokenKey: 'auth_token');


      // ରେସପନ୍ସ (Response) ଏବଂ ମାଉଣ୍ଟେଡ୍ (mounted) ଚେକ୍
      if (res != null && res.data != null && res.data['code'] == 200) {
        final List<dynamic> dataList = res.data['data'];

        // 🚀 Fast & Null-Safe JSON Parsing
        final List<MedicalRecordModel> fetchedInvoices = dataList.map((item) {
          // ନେଷ୍ଟେଡ୍ (Nested) ଡାଟା କୁ ସୁରକ୍ଷିତ ଭାବରେ ବାହାର କରିବା
          final summary = item['summary'] ?? {};
          final clinic = item['clinic_id'] ?? {};

          return MedicalRecordModel(
            id: item['_id']?.toString() ?? UniqueKey().toString(),
            // UI ଖରାପ ନହେବା ପାଇଁ ବର୍ତ୍ତମାନ ଏହାକୁ prescription ଟାଇପ୍ ରେ ମ୍ୟାପ୍ କରାଯାଇଛି
            type: MedicalRecordType.prescription, 
            title: "Invoice: ${item['invoiceNumber'] ?? 'N/A'}",
            date: DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now(),
            notes: "Total: ₹${summary['netAmount'] ?? 0}  |  Status: ${item['paymentStatus'] ?? 'Unknown'}",
            linkedProviderId: clinic['_id']?.toString(),
            linkedProviderName: clinic['name']?.toString() ?? "Unknown Clinic",
          );
        }).toList();

        // ଷ୍ଟେଟ୍ (State) ଅପଡେଟ୍ କରିବା ପୂର୍ବରୁ ସୁରକ୍ଷା ଯାଞ୍ଚ
        if (mounted) {
          setState(() {
            _records = fetchedInvoices;
            _isLoading = false;
          });
        }
      } else {
        // API ରୁ ଖରାପ ରେସପନ୍ସ ଆସିଲେ ଏହା ହ୍ୟାଣ୍ଡେଲ୍ କରିବ
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res?.data['msg'] ?? "Failed to load invoices"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      // କୌଣସି ଆଭ୍ୟନ୍ତରୀଣ ତ୍ରୁଟି (Exception) କୁ ସୁରକ୍ଷିତ ଭାବରେ ଧରିବା
      debugPrint("Fetch Invoices Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("An error occurred while fetching records. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // --- 🚀 NEW FULL SCREEN ROUTING ---
  void _openAddEditScreen({MedicalRecordModel? recordToEdit}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          record: recordToEdit,
          onSave: (payload) {
            if (recordToEdit == null) {
              // Logic for Add
              setState(() => _records.insert(0, payload));
            } else {
              // Logic for Update
              final index = _records.indexWhere((r) => r.id == payload.id);
              setState(() => _records[index] = payload);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Record successfully ${recordToEdit == null ? "saved" : "updated"}!',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- UI CONFIRMATION DIALOG FOR DELETE ---
  void _confirmDelete(MedicalRecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Record?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete '${record.title}' from '${DateFormat('dd MMM yyyy').format(record.date)}'? This cannot be undone.",
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              // 🚀 REAL API INTEGRATION HERE: Delete record
              setState(() => _records.removeWhere((r) => r.id == record.id));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Record removed.')));
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgMain = Color(0xFFF8FAFC);
    const primary = Color(0xFF4F46E5);

    return Scaffold(
      backgroundColor: bgMain,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Manage Medical Records",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEditScreen(),
        backgroundColor: primary,
        shape: const CircleBorder(),
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _records.isEmpty
          ? const EmptyRecordsState()
          : _buildGroupedRecordList(),
    );
  }

  // Sub-widget for categorized scroll view
  Widget _buildGroupedRecordList() {
    Map<MedicalRecordType, List<MedicalRecordModel>> groupedData = {};
    for (var rec in _records) {
      groupedData.putIfAbsent(rec.type, () => []).add(rec);
    }

    final sortedTypes = groupedData.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: sortedTypes.map((type) {
        final recordsList = groupedData[type]!;
        final typeConfig = recordsList.first.typeString;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                  child: Text(
                    typeConfig.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                );
              }

              final record = recordsList[index - 1];

              return RecordListCard(
                record: record,
                onTap: () {
                  // 🚀 NEW ROUTE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordDetailsScreen(
                        record: record,
                        onEdit: () => _openAddEditScreen(recordToEdit: record),
                        onDelete: () => _confirmDelete(record),
                      ),
                    ),
                  );
                },
                onEdit: () => _openAddEditScreen(recordToEdit: record),
                onDelete: () => _confirmDelete(record),
              );
            }, childCount: recordsList.length + 1),
          ),
        );
      }).toList(),
    );
  }
}