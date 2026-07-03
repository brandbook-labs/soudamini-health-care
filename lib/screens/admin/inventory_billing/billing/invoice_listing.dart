import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_new_app/screens/admin/inventory_billing/billing/pos_billing_counter.dart';
import 'package:my_new_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🚀 ନୂଆ InvoiceScreen କୁ ଏଠାରେ ଇମ୍ପୋର୍ଟ କରନ୍ତୁ (ଆପଣଙ୍କର ଫାଇଲ୍ ପାଥ୍ ଅନୁଯାୟୀ ବଦଳାଇବେ)
import 'package:my_new_app/screens/admin/inventory_billing/billing/invoice_screen.dart'; 

class InvoiceListing extends StatefulWidget {
  const InvoiceListing({Key? key}) : super(key: key);

  @override
  State<InvoiceListing> createState() => _InvoiceListingState();
}

class _InvoiceListingState extends State<InvoiceListing> {
  final ApiService _apiService = ApiService();

  List<dynamic> invoices = [];
  bool loading = true;
  String searchTerm = '';

  Map<String, dynamic> clinicProfile = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
    fetchInvoices();
  }

  // 🚀 LocalStorage Profile Data for Clinic Details Fallback
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final storedData = prefs.getString("profileUser");
    if (storedData != null) {
      try {
        final profileUser = json.decode(storedData);
        setState(() {
          clinicProfile = profileUser['clinic'] ?? profileUser ?? {};
        });
      } catch (e) {
        debugPrint("Error parsing profile data");
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --------------------------------------------------------
  // FETCH INVOICES LOGIC (Unchanged Integration)
  // --------------------------------------------------------
  Future<void> fetchInvoices() async {
    setState(() => loading = true);
    try {
      final res = await _apiService.getAllInvoices(tokenKey: 'admin_token');
      final data = res.data is String ? json.decode(res.data) : res.data;

      if (res.statusCode == 200 && data['code'] == 200 && data['data'] != null) {
        setState(() {
          invoices = data['data'];
        });
      } else {
        _showToast(data['message'] ?? "No bills found yet.");
        setState(() {
          invoices = [];
        });
      }
    } catch (err) {
      debugPrint("Error fetching invoices: $err");
      _showToast("Failed to connect to the database.", isError: true);
      setState(() {
        invoices = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  // Metrics Logic
  double get totalRevenue {
    return invoices.fold(0.0, (sum, inv) {
      final summary = inv['summary'] ?? {};
      final netAmount = summary['netAmount'] ?? inv['total'] ?? 0;
      return sum + (netAmount is num ? netAmount.toDouble() : 0.0);
    });
  }

  int get totalBills => invoices.length;

  // Local Search Filter
  List<dynamic> get filteredInvoices {
    final term = searchTerm.toLowerCase();
    return invoices.where((inv) {
      final invoiceNum = inv['invoiceNumber']?.toString().toLowerCase() ?? '';
      final invoiceId = inv['invoiceId']?.toString().toLowerCase() ?? '';
      final customer = inv['customer'] ?? {};
      final custName = customer['name']?.toString().toLowerCase() ?? '';
      final custPhone = customer['phone']?.toString().toLowerCase() ?? '';

      return invoiceNum.contains(term) ||
          invoiceId.contains(term) ||
          custName.contains(term) ||
          custPhone.contains(term);
    }).toList();
  }

  // 🚀 Navigation directly to the actual Invoice Screen
  void handleOpenInvoice(dynamic invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(
          invoiceData: invoice,
          clinicProfile: clinicProfile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Premium light background
      // 🚀 FLAGSHIP FEATURE: Floating Action Button at Bottom Right
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const POSBillingCounter(),
            ),
          ).then((_) => fetchInvoices()); // Refreshing list after returning
        },
        backgroundColor: Colors.blue.shade700,
        elevation: 6,
        icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
        label: const Text(
          "New Bill",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
      ),
      // 🚀 SafeArea ବ୍ୟବହାର କରାଯାଇଛି କାରଣ AppBar କାଟି ଦିଆଯାଇଛି
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMetricsAndSearchRow(),
                    const SizedBox(height: 24),
                    // Header for List (Without Back Arrow & Billing History)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.history, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Recent Transactions",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildInvoicesList(), // 🚀 Premium Cards List
                    const SizedBox(height: 80), // Padding for FAB
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsAndSearchRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;

        Widget metrics = Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Revenue",
                value: "₹${totalRevenue.toStringAsFixed(2)}",
                icon: Icons.account_balance_wallet,
                iconColor: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                title: "Total Invoices",
                value: "$totalBills",
                icon: Icons.assignment_turned_in,
                iconColor: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
            ),
          ],
        );

        Widget searchBar = Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: TextField(
            onChanged: (val) => setState(() => searchTerm = val),
            decoration: InputDecoration(
              hintText: "Search by Bill No, Name, or Phone...",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.blue.shade500),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
              ),
            ),
          ),
        );

        if (isDesktop) {
          return Row(
            children: [
              Expanded(flex: 3, child: metrics),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: searchBar),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [metrics, const SizedBox(height: 20), searchBar],
          );
        }
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 FLAGSHIP FEATURE: Premium Clickable Cards
  Widget _buildInvoicesList() {
    if (loading) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue.shade600),
              const SizedBox(height: 16),
              Text(
                "LOADING RECORDS...",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredInvoices.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                child: Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              const Text(
                "No Bills Found",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                "Try searching with a different name or number.",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredInvoices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final inv = filteredInvoices[index];
        final customer = inv['customer'] ?? {};
        final summary = inv['summary'] ?? {};
        final items = inv['items'] ?? [];

        final dateStr = inv['date'] ?? (inv['createdAt'] != null ? inv['createdAt'].toString().split('T')[0] : '--');
        final billNumber = inv['invoiceNumber'] ?? '--';
        final customerName = customer['name'] ?? "Walk-in Customer";
        final customerPhone = customer['phone'] ?? "N/A";
        final totalItems = summary['totalItems'] ?? items.length;
        final totalAmount = summary['netAmount'] ?? inv['total'] ?? 0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => handleOpenInvoice(inv), // 🚀 Click anywhere on the card to open invoice
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // TOP ROW: Invoice Number & Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "#$billNumber",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_month, size: 14, color: Colors.grey.shade400),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // MIDDLE ROW: Customer Info & Amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              customerName.toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName.toString().toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    customerPhone,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${(totalAmount is num ? totalAmount : 0).toStringAsFixed(2)}",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.green.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$totalItems Items",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 16),

                    // 🚀 BOTTOM ROW: Status & ONLY VIEW Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                            const SizedBox(width: 6),
                            const Text("PAID", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green, letterSpacing: 0.5)),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => handleOpenInvoice(inv),
                          icon: Icon(Icons.visibility, size: 16, color: Colors.blue.shade600),
                          label: Text("VIEW", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}