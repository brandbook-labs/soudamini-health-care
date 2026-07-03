import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? invoiceData;
  final Map<String, dynamic>? clinicProfile;

  const InvoiceScreen({
    super.key,
    this.invoiceData,
    this.clinicProfile = const {},
  });

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final GlobalKey _invoiceKey = GlobalKey();

  bool _isPrinting = false;
  bool _isSharing = false;

  // ========================================================================
  // CACHED NORMALIZED DATA (Fast Memory Access)
  // ========================================================================
  late final String cName;
  late final String cAddress;
  late final String cPhone;
  late final String invNo;
  late final String invDate;
  late final String custName;
  late final String custPhone;
  late final double subTotal;
  late final double totalTax;
  late final double netTotal;
  late final String paymentMethod;
  late final List<dynamic> itemsList;

  @override
  void initState() {
    super.initState();
    _normalizeData();
  }

  void _normalizeData() {
    final invData = widget.invoiceData ?? {};
    final clinProf = widget.clinicProfile ?? {};

    cName =
        invData['clinic_id']?['name'] ??
        invData['clinicName'] ??
        clinProf['name'] ??
        "JIVAN MEDICAL";
    cAddress =
        invData['clinic_id']?['address'] ??
        invData['clinicAddress'] ??
        clinProf['address'] ??
        "Odisha, India";

    final rawPhone =
        invData['clinic_id']?['phone'] ??
        invData['clinicPhone'] ??
        clinProf['phone'];
    cPhone = rawPhone is List
        ? rawPhone.join(', ')
        : (rawPhone?.toString() ?? "N/A");

    invNo = invData['invoiceNumber'] ?? invData['invoiceId'] ?? "N/A";

    final createdAt = invData['createdAt'];
    invDate =
        invData['date'] ??
        (createdAt != null
            ? DateTime.tryParse(createdAt)?.toString().substring(0, 16) ?? "N/A"
            : DateTime.now().toString().substring(0, 16));

    custName = invData['customer']?['name'] ?? "Cash Customer";
    custPhone = invData['customer']?['phone'] ?? "N/A";

    subTotal = (invData['summary']?['subTotal'] ?? invData['subTotal'] ?? 0)
        .toDouble();
    totalTax = (invData['summary']?['totalTax'] ?? invData['totalTax'] ?? 0)
        .toDouble();
    netTotal = (invData['summary']?['netAmount'] ?? invData['netTotal'] ?? 0)
        .toDouble();

    paymentMethod = invData['paymentMethod'] ?? "CASH";
    itemsList = invData['items'] ?? [];
  }

  // --- ACTIONS ---
  void _handleClose() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // 🖨️ Print Document (Perfect A4 Fit)
  Future<void> _handlePrint() async {
    if (_isPrinting) return;
    setState(() => _isPrinting = true);
    JivanToast.show(
      context,
      title: "Printing Invoice",
      message: "Preparing PDF for print...",
      type: ToastType.info,
    );

    try {
      // 1. Capture the image from the RepaintBoundary
      final boundary =
          _invoiceKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null)
        throw Exception("Failed to find invoice visual bounds");

      // Use a high pixel ratio for crisp text
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception("Failed to encode image data");

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // 2. Generate the PDF and send to printer
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          final doc = pw.Document();
          final imageProvider = pw.MemoryImage(pngBytes);

          doc.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              margin: pw
                  .EdgeInsets
                  .zero, // Zero margin to let your UI dictate spacing
              build: (pw.Context context) {
                // Center and contain the image perfectly on the A4 page
                return pw.Center(
                  child: pw.Image(imageProvider, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
          return doc.save();
        },
      );
    } catch (e) {
      debugPrint("Print Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to print invoice.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  // --- SHARE LOGIC (Optimized & Secure) ---
  Future<void> _handleShare() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing secure invoice copy...')),
    );

    try {
      final boundary =
          _invoiceKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null)
        throw Exception("Failed to find invoice visual bounds");

      // High pixelRatio for sharp mobile text rendering
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) throw Exception("Failed to encode image data");

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Secure temp directory (OS handles cleanup)
      final directory = await getTemporaryDirectory();
      final safeName = cName
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
          .toUpperCase();
      final safeInv = invNo.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      final file = File('${directory.path}/${safeName}_$safeInv.png');
      await file.writeAsBytes(pngBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Dear $custName,\n\nHere is your invoice for Bill No: $invNo.\n\nThank you for choosing $cName.\nVisit us at: https://jivan.website',
      );
    } catch (e) {
      debugPrint("Sharing Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate shareable invoice.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Deep Zinc
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: RepaintBoundary(
                  key: _invoiceKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildMetaInfoPanel(),
                        const SizedBox(height: 24),
                        _buildItemsTable(),
                        const SizedBox(height: 32),
                        _buildTotalsSection(),
                        const SizedBox(height: 32),
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildMobileActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4E4E7)),
        ), // zinc-200
      ),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // 🚀 କେବଳ Clinic Details କୁ Center କରାଗଲା
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  cName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF18181B),
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  cAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF71717A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "PH: $cPhone",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF27272A),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 🚀 INVOICE ଟେକ୍ସଟ୍ କୁ ଡାହାଣ ପଟେ (Right Aligned) ରଖାଗଲା
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              "INVOICE",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: Color(0xFFE4E4E7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Details
          const Text(
            "INVOICE DETAILS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1A1AA),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text(
                  "No:",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                ),
              ),
              Text(
                invNo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text(
                  "Date:",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                ),
              ),
              Text(
                invDate,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFFE4E4E7), height: 1),
          const SizedBox(height: 20),

          // Billed To
          const Text(
            "BILLED TO",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA1A1AA),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text(
                  "Name:",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  custName.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF18181B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(
                width: 44,
                child: Text(
                  "Ph:",
                  style: TextStyle(color: Color(0xFF71717A), fontSize: 13),
                ),
              ),
              Text(
                custPhone,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF18181B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              border: Border(bottom: BorderSide(color: Color(0xFFE4E4E7))),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    "ITEM",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF71717A),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    "QTY",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF71717A),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    "AMOUNT",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF71717A),
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items
          if (itemsList.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No items found.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...itemsList.asMap().entries.map((entry) {
            final item = entry.value;
            final qty = item['quantity'] ?? item['qty'] ?? 1;
            final rate = item['selectedPriceType'] == 'SELLING_PRICE'
                ? (item['sellingPrice'] ?? item['price'])
                : (item['unitPrice'] ?? item['price'] ?? item['mrp'] ?? 0);
            final bNo =
                item['batchNumber'] ?? item['selectedBatchNumber'] ?? 'MASTER';
            final itemTotal = item['totalPrice'] ?? (rate * qty);

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                border: entry.key != itemsList.length - 1
                    ? const Border(bottom: BorderSide(color: Color(0xFFF4F4F5)))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] ?? 'Unknown Item',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "BCH: $bNo",
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF71717A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      "$qty",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF27272A),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      (itemTotal as num).toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF18181B),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Column(
      children: [
        // Payment Note
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PAYMENT NOTE",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: Color(0xFF18181B),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF71717A),
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(
                      text: "Amount inclusive of applicable taxes. Paid via ",
                    ),
                    TextSpan(
                      text: paymentMethod,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27272A),
                      ),
                    ),
                    const TextSpan(
                      text: ". Goods once sold cannot be returned.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Totals
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Subtotal (Net):",
                style: TextStyle(color: Color(0xFF71717A), fontSize: 14),
              ),
              Text(
                subTotal.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total GST:",
                style: TextStyle(color: Color(0xFF71717A), fontSize: 14),
              ),
              Text(
                totalTax.toStringAsFixed(2),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "NET TOTAL",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "₹${netTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE4E4E7))),
      ),
      padding: const EdgeInsets.only(top: 24), // ✅ FIXED: EdgeInsets.only()
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.flash_on, size: 12, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    "SOFTWARE TECHNOLOGY PARTNER",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      color: Color(0xFF71717A),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                "JIVAN HEALTHTECH",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "https://jivan.website",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MOBILE OPTIMIZED STICKY ACTION BAR
  Widget _buildMobileActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE4E4E7))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionBtn(
              "Close",
              Icons.close,
              const Color(0xFFF4F4F5),
              const Color(0xFF3F3F46),
              _handleClose,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              "Share",
              _isSharing ? Icons.hourglass_empty : Icons.share,
              Colors.blue.shade600,
              Colors.white,
              _handleShare,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionBtn(
              "Print",
              Icons.print,
              const Color(0xFF18181B),
              Colors.white,
              _handlePrint,
            ),
          ), // Replaced emerald with standard black/zinc
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
