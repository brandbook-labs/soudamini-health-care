import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:my_new_app/screens/admin/inventory_billing/inventory/premium_product_form_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 ସମସ୍ତ ଆବଶ୍ୟକୀୟ ଇମ୍ପୋର୍ଟସ୍ (Imports)
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// 🚀 ଆପଣଙ୍କର API ସର୍ଭିସ୍ ଇମ୍ପୋର୍ଟ (ପାଥ୍ ନିଜ ଅନୁଯାୟୀ ବଦଳାଇବେ)
import 'package:my_new_app/services/api_service.dart';

class PremiumBarcodeScanner extends StatefulWidget {
  final String? id; // Null for Add Mode, passed for Edit Mode

  const PremiumBarcodeScanner({Key? key, this.id}) : super(key: key);

  @override
  State<PremiumBarcodeScanner> createState() => _PremiumBarcodeScannerState();
}

class _PremiumBarcodeScannerState extends State<PremiumBarcodeScanner> {
  final ApiService _apiService = ApiService();

  String? scanResult;
  bool loading = false;
  String activeTab = 'camera';
  String manualBarcode = '';

  // Camera Controller
  late final MobileScannerController _cameraController;

  List<dynamic> scannedVariants = [];

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    // 🚀 ଯଦି Edit Mode (id ଅଛି), ସିଧାସଳଖ ଫର୍ମ ପେଜ୍ କୁ ପଠାଇଦେବେ
    if (widget.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PremiumProductFormPage(id: widget.id),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------------
  // ୧. SCANNER HANDLER LOGIC (USING _apiService)
  // --------------------------------------------------------
  Future<void> handleSuccessfulScan(String barcode) async {
    if (barcode.trim().isEmpty) {
      _showToast("Please enter a valid barcode.", isError: true);
      return;
    }

    setState(() {
      scanResult = barcode;
      loading = true;
      manualBarcode = '';
      scannedVariants = [];
    });

    try {
      // 🚀 Direct Call
      final res = await _apiService.lookupBarcode(barcode);
      final result = res.data;

      if (result['code'] == 200 && result['data'] != null) {
        final fetchedSource = result['data']['source'];
        List foundProducts = [];
        if (result['data']['products'] is List) {
          foundProducts = result['data']['products'];
        } else if (result['data']['product'] != null) {
          foundProducts = [result['data']['product']];
        }

        if (foundProducts.isNotEmpty) {
          if (fetchedSource == 'local_own') {
            setState(() => scannedVariants = foundProducts);
          } else {
            if (foundProducts.length > 1) {
              setState(() => scannedVariants = foundProducts);
            } else {
              // 🚀 Navigate to Form Page with prefill data
              _navigateToForm(
                barcode: barcode,
                prefillData: foundProducts[0] as Map<String, dynamic>,
                fetchedSource: fetchedSource,
              );
            }
          }
        } else {
          // 🚀 Navigate as New Product
          _navigateToForm(barcode: barcode);
        }
      } else {
        _navigateToForm(barcode: barcode);
      }
    } catch (error) {
      _showToast("Network error while fetching details.", isError: true);
      _navigateToForm(barcode: barcode);
    } finally {
      setState(() => loading = false);
    }
  }

  void handleSkipAndAddManually() {
    _showToast("Opened manual entry form. Please fill all details.");
    _navigateToForm(isManualEntry: true);
  }

  void _navigateToForm({
    String? barcode,
    Map<String, dynamic>? prefillData,
    String? fetchedSource,
    bool isManualEntry = false,
  }) {
    // Navigate to Page 2 and reset local states if user comes back
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PremiumProductFormPage(
          barcode: barcode,
          prefillData: prefillData,
          fetchedSource: fetchedSource,
          isManualEntry: isManualEntry,
        ),
      ),
    ).then((_) {
      // Reset scanner when coming back from form
      setState(() {
        scanResult = null;
        scannedVariants = [];
      });
    });
  }

  Future<void> scanBarcodeFromImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() => loading = true);
        final BarcodeCapture? capture = await _cameraController.analyzeImage(image.path);
        
        if (capture != null && capture.barcodes.isNotEmpty) {
          final String? code = capture.barcodes.first.rawValue;
          if (code != null && code.isNotEmpty) {
            await handleSuccessfulScan(code);
          } else {
            setState(() => loading = false);
            _showToast("Could not read barcode from image.", isError: true);
          }
        } else {
          setState(() => loading = false);
          _showToast("No barcode detected in the selected image.", isError: true);
        }
      }
    } catch (e) {
      setState(() => loading = false);
      _showToast("Error processing image.", isError: true);
    }
  }

  // ========================================================
  // 🎨 UI BUILDS (PAGE 1)
  // ========================================================
  @override
  Widget build(BuildContext context) {
    if (widget.id != null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (scanResult == null && scannedVariants.isEmpty)
              _buildScannerModule(),

            if (scannedVariants.isNotEmpty) _buildDisambiguateModal(),

            if (loading && scannedVariants.isEmpty)
              _buildLoader(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Smart Inventory Inwarding",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          Text(
            "Digitize inventory via scanner or manual entry.",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (scanResult == null && scannedVariants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: OutlinedButton.icon(
              onPressed: handleSkipAndAddManually,
              icon: Icon(Icons.edit, size: 14, color: Colors.blue.shade600),
              label: const Text(
                'Manual Entry',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildLoader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text(
              "Querying Database...",
              style: TextStyle(
                color: Colors.blue.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerModule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabBtn('camera', 'Live Scanner', Icons.camera_alt),
                _buildTabBtn('upload', 'Image Upload', Icons.upload_file),
                _buildTabBtn('manual', 'Type Barcode', Icons.keyboard),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. LIVE CAMERA
          if (activeTab == 'camera')
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade100, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      controller: _cameraController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && scanResult == null && !loading) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null && code.isNotEmpty) {
                            handleSuccessfulScan(code);
                          }
                        }
                      },
                    ),
                    Container(
                      width: 250,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade400, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const Positioned(
                      bottom: 20,
                      child: Text(
                        "Align barcode within the frame",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 2. IMAGE UPLOAD
          if (activeTab == 'upload')
            GestureDetector(
              onTap: scanBarcodeFromImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey.shade50,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.cloud_upload, size: 32, color: Colors.blue.shade400),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Tap to select barcode image",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),

          // 3. MANUAL ENTRY
          if (activeTab == 'manual')
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.keyboard, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    "Enter Barcode Manually",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Look for the 12 or 13 digit number below the barcode.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => manualBarcode = val,
                          decoration: InputDecoration(
                            hintText: "e.g. 8904132975408",
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade400),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => handleSuccessfulScan(manualBarcode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Search", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildTabBtn(String tab, String label, IconData icon) {
    bool isActive = activeTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.blue.shade600 : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisambiguateModal() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.layers_outlined,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Disambiguate Variant",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Barcode ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          scanResult ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      Text(
                        " maps to multiple records.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  scannedVariants = [];
                  activeTab = 'camera';
                }),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          ...scannedVariants.map((variant) {
            bool hasBatches =
                variant['batches'] != null &&
                (variant['batches'] as List).isNotEmpty;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            Icons.medication,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                variant['manufacturer'] ?? 'Generic',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              "MRP",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              "₹${variant['price'] ?? variant['sellingPrice'] ?? '0.00'}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: hasBatches
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Select specific batch:",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(variant['batches'] as List).map((batch) {
                                return GestureDetector(
                                  onTap: () {
                                    // 🚀 Pass Selected to Page 2
                                    _navigateToForm(
                                      barcode: variant['barcode'],
                                      prefillData: variant as Map<String, dynamic>,
                                      fetchedSource: 'local_own'
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              batch['batchNumber'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            ),
                                            Text(
                                              "Exp: ${batch['formattedExpiryDate'] ?? '--'}",
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              "${batch['stock']} Units",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.chevron_right,
                                              size: 16,
                                              color: Colors.blue.shade600,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          )
                        : GestureDetector(
                            onTap: () {
                              // 🚀 Pass Selected to Page 2
                              _navigateToForm(
                                barcode: variant['barcode'],
                                prefillData: variant as Map<String, dynamic>,
                                fetchedSource: 'local_own'
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Master Inventory",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                      Text(
                                        "Loc: ${variant['rack'] ?? 'N/A'}",
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${variant['stock'] ?? 0} Units",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // 🚀 Pass New Product to Page 2
                _navigateToForm(barcode: scanResult ?? '');
              },
              icon: const Icon(Icons.add),
              label: const Text("CREATE BRAND NEW VARIANT"),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}