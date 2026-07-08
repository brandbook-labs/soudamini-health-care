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

// --- UTILS ---
final currencyFormat = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Centralised colour set so widgets stop re-deriving the same values.
class LabTheme {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color text;
  final Color subText;
  final Color border;
  final Color field;
  final Color muted; // subtle fills (spec rows, chips)

  const LabTheme._({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.text,
    required this.subText,
    required this.border,
    required this.field,
    required this.muted,
  });

  factory LabTheme.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LabTheme._(
      isDark: dark,
      bg: dark ? kDarkBg : kLightBg,
      card: dark ? kDarkCard : kLightCard,
      text: dark ? Colors.white : const Color(0xFF0F172A),
      subText: dark ? Colors.grey.shade400 : Colors.grey.shade500,
      border: dark ? Colors.white10 : Colors.grey.shade200,
      field: dark ? Colors.grey.shade900 : Colors.grey.shade100,
      muted: dark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF1F5F9),
    );
  }
}

// --- MOCK DATA ---
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
    'tags': ["bestseller", "popular", "full body"],
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
    'tags': ["diabetes", "full body"],
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

const List<String> _categories = [
  "All",
  "Full Body",
  "Diabetes",
  "Thyroid",
  "Fever",
  "Heart",
  "Covid-19",
];

// --- MAIN SCREEN ---
class LabListingScreen extends StatefulWidget {
  const LabListingScreen({super.key});

  @override
  State<LabListingScreen> createState() => _LabListingScreenState();
}

class _LabListingScreenState extends State<LabListingScreen> {
  final Set<String> _cartIds = {};
  final TextEditingController _searchController = TextEditingController();

  String _query = "";
  String _category = "All";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleItem(String id) {
    setState(() {
      _cartIds.contains(id) ? _cartIds.remove(id) : _cartIds.add(id);
    });
  }

  int _priceOf(String id) {
    final all = [...packages, ...individualTests];
    final item = all.firstWhere((e) => e['id'] == id, orElse: () => {});
    return item.isEmpty ? 0 : item['price'] as int;
  }

  double get _cartTotal => _cartIds.fold(0.0, (sum, id) => sum + _priceOf(id));

  // --- FILTERING ---
  bool _matches(Map<String, dynamic> item) {
    // Search matches name.
    if (_query.isNotEmpty &&
        !item['name'].toString().toLowerCase().contains(_query)) {
      return false;
    }
    if (_category == "All") return true;

    final key = _category.toLowerCase();
    if (key == "full body") return item['type'] == "Package";

    final tags = (item['tags'] as List).map((t) => t.toString()).toList();
    final haystack = "${item['name']} ${tags.join(' ')}".toLowerCase();
    return haystack.contains(key.split(' ').first);
  }

  List<Map<String, dynamic>> get _filteredPackages =>
      packages.where(_matches).toList();

  List<Map<String, dynamic>> get _filteredTests =>
      individualTests.where(_matches).toList();

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
    final t = LabTheme.of(context);
    final filteredPackages = _filteredPackages;
    final filteredTests = _filteredTests;
    final hasResults = filteredPackages.isNotEmpty || filteredTests.isNotEmpty;

