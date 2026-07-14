// lib/screens/admin/adminUsers/adminStaff/widgets/staff_list_card.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../staff_details_screen.dart'; 
import '../add_staff_screen.dart'; 
import 'package:my_new_app/models/staff_model.dart';

class StaffListCard extends StatelessWidget {
  final Staff staff; 
  final ThemeData theme;
  final VoidCallback onCall;
  final VoidCallback onSuspend;
  final VoidCallback onDelete;
  final Function(Staff) onUpdate;

  const StaffListCard({
    super.key,
    required this.staff,
    required this.theme,
    required this.onCall,
    required this.onSuspend,
    required this.onDelete,
    required this.onUpdate,
  });

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == "No Phone") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not available."), backgroundColor: Colors.red),
      );
      return;
    }
    final Uri callUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber == "No Phone") return;
    final String message = "Hello ${staff.name},\n\nWelcome to Jivan Platform!\nYour login slug is: ${staff.slug}\nPassword: [Sent via Email/SMS]";
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length == 10) cleanPhone = "91$cleanPhone";
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primaryContainer,
                          image: staff.image.isNotEmpty 
                            ? DecorationImage(image: CachedNetworkImageProvider(staff.image), fit: BoxFit.cover) 
                            : null,
                        ),
                        child: staff.image.isEmpty ? Icon(LucideIcons.user, color: theme.colorScheme.primary) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Manage ${staff.name}",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              staff.role.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: theme.disabledColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.eye, color: Colors.blue, size: 20),
                  ),
                  title: const Text("View Details", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("See complete profile and activity", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  onTap: () async { // 🚀 async ଲଗାନ୍ତୁ
                    Navigator.pop(ctx);
                    final updatedStaff = await Navigator.push(
                      context, MaterialPageRoute(builder: (_) => StaffDetailsScreen(staff: staff))
                    );
                    if (updatedStaff != null && updatedStaff is Staff) onUpdate(updatedStaff); // 🚀 ଫେରିଲେ ଅପଡେଟ୍ ହେବ
                  },
                ),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.pencil, color: Colors.green, size: 20),
                  ),
                  title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("Modify staff information", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final editId = staff.mappingId.isNotEmpty ? staff.mappingId : staff.id; // 🚀 Edit ପାଇଁ mappingId
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddStaffScreen(staffId: editId)));
                  },
                ),

                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(LucideIcons.archive, color: Colors.orange, size: 20),
                  ),
                  title: const Text("Archive Staff", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange)),
                  subtitle: Text("Remove from active list", style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete(); 
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    final String name = staff.name.isNotEmpty ? staff.name : "Unknown";
    final String phone = staff.phone.isNotEmpty ? staff.phone : "No Phone";
    final String roleRaw = staff.role.toLowerCase();
    final String roleDisplay = roleRaw.isNotEmpty ? roleRaw[0].toUpperCase() + roleRaw.substring(1) : "Staff";
    final String imageUrl = staff.image;
    
    final bool isArchived = staff.isArchived; 
    final bool isSuspended = staff.isSuspended || staff.status.toLowerCase() == 'suspended';
    
    final String displayStatus = isArchived ? "Archived" : (isSuspended ? "Suspended" : (staff.status.isNotEmpty ? staff.status : "Active"));

    Color bgColor = theme.cardColor;
    Color borderColor = theme.dividerColor.withOpacity(0.5);
    Color statusColor = Colors.green;
    double borderWidth = 1.0;

    if (isArchived) {
      bgColor = Colors.orange.withOpacity(0.05);
      borderColor = Colors.orange.withOpacity(0.4);
      statusColor = Colors.orange;
      borderWidth = 1.5;
    } else if (isSuspended) {
      bgColor = Colors.red.withOpacity(0.05);
      borderColor = Colors.red.withOpacity(0.4);
      statusColor = Colors.red;
      borderWidth = 1.5;
    }

    String subtitle = roleDisplay;
    if (roleRaw == 'doctor' && staff.specialty.isNotEmpty && staff.specialty != 'General Physician') {
      subtitle = "${staff.specialty} Specialist";
    } else if (staff.clinicName.isNotEmpty && staff.clinicName != 'Private Clinic') {
      subtitle = staff.clinicName;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onLongPress: () => _showActionMenu(context),
          onTap: () async { // 🚀 async ଲଗାନ୍ତୁ
            final updatedStaff = await Navigator.push(
              context, MaterialPageRoute(builder: (context) => StaffDetailsScreen(staff: staff)),
            );
            if (updatedStaff != null && updatedStaff is Staff) onUpdate(updatedStaff); // 🚀 ଫେରିଲେ ଅପଡେଟ୍ ହେବ
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(image: CachedNetworkImageProvider(imageUrl), fit: BoxFit.cover)
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: statusColor),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: isArchived || isSuspended ? TextDecoration.lineThrough : TextDecoration.none,
                                  ),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _StatusBadge(
                                status: displayStatus,
                                color: statusColor, 
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(color: theme.hintColor, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.phone, size: 12, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Text(phone, style: TextStyle(color: theme.hintColor, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: borderColor.withOpacity(0.5),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: LucideIcons.phone,
                      label: "Call",
                      color: Colors.green,
                      onTap: () => _makePhoneCall(context, phone),
                    ),
                    Container(width: 1, height: 20, color: theme.dividerColor.withValues(alpha: 0.3)),
                    _ActionButton(
                      icon: LucideIcons.messageSquare,
                      label: "Chat",
                      color: Colors.blue,
                      onTap: () => _openWhatsApp(context, phone),
                    ),
                    Container(width: 1, height: 20, color: theme.dividerColor.withValues(alpha: 0.3)),
                    _ActionButton(
                      icon: isSuspended ? LucideIcons.checkCircle : LucideIcons.ban,
                      label: isSuspended ? "Activate" : "Suspend",
                      color: isSuspended ? Colors.green : Colors.red,
                      onTap: onSuspend, 
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon, required this.label, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}