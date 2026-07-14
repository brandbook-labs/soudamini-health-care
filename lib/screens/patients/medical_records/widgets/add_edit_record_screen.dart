// lib/screens/medical_records/widgets/add_edit_record_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/admin/admin_widgets/slots/widgets/time_box.dart';
import 'package:my_new_app/screens/patients/booking/booking_success_screen.dart';

// --- IMPORT NECESSARY WIDGETS/MODELS ---
import '../models/record_model.dart';
import '../models/provider_model.dart';
import 'record_type_selector.dart';
import 'linked_provider_selector.dart';

class AddEditRecordScreen extends StatefulWidget {
  final MedicalRecordModel? record;
  final Function(MedicalRecordModel payload) onSave;

  const AddEditRecordScreen({super.key, this.record, required this.onSave});

  @override
  State<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends State<AddEditRecordScreen> {
  late MedicalRecordType _selectedType;
  late DateTime _selectedDate;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String? _fileUrl;
  ProviderModel? _linkedProvider;

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _selectedType = widget.record!.type;
      _selectedDate = widget.record!.date;
      _titleController.text = widget.record!.title;
      _notesController.text = widget.record!.notes ?? '';
      _fileUrl = widget.record!.fileUrl;
    } else {
      _selectedType = MedicalRecordType.prescription;
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // --- MOCK FILE PICKING FUNCTION ---
  Future<void> _pickFile() async {
    setState(() => _fileUrl = "mock_path_for_api.pdf");
  }

  // --- HANDLE SAVE LOGIC ---
  void _handleSave() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a record title."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final payload = MedicalRecordModel(
      id: widget.record?.id ?? "mr_${DateTime.now().millisecondsSinceEpoch}",
      type: _selectedType,
      title: _titleController.text,
      date: _selectedDate,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      fileUrl: _fileUrl,
      linkedProviderId: _linkedProvider?.isJivanVerified ?? false
          ? _linkedProvider!.id
          : null,
      linkedProviderName: !(_linkedProvider?.isJivanVerified ?? true)
          ? _linkedProvider!.name
          : null,
    );

    widget.onSave(payload);
    Navigator.pop(context); // Close the full screen after saving
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF4F46E5);
    const borderCol = Color(0xFFE2E8F0);
    // 🚀 FLAT DESIGN: The whole background is pure white now
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
        title: Text(
          widget.record == null ? "Add Medical Record" : "Edit Record",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
      ),

      // 🚀 STICKY FOOTER: Save button always accessible
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: borderCol)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: _handleSave,
            icon: const Icon(LucideIcons.checkCircle2, size: 18),
            label: Text(
              widget.record == null ? "Save Document" : "Update Document",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: DOCUMENT INFO ---
            _buildSectionHeader("Document Info", LucideIcons.fileText, primary),
            _buildLabel("Document Title"),
            _buildTextField(
              "e.g., Complete Blood Count, X-Ray",
              LucideIcons.type,
              _titleController,
              borderCol,
              primary,
            ),
            const SizedBox(height: 24),
            _buildLabel("Record Type"),
            RecordTypeSelector(
              selectedType: _selectedType,
              onChanged: (type) => setState(() => _selectedType = type),
            ),

            const SizedBox(height: 40),
            const Divider(color: borderCol),
            const SizedBox(height: 32),

            // --- SECTION 2: CONTEXT ---
            _buildSectionHeader(
              "Visit Details",
              LucideIcons.calendarDays,
              primary,
            ),
            _buildLabel("Date of Document/Visit"),
            _buildDatePickerButton(primary, borderCol),
            const SizedBox(height: 24),
            _buildLabel("Doctor or Clinic Name"),
            LinkedProviderSelector(
              initialProvider: _linkedProvider,
              onProviderSelected: (provider) => _linkedProvider = provider,
            ),

            const SizedBox(height: 40),
            const Divider(color: borderCol),
            const SizedBox(height: 32),

            // --- SECTION 3: FILE ATTACHMENT ---
            _buildSectionHeader("Attachment", LucideIcons.paperclip, primary),
            _buildFileAttachmentArea(primary, borderCol),

            const SizedBox(height: 40),
            const Divider(color: borderCol),
            const SizedBox(height: 32),

            // --- SECTION 4: NOTES ---
            _buildSectionHeader(
              "Additional Notes",
              LucideIcons.messageSquare,
              primary,
            ),
            _buildTextField(
              "Add any personal remarks, doctor's advice, or context here...",
              LucideIcons.pencil,
              _notesController,
              borderCol,
              primary,
              maxLines: 4,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =======================================================================
  // UI HELPERS (Updated for Flat Design)
  // =======================================================================

  Widget _buildSectionHeader(String title, IconData icon, Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text, // Removed uppercase for a softer document feel
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDatePickerButton(Color primary, Color borderCol) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primary,
                  onPrimary: Colors.white,
                  onSurface: Colors.black87,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(
            0xFFF8FAFC,
          ), // Light tinted background so it pops off the white page
          border: Border.all(color: borderCol),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendarDays, size: 18, color: Colors.black54),
            const SizedBox(width: 12),
            Text(
              DateFormat('dd MMMM yyyy').format(_selectedDate),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            const Icon(
              LucideIcons.chevronDown,
              size: 18,
              color: Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachmentArea(Color primary, Color borderCol) {
    if (_fileUrl == null) {
      return GestureDetector(
        onTap: _pickFile,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderCol),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.uploadCloud,
                  color: Colors.black54,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Tap to upload document",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Supports PDF, JPG, PNG up to 10MB",
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(LucideIcons.fileText, size: 24, color: primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Document Attached",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "medical_document_ready.pdf",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.red),
              style: IconButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () => setState(() => _fileUrl = null),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextField(
    String hint,
    IconData icon,
    TextEditingController controller,
    Color borderCol,
    Color primary, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 15),
        prefixIcon: maxLines == 1
            ? Icon(icon, size: 18, color: Colors.black45)
            : Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Icon(icon, size: 18, color: Colors.black45),
              ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC), // Light tinted background
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderCol),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}
