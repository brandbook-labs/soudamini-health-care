import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/patients/labs/package_details_screen.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255); // Blue-600
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kOrangeColor = Color(0xFFEA580C);
const Color kSlate50 = Color(0xFFF8FAFC); // Re-added this missing definition

// --- UTILS ---
final currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

// --- MOCK DATA (Renamed to lowerCamelCase) ---
final List<Map<String, dynamic>> packages = [
  {
    'id': 'pkg1',
    'name': "Comprehensive Full Body Checkup",
    'includes': "87 Tests",
    'type': "Package",
    'fasting': "Required (10-12 hrs)",
    'reportTime': "24 Hrs",
    'price': 1499,
    'mrp': 4500,
    'discount': 66,
    'tags': ["bestseller", "popular"],
    'features': [
      "Liver Profile",
      "Kidney Profile",
      "Thyroid",
      "Vitamin D & B12",
    ],
  },
  {
    'id': 'pkg2',
    'name': "Basic Health Checkup",
    'includes': "56 Tests",
    'type': "Package",
    'fasting': "Required (8 hrs)",
    'reportTime': "12 Hrs",
    'price': 899,
    'mrp': 2200,
    'discount': 59,
    'tags': [],
    'features': ["CBC", "Diabetes Screen", "Cholesterol"],
  },
];

final List<Map<String, dynamic>> individualTests = [
  {
    'id': 't1',
    'name': "HbA1c (Glycosylated Hemoglobin)",
    'type': "Test",
    'fasting': "Not Required",
    'reportTime': "6 Hrs",
    'price': 350,
    'mrp': 600,
    'discount': 41,
    'tags': ["diabetes"],
  },
  {
    'id': 't2',
    'name': "Thyroid Profile Total (T3, T4, TSH)",
    'type': "Test",
    'fasting': "Not Required",
    'reportTime': "12 Hrs",
    'price': 450,
    'mrp': 900,
    'discount': 50,
    'tags': ["thyroid"],
  },
];

// --- MAIN SCREEN ---
class LabListingScreen extends StatefulWidget {
  const LabListingScreen({super.key});

  @override
  State<LabListingScreen> createState() => _LabListingScreenState();
}

class _LabListingScreenState extends State<LabListingScreen> {
  final Set<String> _cartIds = {};

  void _toggleItem(String id) {
    setState(() {
      if (_cartIds.contains(id)) {
        _cartIds.remove(id);
      } else {
        _cartIds.add(id);
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (var id in _cartIds) {
      var pkg = packages.firstWhere((p) => p['id'] == id, orElse: () => {});
      if (pkg.isNotEmpty) total += (pkg['price'] as int);

      var test = individualTests.firstWhere(
        (t) => t['id'] == id,
        orElse: () => {},
      );
      if (test.isNotEmpty) total += (test['price'] as int);
    }
    return total;
  }

  void _showPrescriptionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrescriptionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect Theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. APP BAR & SEARCH
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                backgroundColor: cardColor,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(LucideIcons.arrowLeft, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  "Lab Tests",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TextField(
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Search tests (e.g. CBC, Thyroid)...",
                          hintStyle: TextStyle(
                            color: subTextColor,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            color: subTextColor,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. UPLOAD PRESCRIPTION BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          kPrimaryColor,
                          kPrimaryColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.fileText,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Have a prescription?",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "Upload now & get a call back",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showPrescriptionModal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text("Upload"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. CATEGORY PILLS
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children:
                        [
                              "Full Body Checkup",
                              "Diabetes",
                              "Thyroid",
                              "Fever",
                              "Heart",
                              "Covid-19",
                            ]
                            .map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),

              // 4. PACKAGES SECTION
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader("Popular Packages", textColor),
                    const SizedBox(height: 12),
                  ]),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final pkg = packages[index];
                    return PackageCard(
                      item: pkg,
                      isAdded: _cartIds.contains(pkg['id']),
                      onToggle: () => _toggleItem(pkg['id']),
                      isDarkMode: isDarkMode,
                    );
                  }, childCount: packages.length),
                ),
              ),

              // 5. INDIVIDUAL TESTS SECTION
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 24),
                    _buildSectionHeader("Top Booked Tests", textColor),
                    const SizedBox(height: 12),
                    ...individualTests.map(
                      (test) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TestRow(
                          item: test,
                          isAdded: _cartIds.contains(test['id']),
                          onToggle: () => _toggleItem(test['id']),
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Space for sticky bar
                  ]),
                ),
              ),
            ],
          ),

          // 6. STICKY BOOKING BAR
          if (_cartIds.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${_cartIds.length} Tests Selected",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: subTextColor,
                          ),
                        ),
                        Text(
                          currencyFormat.format(_cartTotal),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Book Now",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const Text(
          "View All",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// --- WIDGETS ---

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdded;
  final VoidCallback onToggle;
  final bool isDarkMode;

  const PackageCard({
    super.key,
    required this.item,
    required this.isAdded,
    required this.onToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final features = item['features'] as List<String>;
    final tags = item['tags'] as List<String>;

    // Theme Colors
    final cardBg = isDarkMode ? kDarkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return GestureDetector(
      // --- NAVIGATION TRIGGER ---
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PackageDetailsScreen(package: item),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isAdded ? kPrimaryColor : borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.activity,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                      ),
                      if (tags.contains('bestseller'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kOrangeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "BESTSELLER",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kOrangeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Includes ${features.join(', ')}",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.grey : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Specs (Non-interactive)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.05)
                          : kSlate50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSpec(
                          LucideIcons.flaskConical,
                          item['includes'],
                          textColor,
                        ),
                        _buildSpec(
                          LucideIcons.clock,
                          item['reportTime'],
                          textColor,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Price & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "₹${item['mrp']}",
                                style: const TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${item['discount']}% OFF",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: kGreenColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            currencyFormat.format(item['price']),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      // Book Button (Separate Gesture)
                      ElevatedButton(
                        onPressed: onToggle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdded
                              ? Colors.grey.withValues(alpha: 0.2)
                              : kPrimaryColor,
                          foregroundColor: isAdded ? textColor : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          minimumSize: const Size(80, 36),
                          elevation: 0,
                        ),
                        child: Text(isAdded ? "Added" : "Book"),
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

  Widget _buildSpec(IconData icon, String text, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class TestRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdded;
  final VoidCallback onToggle;
  final bool isDarkMode;

  const TestRow({
    super.key,
    required this.item,
    required this.isAdded,
    required this.onToggle,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDarkMode ? kDarkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.microscope,
              color: kPrimaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      item['reportTime'],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['fasting'],
                      style: TextStyle(
                        fontSize: 10,
                        color: item['fasting'].contains('Not')
                            ? kGreenColor
                            : kOrangeColor,
                        fontWeight: FontWeight.bold,
                      ),
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
                currencyFormat.format(item['price']),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isAdded
                        ? Colors.grey.withValues(alpha: 0.2)
                        : kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isAdded
                          ? Colors.transparent
                          : kPrimaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isAdded ? "ADDED" : "ADD",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAdded ? Colors.grey : kPrimaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 5. PRESCRIPTION MODAL
class PrescriptionModal extends StatelessWidget {
  const PrescriptionModal({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? kDarkCard : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Upload Prescription",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(16),
              color: isDarkMode ? kDarkBg : kLightBg,
            ),
            child: const Column(
              children: [
                Icon(LucideIcons.camera, size: 40, color: kPrimaryColor),
                SizedBox(height: 12),
                Text(
                  "Tap to Upload",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Request Call Back",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
