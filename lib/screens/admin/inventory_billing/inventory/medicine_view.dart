import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Replace with your actual constants file import
const String BASE_URL = 'https://your-api-url.com/api/';

class MedicineView extends StatefulWidget {
  final String id; // Pass the ID via constructor or route arguments

  const MedicineView({Key? key, required this.id}) : super(key: key);

  @override
  State<MedicineView> createState() => _MedicineViewState();
}

class _MedicineViewState extends State<MedicineView> {
  Map<String, dynamic>? medicine;
  bool loading = true;

  // Legacy Stock Engine
  int currentStock = 0;
  bool isUpdating = false;

  // PREMIUM STATE: Multi-Image & Batches
  int activeImageIndex = 0;
  Map<String, int> batchStocks = {};
  String? updatingBatchId;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  // --------------------------------------------------------
  // Fetch Details API (UNCHANGED INTEGRATION)
  // --------------------------------------------------------
  Future<void> fetchDetails() async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await http.get(
        Uri.parse('${BASE_URL}medicines/${widget.id}'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = json.decode(res.body);

      if (data['code'] == 200 && data['data'] != null) {
        setState(() {
          medicine = data['data'];
          currentStock = (medicine!['stock'] ?? 0) as int;

          // Initialize Local Batch Stocks
          if (medicine!['batches'] is List) {
            for (var b in medicine!['batches']) {
              batchStocks[b['_id']] = (b['stock'] ?? 0) as int;
            }
          }
        });
      } else {
        _showToast("Medicine not found!", isError: true);
        Navigator.pop(context);
      }
    } catch (err) {
      _showToast("Network error while fetching details.", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // --------------------------------------------------------
  // Specific Batch Stock Update API (UNCHANGED INTEGRATION)
  // --------------------------------------------------------
  Future<void> handleBatchStockUpdate(String batchId) async {
    final newStock = batchStocks[batchId] ?? 0;

    // Find original batch stock
    final List batches = medicine!['batches'] ?? [];
    final originalBatch = batches.firstWhere(
      (b) => b['_id'] == batchId,
      orElse: () => null,
    );

    if (originalBatch == null) return;
    if (newStock == originalBatch['stock']) {
      _showToast("No changes to save for this batch.");
      return;
    }

    setState(() => updatingBatchId = batchId);
    _showToast("Committing stock for ${originalBatch['batchNumber']}...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await http.put(
        Uri.parse('${BASE_URL}medicines/batch-stock/${widget.id}/$batchId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'newStock': newStock}),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showToast("Batch updated successfully!");
        setState(() {
          medicine!['stock'] =
              data['data']?['newTotalStock'] ?? medicine!['stock'];
          // Update the local medicine state batch list
          for (var i = 0; i < batches.length; i++) {
            if (batches[i]['_id'] == batchId) {
              batches[i]['stock'] = newStock;
            }
          }
        });
      } else {
        _showToast(data['message'] ?? "Failed to update batch", isError: true);
        setState(() => batchStocks[batchId] = originalBatch['stock']);
      }
    } catch (err) {
      _showToast("Server error during batch update.", isError: true);
      setState(() => batchStocks[batchId] = originalBatch['stock']);
    } finally {
      setState(() => updatingBatchId = null);
    }
  }

  void adjustBatchStock(String batchId, int delta) {
    setState(() {
      int current = batchStocks[batchId] ?? 0;
      batchStocks[batchId] = max(0, current + delta);
    });
  }

  // --------------------------------------------------------
  // Legacy Update Stock API (UNCHANGED INTEGRATION)
  // --------------------------------------------------------
  Future<void> handleStockUpdate() async {
    if (currentStock == medicine!['stock']) {
      _showToast("No changes made to stock.");
      return;
    }

    setState(() => isUpdating = true);
    _showToast("Updating inventory stock...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final res = await http.put(
        Uri.parse('${BASE_URL}medicines/update/${widget.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'stock': currentStock}),
      );

      final data = json.decode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showToast(data['message'] ?? "Stock updated successfully!");
        setState(() => medicine = data['data']);
      } else {
        _showToast(data['message'] ?? "Failed to update stock", isError: true);
        setState(() => currentStock = medicine!['stock']);
      }
    } catch (err) {
      _showToast("Server error during update.", isError: true);
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void adjustStock(int delta) {
    setState(() => currentStock = max(0, currentStock + delta));
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      ),
    );
  }

  List<dynamic> get parsedSalts {
    if (medicine?['salts'] == null) return [];
    try {
      if (medicine!['salts'] is String) {
        return json.decode(medicine!['salts']);
      }
      return medicine!['salts'];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue.shade600),
              const SizedBox(height: 16),
              Text(
                "DECRYPTING CORE DATA...",
                style: TextStyle(
                  color: Colors.blue.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (medicine == null) return const Scaffold(body: SizedBox.shrink());

    final num costPriceNum = medicine!['purchasePrice'] ?? 0;
    final num sellPriceNum =
        medicine!['sellingPrice'] ?? medicine!['price'] ?? 0;
    final double costPrice = costPriceNum.toDouble();
    final double sellPrice = sellPriceNum.toDouble();
    final double marginAmt = sellPrice - costPrice;
    final double marginPct = costPrice > 0
        ? ((marginAmt / costPrice) * 100)
        : 0;

    final analytics = medicine!['analytics'] ?? {};
    final lifetime =
        analytics['lifetimeVelocity'] ?? {'units': 0, 'revenue': 0};
    final patientsInfo =
        analytics['uniquePatients'] ?? {'total': 0, 'retentionRate': "0%"};
    final prescriber =
        analytics['topPrescriber'] ?? {'name': "N/A", 'referredSalesVolume': 0};
    final List transactions = medicine!['recentTransactions'] ?? [];

    List imagesList = [];
    if (medicine!['images'] != null &&
        (medicine!['images'] as List).isNotEmpty) {
      imagesList = medicine!['images'];
    } else if (medicine!['image'] != null) {
      imagesList = [medicine!['image']];
    }

    final bool hasBatches =
        medicine!['batches'] != null &&
        (medicine!['batches'] as List).isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ROW 1: MASTER LAYOUT
            // We use a responsive-friendly layout (Column for mobile view)
            _buildIdentityAndCommercials(
              costPrice,
              sellPrice,
              marginAmt,
              marginPct,
            ),
            const SizedBox(height: 16),
            _buildLocatorAndClinical(),
            const SizedBox(height: 16),

            // Image Gallery & Legacy Stock
            _buildImageGallery(imagesList),
            const SizedBox(height: 16),
            if (!hasBatches) _buildLegacyStockManager(),
            if (!hasBatches) const SizedBox(height: 16),

            // PREMIUM BATCH ENGINE
            if (hasBatches) _buildBatchEngine(),
            if (hasBatches) const SizedBox(height: 16),

            // ROW 2: ADVANCED ANALYTICS HUD
            _buildAnalyticsHUD(lifetime, patientsInfo, prescriber),
            const SizedBox(height: 16),

            // ROW 3: PATIENT / BILLING TRANSACTION LEDGER
            _buildTransactions(transactions),
            const SizedBox(height: 24),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CREATED: ${medicine!['createdAt']?.toString().split('T')[0] ?? '--'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'UPDATED: ${medicine!['updatedAt']?.toString().split('T')[0] ?? '--'}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine!['name'] ?? 'Details',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (medicine!['isRxRequired'] == true) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 10,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rx',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Text(
            '#${medicine!['barcode'] ?? '--'} | ${medicine!['category'] ?? 'Medicine'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/inventory/edit/${medicine!['_id']}',
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIdentityAndCommercials(
    double cost,
    double sell,
    double marginAmt,
    double marginPct,
  ) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: Colors.blue.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                "IDENTITY & COMMERCIALS",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TRADE NAME",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      medicine!['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "MANUFACTURER",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.factory_outlined,
                          size: 12,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            medicine!['brand'] ??
                                medicine!['manufacturer'] ??
                                "Generic Mfr",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "PURCHASE (COST)",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      "₹${cost.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SELLING PRICE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Text(
                      "₹${sell.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "PROFITABILITY MATRIX",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: marginPct > 20
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  border: Border.all(
                    color: marginPct > 20
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${marginPct.toStringAsFixed(1)}% Margin",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: marginPct > 20
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "+₹${marginAmt.toStringAsFixed(2)} / unit",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocatorAndClinical() {
    return Column(
      children: [
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.indigo.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "PHYSICAL LOCATOR",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLocatorRow("Zone / Rack", medicine!['rack'] ?? '--'),
              const SizedBox(height: 8),
              _buildLocatorRow(
                "Shelf / Drawer",
                "${medicine!['shelf'] ?? '--'} / ${medicine!['drawer'] ?? '--'}",
              ),
              const SizedBox(height: 8),
              _buildLocatorRow(
                "Condition",
                medicine!['storageCondition'] ?? 'Room Temp',
                valueColor: Colors.blue.shade600,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    size: 16,
                    color: Colors.purple.shade400,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "FORMULATION (SALTS)",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (parsedSalts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "NO FORMULATION DATA",
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                ...parsedSalts
                    .map(
                      (salt) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    salt['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (salt['excipients'] != null)
                                    Text(
                                      salt['excipients'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                border: Border.all(
                                  color: Colors.purple.shade100,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                salt['strength'] ?? '',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.purple.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocatorRow(String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List imagesList) {
    return _buildCard(
      child: Column(
        children: [
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: imagesList.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imagesList[activeImageIndex],
                      fit: BoxFit.contain,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "NO IMAGE ASSET",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
          ),
          if (imagesList.length > 1) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: imagesList.length,
                itemBuilder: (context, index) {
                  final isActive = activeImageIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => activeImageIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? Colors.blue.shade500
                              : Colors.grey.shade300,
                          width: isActive ? 2 : 1,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          imagesList[index],
                          fit: BoxFit.cover,
                          color: isActive
                              ? null
                              : Colors.white.withOpacity(0.5),
                          colorBlendMode: BlendMode.lighten,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegacyStockManager() {
    bool hasOffset = currentStock != medicine!['stock'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MASTER INVENTORY ENGINE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                  letterSpacing: 1,
                ),
              ),
              Row(
                children: [
                  Icon(
                    medicine!['isActive'] == true
                        ? Icons.check_circle
                        : Icons.error_outline,
                    size: 14,
                    color: medicine!['isActive'] == true
                        ? Colors.green.shade600
                        : Colors.red.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    medicine!['isActive'] == true ? "Active" : "Suspended",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: medicine!['isActive'] == true
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => adjustStock(-1),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Text(
                  "$currentStock",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  onPressed: () => adjustStock(1),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "System Value: ${medicine!['stock']}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasOffset)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Unsaved Offset",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (!isUpdating && hasOffset) ? handleStockUpdate : null,
              icon: const Icon(Icons.save, size: 18),
              label: Text(
                isUpdating ? "COMMITTING..." : "COMMIT MASTER OFFSET",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchEngine() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
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
                    Icons.layers_outlined,
                    size: 18,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "GLOBAL BATCH ENGINE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      "MASTER QTY ",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${medicine!['stock']}",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...((medicine!['batches'] as List).map((batch) {
            final currentBStock = batchStocks[batch['_id']] ?? batch['stock'];
            final hasOffset = currentBStock != batch['stock'];

            Color borderColor = Colors.grey.shade300;
            if (hasOffset)
              borderColor = Colors.blue.shade400;
            else if (batch['isLowStock'] == true &&
                batch['isNearExpiry'] == true)
              borderColor = Colors.red.shade300;
            else if (batch['isLowStock'] == true)
              borderColor = Colors.red.shade200;
            else if (batch['isNearExpiry'] == true)
              borderColor = Colors.orange.shade300;

            Color batchNumColor = batch['isLowStock'] == true
                ? Colors.red.shade600
                : (batch['isNearExpiry'] == true
                      ? Colors.orange.shade600
                      : Colors.blue.shade700);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: hasOffset ? 2 : 1,
                ),
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
                              Text(
                                batch['batchNumber'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: batchNumColor,
                                ),
                              ),
                              if (batch['isLowStock'] == true) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.trending_down,
                                  size: 14,
                                  color: Colors.red.shade600,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Mfg: ${batch['formattedMfgDate'] ?? (batch['mfgDate']?.toString().split('T')[0] ?? 'N/A')}",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: batch['isNearExpiry'] == true
                                    ? Colors.orange.shade600
                                    : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Exp: ${batch['formattedExpiryDate'] ?? (batch['expiryDate']?.toString().split('T')[0] ?? 'N/A')}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: batch['isNearExpiry'] == true
                                      ? Colors.orange.shade600
                                      : Colors.grey.shade600,
                                ),
                              ),
                              if (batch['isNearExpiry'] == true) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: Colors.orange.shade600,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      if (hasOffset)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            "UNSAVED",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => adjustBatchStock(batch['_id'], -1),
                          icon: const Icon(Icons.remove, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "$currentBStock",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          onPressed: () => adjustBatchStock(batch['_id'], 1),
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.green.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (updatingBatchId == batch['_id'] || !hasOffset)
                          ? null
                          : () => handleBatchStockUpdate(batch['_id']),
                      icon: const Icon(Icons.save, size: 14),
                      label: Text(
                        updatingBatchId == batch['_id']
                            ? "COMMITTING..."
                            : "COMMIT BATCH OFFSET",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  Widget _buildAnalyticsHUD(Map lifetime, Map patientsInfo, Map prescriber) {
    return Column(
      children: [
        _buildStatCard(
          title: "LIFETIME VELOCITY",
          icon: Icons.trending_up,
          iconColor: Colors.green,
          mainValue: "${lifetime['units']} Units",
          subLabel: "Total Revenue Generated",
          subValue: "₹${(lifetime['revenue'] ?? 0).toStringAsFixed(2)}",
          subValueColor: Colors.green.shade700,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          title: "UNIQUE PATIENTS",
          icon: Icons.people_outline,
          iconColor: Colors.blue,
          mainValue: "${patientsInfo['total']}",
          subLabel: "Retention Rate",
          subValue: "${patientsInfo['retentionRate']}",
          subValueColor: Colors.green.shade700,
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          title: "TOP PRESCRIBER",
          icon: Icons.medical_services_outlined,
          iconColor: Colors.purple,
          mainValue: "${prescriber['name']}",
          subLabel: "Referred Sales Volume",
          subValue: "${prescriber['referredSalesVolume']} Units",
          subValueColor: Colors.purple.shade600,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String mainValue,
    required String subLabel,
    required String subValue,
    required Color subValueColor,
  }) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mainValue,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: subValueColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(List transactions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "RECENT TRANSACTIONS",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "REAL-TIME",
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt, size: 32, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      "No recent transactions found.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...transactions
                .map(
                  (tx) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['patientName'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    tx['invoiceId'] ?? '--',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${(tx['revenue'] ?? 0).toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                Text(
                                  "Qty: ${tx['qtyBought']}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medical_services_outlined,
                                  size: 12,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  tx['prescriber'] ?? 'Self (OTC)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              tx['date']?.toString().split('T')[0] ?? '--',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
        ],
      ),
    );
  }
}
