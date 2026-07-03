import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_new_app/services/api_service.dart';

class PremiumProductFormPage extends StatefulWidget {
  final String? id; // For Edit Mode
  final String? barcode; 
  final Map<String, dynamic>? prefillData; 
  final String? fetchedSource; 
  final bool isManualEntry;

  const PremiumProductFormPage({
    Key? key,
    this.id,
    this.barcode,
    this.prefillData,
    this.fetchedSource,
    this.isManualEntry = false,
  }) : super(key: key);

  @override
  State<PremiumProductFormPage> createState() => _PremiumProductFormPageState();
}

class _PremiumProductFormPageState extends State<PremiumProductFormPage> {
  final ApiService _apiService = ApiService();

  bool loading = false;

  // Multi-Image State
  List<String> existingImages = [];
  List<File> newImages = [];

  List<Map<String, dynamic>> salts = [
    {'name': '', 'strength': '', 'excipients': ''},
  ];
  List<String> storagePath = [''];

  Map<String, dynamic>? productDetails;

  Map<String, dynamic> getEmptyProductState(String barcodeVal) {
    return {
      'barcode': barcodeVal,
      'name': '',
      'brand': '',
      'category': 'Tablet',
      'packSize': '',
      'manufacturer': '',
      'supplier': '',
      'hsnCode': '',
      'purchasePrice': '',
      'sellingPrice': '',
      'price': '',
      'taxPercent': '12',
      'isGstInclusive': true,
      'stock': '',
      'minStockAlert': '10',
      'batchNumber': '',
      'mfgDate': '',
      'expiryDate': '',
      'rack': '',
      'shelf': '',
      'drawer': '',
      'storageCondition': 'Room Temperature',
      'isRxRequired': false,
      'drugSchedule': 'OTC',
      'datasheetUrl': '',
      'batches': [],
      'diseases': [],
      'maxCappedQty': 0,
      'coldStorage': false,
      'isActive': true,
    };
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.id != null) {
      fetchMedicineDetails(widget.id!);
    } else if (widget.prefillData != null) {
      loadProductIntoForm(widget.prefillData!, widget.fetchedSource ?? '', widget.barcode ?? '');
    } else if (widget.isManualEntry) {
      handleSkipAndAddManually();
    } else {
      initiateNewProduct(widget.barcode ?? '');
    }
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
  // FETCH DETAILS (USING _apiService)
  // --------------------------------------------------------
  Future<void> fetchMedicineDetails(String medicineId) async {
    setState(() => loading = true);
    try {
      final res = await _apiService.getMedicineDetails(medicineId);
      final data = res.data;

      if (data['code'] == 200 && data['data'] != null) {
        final med = data['data'];
        setState(() {
          productDetails = {
            ...getEmptyProductState(''),
            ...med,
            'isGstInclusive': med['isGstInclusive'] != false,
          };

          List<String> path = [];
          if (med['rack'] != null && med['rack'] != '') path.add(med['rack']);
          if (med['shelf'] != null && med['shelf'] != '') path.add(med['shelf']);
          if (med['drawer'] != null && med['drawer'] != '') path.add(med['drawer']);
          storagePath = path.isNotEmpty ? path : [''];

          if (med['salts'] != null) {
            try {
              var parsedSalts = med['salts'] is String ? json.decode(med['salts']) : med['salts'];
              if (parsedSalts is List && parsedSalts.isNotEmpty) {
                salts = List<Map<String, dynamic>>.from(parsedSalts);
              }
            } catch (e) {
              print("Error parsing salts");
            }
          }

          if (med['images'] != null && med['images'].isNotEmpty) {
            existingImages = List<String>.from(med['images']);
          } else if (med['image'] != null) {
            existingImages = [med['image']];
          } else {
            existingImages = [];
          }
          newImages = [];
        });
      } else {
        _showToast("Failed to fetch medicine details", isError: true);
      }
    } catch (err) {
      _showToast("Network Error while fetching", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  void loadProductIntoForm(Map<String, dynamic> productData, String fetchedSource, String barcode) {
    List<Map<String, dynamic>> parseSaltsSafely(dynamic saltsData) {
      if (saltsData == null) return [{'name': '', 'strength': '', 'excipients': ''}];
      try {
        var parsed = saltsData is String ? json.decode(saltsData) : saltsData;
        if (parsed is List && parsed.isNotEmpty) {
          return List<Map<String, dynamic>>.from(parsed);
        }
        return [{'name': '', 'strength': '', 'excipients': ''}];
      } catch (e) {
        return [{'name': '', 'strength': '', 'excipients': ''}];
      }
    }

    List<String> dbImages = [];
    if (productData['images'] is List && productData['images'].isNotEmpty) {
      dbImages = List<String>.from(productData['images']);
    } else if (productData['image'] != null) {
      dbImages = [productData['image']];
    }

    if (fetchedSource == 'local_own') {
      if (productData['isActive'] == false) {
        _showToast("Found deleted product. Updating will re-activate it.");
      } else {
        _showToast("Loaded existing clinic product for editing.");
      }

      setState(() {
        productDetails = {
          ...getEmptyProductState(productData['barcode'] ?? barcode),
          ...productData,
          'isGstInclusive': productData['isGstInclusive'] != false,
          'isActive': productData['isActive'] != false,
        };

        existingImages = dbImages;
        newImages = [];

        List<String> path = [];
        if (productData['rack'] != null && productData['rack'] != '') path.add(productData['rack']);
        if (productData['shelf'] != null && productData['shelf'] != '') path.add(productData['shelf']);
        if (productData['drawer'] != null && productData['drawer'] != '') path.add(productData['drawer']);
        storagePath = path.isNotEmpty ? path : [''];

        salts = parseSaltsSafely(productData['salts']);
      });
    } else {
      _showToast("Global template loaded! Please set your pricing and stock.");

      setState(() {
        productDetails = {
          ...getEmptyProductState(productData['barcode'] ?? barcode),
          'name': productData['name'] ?? '',
          'brand': productData['brand'] ?? '',
          'manufacturer': productData['manufacturer'] ?? '',
          'category': productData['category'] ?? 'Tablet',
          'packSize': productData['packSize'] ?? '',
          'supplier': productData['supplier'] ?? '',
          'hsnCode': productData['hsnCode'] ?? '',
          'taxPercent': productData['taxPercent'] ?? '12',
          'coldStorage': productData['coldStorage'] ?? false,
          'isRxRequired': productData['isRxRequired'] ?? false,
          'drugSchedule': productData['drugSchedule'] ?? 'OTC',
          'datasheetUrl': productData['datasheetUrl'] ?? '',
          'diseases': productData['diseases'] is List ? productData['diseases'] : [],
          'price': '', 'purchasePrice': '', 'sellingPrice': '', 'stock': '',
          'batches': [],
          'maxCappedQty': 0,
          'rack': '', 'shelf': '', 'drawer': '',
          'isActive': true,
        };

        existingImages = dbImages;
        newImages = [];
        salts = parseSaltsSafely(productData['salts']);
        storagePath = [''];
      });
    }
  }

  void initiateNewProduct(String barcode) {
    _showToast("New variant initiated. Please fill the details.");
    setState(() {
      productDetails = getEmptyProductState(barcode);
      storagePath = [''];
      existingImages = [];
      newImages = [];
    });
  }

  void handleSkipAndAddManually() {
    setState(() {
      productDetails = getEmptyProductState('');
      existingImages = [];
      newImages = [];
      salts = [{'name': '', 'strength': '', 'excipients': ''}];
      storagePath = [''];
    });
  }

  // --------------------------------------------------------
  // IMAGE HANDLERS
  // --------------------------------------------------------
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    
    if (images != null) {
      if (existingImages.length + newImages.length + images.length > 5) {
        _showToast("Maximum 5 images allowed.", isError: true);
        return;
      }
      setState(() {
        newImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void removeImage(int index) {
    setState(() {
      if (index < existingImages.length) {
        existingImages.removeAt(index);
      } else {
        newImages.removeAt(index - existingImages.length);
      }
    });
  }

  // --------------------------------------------------------
  // SAVE / SUBMIT LOGIC (USING _apiService)
  // --------------------------------------------------------
  Future<void> handleSaveProduct() async {
    if (productDetails == null) return;

    final isEditing = widget.id != null;
    final isReactivating = productDetails!['isActive'] == false;
    final updateMode = isEditing || productDetails!['_id'] != null;

    setState(() => loading = true);

    try {
      // ୧. Prepare Text Data Map
      Map<String, dynamic> payload = {
        'barcode': productDetails!['barcode']?.toString() ?? '',
        'name': productDetails!['name']?.toString() ?? '',
        'manufacturer': productDetails!['manufacturer']?.toString() ?? '',
        'price': productDetails!['price']?.toString() ?? '',
        'brand': productDetails!['brand']?.toString() ?? '',
        'category': productDetails!['category']?.toString() ?? '',
        'packSize': productDetails!['packSize']?.toString() ?? '',
        'supplier': productDetails!['supplier']?.toString() ?? '',
        'hsnCode': productDetails!['hsnCode']?.toString() ?? '',
        'purchasePrice': productDetails!['purchasePrice']?.toString() ?? '',
        'sellingPrice': productDetails!['sellingPrice']?.toString() ?? '',
        'taxPercent': productDetails!['taxPercent']?.toString() ?? '12',
        'isGstInclusive': productDetails!['isGstInclusive']?.toString() ?? 'true',
        'minStockAlert': productDetails!['minStockAlert']?.toString() ?? '10',
        'maxCappedQty': productDetails!['maxCappedQty']?.toString() ?? '0',
        'coldStorage': productDetails!['coldStorage']?.toString() ?? 'false',
        'storageCondition': productDetails!['storageCondition']?.toString() ?? 'Room Temperature',
        'isRxRequired': productDetails!['isRxRequired']?.toString() ?? 'false',
        'drugSchedule': productDetails!['drugSchedule']?.toString() ?? 'OTC',
        'datasheetUrl': productDetails!['datasheetUrl']?.toString() ?? '',
        'rack': storagePath.isNotEmpty ? storagePath[0] : '',
        'shelf': storagePath.length > 1 ? storagePath[1] : '',
        'drawer': storagePath.length > 2 ? storagePath.sublist(2).join(' / ') : '',
      };

      // ୨. Stringify Arrays for FormData
      List validBatches = (productDetails!['batches'] as List? ?? [])
          .where((b) => b['batchNumber'] != null && b['batchNumber'].toString().trim().isNotEmpty).toList();
      payload['batches'] = json.encode(validBatches);

      List validDiseases = (productDetails!['diseases'] as List? ?? [])
          .where((d) => d.toString().trim().isNotEmpty).toList();
      payload['diseases'] = json.encode(validDiseases);

      List validSalts = salts.where((s) => s['name'].toString().trim().isNotEmpty).toList();
      payload['salts'] = json.encode(validSalts);

      if (isReactivating) payload['isActive'] = 'true';
      payload['existingImages'] = json.encode(existingImages);

      // ୩. Prepare Single Image File as XFile
      XFile? imageToSend;
      if (newImages.isNotEmpty) {
         imageToSend = XFile(newImages.first.path); 
      }

      // 🚀 ୪. Direct Call to Service
      Response res;
      if (updateMode) {
        res = await _apiService.updateMedicine(
          id: productDetails!['_id'] ?? widget.id!,
          data: payload,
          image: imageToSend,
        );
      } else {
        res = await _apiService.addMedicine(
          payload, 
          imageToSend,
        );
      }

      final data = res.data;

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showToast(data['message'] ?? (updateMode ? "Medicine updated successfully!" : "Medicine added successfully!"));
        Navigator.pop(context); // Go back on success
      } else {
        _showToast(data['message'] ?? "Failed to save product.", isError: true);
      }
    } catch (err) {
      _showToast("Server error while saving.", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // ========================================================
  // 🎨 UI BUILDS (FORM PAGE)
  // ========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
                Text(
                  widget.id != null ? "Edit Master Record" : "Create Master Record",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Text(
              "Update pricing, storage locator, and clinical data.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: Stack(
        children: [
          if (loading && productDetails == null)
            const Center(child: CircularProgressIndicator())
          else if (productDetails != null)
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMasterForm(),
                  const SizedBox(height: 80),
                ],
              ),
            ),

          if (productDetails != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: loading ? null : handleSaveProduct,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    widget.id != null || productDetails!['_id'] != null
                        ? "UPDATE MEDICINE RECORD"
                        : "SAVE MEDICINE TO INVENTORY",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // MASTER FORM (WHITE THEME)
  // --------------------------------------------------------
  Widget _buildMasterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Record ID: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    widget.isManualEntry
                        ? 'MANUAL CREATION'
                        : (productDetails!['barcode'] ?? ''),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 1. Basic Details
        _buildSectionHeader("Basic Details", Icons.info_outline),
        _buildTextField('Trade Name', 'name'),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Manufacturer / Brand', 'manufacturer'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField('Pack Size (e.g. 10x10)', 'packSize'),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildDropdown('Category', 'category', [
                'Tablet',
                'Syrup',
                'Injection',
                'Cream',
                'Drops',
                'Other',
              ]),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('HSN Code', 'hsnCode')),
          ],
        ),

        const SizedBox(height: 24),
        // 2. Financials
        _buildSectionHeader("Financials", Icons.attach_money),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Purchase Price (₹)',
                'purchasePrice',
                isNumber: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Selling Price (₹)',
                'sellingPrice',
                isNumber: true,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildTextField('MRP (₹)', 'price', isNumber: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown('Tax %', 'taxPercent', [
                '0',
                '5',
                '12',
                '18',
                '28',
              ]),
            ),
          ],
        ),

        const SizedBox(height: 24),
        // 3. Clinical Composition
        _buildClinicalComposition(),

        const SizedBox(height: 24),
        // 4. Storage & Location
        _buildStoragePathManager(),

        const SizedBox(height: 24),
        // 5. Image Uploads
        _buildImageUploaderSection(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller:
                TextEditingController(text: productDetails![key]?.toString())
                  ..selection = TextSelection.collapsed(
                    offset: (productDetails![key]?.toString() ?? '').length,
                  ),
            onChanged: (val) => productDetails![key] = val,
            keyboardType: isNumber
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String key, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: options.contains(productDetails![key]?.toString())
                    ? productDetails![key]?.toString()
                    : options.first,
                isExpanded: true,
                items: options
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => productDetails![key] = val),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // CLINICAL COMPOSITION
  // --------------------------------------------------------
  Widget _buildClinicalComposition() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: Colors.purple.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Clinical & Formulation",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(
                      () => productDetails!['isRxRequired'] =
                          !productDetails!['isRxRequired'],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: productDetails!['isRxRequired']
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: productDetails!['isRxRequired']
                              ? Colors.red.shade200
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        productDetails!['isRxRequired'] ? "Rx Required" : "OTC",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: productDetails!['isRxRequired']
                              ? Colors.red.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            "API & EXCIPIENTS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...salts.asMap().entries.map((entry) {
            int index = entry.key;
            var salt = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: salt['name'])
                            ..selection = TextSelection.collapsed(
                              offset: salt['name'].length,
                            ),
                          onChanged: (val) => salts[index]['name'] = val,
                          decoration: const InputDecoration(
                            hintText: "API Name",
                            isDense: true,
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller:
                              TextEditingController(text: salt['strength'])
                                ..selection = TextSelection.collapsed(
                                  offset: salt['strength'].length,
                                ),
                          onChanged: (val) => salts[index]['strength'] = val,
                          decoration: const InputDecoration(
                            hintText: "Strength",
                            isDense: true,
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red.shade400,
                        onPressed: salts.length > 1
                            ? () => setState(() => salts.removeAt(index))
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: salt['excipients'])
                      ..selection = TextSelection.collapsed(
                        offset: salt['excipients'].length,
                      ),
                    onChanged: (val) => salts[index]['excipients'] = val,
                    decoration: InputDecoration(
                      hintText: "Excipients (Optional)",
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.info_outline, size: 14),
                      prefixIconConstraints: const BoxConstraints(minWidth: 24),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          TextButton.icon(
            onPressed: () => setState(
              () => salts.add({'name': '', 'strength': '', 'excipients': ''}),
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text(
              "Add Formulation Component",
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // STORAGE PATH MANAGER
  // --------------------------------------------------------
  Widget _buildStoragePathManager() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.indigo.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Physical Locator Path",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => setState(() => storagePath.add('')),
                icon: const Icon(Icons.add, size: 12),
                label: const Text("Add Node", style: TextStyle(fontSize: 10)),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.indigo.shade50,
                  foregroundColor: Colors.indigo.shade700,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: storagePath.asMap().entries.map((entry) {
              int idx = entry.key;
              String node = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    padding: const EdgeInsets.only(
                      right: 28,
                    ), // Space for close icon
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        TextField(
                          controller: TextEditingController(text: node)
                            ..selection = TextSelection.collapsed(
                              offset: node.length,
                            ),
                          onChanged: (val) => storagePath[idx] = val,
                          decoration: InputDecoration(
                            hintText: idx == 0
                                ? "Rack"
                                : idx == 1
                                ? "Shelf"
                                : "Drawer",
                            hintStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(
                                color: Colors.indigo.shade400,
                              ),
                            ),
                          ),
                        ),
                        if (storagePath.length > 1)
                          GestureDetector(
                            onTap: () =>
                                setState(() => storagePath.removeAt(idx)),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                Icons.cancel,
                                size: 14,
                                color: Colors.red.shade300,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (idx < storagePath.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              );
            }).toList(), // ✅ ଏହା children: [] ପାଇଁ ଠିକ୍ ଭାବରେ କାମ କରିବ
          ), // ✅ ଏଠାରୁ ଅତିରିକ୍ତ .toList() ହଟାଇ ଦିଆଯାଇଛି
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // IMAGE UPLOADER SECTION
  // --------------------------------------------------------
  Widget _buildImageUploaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image_outlined, size: 18, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text(
                "Product Images",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Spacer(),
              Text(
                "${existingImages.length + newImages.length} / 5",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(
                        color: Colors.blue.shade200,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.blue.shade400,
                        ),
                        const Text(
                          "Add",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Existing Images
                ...existingImages.asMap().entries.map(
                  (entry) => _buildImageThumbnail(
                    entry.value,
                    entry.key,
                    isNetwork: true,
                  ),
                ),
                // New Images
                ...newImages.asMap().entries.map(
                  (entry) => _buildImageThumbnail(
                    entry.value,
                    entry.key + existingImages.length,
                    isNetwork: false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(
    dynamic imageSource,
    int index, {
    required bool isNetwork,
  }) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: isNetwork
                ? Image.network(imageSource as String, fit: BoxFit.cover)
                : Image.file(imageSource as File, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 16,
          child: GestureDetector(
            onTap: () => removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cancel, size: 16, color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}