import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
// --- NEW IMPORTS ---
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255); // Blue-600
const Color kOrangeColor = Color(0xFFEA580C);
const Color kGreenColor = Color(0xFF16A34A);
const Color kRedColor = Color(0xFFEF4444);

// Dark Mode Colors
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
// Light Mode Colors
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;

// --- MOCK DATA ---
class Product {
  final int id;
  final String name;
  final String brand;
  final String pack;
  final String form;
  final double price;
  final double mrp;
  final int discount;
  final double rating;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.pack,
    required this.form,
    required this.price,
    required this.mrp,
    required this.discount,
    required this.rating,
    required this.tags,
  });
}

final List<Product> MOCK_PRODUCTS = [
  Product(
    id: 101,
    name: "Salmon Omega 3 Fish Oil",
    brand: "Tata 1mg",
    pack: "60 Capsules",
    form: "Capsule",
    price: 380,
    mrp: 950,
    discount: 60,
    rating: 4.5,
    tags: ["bestseller"],
  ),
  Product(
    id: 102,
    name: "Telma 40mg Tablet",
    brand: "Glenmark",
    pack: "30 Tablets",
    form: "Tablet",
    price: 240,
    mrp: 300,
    discount: 20,
    rating: 4.8,
    tags: ["rx_required"],
  ),
  Product(
    id: 103,
    name: "Shelcal 500mg",
    brand: "Torrent",
    pack: "15 Tablets",
    form: "Tablet",
    price: 115,
    mrp: 130,
    discount: 12,
    rating: 4.6,
    tags: [],
  ),
  Product(
    id: 104,
    name: "Dabur Chyawanprash",
    brand: "Dabur",
    pack: "1kg Jar",
    form: "Paste",
    price: 350,
    mrp: 395,
    discount: 11,
    rating: 4.4,
    tags: ["deal"],
  ),
  Product(
    id: 105,
    name: "Neurobion Forte",
    brand: "P&G",
    pack: "30 Tablets",
    form: "Tablet",
    price: 45,
    mrp: 55,
    discount: 18,
    rating: 4.3,
    tags: ["bestseller"],
  ),
  Product(
    id: 106,
    name: "Digene Gel Orange",
    brand: "Abbott",
    pack: "200ml Bottle",
    form: "Syrup",
    price: 120,
    mrp: 145,
    discount: 17,
    rating: 4.5,
    tags: ["fast_moving"],
  ),
];

class MedicineShopScreen extends StatefulWidget {
  const MedicineShopScreen({super.key});

  @override
  State<MedicineShopScreen> createState() => _MedicineShopScreenState();
}

class _MedicineShopScreenState extends State<MedicineShopScreen> {
  final Set<int> _cart = {};
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  void _toggleCart(int id) {
    setState(() {
      if (_cart.contains(id)) {
        _cart.remove(id);
      } else {
        _cart.add(id);
      }
    });
  }

  double get _cartTotal {
    double total = 0;
    for (var id in _cart) {
      total += MOCK_PRODUCTS.firstWhere((p) => p.id == id).price;
    }
    return total;
  }

