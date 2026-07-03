import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:my_new_app/screens/main_layout.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart'; // 🚀 [NEW]: For Share and Download

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kSlate900 = Color(0xFF0F172A);
const Color kSlate50 = Color(0xFFF8FAFC);

class BookingSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> appointmentDetails;

  const BookingSuccessScreen({super.key, required this.appointmentDetails});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen> {
  late ConfettiController _confettiController;
  final GlobalKey _ticketKey = GlobalKey(); // 🚀 [NEW]: Ticket Capture Key

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- HELPERS ---
  String _generatePatientId(String? name, String? phone) {
    if (name == null || name.isEmpty) return "PT-0000";
    String namePart = name
        .replaceAll(RegExp(r'[^a-zA-Z]'), "")
        .padRight(3, 'X')
        .substring(0, 3)
        .toUpperCase();
    String phoneClean = phone?.replaceAll(RegExp(r'\D'), "") ?? "0000";
    String phonePart = phoneClean.length > 4
        ? phoneClean.substring(phoneClean.length - 4)
        : phoneClean;
    return "$namePart-$phonePart";
  }

  // 🚀 SUPER SENIOR LOGIC: Capture and Share/Download Ticket 🚀
  Future<void> _captureAndShareTicket({required bool isDownload}) async {
    try {
      // ୧. Loading ଦେଖାନ୍ତୁ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDownload ? "Preparing Ticket for Download..." : "Preparing Ticket to Share..."),
          backgroundColor: kPrimaryColor,
          duration: const Duration(seconds: 1),
        ),
      );

      // ୨. ଟିକେଟ୍ UI କୁ ଉଚ୍ଚ ମାନର (High-Res) ଇମେଜ୍ ରେ ପରିବର୍ତ୍ତନ କରନ୍ତୁ
      RenderRepaintBoundary boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // 3.0 for sharp quality
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // ୩. ଫାଇଲ୍ ନାମ ସୃଷ୍ଟି କରନ୍ତୁ: patientName_slotNumber_date
      final patientName = (widget.appointmentDetails['patientName'] ?? 'Patient').toString().replaceAll(' ', '_');
      final slotNum = (widget.appointmentDetails['slotNumber'] ?? 'Slot').toString();
      final date = (widget.appointmentDetails['date'] ?? 'Date').toString();
      final fileName = "${patientName}_${slotNum}_$date.png";

      // ୪. XFile ସୃଷ୍ଟି କରନ୍ତୁ (ଏହା Web ଏବଂ Mobile ଉଭୟରେ କାମ କରେ)
      final xFile = XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName);

      // ୫. Share/Download କରନ୍ତୁ (Web ରେ ଏହା ସିଧାସଳଖ ଡାଉନଲୋଡ୍ ହୋଇଯିବ)
      await Share.shareXFiles(
        [xFile],
        text: isDownload ? null : "Here is my appointment ticket for Jivan Health.",
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing ticket: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : kSlate900;
    final subTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    final innerContainerColor = isDarkMode ? Colors.black26 : kSlate50;

    final details = widget.appointmentDetails;

    // Safety checks for null values
    final patientName = details['patientName'] ?? "Guest";
    final phone = details['phone'] ?? "0000000000";
    final bookingId = details['bookingId'] ?? "ID-000";
    final time = details['time'] ?? "09:00 AM";
    final date = details['date'] ?? "N/A";
    final amount = details['amount'] ?? 0;
    final slotNumber = details['slotNumber'] ?? "A-01"; 

    final serviceName = details['doctorName'] ?? "Medical Service";
    final serviceType = details['specialty'] ?? "General";
    final serviceImage = details['doctorImage']; 

    final patientId = _generatePatientId(patientName, phone);
    final isPayAtClinic =
        details['paymentMode'] == 'pay_at_clinic' ||
        details['paymentMode'] == 'pay_at_home';
    final double totalAmount = (amount as num).toDouble();

    // 🚀 [ENHANCED QR DATA]: ସମସ୍ତ ଗୁରୁତ୍ୱପୂର୍ଣ୍ଣ ତଥ୍ୟ
    final qrData = "JIVAN HEALTHCARE\nBooking: $bookingId\nSlot: $slotNumber\nPatient: $patientName ($patientId)\nDoctor: $serviceName\nDate: $date\nTime: $time\nTotal: ₹$totalAmount";

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 150), // Increased bottom padding for buttons
            child: Column(
              children: [
                const Icon(
                  LucideIcons.checkCircle,
                  size: 64,
                  color: kGreenColor,
                ),
                const SizedBox(height: 16),
                Text(
                  "Booking Confirmed!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.heart,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "A better health is just a step away.",
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- 🚀 REPAINT BOUNDARY FOR TICKET CAPTURE 🚀 ---
                RepaintBoundary(
                  key: _ticketKey,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDarkMode
                          ? []
                          : [
                              BoxShadow(
                                color: kPrimaryColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      children: [
                        // 1. SERVICE / DOCTOR SECTION
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white10),
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  image: serviceImage != null && serviceImage.toString().isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(serviceImage),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: serviceImage == null || serviceImage.toString().isEmpty
                                    ? const Icon(
                                        LucideIcons.stethoscope,
                                        color: kPrimaryColor,
                                        size: 30,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "APPOINTMENT WITH",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: subTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      serviceName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        serviceType,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),

                        // 2. 🚀 ENHANCED QR & TOKEN SECTION 🚀
                        Container(
                          color: innerContainerColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24, // Added more padding for breathing room
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "SLOT NUMBER",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: subTextColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      slotNumber,
                                      style: const TextStyle(
                                        fontSize: 38, // BIGGER SLOT NUMBER
                                        fontWeight: FontWeight.w900,
                                        color: kGreenColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Show this QR at the reception.",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: subTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 🚀 BIGGER AND CLEARER QR CODE
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white, // Always white bg for QR scanning
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: QrImageView(
                                  data: qrData,
                                  version: QrVersions.auto,
                                  size: 90.0, // Increased Size
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Colors.black,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),

                        // 3. PATIENT DETAILS SECTION
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("PATIENT NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor)),
                                        const SizedBox(height: 4),
                                        Text(patientName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("PATIENT ID", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor)),
                                      const SizedBox(height: 4),
                                      Text(patientId, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("PHONE NUMBER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor)),
                                      const SizedBox(height: 4),
                                      Text("+91 $phone", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: borderColor),

                        // 4. DATE & TIME DETAILS GRID
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildDetailItem(LucideIcons.calendar, "Date", date, innerContainerColor, borderColor, subTextColor, textColor),
                                  _buildDetailItem(LucideIcons.clock, "Time", time, innerContainerColor, borderColor, subTextColor, textColor),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kSlate900,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isPayAtClinic ? "PAYABLE AT VISIT" : "AMOUNT PAID",
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white54),
                                        ),
                                        Text(
                                          "₹${totalAmount.toStringAsFixed(0)}",
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    if (isPayAtClinic)
                                      const Icon(LucideIcons.alertCircle, color: Colors.amber, size: 28)
                                    else
                                      const Icon(LucideIcons.checkCircle, color: kGreenColor, size: 28),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // --- END REPAINT BOUNDARY ---
                
                const SizedBox(height: 24),

                // BOOKING ID COPY
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: bookingId));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Booking ID Copied!")),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BOOKING REFERENCE",
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor),
                            ),
                            Text(
                              bookingId,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: textColor),
                            ),
                          ],
                        ),
                        Icon(LucideIcons.copy, size: 16, color: subTextColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONFETTI
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.2,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange],
            ),
          ),

          // 🚀 ENHANCED BOTTOM BUTTONS (Download, Share, Home) 🚀
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // 🚀 DOWNLOAD BUTTON
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _captureAndShareTicket(isDownload: true),
                          icon: Icon(LucideIcons.download, size: 18, color: textColor),
                          label: Text("Download", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 🚀 SHARE BUTTON
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _captureAndShareTicket(isDownload: false),
                          icon: const Icon(LucideIcons.share2, size: 18, color: Colors.white),
                          label: const Text("Share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // RETURN HOME TEXT BUTTON
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MainLayout()), 
                        (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text("Return to Home", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color bg, Color border, Color labelColor, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: kPrimaryColor),
                const SizedBox(width: 8),
                Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor)),
          ],
        ),
      ),
    );
  }
}