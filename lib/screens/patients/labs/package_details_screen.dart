import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:my_new_app/screens/patients/booking/lab_booking_screen.dart';

// --- THEME CONSTANTS ---
const Color kPrimaryColor = Color.fromARGB(255, 22, 96, 255);
const Color kPrimaryDark = Color(0xFF1E40AF);
const Color kDarkBg = Color(0xFF151515);
const Color kDarkCard = Color(0xFF191919);
const Color kLightBg = Color(0xFFF8FAFC);
const Color kLightCard = Colors.white;
const Color kGreenColor = Color(0xFF16A34A);
const Color kAmberColor = Color(0xFFF59E0B);
const Color kOrangeColor = Color(0xFFEA580C);

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

/// Centralised colour set (mirrors the listing screen).
class LabTheme {
  final bool isDark;
  final Color bg, card, text, subText, border, muted;

  const LabTheme._({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.text,
    required this.subText,
    required this.border,
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
      muted: dark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF1F5F9),
    );
  }
}

class PackageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> package;

  const PackageDetailsScreen({super.key, required this.package});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  final ScrollController _scroll = ScrollController();
  bool _collapsed = false;
  bool _favorite = false;

  // --- Safe accessors (package maps can be partial) ---
  Map<String, dynamic> get p => widget.package;
  String get _name => (p['name'] ?? 'Health Package').toString();
  String get _type => (p['type'] ?? 'Package').toString();
  String get _includes => (p['includes'] ?? '').toString();
  String get _reportTime => (p['reportTime'] ?? '24 Hrs').toString();
  String get _fasting => (p['fasting'] ?? 'Not Required').toString();
  int get _price => (p['price'] ?? 0) as int;
  int get _mrp => (p['mrp'] ?? _price) as int;
  int get _savings => (_mrp - _price).clamp(0, _mrp);
  int get _discount =>
      (p['discount'] ?? (_mrp > 0 ? ((_savings / _mrp) * 100).round() : 0))
          as int;
  bool get _fastingRequired => !_fasting.toLowerCase().contains('not');
  List<String> get _features =>
      ((p['features'] as List?) ?? const []).map((e) => e.toString()).toList();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final collapsed = _scroll.hasClients && _scroll.offset > 180;
      if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _goToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabBookingScreen(package: widget.package),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = LabTheme.of(context);

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          _header(t),
          SliverToBoxAdapter(child: _body(t)),
        ],
      ),
      bottomNavigationBar: _BottomBar(
        theme: t,
        price: _price,
        mrp: _mrp,
        savings: _savings,
        onBook: _goToBooking,
      ),
    );
  }

  // ---------------------------------------------------------------- HEADER
  Widget _header(LabTheme t) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 240,
      backgroundColor: kPrimaryColor,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      elevation: 0,
      leading: _circleButton(
        icon: LucideIcons.arrowLeft,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _circleButton(
          icon: _favorite ? Icons.favorite : Icons.favorite_border,
          color: _favorite ? Colors.red.shade300 : Colors.white,
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _favorite = !_favorite);
          },
        ),
        _circleButton(icon: Icons.share_outlined, onTap: () {}),
        const SizedBox(width: 4),
      ],
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _collapsed ? 1 : 0,
        child: Text(
          _name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryDark],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Icon(
                  LucideIcons.microscope,
                  size: 220,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _pill(_type.toUpperCase()),
                          const SizedBox(width: 8),
                          if (_discount > 0)
                            _pill(
                              "$_discount% OFF",
                              bg: Colors.white,
                              fg: kOrangeColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 15, color: kAmberColor),
                          const SizedBox(width: 4),
                          const Text(
                            "4.8",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(12.4k booked)",
                            style: TextStyle(
                              color: Colors.blue.shade100,
                              fontSize: 13,
                            ),
                          ),
                          if (_includes.isNotEmpty) ...[
                            Text(
                              "  ·  ",
                              style: TextStyle(color: Colors.blue.shade100),
                            ),
                            Text(
                              _includes,
                              style: TextStyle(
                                color: Colors.blue.shade100,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ BODY
  Widget _body(LabTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _trustStrip(t),
          const SizedBox(height: 16),
          _statsCard(t),
          const SizedBox(height: 16),
          _couponStrip(t),
          const SizedBox(height: 24),
          _includedSection(t),
          const SizedBox(height: 24),
          _sectionTitle("How it Works", t),
          const SizedBox(height: 16),
          _timeline(t),
          const SizedBox(height: 24),
          _sectionTitle("Frequently Asked", t),
          const SizedBox(height: 12),
          _faq(t),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, LabTheme t) => Text(
    text,
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: t.text),
  );

  Widget _trustStrip(LabTheme t) {
    Widget item(IconData icon, String label) => Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: kPrimaryColor),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: t.subText,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          item(Icons.verified_outlined, "NABL\nCertified"),
          item(Icons.local_shipping_outlined, "Free Home\nCollection"),
          item(Icons.verified_user_outlined, "100%\nSafe & Hygienic"),
          item(Icons.description_outlined, "Digital\nReports"),
        ],
      ),
    );
  }

  Widget _statsCard(LabTheme t) {
    Widget divider() => Container(width: 1, height: 40, color: t.border);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(LucideIcons.clock, "Report In", _reportTime, t.text, t),
          divider(),
          _stat(
            LucideIcons.utensilsCrossed,
            "Fasting",
            _fastingRequired ? "Required" : "Not Needed",
            _fastingRequired ? kOrangeColor : kGreenColor,
            t,
          ),
          divider(),
          _stat(LucideIcons.home, "Home Visit", "Available", kGreenColor, t),
        ],
      ),
    );
  }

  Widget _couponStrip(LabTheme t) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kGreenColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGreenColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: kGreenColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, color: t.text),
                children: const [
                  TextSpan(
                    text: "HEALTH20 ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kGreenColor,
                    ),
                  ),
                  TextSpan(text: "applied — extra 20% off on this package"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _includedSection(LabTheme t) {
    final features = _features;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle("What's Included", t),
            if (_includes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _includes,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (features.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Text(
              "Detailed test breakdown will be shared with your report.",
              style: TextStyle(fontSize: 13, color: t.subText),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: t.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: t.border),
            ),
            child: Theme(
              // Remove ExpansionTile's default dividers for a cleaner look.
              data: Theme.of(context).copyWith(dividerColor: t.border),
              child: Column(
                children: [
                  for (int i = 0; i < features.length; i++)
                    _FeatureTile(
                      title: features[i],
                      theme: t,
                      showDivider: i != features.length - 1,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _timeline(LabTheme t) {
    final steps = <List<String>>[
      ["Book Test", "Select package and schedule a time slot"],
      ["Sample Collection", "Our certified phlebotomist visits your home"],
      ["Processing", "Sample analysed in NABL-accredited labs"],
      ["Get Report", "Digital report delivered within $_reportTime"],
    ];
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _ProcessStep(
            index: i + 1,
            title: steps[i][0],
            subtitle: steps[i][1],
            isLast: i == steps.length - 1,
            theme: t,
          ),
      ],
    );
  }

  Widget _faq(LabTheme t) {
    final faqs = <List<String>>[
      [
        "Do I need to fast before the test?",
        _fastingRequired
            ? "Yes. Fasting of $_fasting is recommended for accurate results."
            : "No fasting is required for this package. You can book any time.",
      ],
      [
        "When will I get my report?",
        "Your digital report will be available within $_reportTime of sample collection.",
      ],
      [
        "Is home sample collection free?",
        "Yes, home collection is completely free with this package.",
      ],
    ];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: t.border),
        child: Column(
          children: [
            for (int i = 0; i < faqs.length; i++)
              _FaqTile(
                question: faqs[i][0],
                answer: faqs[i][1],
                theme: t,
                showDivider: i != faqs.length - 1,
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------- HELPERS
  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: Colors.black.withValues(alpha: 0.15),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {Color? bg, Color fg = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg ?? Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _stat(
    IconData icon,
    String label,
    String value,
    Color valueColor,
    LabTheme t,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: kPrimaryColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: t.subText)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- WIDGETS

class _FeatureTile extends StatelessWidget {
  final String title;
  final LabTheme theme;
  final bool showDivider;
  const _FeatureTile({
    required this.title,
    required this.theme,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.testTube,
              size: 18,
              color: kPrimaryColor,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.text,
            ),
          ),
          subtitle: Text(
            "Tap to view parameters",
            style: TextStyle(fontSize: 12, color: theme.subText),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final param in const [
              "Parameter A",
              "Parameter B",
              "Parameter C",
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 14,
                      color: kGreenColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      param,
                      style: TextStyle(fontSize: 13, color: theme.subText),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (showDivider) Divider(height: 1, color: theme.border),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final LabTheme theme;
  final bool showDivider;
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.theme,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: theme.text,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              answer,
              style: TextStyle(fontSize: 13, height: 1.5, color: theme.subText),
            ),
          ],
        ),
        if (showDivider) Divider(height: 1, color: theme.border),
      ],
    );
  }
}

class _ProcessStep extends StatelessWidget {
  final int index;
  final String title;
  final String subtitle;
  final bool isLast;
  final LabTheme theme;

  const _ProcessStep({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.isLast,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: kPrimaryColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    "$index",
                    style: const TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: theme.subText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final LabTheme theme;
  final int price;
  final int mrp;
  final int savings;
  final VoidCallback onBook;

  const _BottomBar({
    required this.theme,
    required this.price,
    required this.mrp,
    required this.savings,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (savings > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: kGreenColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "You save ${_currency.format(savings)} on this package",
                style: const TextStyle(
                  color: kGreenColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Total Price",
                    style: TextStyle(fontSize: 12, color: theme.subText),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currency.format(price),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: theme.text,
                        ),
                      ),
                      if (mrp > price) ...[
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            _currency.format(mrp),
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onBook,
                icon: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  "Book Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
