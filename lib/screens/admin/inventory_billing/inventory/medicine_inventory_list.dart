import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/screens/admin/inventory_billing/inventory/premium_barcode_scanner.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MedicineInventoryList extends StatefulWidget {
  const MedicineInventoryList({Key? key}) : super(key: key);

  @override
  State<MedicineInventoryList> createState() => _MedicineInventoryListState();
}

class _MedicineInventoryListState extends State<MedicineInventoryList> {
  final ApiService _apiService = ApiService();

  List<dynamic> medicines = [];
  bool loading = true;
  String searchTerm = '';
  String filter = 'all'; // all | low-stock | expiring
  String viewMode = 'card'; // card | table

  @override
  void initState() {
    super.initState();
    fetchMedicines();
  }

  // --------------------------------------------------------
  // ୧. Fetch All Medicines (USING MEDICINE SERVICE)
  // --------------------------------------------------------
  Future<void> fetchMedicines() async {
    setState(() => loading = true);
    try {
      final res = await _apiService.getAllMedicines();

      // Dio ଆପେ ଆପେ JSON କୁ decode କରିଦିଏ, ତେଣୁ json.decode ଦରକାର ନାହିଁ
      final data = res.data; 

      if (data['code'] == 200) {
        setState(() {
          medicines = (data['data'] as List)
              .where((m) => m['isActive'] != false)
              .toList();
        });
      }
    } catch (err) {
      _showToast("Failed to load inventory data", isError: true);
    } finally {
      setState(() => loading = false);
    }
  }

