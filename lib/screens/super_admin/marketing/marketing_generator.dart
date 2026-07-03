import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/core/utils/theme_utils.dart';
import 'package:my_new_app/screens/super_admin/layout/marketing_data.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';


// ===========================================================================
// 1. MISSING DATA MODELS (ADDED THESE BACK)
// ===========================================================================

class Clinic {
  final String id;
  final String name;
  final String address;
  final String city;
  final String phone;
  final String website;
  final BrandingAssets brandingAssets;

  Clinic({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.phone,
    required this.website,
    required this.brandingAssets,
  });
}

class BrandingAssets {
  final String? logoTransparent;
  final String primaryColor;
  BrandingAssets({this.logoTransparent, required this.primaryColor});
}

// ===========================================================================
// 2. MOCK DATA
// ===========================================================================
final Clinic kMockClinic = Clinic(
  id: "preview_clinic",
  name: "Jivan Preview Clinic",
  address: "Medical Road",
  city: "Bhadrak",
  phone: "+91 99388 00000",
  website: "https://jivan.website",
  brandingAssets: BrandingAssets(
    primaryColor: "#2563EB",
    logoTransparent: null,
  ),
);

// ===========================================================================
// 3. MAIN SCREEN
// ===========================================================================
class MarketingGeneratorScreen extends StatefulWidget {
  const MarketingGeneratorScreen({super.key});

  @override
  State<MarketingGeneratorScreen> createState() =>
      _MarketingGeneratorScreenState();
}

class _MarketingGeneratorScreenState extends State<MarketingGeneratorScreen> {
  final GlobalKey _previewContainerKey = GlobalKey();

  // --- STATE ---
  MarketingTemplate? selectedTemplate;

  // Canvas Configuration
  bool _isOdia = false;
  bool _isStoryFormat = false; // 9:16 vs 1:1
  double _zoomLevel = 1.0; // 1.0 = Fit to Screen

