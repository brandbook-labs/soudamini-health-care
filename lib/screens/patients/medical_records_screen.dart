import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
// Dark Mode
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

// --- MOCK DATA ---
class MedicalRecord {
  final String id;
  final String title;
  final String date;
  final String type; // 'Prescription', 'Lab Report', 'Scan'
  final String doctorOrLab;
  final String fileSize;

  MedicalRecord({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.doctorOrLab,
    required this.fileSize,
  });
}

final List<MedicalRecord> mockRecords = [
  MedicalRecord(
    id: "REC-001",
    title: "Blood Test Report",
    date: "20 Jan, 2024",
    type: "Lab Report",
    doctorOrLab: "City Care Lab",
    fileSize: "1.2 MB",
  ),
  MedicalRecord(
    id: "REC-002",
    title: "Viral Fever Rx",
    date: "15 Dec, 2023",
    type: "Prescription",
    doctorOrLab: "Dr. Ananya Sharma",
    fileSize: "450 KB",
  ),
  MedicalRecord(
    id: "REC-003",
    title: "MRI Scan - Knee",
    date: "10 Nov, 2023",
    type: "Scan",
    doctorOrLab: "Max Imaging Center",
    fileSize: "8.5 MB",
  ),
  MedicalRecord(
    id: "REC-004",
    title: "General Checkup",
    date: "05 Oct, 2023",
    type: "Prescription",
    doctorOrLab: "Dr. J. Mohanty",
    fileSize: "600 KB",
  ),
];

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  String _selectedFilter = "All";
  final List<String> _filters = ["All", "Prescription", "Lab Report", "Scan"];

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    // Filter Logic
    final filteredRecords = _selectedFilter == "All"
        ? mockRecords
        : mockRecords.where((r) => r.type == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          "Medical Records",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.sort, color: textColor),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open File Picker or Camera
        },
        backgroundColor: kPrimaryColor,
        icon: const Icon(LucideIcons.uploadCloud, color: Colors.white),
        label: const Text(
          "Upload",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // --- 1. SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(LucideIcons.search, color: subTextColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: "Search records...",
                        hintStyle: TextStyle(color: subTextColor),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. FILTER CHIPS ---
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? kPrimaryColor : cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? kPrimaryColor : borderColor,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : subTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- 3. RECORD LIST ---
          Expanded(
            child: filteredRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.folderOpen,
                          size: 64,
                          color: subTextColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No records found",
                          style: TextStyle(
                            color: subTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      80,
                    ), // Bottom padding for FAB
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) {
                      return RecordCard(
                        record: filteredRecords[index],
                        cardColor: cardColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                        borderColor: borderColor,
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- RECORD CARD WIDGET ---
class RecordCard extends StatelessWidget {
  final MedicalRecord record;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDarkMode;

  const RecordCard({
    super.key,
    required this.record,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDarkMode,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'Prescription':
        return LucideIcons.fileText;
      case 'Lab Report':
        return LucideIcons.flaskConical;
      case 'Scan':
        return LucideIcons.scanLine;
      default:
        return LucideIcons.file;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'Prescription':
        return Colors.blue;
      case 'Lab Report':
        return Colors.purple;
      case 'Scan':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(record.type);
    final iconColor = _getIconColor(record.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${record.date} • ${record.doctorOrLab}",
                  style: TextStyle(fontSize: 12, color: subTextColor),
                ),
                const SizedBox(height: 4),
                Text(
                  record.fileSize,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: subTextColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            onPressed: () {
              // Open/Download logic
            },
            icon: Icon(LucideIcons.eye, color: subTextColor, size: 20),
          ),
          IconButton(
            onPressed: () {
              // Share logic
            },
            icon: Icon(LucideIcons.share2, color: subTextColor, size: 20),
          ),
        ],
      ),
    );
  }
}
