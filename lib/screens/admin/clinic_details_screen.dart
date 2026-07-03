import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_new_app/screens/admin/adminSettings/edit_clinic_profile_screen.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ClinicDetailsScreen extends StatefulWidget {
  final String clinicId;

  const ClinicDetailsScreen({super.key, required this.clinicId});

  @override
  State<ClinicDetailsScreen> createState() => _ClinicDetailsScreenState();
}

class _ClinicDetailsScreenState extends State<ClinicDetailsScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic> _clinic = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String _activeTab = 'overview';

  // Controls the "Show More" toggle for facilities
  bool _isFacilitiesExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetchClinicDetails();
  }

  Future<void> _fetchClinicDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getClinicDetails(widget.clinicId);

      if (response.statusCode == 200 && response.data['data'] != null) {
        if (mounted) {
          setState(() {
            _clinic = response.data['data'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint("Error fetching clinic details: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- HELPERS ---
  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr == '00:00' || timeStr.isEmpty) {
      return 'Closed';
    }
    try {
      final parts = timeStr.split(':');
      final h = int.parse(parts[0]);
      final min = parts[1];
      final ampm = h >= 12 ? 'PM' : 'AM';
      final h12 = h % 12 == 0 ? 12 : h % 12;
      return '$h12:$min $ampm';
    } catch (e) {
      return timeStr;
    }
  }

  ImageProvider? _getLogoProvider(dynamic rawLogo) {
    if (rawLogo is String && rawLogo.isNotEmpty) {
      return NetworkImage(rawLogo);
    } else if (rawLogo is Map<String, dynamic> && rawLogo['data'] != null) {
      try {
        return MemoryImage(base64Decode(rawLogo['data']));
      } catch (e) {
        debugPrint("Base64 error: $e");
      }
    }
    return null;
  }

  String get _primaryPhone {
    final phone = _clinic['phone'];
    if (phone is List && phone.isNotEmpty) {
      return phone[0].toString();
    }
    if (phone is String) {
      return phone;
    }
    return "";
  }

  String get _displayPhone {
    final phone = _clinic['phone'];
    if (phone is List && phone.isNotEmpty) {
      return phone.join(", ");
    }
    if (phone is String) {
      return phone;
    }
    return "N/A";
  }

  // --- MODALS & ACTIONS ---

  void _handleEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditClinicProfileScreen(clinicId: widget.clinicId),
      ),
    ).then((_) {
      // Refresh details when coming back from the edit screen
      _fetchClinicDetails();
    });
  }

  Future<void> _toggleStatus() async {
    final currentStatus = _clinic['status'] ?? 'closed';
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    try {
      // Preserving your exact API logic intact (Uncomment to use API)
      // await _apiService.updateAdminClinic(widget.clinicId, {'status': newStatus}, null);

      setState(() => _clinic['status'] = newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Clinic successfully marked as $newStatus."),
            backgroundColor: newStatus == 'active'
                ? Colors.green.shade800
                : Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Status update error: $e");
    }
  }

  // --- VERIFICATION BOTTOM SHEET ---
  void _showStatusConfirmationSheet() {
    final isActive = _clinic['status'] == 'active';
    final String actionText = isActive ? "DEACTIVATE" : "ACTIVATE";
    final Color actionColor = isActive ? Colors.redAccent : Colors.greenAccent;
    final String expectedName = (_clinic['name'] ?? '')
        .toString()
        .toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (ctx) {
        bool isMatch = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 32,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: actionColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isActive ? LucideIcons.powerOff : LucideIcons.power,
                          color: actionColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "$actionText FACILITY",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "This action will change the facility's visibility and operational status on the platform.",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                      children: [
                        const TextSpan(text: "Please type "),
                        TextSpan(
                          text: expectedName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const TextSpan(text: " below to confirm."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF09090B),
                      hintText: "CLINIC NAME",
                      hintStyle: TextStyle(color: Colors.grey.shade700),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: actionColor, width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade800),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        isMatch = val.trim().toUpperCase() == expectedName;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isMatch
                          ? () {
                              Navigator.pop(ctx);
                              _toggleStatus();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: isActive ? Colors.white : Colors.black,
                        disabledBackgroundColor: const Color(0xFF27272A),
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: isMatch ? 8 : 0,
                        shadowColor: actionColor.withValues(alpha: 0.4),
                      ),
                      child: const Text(
                        "CONFIRM ACTION",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQRModal() {
    final scanUrl =
        "https://jivan.website/${_clinic['facility_type'] ?? 'clinic'}/${_clinic['slug'] ?? widget.clinicId}";

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Scan to Visit",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Share this with patients",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: scanUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(
                  scanUrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF18181B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 24),
              ),
              _buildActionTile(
                LucideIcons.edit3,
                "Edit Details",
                Colors.white,
                () {
                  Navigator.pop(ctx);
                  _handleEdit();
                },
              ),
              _buildActionTile(
                LucideIcons.qrCode,
                "Generate QR",
                Colors.white,
                () {
                  Navigator.pop(ctx);
                  _showQRModal();
                },
              ),
              const Divider(color: Color(0xFF27272A), height: 32),
              _buildActionTile(
                LucideIcons.power,
                _clinic['status'] == 'active'
                    ? "Deactivate Facility"
                    : "Activate Facility",
                _clinic['status'] == 'active'
                    ? Colors.redAccent
                    : Colors.greenAccent,
                () {
                  Navigator.pop(ctx);
                  _showStatusConfirmationSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- BUILD METHODS ---
  @override
  Widget build(BuildContext context) {
    const bgMain = Color(0xFF09090B);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgMain,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6366F1)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgMain,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              left: 16,
              right: 16,
              bottom: 120, // Space for floating dock
            ),
            children: [
              _buildHeroCard(),
              const SizedBox(height: 32),
              _buildTabBar(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildTabContent(),
              ),
            ],
          ),

          // Floating Glassmorphism Action Dock
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildFloatingActionDock(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF09090B).withValues(alpha: 0.7),
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _clinic['name'] ?? 'Facility Details',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "ID: ${widget.clinicId.length > 6 ? widget.clinicId.substring(widget.clinicId.length - 6).toUpperCase() : widget.clinicId}",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.qrCode, color: Colors.white, size: 22),
          onPressed: _showQRModal,
        ),
        IconButton(
          icon: const Icon(
            LucideIcons.moreVertical,
            color: Colors.white,
            size: 22,
          ),
          onPressed: _showActionsSheet,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingActionDock() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: _showActionsSheet,
                  icon: const Icon(
                    LucideIcons.menu,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'More Actions',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleEdit,
                  icon: const Icon(LucideIcons.edit3, size: 18),
                  label: const Text(
                    "Edit Clinic Profile",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF6366F1,
                    ), // Indigo SaaS primary
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    final logoImage = _getLogoProvider(_clinic['logo']);
    final isVerified = _clinic['isVerified'] == true;
    final isActive = _clinic['status'] == 'active';
    final facilities = _clinic['facilities'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Glowing Logo container
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF09090B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      if (logoImage != null)
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                    ],
                    image: logoImage != null
                        ? DecorationImage(image: logoImage, fit: BoxFit.cover)
                        : null,
                    border: Border.all(color: const Color(0xFF27272A)),
                  ),
                  child: logoImage == null
                      ? const Icon(
                          LucideIcons.building2,
                          color: Colors.grey,
                          size: 36,
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (_clinic['facility_type'] ?? 'Facility')
                                  .toString()
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.badgeCheck,
                              color: Colors.blueAccent,
                              size: 18,
                            ),
                          ],
                          const Spacer(),
                          // Polished Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.greenAccent.withValues(alpha: 0.1)
                                  : Colors.redAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.greenAccent.withValues(alpha: 0.2)
                                    : Colors.redAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (isActive
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                .withValues(alpha: 0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? "ACTIVE" : "CLOSED",
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _clinic['name'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionChip(LucideIcons.mapPin, "Location", () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Opening map...")),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                if (_clinic['website'] != null) ...[
                  Expanded(
                    child: _buildActionChip(LucideIcons.globe, "Website", () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Opening website...")),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: _buildActionChip(LucideIcons.phone, "Call", () {
                    if (_primaryPhone.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Calling $_primaryPhone...")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No phone number available."),
                        ),
                      );
                    }
                  }, isPrimary: true),
                ),
              ],
            ),
          ),

          // --- FACILITIES SECTION (With Show More/Less Logic) ---
          if (facilities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: 24,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Key Amenities",
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildFacilitiesList(facilities),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // --- FACILITIES LIST BUILDER ---
  List<Widget> _buildFacilitiesList(List facilities) {
    const int maxVisible = 4; // Show only 4 items initially
    final bool hasMore = facilities.length > maxVisible;

    final displayList = (_isFacilitiesExpanded || !hasMore)
        ? facilities
        : facilities.take(maxVisible).toList();

    // FIX: Added <Widget> here so Dart creates a List<Widget> instead of a strict List<Container>
    List<Widget> chips = displayList.map<Widget>((f) {
      bool isPharmacy = f.toString().toLowerCase().contains('pharmacy');
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPharmacy ? LucideIcons.zap : LucideIcons.checkCircle2,
              size: 14,
              color: isPharmacy ? Colors.amberAccent : Colors.greenAccent,
            ),
            const SizedBox(width: 8),
            Text(
              f.toString(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }).toList();

    // Add the Show More / Show Less button if needed
    if (hasMore) {
      chips.add(
        InkWell(
          onTap: () =>
              setState(() => _isFacilitiesExpanded = !_isFacilitiesExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isFacilitiesExpanded
                      ? "View Less"
                      : "+ ${facilities.length - maxVisible} More",
                  style: const TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isFacilitiesExpanded
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 14,
                  color: const Color(0xFF818CF8),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return chips;
  }

  Widget _buildActionChip(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? const Color(0xFF6366F1).withValues(alpha: 0.15)
              : const Color(0xFF09090B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF6366F1).withValues(alpha: 0.3)
                : const Color(0xFF27272A),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? const Color(0xFF818CF8) : Colors.grey.shade300,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary
                    ? const Color(0xFF818CF8)
                    : Colors.grey.shade300,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildTabBtn('overview', 'Overview', LucideIcons.layoutDashboard),
          _buildTabBtn('slots', 'Schedule', LucideIcons.calendarClock),
          _buildTabBtn('staff', 'Staff', LucideIcons.users2),
          _buildTabBtn('analytics', 'Analytics', LucideIcons.lineChart),
        ],
      ),
    );
  }

  Widget _buildTabBtn(String id, String label, IconData icon) {
    final isActive = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF27272A) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? const Color(0xFF3F3F46) : const Color(0xFF27272A),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.grey.shade500,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case 'overview':
        return _buildOverviewTab();
      case 'slots':
        return _buildScheduleTab();
      case 'staff':
        return _buildStaffTab();
      case 'analytics':
        return _buildAnalyticsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- TAB: OVERVIEW ---
  Widget _buildOverviewTab() {
    final services = _clinic['services'] as List? ?? [];
    final address = _clinic['address'] ?? '';
    final city = _clinic['city'] ?? '';
    final pincode = _clinic['pincode'] ?? '';

    return Column(
      key: const ValueKey('overview'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          "About Facility",
          LucideIcons.alignLeft,
          child: Text(
            (_clinic['notes'] ?? 'No detailed description available.')
                .toString()
                .replaceAll('<br/>', '\n'),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          "Services Available",
          LucideIcons.stethoscope,
          child: services.isEmpty
              ? _buildEmptyState("No services listed", LucideIcons.stethoscope)
              : Column(
                  children: services
                      .map(
                        (s) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "₹${s['price'] ?? 0}",
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          "Contact Info",
          LucideIcons.contact,
          child: Column(
            children: [
              _buildInfoRow(LucideIcons.phone, "Phone", _displayPhone),
              _buildInfoRow(
                LucideIcons.mail,
                "Email",
                _clinic['email'] ?? "N/A",
              ),
              _buildInfoRow(
                LucideIcons.globe,
                "Website",
                _clinic['website'] ?? "N/A",
                noBorder: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          "Location",
          LucideIcons.map,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address,
                style: TextStyle(
                  color: Colors.grey.shade300,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildMiniStatBox("City", city)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMiniStatBox("Pincode", pincode)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF27272A),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.grey.shade700),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatBox(String label, String val) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF09090B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            val.isEmpty ? "N/A" : val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool noBorder = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: noBorder
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFF27272A))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF09090B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade400),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB: SCHEDULE ---
  Widget _buildScheduleTab() {
    final slots = _clinic['available_slots'] as List? ?? [];
    final timings = _clinic['operating_hours']?['timings'] as Map? ?? {};

    return Column(
      key: const ValueKey('slots'),
      children: [
        _buildSectionCard(
          "Booking Slots",
          LucideIcons.calendarRange,
          child: slots.isEmpty
              ? _buildEmptyState(
                  "No appointment slots configured",
                  LucideIcons.calendarX,
                )
              : Column(
                  children: slots.map((s) {
                    final rec = s['recurrence'];
                    String recLabel = "Everyday";
                    if (rec != null &&
                        rec['days'] != null &&
                        (rec['days'] as List).isNotEmpty) {
                      recLabel = (rec['days'] as List).join(", ");
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF09090B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF27272A)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF6366F1,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  (s['type'] ?? 'Weekly')
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF18181B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF27272A),
                                  ),
                                ),
                                child: Text(
                                  "${_formatTime(s['start'])} - ${_formatTime(s['end'])}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            s['label'] ?? 'Slot',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.repeat,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recLabel,
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          "Operating Hours",
          LucideIcons.clock,
          child: timings.isEmpty
              ? _buildEmptyState(
                  "Standard 9-5 Hours Applied",
                  LucideIcons.clock,
                )
              : Column(
                  children: timings.entries.map((e) {
                    final day = e.key;
                    final time = e.value;
                    final isClosed = time['open'] == '00:00';
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF27272A)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            day.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isClosed
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isClosed
                                  ? 'CLOSED'
                                  : "${_formatTime(time['open'])} - ${_formatTime(time['close'])}",
                              style: TextStyle(
                                color: isClosed
                                    ? Colors.redAccent
                                    : Colors.white,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: isClosed
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  // --- TAB: STAFF ---
  Widget _buildStaffTab() {
    final doctors = _clinic['doctors'] as List? ?? [];
    return Column(
      key: const ValueKey('staff'),
      children: [
        _buildSectionCard(
          "Medical Staff Directory",
          LucideIcons.users2,
          child: doctors.isEmpty
              ? _buildEmptyState(
                  "No staff members found. Start building your team.",
                  LucideIcons.userX,
                )
              : Column(
                  children: doctors
                      .map(
                        (doc) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09090B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF27272A)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF6366F1),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: const Color(0xFF27272A),
                                  backgroundImage:
                                      (doc['image'] != null &&
                                          doc['image'].isNotEmpty)
                                      ? NetworkImage(doc['image'])
                                      : null,
                                  child:
                                      (doc['image'] == null ||
                                          doc['image'].isEmpty)
                                      ? const Icon(
                                          LucideIcons.user,
                                          color: Colors.white70,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      doc['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      doc['specialty'] ?? 'General Physician',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  doc['status'] ?? 'Available',
                                  style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  // --- TAB: ANALYTICS (Mocked) ---
  Widget _buildAnalyticsTab() {
    return Column(
      key: const ValueKey('analytics'),
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Total Patients",
                "1,248",
                LucideIcons.users,
                "+12%",
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Revenue",
                "₹45K",
                LucideIcons.wallet,
                "+8%",
                true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                "Wait Time",
                "14 min",
                LucideIcons.timer,
                "-2m",
                true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                "Retention",
                "85%",
                LucideIcons.trendingUp,
                null,
                null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          "Appointment Health",
          LucideIcons.activity,
          child: Column(
            children: [
              _buildProgressBar("Completed", 75, Colors.greenAccent, "845"),
              const SizedBox(height: 20),
              _buildProgressBar("Rescheduled", 15, Colors.blueAccent, "124"),
              const SizedBox(height: 20),
              _buildProgressBar("Cancelled", 10, Colors.redAccent, "45"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String val,
    IconData icon,
    String? trend,
    bool? trendUp,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF27272A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.grey.shade300, size: 16),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendUp!
                        ? Colors.greenAccent.withValues(alpha: 0.1)
                        : Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trendUp ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double percent,
    Color color,
    String count,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF27272A),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE COMPONENT WRAPPER ---
  Widget _buildSectionCard(
    String title,
    IconData icon, {
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF27272A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF27272A))),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }
}