  // --------------------------------------------------------
  // ୨. Soft Delete Logic (USING MEDICINE SERVICE)
  // --------------------------------------------------------
  Future<void> handleDelete(String id, String name) async {
    _showToast("Removing $name...");
    try {
      // ଆମେ updateMedicine ରେ isActive: false ପଠାଉଛୁ (ଯେମିତି ଆପଣଙ୍କ ପୁରୁଣା ଲଜିକ୍ ଥିଲା)
      final res = await _apiService.updateMedicine(
        id: id,
        data: {'isActive': false},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _showToast("$name removed from active inventory");
        setState(() {
          medicines.removeWhere((m) => m['_id'] == id);
        });
      } else {
        _showToast("Failed to delete", isError: true);
      }
    } catch (err) {
      _showToast("Network error", isError: true);
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
  // 🚀 SMART SEARCH & FILTER LOGIC
  // --------------------------------------------------------
  List<dynamic> get filteredMedicines {
    final searchLower = searchTerm.toLowerCase();

    return medicines.where((m) {
      final nameMatches = (m['name'] ?? '').toLowerCase().contains(searchLower);
      final barcodeMatches =
          m['barcode'] != null && m['barcode'].toString().contains(searchTerm);

      bool batchMatches = false;
      if (m['batches'] != null) {
        batchMatches = (m['batches'] as List).any(
          (b) => (b['batchNumber'] ?? '').toLowerCase().contains(searchLower),
        );
      }

      final matchesSearch = nameMatches || barcodeMatches || batchMatches;

      bool matchesFilter = true;
      final stock = (m['stock'] ?? 0) as num;
      final minStock = (m['minStockAlert'] ?? 10) as num;

      if (filter == 'low-stock') {
        bool hasLowStockBatch = false;
        if (m['batches'] != null) {
          hasLowStockBatch = (m['batches'] as List).any(
            (b) => b['isLowStock'] == true,
          );
        }
        matchesFilter = (stock <= minStock) || hasLowStockBatch;
      } else if (filter == 'expiring') {
        if (m['batches'] != null) {
          matchesFilter = (m['batches'] as List).any(
            (b) => b['isNearExpiry'] == true,
          );
        } else {
          matchesFilter = false;
        }
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  void handleRowClick(String id) {
    Navigator.pushNamed(context, '/inventory/view/$id');
  }

  @override
  Widget build(BuildContext context) {
    // WHITE THEME ADAPTATION
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Back Arrow
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.blue.shade600,
                      size: 24, // ଟିକେ ଛୋଟ କରାଯାଇଛି ମୋବାଇଲ୍ ପାଇଁ
                    ),
                    const SizedBox(width: 8),
                    // 🚀 ଫିକ୍ସ: Expanded ଲଗାଇବା ଦ୍ୱାରା Yellow Line ଆସିବ ନାହିଁ
                    const Expanded(
                      child: Text(
                        'Inventory Matrix',
                        style: TextStyle(
                          fontSize: 20, // ଟିକେ ଛୋଟ କରାଯାଇଛି
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0),
                  child: Text(
                    'Manage Variants, Batches, Pricing & Global Stock.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PremiumBarcodeScanner(),
                ),
              );
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Stock', style: TextStyle(fontSize: 13)), // ଟେକ୍ସଟ୍ ଛୋଟ କରାଯାଇଛି
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (val) => setState(() => searchTerm = val),
            decoration: InputDecoration(
              hintText: "Query by nomenclature, SKU, or Batch ID...",
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade400),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filters & View Toggles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'all',
                        'Global',
                        Colors.grey.shade800,
                        Colors.grey.shade200,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'low-stock',
                        'Low Stock',
                        Colors.red.shade600,
                        Colors.red.shade50,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'expiring',
                        'Near Expiry',
                        Colors.orange.shade700,
                        Colors.orange.shade50,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      color: viewMode == 'card'
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
                      onPressed: () => setState(() => viewMode = 'card'),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.format_list_bulleted_rounded,
                        size: 18,
                      ),
                      color: viewMode == 'table'
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
                      onPressed: () => setState(() => viewMode = 'table'),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String filterValue,
    String label,
    Color activeColor,
    Color activeBg,
  ) {
    bool isActive = filter == filterValue;
    return InkWell(
      onTap: () => setState(() => filter = filterValue),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: isActive ? activeColor : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade600),
            const SizedBox(height: 16),
            Text(
              "SYNCING MATRIX...",
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    final items = filteredMedicines;

    if (items.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade300,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                "NO RECORDS FOUND",
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Text(
                "Adjust your search or filters to see more results.",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (viewMode == 'card') {
      // 🚀 ଫିକ୍ସ: GridView ବଦଳରେ ListView, ଯାହା Vertical Scroll ଦେବ (ଗୋଟିକ ତଳେ ଗୋଟିଏ)
      return ListView.separated(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80, top: 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildCard(items[index]),
      );
    } else {
      return _buildTable(items);
    }
  }

  // =========================================
  // 🎴 GRID / CARD VIEW (WHITE THEME)
  // =========================================
  Widget _buildCard(dynamic med) {
    final num stock = med['stock'] ?? 0;
    final num minStock = med['minStockAlert'] ?? 10;
    final bool isLowStock = stock <= minStock;
    final bool hasExpiring =
        (med['batches'] != null) &&
        (med['batches'] as List).any((b) => b['isNearExpiry'] == true);

    return GestureDetector(
      onTap: () => handleRowClick(med['_id']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min, // 🚀 ଫିକ୍ସ: ListView ରେ କାର୍ଡ ର Size ଠିକ୍ ରଖିବା ପାଇଁ
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Stack
            SizedBox(
              height: 140, // ଇମେଜ୍ ପାଇଁ ଫିକ୍ସଡ୍ ଉଚ୍ଚତା
              child: Stack(
                fit: StackFit.expand,
                children: [
                  med['image'] != null
                      ? Image.network(med['image'], fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.storefront,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                        ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if ((med['price'] ?? 0) > (med['sellingPrice'] ?? 0))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MRP ₹${med['price']}',
                              style: const TextStyle(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            '₹${med['sellingPrice'] ?? 0}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLowStock)
                          _buildMiniBadge(
                            'LOW STOCK',
                            Colors.red,
                            Icons.trending_down,
                          ),
                        if (hasExpiring)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildMiniBadge(
                              'NEAR EXPIRY',
                              Colors.orange,
                              Icons.warning_amber,
                            ),
                          ),
                        if (med['isRxRequired'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: _buildMiniBadge(
                              'Rx',
                              Colors.purple,
                              Icons.health_and_safety,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med['name'] ?? 'Unknown',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (med['packSize'] != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            med['packSize'],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          med['brand'] ?? med['manufacturer'] ?? 'Generic',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Batches List
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(8),
                    // 🚀 ଫିକ୍ସ: ListView.builder ବଦଳରେ Column, ଯାହା Scroll Error ସୃଷ୍ଟି କରିବ ନାହିଁ
                    child: med['batches'] != null && (med['batches'] as List).isNotEmpty
                        ? Column(
                            children: (med['batches'] as List).map<Widget>((batch) {
                              final bLow = batch['isLowStock'] == true;
                              final bExp = batch['isNearExpiry'] == true;
                              Color bColor = bLow
                                  ? Colors.red
                                  : (bExp ? Colors.orange : Colors.blue.shade600);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: bColor.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          batch['batchNumber'] ?? 'N/A',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: bColor,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${batch['stock']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: bLow ? Colors.red : Colors.green.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Exp: ${batch['formattedExpiryDate'] ?? (batch['expiryDate']?.toString().split('T')[0] ?? '--')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: bExp ? Colors.orange.shade700 : Colors.grey.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Mfg: ${batch['formattedMfgDate'] ?? (batch['mfgDate']?.toString().split('T')[0] ?? '--')}',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No Batches Configured',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Footer: Progress Bar & Actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Inv',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isLowStock ? Colors.red : Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '$stock Units',
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: (stock / (minStock * 5)).clamp(0.0, 1.0).toDouble(),
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isLowStock ? Colors.red : Colors.green,
                              ),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: Colors.grey.shade700,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey.shade100,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/inventory/edit/${med['_id']}',
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red.shade500,
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                            ),
                            onPressed: () => handleDelete(med['_id'], med['name']),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // 📊 LEDGER / TABLE VIEW (WHITE THEME)
  // =========================================
  Widget _buildTable(List<dynamic> items) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          dividerThickness: 1,
          dataRowMaxHeight: 80,
          dataRowMinHeight: 60,
          columnSpacing: 24,
          columns: const [
            DataColumn(
              label: Text(
                'Img',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'SKU / Designation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Variant Batches',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Economics (₹)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Total Stock',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            DataColumn(
              label: Text(
                'Protocol',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
          rows: items.map((med) {
            final num stock = med['stock'] ?? 0;
            final num minStock = med['minStockAlert'] ?? 10;
            final isLowStock = stock <= minStock;

            return DataRow(
              onSelectChanged: (_) => handleRowClick(med['_id']),
              cells: [
                // 1. Img
                DataCell(
                  med['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            med['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            Icons.medication,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                        ),
                ),
                // 2. Name & SKU
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            med['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          if (med['isRxRequired'] == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Rx',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${med['barcode'] ?? 'N/A'} • ${med['brand'] ?? 'Generic'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. Batches
                DataCell(
                  SizedBox(
                    width: 200,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            (med['batches'] as List?)?.map<Widget>((b) {
                              final bLow = b['isLowStock'] == true;
                              final bExp = b['isNearExpiry'] == true;
                              Color txtColor = bLow
                                  ? Colors.red
                                  : (bExp
                                        ? Colors.orange
                                        : Colors.blue.shade700);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  '${b['batchNumber']} (${b['stock']}) - Exp: ${b['formattedExpiryDate'] ?? (b['expiryDate']?.toString().split('T')[0] ?? '--')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: txtColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList() ??
                            [
                              Text(
                                'No batches',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                      ),
                    ),
                  ),
                ),
                // 4. Economics
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Buy: ₹${med['purchasePrice'] ?? 0}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        'Sell: ₹${med['sellingPrice'] ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if ((med['price'] ?? 0) > (med['sellingPrice'] ?? 0))
                        Text(
                          'MRP: ₹${med['price']}',
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
                // 5. Total Stock
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isLowStock
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLowStock
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                      ),
                    ),
                    child: Text(
                      '$stock Units',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLowStock
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
                // 6. Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        color: Colors.blue.shade600,
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/inventory/edit/${med['_id']}',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: Colors.red.shade600,
                        onPressed: () => handleDelete(med['_id'], med['name']),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
