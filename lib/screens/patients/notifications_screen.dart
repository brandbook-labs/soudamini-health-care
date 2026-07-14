import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
// Dark Mode
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

// --- MOCK DATA ---
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type; // 'appointment', 'order', 'promo', 'info'
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock List
  List<AppNotification> notifications = [
    AppNotification(
      id: "1",
      title: "Appointment Reminder",
      body:
          "You have an appointment with Dr. Ananya Sharma tomorrow at 10:00 AM.",
      time: "2 hrs ago",
      type: "appointment",
      isRead: false,
    ),
    AppNotification(
      id: "2",
      title: "Order Shipped",
      body:
          "Your medicine order #OD-8821 has been shipped and will arrive by Friday.",
      time: "5 hrs ago",
      type: "order",
      isRead: false,
    ),
    AppNotification(
      id: "3",
      title: "Flash Sale Alert! ⚡",
      body:
          "Get flat 25% OFF on all Full Body Checkups today. Use code HEALTH25.",
      time: "Yesterday",
      type: "promo",
      isRead: true,
    ),
    AppNotification(
      id: "4",
      title: "Welcome to Jivan",
      body:
          "Your profile is 80% complete. Add your medical history for better recommendations.",
      time: "2 days ago",
      type: "info",
      isRead: true,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (var n in notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All notifications marked as read")),
    );
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme Detection
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? context.surface : context.surface;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text("Mark all read"),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.bellOff,
                    size: 64,
                    color: subTextColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No notifications yet",
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          // 🚀 CHANGED: ListView.builder to ListView.separated
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => Divider(
                color: borderColor,
                height: 1, // Minimal height so it doesn't take up extra space
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: Key(notification.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Notification removed")),
                    );
                  },
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(LucideIcons.trash2, color: Colors.white),
                  ),
                  child: NotificationTile(
                    notification: notification,
                    cardColor: cardColor,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    borderColor: borderColor,
                    isDarkMode: isDarkMode,
                  ),
                );
              },
            ),
    );
  }
}

// --- NOTIFICATION TILE WIDGET ---
class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final Color cardColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;
  final bool isDarkMode;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.cardColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
    required this.isDarkMode,
  });

  // Helper to get icon based on type
  IconData _getIcon() {
    switch (notification.type) {
      case 'appointment':
        return LucideIcons.calendarClock;
      case 'order':
        return LucideIcons.packageCheck;
      case 'promo':
        return LucideIcons.percent;
      default:
        return LucideIcons.info;
    }
  }

  // Helper to get icon color based on type
  Color _getIconColor() {
    switch (notification.type) {
      case 'appointment':
        return kPrimaryColor;
      case 'order':
        return Colors.green;
      case 'promo':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
        top: 10,
      ), // Added top margin to balance the divider
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
        color: notification.isRead
            ? cardColor
            : (isDarkMode
                  ? kPrimaryColor.withValues(alpha: 0.05)
                  : AppPalette.neutralWhite),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(), size: 20, color: iconColor),
          ),
          const SizedBox(width: 10),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: notification.isRead
                              ? FontWeight.w600
                              : FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      notification.time,
                      style: TextStyle(fontSize: 10, color: subTextColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 12,
                    color: notification.isRead
                        ? subTextColor
                        : textColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Unread Dot
          if (!notification.isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: kPrimaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
