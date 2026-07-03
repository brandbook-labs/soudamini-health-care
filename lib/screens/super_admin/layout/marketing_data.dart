// lib/screens/super_admin/marketing/marketing_data.dart

class MarketingTemplate {
  final String id;
  final String category; // "festival", "health_tip", "promo", "awareness"
  final String
  group; // NEW: "Rath Yatra", "Diwali", "General" (For grouping variants)
  final String title;
  final String baseImageUrl;
  final Map<String, dynamic> overlayConfig;
  final Map<String, String> greetingText;

  const MarketingTemplate({
    required this.id,
    required this.category,
    this.group = "General",
    required this.title,
    required this.baseImageUrl,
    required this.overlayConfig,
    required this.greetingText,
  });
}

// ===========================================================================
// THE BASE DESIGN REPOSITORY (50+ DESIGNS)
// ===========================================================================
final List<MarketingTemplate> kAllTemplates = [
  // --- GROUP: RATH YATRA (Multiple Styles) ---
  _createTmpl(
    "rath_v1",
    "festival",
    "Rath Yatra",
    "Rath Yatra Classic",
    "rath yatra chariot",
    "Happy Rath Yatra",
    "ପବିତ୍ର ରଥଯାତ୍ରା",
    "#FFFFFF",
  ),
  _createTmpl(
    "rath_v2",
    "festival",
    "Rath Yatra",
    "Rath Yatra Modern",
    "lord jagannath abstract",
    "Jai Jagannath",
    "ଜୟ ଜଗନ୍ନାଥ",
    "#FFD700",
  ),
  _createTmpl(
    "rath_v3",
    "festival",
    "Rath Yatra",
    "Rath Yatra Minimal",
    "chariot wheel art",
    "Rath Yatra Greetings",
    "ରଥଯାତ୍ରାର ଶୁଭେଚ୍ଛା",
    "#1E293B",
  ),

  // --- GROUP: RAJA PARBA ---
  _createTmpl(
    "raja_v1",
    "festival",
    "Raja Parba",
    "Raja Parba Trad",
    "swing nature girl",
    "Happy Raja Parba",
    "ରଜ ପର୍ବର ଶୁଭେଚ୍ଛା",
    "#FFFFFF",
  ),
  _createTmpl(
    "raja_v2",
    "festival",
    "Raja Parba",
    "Raja Parba Fun",
    "poda pitha odia",
    "Enjoy Poda Pitha",
    "ରଜ ମଉଜ",
    "#1E293B",
  ),

  // --- GROUP: DIWALI ---
  _createTmpl(
    "diwali_v1",
    "festival",
    "Diwali",
    "Diwali Lights",
    "diwali diyas dark",
    "Happy Diwali",
    "ଶୁଭ ଦୀପାବଳି",
    "#FFD700",
  ),
  _createTmpl(
    "diwali_v2",
    "festival",
    "Diwali",
    "Diwali Family",
    "family celebrating diwali",
    "Safe & Happy Diwali",
    "ସୁରକ୍ଷିତ ଦୀପାବଳି",
    "#FFFFFF",
  ),

  // --- GROUP: HEALTH TIPS ---
  _createTmpl(
    "health_heart_01",
    "health_tip",
    "Heart",
    "World Heart Day",
    "human heart illustration",
    "Keep Heart Healthy",
    "ହୃଦୟ ଯତ୍ନ ନିଅନ୍ତୁ",
    "#FFFFFF",
  ),
  _createTmpl(
    "health_sugar_01",
    "health_tip",
    "Diabetes",
    "Sugar Control",
    "glucometer test",
    "Control Diabetes",
    "ମଧୁମେହ ନିୟନ୍ତ୍ରଣ",
    "#1E293B",
  ),
  _createTmpl(
    "health_water_01",
    "health_tip",
    "Kidney",
    "Drink Water",
    "glass of water",
    "Stay Hydrated",
    "ପାଣି ପିଅନ୍ତୁ",
    "#1E293B",
  ),

  // --- GROUP: PROMO ---
  _createTmpl(
    "promo_dental",
    "promo",
    "Dental",
    "Free Dental Checkup",
    "dentist tools",
    "Free Checkup",
    "ମାଗଣା ଦାନ୍ତ ଚିକିତ୍ସା",
    "#1E293B",
  ),
  _createTmpl(
    "promo_eye",
    "promo",
    "Eye",
    "Eye Camp",
    "eye test chart",
    "Protect Vision",
    "ଚକ୍ଷୁ ପରୀକ୍ଷା",
    "#1E293B",
  ),
  _createTmpl(
    "promo_lab",
    "promo",
    "Lab",
    "20% Off Labs",
    "microscope",
    "Lab Discount",
    "ରିହାତି",
    "#FFFFFF",
  ),

  // ... Add as many as you like here without touching the main UI code
];

// Helper to generate template object quickly
MarketingTemplate _createTmpl(
  String id,
  String cat,
  String grp,
  String title,
  String keywords,
  String en,
  String or,
  String color,
) {
  // Using Pollinations AI for stable, keyword-based generation mock
  // In production, replace with: "https://firebasestorage.googleapis.../marketing/$id.png"
  String url =
      "https://image.pollinations.ai/prompt/$keywords?width=800&height=800&nologo=true&seed=$id";

  return MarketingTemplate(
    id: id,
    category: cat,
    group: grp,
    title: title,
    baseImageUrl: url,
    overlayConfig: {
      "logo_position": {"top": 20.0, "right": 20.0, "width": 60.0},
      "text_color": color,
    },
    greetingText: {"en": en, "or": or},
  );
}