  // Filter State
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Loading
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (kAllTemplates.isNotEmpty) {
      selectedTemplate = kAllTemplates.first;
    }
  }

  // --- ACTIONS ---
  Future<void> _captureAndShare() async {
    setState(() => _isLoading = true);
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Wait for UI update
    try {
      if (!mounted) return;
      final renderContext = _previewContainerKey.currentContext;
      if (renderContext == null) return;

      // 1. Force the boundary to render at high resolution regardless of screen zoom
      RenderRepaintBoundary boundary =
          renderContext.findRenderObject() as RenderRepaintBoundary;

      // Calculate pixel ratio to ensure 1080px width output
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      if (!mounted) return;
      await Share.shareXFiles([
        XFile.fromData(
          pngBytes,
          name: 'jivan-${selectedTemplate?.id}.png',
          mimeType: 'image/png',
        ),
      ], text: 'Marketing Design: ${selectedTemplate?.title}');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Breakpoint
    final isDesktop = context.width > 900;

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Marketing Studio",
          style: context.titleLg?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          // Zoom Controls (Desktop Only)
          if (isDesktop) ...[
            IconButton(
              icon: const Icon(Icons.zoom_out),
              onPressed: () => setState(
                () => _zoomLevel = (_zoomLevel - 0.1).clamp(0.5, 2.0),
              ),
              tooltip: "Zoom Out",
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "${(_zoomLevel * 100).toInt()}%",
                style: context.labelMd,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.zoom_in),
              onPressed: () => setState(
                () => _zoomLevel = (_zoomLevel + 0.1).clamp(0.5, 2.0),
              ),
              tooltip: "Zoom In",
            ),
            const VerticalDivider(indent: 12, endIndent: 12),
          ],

          // Export Button
          Padding(
            padding: EdgeInsets.only(right: context.spaceLg),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _captureAndShare,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 18),
              label: Text(_isLoading ? "Exporting..." : "Download"),
            ),
          ),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ===========================================================================
  // LAYOUTS
  // ===========================================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LEFT: Asset Library (Resizable feel)
        SizedBox(
          width: 420,
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(
                right: BorderSide(color: context.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                _buildSearchAndFilterBar(),
                Expanded(child: _buildTemplateGrid()),
              ],
            ),
          ),
        ),

        // CENTER: The Workspace
        Expanded(
          child: Container(
            color: context
                .colorScheme
                .surfaceContainerHighest, // Neutral grey background
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. The Canvas (Pannable/Zoomable)
                // Using InteractiveViewer for natural pan/zoom interaction
                InteractiveViewer(
                  minScale: 0.1,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(context.spaceXl),
                      // FittedBox ensures it fits initially, then InteractiveViewer takes over
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _buildCanvas(),
                      ),
                    ),
                  ),
                ),

                // 2. Floating Config Bar (Bottom Center)
                Positioned(
                  bottom: context.spaceXl,
                  child: _buildFloatingConfigBar(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // TOP: Canvas Area
        Expanded(
          flex: 5,
          child: Container(
            color: context.colorScheme.surfaceContainerHighest,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(context.spaceLg),
                child: FittedBox(
                  fit: BoxFit
                      .contain, // Ensures 9:16 fits fully on mobile screens
                  child: _buildCanvas(),
                ),
              ),
            ),
          ),
        ),

        // BOTTOM: Controls & Library
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: context.shadowMd,
            ),
            child: Column(
              children: [
                context.gapMd,
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                context.gapMd,

                // Config Toggles
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
                  child: Row(
                    children: [
                      _buildToggleChip(
                        "Odia Text",
                        _isOdia,
                        (v) => setState(() => _isOdia = v),
                      ),
                      context.gapMd,
                      _buildToggleChip(
                        "Story (9:16)",
                        _isStoryFormat,
                        (v) => setState(() => _isStoryFormat = v),
                      ),
                    ],
                  ),
                ),
                const Divider(),

                // Template Grid
                Expanded(child: _buildTemplateGrid(isMobile: true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // WIDGET: SEARCH & FILTERS
  // ===========================================================================
  Widget _buildSearchAndFilterBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Input
        Padding(
          padding: EdgeInsets.all(context.spaceMd),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: "Search designs...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: context.colorScheme.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: context.roundedLg,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Category Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: context.spaceMd),
          child: Row(
            children: ["All", "festival", "health_tip", "promo", "awareness"]
                .map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: context.spaceSm,
                      bottom: context.spaceSm,
                    ),
                    child: ChoiceChip(
                      label: Text(cat.toUpperCase()),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? context.onPrimary
                            : context.onSurface,
                      ),
                      // Using Theme Context colors
                      selectedColor: context.primaryColor,
                      backgroundColor: context.colorScheme.surfaceContainer,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  // ===========================================================================
  // WIDGET: TEMPLATE GRID
  // ===========================================================================
  Widget _buildTemplateGrid({bool isMobile = false}) {
    // 1. Filter Logic
    final filtered = kAllTemplates.where((t) {
      final matchesCat =
          _selectedCategory == 'All' || t.category == _selectedCategory;
      final matchesSearch = t.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      return matchesCat && matchesSearch;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: context.colorScheme.outline,
            ),
            context.gapSm,
            Text(
              "No designs found",
              style: context.bodyMd?.copyWith(
                color: context.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(context.spaceMd),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 3 : 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final t = filtered[index];
        final isSelected = selectedTemplate?.id == t.id;

        return GestureDetector(
          onTap: () => setState(() => selectedTemplate = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: context.roundedMd,
              border: Border.all(
                color: isSelected
                    ? context.primaryColor
                    : context.colorScheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? context.shadowMd : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                6,
              ), // Slightly less than container
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(t.baseImageUrl, fit: BoxFit.cover),

                  // Gradient Overlay for text readability
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 40,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent],
                        ),
                      ),
                      alignment: Alignment.bottomLeft,
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        t.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Selection Indicator
                  if (isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: context.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // WIDGET: FLOATING CONFIG BAR (Desktop)
  // ===========================================================================
  Widget _buildFloatingConfigBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.surface.withOpacity(0.9), // Glassmorphism-ish
        borderRadius: BorderRadius.circular(50),
        boxShadow: context.shadowMd,
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleChip(
            "Odia Language",
            _isOdia,
            (v) => setState(() => _isOdia = v),
          ),
          const SizedBox(width: 12),
          Container(
            height: 20,
            width: 1,
            color: context.colorScheme.outlineVariant,
          ),
          const SizedBox(width: 12),
          _buildToggleChip(
            "Story Format (9:16)",
            _isStoryFormat,
            (v) => setState(() => _isStoryFormat = v),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool value, Function(bool) onChanged) {
    final activeColor = context.primaryColor;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? activeColor : context.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check : Icons.circle_outlined,
              size: 14,
              color: value ? activeColor : context.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value ? activeColor : context.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // CORE: THE CANVAS
  // ===========================================================================
  Widget _buildCanvas() {
    if (selectedTemplate == null) return const SizedBox();

    // LOGIC: High Resolution Dimensions
    // We render at high res (e.g., 600px width), but FittedBox scales it down visually.
    final double width = 600;
    final double height = _isStoryFormat
        ? 1066
        : 600; // 9:16 (1066) vs 1:1 (600)

    return RepaintBoundary(
      key: _previewContainerKey,
      child: Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          color: Colors.white, // Canvas is always white base
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 40,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Base Image
            Image.network(
              selectedTemplate!.baseImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),

            // Layer 2: Logo Overlay
            _buildLogoOverlay(scale: 1.5), // Scale up for the larger canvas
            // Layer 3: Greeting Text
            Positioned(
              top: _isStoryFormat ? 150 : 80,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _getGreeting(),
                  textAlign: TextAlign.center,
                  style: _getGreetingStyle(scale: 1.5),
                ),
              ),
            ),

            // Layer 4: Footer
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildStandardFooter(width: width),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoOverlay({double scale = 1.0}) {
    final config = selectedTemplate!.overlayConfig['logo_position'];
    final double baseWidth = config['width'] ?? 50.0;
    final double width = baseWidth * scale; // Scale relative to canvas size

    // Helper function to safely parse color from hex
    Color parseColor(String? hexString, {Color fallback = Colors.white}) {
      if (hexString == null) return fallback;
      try {
        final buffer = StringBuffer();
        if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
        buffer.write(hexString.replaceFirst('#', ''));
        return Color(int.parse(buffer.toString(), radix: 16));
      } catch (e) {
        return fallback;
      }
    }

    final borderColor = parseColor(
      kMockClinic.brandingAssets.primaryColor,
      fallback: context.primaryColor,
    );

    return Positioned(
      top: (config['top'] ?? 20) * scale,
      left: config['left'] != null ? config['left'] * scale : null,
      right: config['right'] != null ? config['right'] * scale : null,
      child: Container(
        width: width,
        height: width,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 2 * scale),
          boxShadow: [
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            "J",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: borderColor,
              fontSize: 24 * scale,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStandardFooter({required double width}) {
    // Tracking URL
    final trackingUrl =
        "${kMockClinic.website}/booking?clinic=${kMockClinic.id}&source=social_post";

    // Use Branding color if available, else primary
    final brandingColorHex = kMockClinic.brandingAssets.primaryColor;

    Color primaryColor;
    try {
      final buffer = StringBuffer();
      if (brandingColorHex.length == 6 || brandingColorHex.length == 7)
        buffer.write('ff');
      buffer.write(brandingColorHex.replaceFirst('#', ''));
      primaryColor = Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      primaryColor = context.primaryColor;
    }

    final onSurface = Colors.black87;

    // Scale factor based on canvas width vs screen width (simplified)
    final double h = _isStoryFormat ? 140 : 120;
    final double fontSizeName = 20;
    final double fontSizeDetails = 16;
    final double iconSize = 16;

    return Container(
      height: h,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: primaryColor, width: 6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: trackingUrl,
              version: QrVersions.auto,
              size: h * 0.6,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: primaryColor,
              ),
            ),
          ),

          const SizedBox(width: 24),

          // Clinic Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kMockClinic.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: fontSizeName,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.phone, size: iconSize, color: onSurface),
                    const SizedBox(width: 8),
                    Text(
                      kMockClinic.phone,
                      style: GoogleFonts.poppins(
                        fontSize: fontSizeDetails,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: iconSize, color: onSurface),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "${kMockClinic.address}, ${kMockClinic.city}",
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeDetails,
                          color: onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Powered By",
                  style: GoogleFonts.poppins(fontSize: 10, color: onSurface),
                ),
                Text(
                  "JIVAN",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TEXT HELPERS ---
  String _getGreeting() {
    if (_isOdia && selectedTemplate!.greetingText.containsKey('or')) {
      return selectedTemplate!.greetingText['or']!;
    }
    return selectedTemplate!.greetingText['en']!;
  }

  TextStyle _getGreetingStyle({double scale = 1.0}) {
    final hexColor = selectedTemplate!.overlayConfig['text_color'] ?? "#000000";
    // Color Parsing
    Color color;
    try {
      final buffer = StringBuffer();
      if (hexColor.length == 6 || hexColor.length == 7) buffer.write('ff');
      buffer.write(hexColor.replaceFirst('#', ''));
      color = Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      color = Colors.black;
    }

    final fontSize = (_isStoryFormat ? 48 : 36) * scale;

    if (_isOdia) {
      return GoogleFonts.baloo2(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6 * scale),
        ],
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color,
      shadows: [
        Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 6 * scale),
      ],
    );
  }
}