    return Scaffold(
      backgroundColor: t.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. APP BAR & SEARCH

              // 2. UPLOAD PRESCRIPTION BANNER
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PrescriptionBanner(onUpload: _showPrescriptionModal),
                ),
              ),

              // 3. CATEGORY PILLS
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cat = _categories[i];
                      final selected = cat == _category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? kPrimaryColor : t.card,
                            border: Border.all(
                              color: selected ? kPrimaryColor : t.border,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : t.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 4. NO RESULTS
              if (!hasResults)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyResults(theme: t),
                ),

              // 5. PACKAGES SECTION
              if (filteredPackages.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _sectionHeader("Popular Packages", t.text),
                      const SizedBox(height: 12),
                      for (final pkg in filteredPackages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PackageCard(
                            item: pkg,
                            isAdded: _cartIds.contains(pkg['id']),
                            onToggle: () => _toggleItem(pkg['id']),
                            theme: t,
                          ),
                        ),
                    ]),
                  ),
                ),

              // 6. INDIVIDUAL TESTS SECTION
              if (filteredTests.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _sectionHeader("Top Booked Tests", t.text),
                      const SizedBox(height: 12),
                      for (final test in filteredTests)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TestRow(
                            item: test,
                            isAdded: _cartIds.contains(test['id']),
                            onToggle: () => _toggleItem(test['id']),
                            theme: t,
                          ),
                        ),
                    ]),
                  ),
                ),

              // Space for the sticky bar.
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),

          // 7. STICKY BOOKING BAR
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BookingBar(
              theme: t,
              count: _cartIds.length,
              total: _cartTotal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color textColor) {
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

class _PrescriptionBanner extends StatelessWidget {
  final VoidCallback onUpload;
  const _PrescriptionBanner({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.8)],
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
            child: const Icon(LucideIcons.fileText, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Have a prescription?",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Upload now & get a call back",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onUpload,
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
    );
  }
}

class PackageCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdded;
  final VoidCallback onToggle;
  final LabTheme theme;

  const PackageCard({
    super.key,
    required this.item,
    required this.isAdded,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final features = (item['features'] as List).cast<String>();
    final tags = (item['tags'] as List).cast<String>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
            color: theme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isAdded ? kPrimaryColor : theme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                  if (tags.contains('bestseller')) const _Badge(),
                ],
              ),
              const SizedBox(height: 12),
              // Title
              Text(
                item['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                "Includes ${features.join(', ')}",
                style: TextStyle(fontSize: 11, color: theme.subText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Specs (non-interactive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.muted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _spec(
                      LucideIcons.flaskConical,
                      item['includes'],
                      theme.text,
                    ),
                    _spec(LucideIcons.clock, item['reportTime'], theme.text),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
                          color: theme.text,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAdded
                          ? Colors.grey.withValues(alpha: 0.2)
                          : kPrimaryColor,
                      foregroundColor: isAdded ? theme.text : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(84, 38),
                      elevation: 0,
                    ),
                    child: Text(isAdded ? "Added ✓" : "Book"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _spec(IconData icon, String text, Color textColor) {
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

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}

class TestRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isAdded;
  final VoidCallback onToggle;
  final LabTheme theme;

  const TestRow({
    super.key,
    required this.item,
    required this.isAdded,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final fastingNotRequired = item['fasting']
        .toString()
        .toLowerCase()
        .contains('not');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAdded ? kPrimaryColor : theme.border),
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
                    color: theme.text,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
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
                        color: fastingNotRequired ? kGreenColor : kOrangeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(item['price']),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.text,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
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

class _EmptyResults extends StatelessWidget {
  final LabTheme theme;
  const _EmptyResults({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: theme.subText),
          const SizedBox(height: 16),
          Text(
            "No tests found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Try a different search or category.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: theme.subText),
          ),
        ],
      ),
    );
  }
}

class _BookingBar extends StatelessWidget {
  final LabTheme theme;
  final int count;
  final double total;

  const _BookingBar({
    required this.theme,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final visible = count > 0;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: theme.card,
            border: Border(top: BorderSide(color: theme.border)),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$count ${count == 1 ? 'item' : 'items'} selected",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.subText,
                    ),
                  ),
                  Text(
                    currencyFormat.format(total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: theme.text,
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
                    vertical: 14,
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
    );
  }
}

// --- PRESCRIPTION MODAL ---
class PrescriptionModal extends StatelessWidget {
  const PrescriptionModal({super.key});

  @override
  Widget build(BuildContext context) {
    final t = LabTheme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: t.card,
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
                  color: t.text,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: t.text),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              border: Border.all(color: t.border),
              borderRadius: BorderRadius.circular(16),
              color: t.bg,
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
