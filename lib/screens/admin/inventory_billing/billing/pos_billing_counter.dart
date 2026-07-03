import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_new_app/core/components/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 ଆପଣଙ୍କର ନୂଆ API Service ଏବଂ Invoice Screen ଇମ୍ପୋର୍ଟ
import 'package:my_new_app/services/api_service.dart'; 
import 'package:my_new_app/screens/admin/inventory_billing/billing/invoice_screen.dart';

// 🚀 ଦୟାକରି ଆପଣଙ୍କର JivanToast ଫାଇଲ୍ ଏବଂ ToastType ଏଠାରେ ଇମ୍ପୋର୍ଟ କରନ୍ତୁ
// import 'package:my_new_app/utils/jivan_toast.dart'; 

class POSBillingCounter extends StatefulWidget {
  const POSBillingCounter({Key? key}) : super(key: key);

  @override
  State<POSBillingCounter> createState() => _POSBillingCounterState();
}

class _POSBillingCounterState extends State<POSBillingCounter> {
  final ApiService _apiService = ApiService();

  // Search & Cart
  String searchTerm = '';
  List<dynamic> suggestions = [];
  List<Map<String, dynamic>> cart = [];

  Map<String, dynamic>? invoiceData;
  List<dynamic> scannedVariants = [];

  // Customer State
  String customerPhone = '';
  String customerName = '';
  String customerAge = '';
  String customerGender = 'Male';
  String? customerId;
  List<dynamic> patientSuggestions = [];
  bool isSearchingUser = false;

  // Doctor State
  String doctorName = '';
  String? doctorId;
  List<dynamic> doctorSuggestions = [];

  // Hardware Scanner State
  String _barcodeBuffer = '';
  int _lastKeyTime = 0;
  final FocusNode _keyboardFocusNode = FocusNode();

  Timer? _searchTimer;
  Timer? _customerTimer;
  Timer? _doctorTimer;