  // --- ACTIONS ---

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/919692664009");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp")),
        );
      }
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri url = Uri.parse("tel:+919692664009");
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Dialer")),
        );
      }
    }
  }

  Future<void> _openCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Prescription Captured: ${photo.name}")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Camera permission denied")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Detect Theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? kDarkBg : kLightBg;
    final cardColor = isDarkMode ? kDarkCard : kLightCard;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDarkMode
        ? Colors.grey.shade400
        : Colors.grey.shade500;
    final borderColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // --- 1. HERO SECTION ---
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Background
                    Container(
                      height: 340, // Increased height for better spacing
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF001E3C), // Deep Navy for contrast
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(32),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -50,
                            right: -50,
                            child: _buildBlurCircle(
                              kPrimaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          Positioned(
                            bottom: -50,
                            left: -50,
                            child: _buildBlurCircle(
                              kOrangeColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Get Medicines",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "Superfast delivery to your door",
                                    style: TextStyle(
                                      color: Colors.blue.shade100,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.shoppingBag,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Floating Search Hub
                          _buildFloatingHub(
                            context,
                            isDarkMode,
                            cardColor,
                            textColor,
                            subTextColor,
                            borderColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. OFFERS SECTION ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildOfferCard(
                          title: "25% OFF",
                          subtitle: "App Only",
                          icon: LucideIcons.smartphone,
                          color: kPrimaryColor,
                          bg: isDarkMode ? kDarkCard : Colors.blue.shade50,
                          textColor: textColor,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildOfferCard(
                          title: "23% OFF",
                          subtitle: "Code: 23NUFIT",
                          icon: LucideIcons.zap,
                          color: kOrangeColor,
                          bg: isDarkMode ? kDarkCard : Colors.orange.shade50,
                          textColor: textColor,
                          isDarkMode: isDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- 3. PRODUCTS HEADER ---
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Popular Medicines",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          "View All",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              // --- 4. ENHANCED PRODUCT GRID ---
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62, // Taller card for better layout
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final product = MOCK_PRODUCTS[index];
                    return _buildProductCard(
                      product,
                      _cart.contains(product.id),
                      () => _toggleCart(product.id),
                      cardColor,
                      textColor,
                      subTextColor,
                      borderColor,
                      isDarkMode,
                    );
                  }, childCount: MOCK_PRODUCTS.length),
                ),
              ),
            ],
          ),

          // --- 5. STICKY CART FOOTER ---
          if (_cart.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border(top: BorderSide(color: borderColor)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${_cart.length} ITEMS ADDED",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: subTextColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            "₹${NumberFormat('#,##0').format(_cartTotal)}",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: kPrimaryColor.withValues(alpha: 0.4),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              "Proceed",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(LucideIcons.chevronRight, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildBlurCircle(Color color) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildFloatingHub(
    BuildContext context,
    bool isDarkMode,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          // Search
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isDarkMode ? kDarkBg : kLightBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(LucideIcons.search, color: subTextColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: "Search medicines...",
                      hintStyle: TextStyle(color: subTextColor),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: kPrimaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    "Search",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              _buildActionButton(
                LucideIcons.messageCircle,
                "WhatsApp",
                const Color(0xFF25D366),
                isDarkMode,
                onTap: _openWhatsApp,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                LucideIcons.camera,
                "Scan Rx",
                kPrimaryColor,
                isDarkMode,
                onTap: _openCamera,
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                LucideIcons.phone,
                "Call Now",
                kPrimaryColor,
                isDarkMode,
                onTap: _makePhoneCall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color color,
    bool isDarkMode, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bg,
    required Color textColor,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDarkMode
                  ? []
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    bool isAdded,
    VoidCallback onToggle,
    Color cardColor,
    Color textColor,
    Color subTextColor,
    Color borderColor,
    bool isDarkMode,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isAdded ? kPrimaryColor : borderColor),
        boxShadow: isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background Decoration for Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.02)
                    : Colors.grey.withValues(alpha: 0.03),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (product.tags.contains('bestseller'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: kOrangeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "BESTSELLER",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else if (product.tags.contains('rx_required'))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "RX",
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      else
                        const SizedBox(),

                      // Rating
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: kGreenColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              product.rating.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kGreenColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.star,
                              size: 10,
                              color: kGreenColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Image Center
                  const Spacer(flex: 2),
                  Center(
                    child: Hero(
                      tag: product.id,
                      child: Icon(
                        product.form == 'Capsule'
                            ? LucideIcons.pill
                            : LucideIcons.tablet,
                        size: 56,
                        color: isDarkMode
                            ? Colors.grey.shade700
                            : Colors.grey.shade300,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Text Info
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.pack,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: subTextColor,
                    ),
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 12),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "₹${product.mrp.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: subTextColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${product.discount}% OFF",
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: kGreenColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "₹${product.price.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: onToggle,
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isAdded ? Colors.transparent : kPrimaryColor,
                            border: Border.all(
                              color: isAdded
                                  ? subTextColor
                                  : Colors.transparent,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isAdded
                                ? []
                                : [
                                    BoxShadow(
                                      color: kPrimaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Text(
                            isAdded ? "ADDED" : "ADD",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAdded ? subTextColor : Colors.white,
                            ),
                          ),
                        ),
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
}