  Map<String, dynamic> clinicProfile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _customerTimer?.cancel();
    _doctorTimer?.cancel();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString("profileUser");
    if (storedData != null) {
      final profileUser = json.decode(storedData);
      setState(() {
        clinicProfile = profileUser['clinic'] ?? profileUser ?? {};
      });
    }
  }

  // 🚀 JivanToast Wrapper Integration
  void _showToast(String message, {bool isError = false, bool isWarning = false}) {
    // ଧ୍ୟାନ ଦେବେ: ଆପଣଙ୍କର JivanToast କ୍ଲାସ୍ ନିଶ୍ଚିତ ଭାବେ import ହୋଇଥିବା ଦରକାର।
    JivanToast.show(
      context,
      title: isError ? "Error" : (isWarning ? "Warning" : "Success"),
      message: message,
      type: isError ? ToastType.error : (isWarning ? ToastType.warning : ToastType.success),
    );
  }

  // --------------------------------------------------------
  // CUSTOMER LOOKUP API
  // --------------------------------------------------------
  void _onCustomerPhoneChanged(String val) {
    setState(() => customerPhone = val);
    if (_customerTimer?.isActive ?? false) _customerTimer!.cancel();

    _customerTimer = Timer(const Duration(milliseconds: 400), () async {
      if (customerPhone.length == 10) {
        setState(() => isSearchingUser = true);
        try {
          final res = await _apiService.searchDatabaseForBooking(customerPhone);
          final data = res.data is String ? json.decode(res.data) : res.data;

          if (res.statusCode == 200 && data['data'] != null && data['data']['patients'] != null && (data['data']['patients'] as List).isNotEmpty) {
            final patients = data['data']['patients'] as List;
            setState(() {
              patientSuggestions = patients;
              final firstPatient = patients[0];
              customerName = firstPatient['name'] ?? '';
              customerAge = firstPatient['age']?.toString() ?? '';
              customerGender = firstPatient['gender'] ?? 'Male';
              customerId = firstPatient['user_id'];
            });
          } else {
            setState(() { patientSuggestions = []; customerId = null; });
          }
        } catch (err) {
          debugPrint("User lookup failed: $err");
        } finally {
          setState(() => isSearchingUser = false);
        }
      } else {
        setState(() { patientSuggestions = []; customerId = null; });
      }
    });
  }

  void handleSelectPatient(dynamic patient) {
    setState(() {
      customerName = patient['name'] ?? '';
      customerAge = patient['age']?.toString() ?? '';
      customerGender = patient['gender'] ?? 'Male';
      customerId = patient['user_id'];
      patientSuggestions = [];
    });
  }

  // --------------------------------------------------------
  // DOCTOR LOOKUP LOGIC
  // --------------------------------------------------------
  void _onDoctorNameChanged(String val) {
    setState(() { doctorName = val; doctorId = null; });
    if (_doctorTimer?.isActive ?? false) _doctorTimer!.cancel();

    if (val.length >= 2) {
      _doctorTimer = Timer(const Duration(milliseconds: 400), () async {
        try {
          // 🚀 ଏବେ ଏହା ସିଧାସଳଖ List<dynamic> (JSON ଲିଷ୍ଟ୍) ଫେରାଇବ
          final List<dynamic> staffs = await _apiService.searchAdminStaffs(query: val, role: 'doctor');

          if (staffs.isNotEmpty) {
            setState(() {
              // JSON ରୁ ଡାଟା ନେଇ ଆମେ ନିଜର doctorSuggestions ମ୍ୟାପ୍ ତିଆରି କରୁଛୁ
              doctorSuggestions = staffs.map((s) => {
                // ଧ୍ୟାନ ଦେବେ: ଆପଣଙ୍କ backend ରେ id ଯଦି 'id', '_id' କିମ୍ବା 'user_id' ଅଛି ତାହା ଲେଖିବେ
                '_id': s['_id'] ?? s['id'] ?? '', 
                'name': s['name'] ?? 'Unknown Doctor',
                'profile': s['profile'] ?? null,
                'experience': s['experience'] ?? null,
              }).toList();
            });
          } else {
            setState(() => doctorSuggestions = []);
          }
        } catch (err) {
          debugPrint("Doctor search error: $err");
          setState(() => doctorSuggestions = []);
        }
      });
    } else {
      setState(() => doctorSuggestions = []);
    }
  }

  // --------------------------------------------------------
  // HARDWARE SCANNER
  // --------------------------------------------------------
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime - _lastKeyTime > 50) _barcodeBuffer = '';

      if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.length >= 5) {
        handleHardwareScan(_barcodeBuffer);
        _barcodeBuffer = '';
        setState(() => searchTerm = '');
      } else if (event.character != null && event.character!.isNotEmpty) {
        _barcodeBuffer += event.character!;
      }
      _lastKeyTime = currentTime;
    }
  }

  Future<void> handleHardwareScan(String barcode) async {
    try {
      final res = await _apiService.getAllMedicines(search: barcode);
      final data = res.data is String ? json.decode(res.data) : res.data;

      if (data['code'] == 200 && data['data'] != null && (data['data'] as List).isNotEmpty) {
        List products = data['data'];
        if (products.length == 1) {
          if (products[0]['batches'] != null && (products[0]['batches'] as List).isNotEmpty) {
            setState(() => scannedVariants = products);
            _showDisambiguationModal();
          } else {
            handleAddToCart(products[0]);
          }
        } else {
          setState(() => scannedVariants = products);
          _showDisambiguationModal();
        }
      } else {
        _showToast("Item not found for: $barcode", isError: true);
      }
    } catch (err) {
      _showToast("Network error.", isError: true);
    }
  }

  // --------------------------------------------------------
  // TYPE SEARCH API
  // --------------------------------------------------------
  void _onSearchTermChanged(String val) {
    setState(() => searchTerm = val);
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();

    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
      if (searchTerm.length < 2) {
        setState(() => suggestions = []);
        return;
      }
      try {
        final res = await _apiService.getAllMedicines(search: searchTerm);
        final data = res.data is String ? json.decode(res.data) : res.data;
        if (data['code'] == 200 && data['data'] != null) {
          setState(() => suggestions = data['data']);
        }
      } catch (err) {
        debugPrint(err.toString());
      }
    });
  }

  // --------------------------------------------------------
  // CART LOGIC
  // --------------------------------------------------------
  void handleAddToCart(dynamic medicine) {
    final selectedBatch = medicine['selectedBatch'];
    final activeStock = selectedBatch != null ? (selectedBatch['stock'] ?? 0) : (medicine['stock'] ?? 0);
    final activeBatchId = selectedBatch != null ? selectedBatch['_id'] : null;
    final activeBatchNum = selectedBatch != null ? selectedBatch['batchNumber'] : null;
    final activeExpiry = selectedBatch != null ? selectedBatch['expiryDate'] : null;

    if (activeStock <= 0) {
      _showToast("Out of Stock for ${activeBatchNum ?? 'Master'}!", isError: true);
      return;
    }

    setState(() {
      int existingIndex = cart.indexWhere((item) => item['_id'] == medicine['_id'] && item['selectedBatchId'] == activeBatchId);

      if (existingIndex != -1) {
        if (cart[existingIndex]['qty'] + 1 > activeStock) {
          _showToast("Only $activeStock units available.", isWarning: true);
          return;
        }
        cart[existingIndex]['qty'] += 1;
      } else {
        cart.add({
          ...medicine,
          'qty': 1,
          'selectedPriceType': 'MRP',
          'selectedBatchId': activeBatchId,
          'selectedBatchNumber': activeBatchNum,
          'selectedBatchExpiry': activeExpiry,
          'maxAvailableStock': activeStock,
        });
      }
      searchTerm = '';
      suggestions = [];
      scannedVariants = [];
    });
    _showToast("${medicine['name']} added to cart.");
  }

  void updateQuantity(String id, String? batchId, int delta, int stockLimit) {
    setState(() {
      int index = cart.indexWhere((item) => item['_id'] == id && item['selectedBatchId'] == batchId);
      if (index != -1) {
        int newQty = cart[index]['qty'] + delta;
        if (newQty > stockLimit) {
          _showToast("Only $stockLimit units available.", isWarning: true);
        } else if (newQty >= 1) {
          cart[index]['qty'] = newQty;
        }
      }
    });
  }

  void togglePriceType(String id, String? batchId, String type) {
    setState(() {
      int index = cart.indexWhere((item) => item['_id'] == id && item['selectedBatchId'] == batchId);
      if (index != -1) cart[index]['selectedPriceType'] = type;
    });
  }

  void removeFromCart(String id, String? batchId) {
    setState(() { cart.removeWhere((item) => item['_id'] == id && item['selectedBatchId'] == batchId); });
  }

  // --------------------------------------------------------
  // 🚀 CHECKOUT API & JIVAN REDIRECT FLOW
  // --------------------------------------------------------
  Future<void> handleCheckoutAndGenerateBill() async {
    if (cart.isEmpty) return;
    if (customerPhone.isEmpty || customerName.isEmpty) {
      _showToast("Phone number and Name are required.", isError: true);
      return;
    }

    try {
      final payload = {
        'user_id': customerId,
        'items': cart.map((item) {
          double activePrice = item['selectedPriceType'] == 'SELLING_PRICE'
              ? double.parse((item['sellingPrice'] ?? item['price']).toString())
              : double.parse((item['price'] ?? item['mrp'] ?? 0).toString());

          return {
            'medicine_id': item['_id'],
            'batch_id': item['selectedBatchId'],
            'batchNumber': item['selectedBatchNumber'],
            'quantity': item['qty'],
            'name': item['name'],
            'unitPrice': activePrice,
            'taxPercent': double.parse((item['taxPercent'] ?? 0).toString()),
          };
        }).toList(),
        'customer': {
          'phone': customerPhone, 'name': customerName, 'age': customerAge,
          'gender': customerGender, 'doctorName': doctorName, 'doctor_id': doctorId,
        },
      };

      final res = await _apiService.createInvoice(payload);
      final responseData = res.data is String ? json.decode(res.data) : res.data;

      if (res.statusCode != 200 && res.statusCode != 201) throw Exception(responseData['message'] ?? "Billing Failed");

      final apiClinic = responseData['data']?['clinic_id'] ?? {};
      final generatedInvoiceId = responseData['data']?['invoiceNumber'] ?? "INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      dynamic rawPhone = apiClinic['phone'] ?? clinicProfile['phone'] ?? "N/A";
      String extractedPhone = rawPhone is List ? (rawPhone.isNotEmpty ? rawPhone[0] : "N/A") : rawPhone.toString();

      final newInvoice = {
        'invoiceId': generatedInvoiceId,
        'date': DateTime.now().toString(),
        'items': List.from(cart),
        'subTotal': _calcTotals()['subTotal'],
        'totalTax': _calcTotals()['totalTax'],
        'netTotal': _calcTotals()['netTotal'],
        'clinicName': apiClinic['name'] ?? clinicProfile['name'] ?? "Jivan Medical",
        'clinicAddress': apiClinic['address'] ?? clinicProfile['address'] ?? "Odisha",
        'clinicPhone': extractedPhone,
        'customer': payload['customer'],
      };

      // 🚀 ୧. Jivan Custom Toaster
      JivanToast.show(
        context,
        title: "Success",
        message: "Invoice #$generatedInvoiceId created successfully!",
        type: ToastType.success,
      );

      // 🚀 ୨. Smooth Redirect after toast duration
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceScreen(
              invoiceData: newInvoice,
              clinicProfile: clinicProfile,
            ),
          ),
        );
      });

    } catch (error) {
      _showToast(error.toString(), isError: true);
    }
  }

  Map<String, double> _calcTotals() {
    double subTotal = 0, taxIncluded = 0, taxAddedOnTop = 0, netAmount = 0;
    for (var item in cart) {
      double activePrice = item['selectedPriceType'] == 'SELLING_PRICE' ? double.parse((item['sellingPrice'] ?? item['price'] ?? 0).toString()) : double.parse((item['price'] ?? item['mrp'] ?? 0).toString());
      double taxRate = double.tryParse(item['taxPercent']?.toString() ?? '0') ?? 0;
      double totalItemPrice = activePrice * item['qty'];

      if (item['isGstInclusive'] != false) {
        double basePrice = totalItemPrice / (1 + (taxRate / 100));
        subTotal += basePrice; taxIncluded += (totalItemPrice - basePrice); netAmount += totalItemPrice;
      } else {
        double taxAmt = totalItemPrice * (taxRate / 100);
        subTotal += totalItemPrice; taxAddedOnTop += taxAmt; netAmount += (totalItemPrice + taxAmt);
      }
    }
    return { 'subTotal': subTotal, 'totalTax': taxIncluded + taxAddedOnTop, 'netTotal': netAmount };
  }

  // --------------------------------------------------------
  // 🚀 PREMIUM BATCH BUTTON BUILDER (Handles Near Expiry & Low Stock)
  // --------------------------------------------------------
  Widget _buildPremiumBatchButton(dynamic batch, dynamic medicine) {
    bool isLowStock = batch['isLowStock'] == true;
    bool isNearExpiry = batch['isNearExpiry'] == true;

    // Default Premium Blue
    Color bgColor = Colors.blue.shade50;
    Color borderColor = Colors.blue.shade200;
    Color titleColor = Colors.blue.shade800;

    // Danger / Warning Overrides
    if (isLowStock) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      titleColor = Colors.red.shade800;
    } else if (isNearExpiry) {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      titleColor = Colors.orange.shade900;
    }

    return GestureDetector(
      onTap: () { 
        handleAddToCart({...medicine, 'selectedBatch': batch}); 
        FocusScope.of(context).unfocus(); 
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor, 
          border: Border.all(color: borderColor, width: 1.5), 
          borderRadius: BorderRadius.circular(10)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_shopping_cart, size: 16, color: titleColor),
                const SizedBox(width: 6),
                Text(batch['batchNumber'] ?? '', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: titleColor)),
                const SizedBox(width: 4),
                Text("(Qty: ${batch['stock']})", style: TextStyle(fontSize: 11, color: titleColor.withOpacity(0.8), fontWeight: FontWeight.bold)),
              ],
            ),
            if (isLowStock || isNearExpiry)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isNearExpiry) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), 
                        child: Text("Near Expiry", style: TextStyle(fontSize: 9, color: Colors.orange.shade900, fontWeight: FontWeight.w900, letterSpacing: 0.5))
                      ),
                    if (isNearExpiry && isLowStock) const SizedBox(width: 6),
                    if (isLowStock) 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)), 
                        child: Text("Low Stock", style: TextStyle(fontSize: 9, color: Colors.red.shade900, fontWeight: FontWeight.w900, letterSpacing: 0.5))
                      ),
                  ]
                )
              )
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // DISAMBIGUATION MODAL
  // --------------------------------------------------------
  void _showDisambiguationModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Icon(Icons.layers_outlined, color: Colors.blue.shade600, size: 24), const SizedBox(width: 8), const Text("Select Variant", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))]),
                    IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() => scannedVariants = []); Navigator.pop(context); }),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: scannedVariants.length,
                    itemBuilder: (context, idx) {
                      final variant = scannedVariants[idx];
                      final hasBatches = variant['batches'] != null && (variant['batches'] as List).isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.purple.shade100)), child: Icon(Icons.medication, color: Colors.purple.shade400)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(variant['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.purple.shade100)),
                                          child: Text("${variant['variantName'] ?? 'Standard'} • ${variant['packSize'] ?? '1 Unit'}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(variant['manufacturer'] ?? 'Generic', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text("MRP", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      Text("₹${variant['price'] ?? variant['sellingPrice'] ?? '0.00'}", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.green.shade700)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)), border: Border(top: BorderSide(color: Colors.grey.shade200))),
                              child: hasBatches
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Select specific batch:", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 1)),
                                        const SizedBox(height: 12),
                                        Wrap(
                                          spacing: 10, runSpacing: 10,
                                          children: (variant['batches'] as List).map((batch) {
                                            return _buildPremiumBatchButton(batch, variant);
                                          }).toList(),
                                        )
                                      ],
                                    )
                                  : GestureDetector(
                                      onTap: () { handleAddToCart(variant); Navigator.pop(context); },
                                      child: Container(
                                        padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Master Inventory", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)), Text("Loc: ${variant['rack'] ?? 'N/A'}", style: TextStyle(fontSize: 10, color: Colors.grey.shade600))]),
                                            Row(children: [Text("${variant['stock'] ?? 0} Units", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), Icon(Icons.check_circle, size: 16, color: Colors.green.shade600)]),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================
  // MOBILE OPTIMIZED LAYOUT (TOP TO BOTTOM)
  // ========================================================
  @override
  Widget build(BuildContext context) {
    final totals = _calcTotals();

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F4F5), // Premium Zinc 100 Background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          shadowColor: Colors.black12,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
          title: Row(
            children: [
              Icon(Icons.storefront_outlined, color: Colors.blue.shade600, size: 22),
              const SizedBox(width: 8),
              const Text("POS Billing", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        body: Column(
          children: [
            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCustomerSection(),
                    const SizedBox(height: 16),
                    _buildSearchSection(),
                    const SizedBox(height: 16),
                    _buildCartSection(),
                  ],
                ),
              ),
            ),
            // Sticky Bottom Checkout Section
            _buildBottomCheckoutSection(totals),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // 1. CUSTOMER SECTION
  // --------------------------------------------------------
  Widget _buildCustomerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.person_outline, size: 18, color: Colors.blue.shade600), const SizedBox(width: 8), const Text("CUSTOMER DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))]),
          const Divider(height: 24),

          // Phone Field
          TextField(
            onChanged: _onCustomerPhoneChanged, keyboardType: TextInputType.phone, maxLength: 10,
            decoration: _premiumInputDecoration("Mobile Number *").copyWith(counterText: "", suffixIcon: isSearchingUser ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null),
          ),
          
          // Inline Patient Suggestions
          if (patientSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)]),
              child: ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: patientSuggestions.length,
                separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (c, i) {
                  final p = patientSuggestions[i];
                  return ListTile(dense: true, title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text("Age: ${p['age']} | Gen: ${p['gender']}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)), onTap: () { handleSelectPatient(p); FocusScope.of(context).unfocus(); });
                },
              ),
            )
          else const SizedBox(height: 12),

          // Name Field
          TextField(controller: TextEditingController(text: customerName)..selection = TextSelection.collapsed(offset: customerName.length), onChanged: (val) => customerName = val, decoration: _premiumInputDecoration("Patient Name *")),
          const SizedBox(height: 12),

          // Age & Gender
          Row(
            children: [
              Expanded(child: TextField(controller: TextEditingController(text: customerAge)..selection = TextSelection.collapsed(offset: customerAge.length), onChanged: (val) => customerAge = val, keyboardType: TextInputType.number, decoration: _premiumInputDecoration("Age"))),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 48, padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade50, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: customerGender, isExpanded: true, items: ['Male', 'Female'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (val) => setState(() => customerGender = val!),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Doctor Name
          TextField(controller: TextEditingController(text: doctorName)..selection = TextSelection.collapsed(offset: doctorName.length), onChanged: _onDoctorNameChanged, decoration: _premiumInputDecoration("Doctor Name (Optional)")),

          // Inline Doctor Suggestions
          if (doctorSuggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade100), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10)]),
              child: ListView.separated(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: doctorSuggestions.length,
                separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (c, i) {
                  final d = doctorSuggestions[i];
                  final docName = d['name'] ?? 'Unknown Doctor';
                  final profilePic = d['profile'];
                  return ListTile(
                    leading: CircleAvatar(radius: 16, backgroundColor: Colors.blue.shade50, backgroundImage: profilePic != null ? NetworkImage(profilePic) : null, child: profilePic == null ? Icon(Icons.person, size: 16, color: Colors.blue.shade300) : null),
                    title: Text(docName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                    subtitle: Text("${d['experience'] ?? '0'} Yrs Exp", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    onTap: () { setState(() { doctorName = docName; doctorId = d['_id'] ?? d['id']; doctorSuggestions = []; FocusScope.of(context).unfocus(); }); },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // 2. SEARCH MEDICINE SECTION
  // --------------------------------------------------------
  Widget _buildSearchSection() {
    return Column(
      children: [
        TextField(
          onChanged: _onSearchTermChanged,
          decoration: _premiumInputDecoration("Search medicine or scan barcode...").copyWith(prefixIcon: Icon(Icons.search, color: Colors.blue.shade600)),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
            child: ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: suggestions.length,
              separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final med = suggestions[index];
                final hasBatches = med['batches'] != null && (med['batches'] as List).isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(med['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("${med['variantName'] ?? 'Standard'} • Pack: ${med['packSize'] ?? '1 Unit'}", style: TextStyle(fontSize: 12, color: Colors.purple.shade600, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          Text("₹${med['price'] ?? 0}", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade700, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (hasBatches)
                        Wrap(
                          spacing: 10, runSpacing: 10,
                          children: (med['batches'] as List).map((b) {
                            return _buildPremiumBatchButton(b, med);
                          }).toList(),
                        )
                      else
                        GestureDetector(
                          onTap: () { handleAddToCart(med); FocusScope.of(context).unfocus(); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green.shade200), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_shopping_cart, size: 14, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                const Text("Master Inventory", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                                Text(" (Qty: ${med['stock']})", style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --------------------------------------------------------
  // 3. CART SECTION
  // --------------------------------------------------------
  Widget _buildCartSection() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0,4))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [const Icon(Icons.shopping_cart_outlined, size: 18, color: Colors.black87), const SizedBox(width: 8), const Text("CART ITEMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1))]),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(8)), child: Text("${cart.length}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          if (cart.isEmpty)
            Container(
              height: 150, alignment: Alignment.center,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_cart, size: 40, color: Colors.grey.shade300), const SizedBox(height: 12), Text("Cart is empty", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold))]),
            )
          else
            ListView.separated(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: cart.length,
              separatorBuilder: (c, i) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final item = cart[index];
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.blue.shade100)),
                                      child: Text("BTH: ${item['selectedBatchNumber'] ?? 'MASTER'}", style: TextStyle(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 8),
                                    Text("GST: ${item['taxPercent'] ?? 0}%", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 22), color: Colors.red.shade400, onPressed: () => removeFromCart(item['_id'], item['selectedBatchId']), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 40, padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: item['selectedPriceType'], isExpanded: true, icon: const Icon(Icons.arrow_drop_down, size: 18),
                                  style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold),
                                  onChanged: (val) => togglePriceType(item['_id'], item['selectedBatchId'], val!),
                                  items: [
                                    DropdownMenuItem(value: 'MRP', child: Text("MRP: ₹${item['price']}")),
                                    if (item['sellingPrice'] != null) DropdownMenuItem(value: 'SELLING_PRICE', child: Text("SALE: ₹${item['sellingPrice']}")),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 40, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: Colors.grey.shade50),
                            child: Row(
                              children: [
                                IconButton(icon: const Icon(Icons.remove, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36), onPressed: () => updateQuantity(item['_id'], item['selectedBatchId'], -1, item['maxAvailableStock'])),
                                Container(width: 30, alignment: Alignment.center, child: Text("${item['qty']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                                IconButton(icon: const Icon(Icons.add, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36), onPressed: () => updateQuantity(item['_id'], item['selectedBatchId'], 1, item['maxAvailableStock'])),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight, 
                        child: Text("₹${((item['selectedPriceType'] == 'SELLING_PRICE' ? double.parse((item['sellingPrice'] ?? item['price'] ?? 0).toString()) : double.parse((item['price'] ?? 0).toString())) * item['qty']).toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green.shade700))
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // 4. BOTTOM CHECKOUT SECTION (Premium Financial Summary)
  // --------------------------------------------------------
  Widget _buildBottomCheckoutSection(Map<String, double> totals) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), // Bottom padding for safe area
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.receipt_long, size: 16, color: Colors.green.shade600)),
              const SizedBox(width: 10),
              const Text("PRICE DETAILS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildPremiumSummaryRow("Total Items", "${cart.fold<int>(0, (sum, item) => sum + (item['qty'] as int))}"),
          const SizedBox(height: 10),
          _buildPremiumSummaryRow("Subtotal (Net)", "₹${totals['subTotal']!.toStringAsFixed(2)}"),
          const SizedBox(height: 10),
          _buildPremiumSummaryRow("Total GST/Tax", "+ ₹${totals['totalTax']!.toStringAsFixed(2)}", color: Colors.red.shade400),
          
          const SizedBox(height: 16),
          Row(children: List.generate(30, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300, height: 1)))),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.green.shade50, Colors.green.shade50]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("NET PAYABLE", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade900, fontSize: 13, letterSpacing: 0.5)),
                Text("₹${totals['netTotal']!.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade700, fontSize: 22)),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : handleCheckoutAndGenerateBill,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text("CONFIRM & GENERATE BILL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300, disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 18), 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
                elevation: cart.isEmpty ? 0 : 6,
                shadowColor: Colors.blue.withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color ?? Colors.black87, fontSize: 14)),
      ],
    );
  }

  // Common Input Decoration
  InputDecoration _premiumInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, filled: true, fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.blue.shade500, width: 1.5)),
    );
  }
}