
class TranslationHelper {
  // ============================================================
  // 1. THE DICTIONARY (For Fixed Medical Terms & UI)
  // ============================================================
  static final Map<String, String> _dictionary = {
    // --- UI TERMS ---
    "find doctors": "ଡାକ୍ତର ଖୋଜନ୍ତୁ",
    "top specialists": "ଶୀର୍ଷ ବିଶେଷଜ୍ଞ",
    "nearby medicals": "ନିକଟସ୍ଥ ମେଡିକାଲ୍",
    "see all": "ସମସ୍ତ ଦେଖନ୍ତୁ",
    "book now": "ବୁକ୍ କରନ୍ତୁ",
    "book": "ବୁକ୍",
    "consultation": "ପରାମର୍ଶ",
    "consultation fee": "ପରାମର୍ଶ ଫି",
    "experience": "ଅଭିଜ୍ଞତା",
    "patients": "ରୋଗୀ",
    "reviews": "ମତାମତ",
    "about doctor": "ଡାକ୍ତରଙ୍କ ବିଷୟରେ",
    "location": "ଠିକଣା",
    "languages": "ଭାଷା",
    "availability": "ଉପଲବ୍ଧତା",
    "available today": "ଆଜି ଉପଲବ୍ଧ",
    "check slots": "ସ୍ଲଟ୍ ଦେଖନ୍ତୁ",
    "fully booked": "ସମ୍ପୂର୍ଣ୍ଣ ବୁକ୍",
    "call now": "କଲ୍ କରନ୍ତୁ",
    "emergency 24/7": "ଜରୁରୀକାଳୀନ ୨୪/୭",
    "sunday & friday": "ରବିବାର ଏବଂ ଶୁକ୍ରବାର",
    "every friday": "ପ୍ରତ୍ୟେକ ଶୁକ୍ରବାର",
    "every sunday": "ପ୍ରତ୍ୟେକ ରବିବାର",

    // --- API TERMS (SPECIALTIES) ---
    "general physician": "ସାଧାରଣ ଚିକିତ୍ସକ",
    "general-medicine": "ସାଧାରଣ ଚିକିତ୍ସା",
    "pediatrics": "ଶିଶୁ ରୋଗ ବିଶେଷଜ୍ଞ",
    "orthopedics": "ଅସ୍ଥି ଶଲ୍ୟ ଚିକିତ୍ସକ",
    "endocrinology": "ହରମୋନ୍ ରୋଗ ବିଶେଷଜ୍ଞ",
    "cardiologist": "ହୃଦରୋଗ ବିଶେଷଜ୍ଞ",
    "dentist": "ଦନ୍ତ ଚିକିତ୍ସକ",
    "dermatologist": "ଚର୍ମ ରୋଗ ବିଶେଷଜ୍ଞ",
    "neurologist": "ସ୍ନାୟୁ ରୋଗ ବିଶେଷଜ୍ଞ",
    "gynecologist": "ସ୍ତ୍ରୀ ରୋଗ ବିଶେଷଜ୍ଞ",

    // --- COMMON ABBREVIATIONS ---
    "dr.": "ଡା.",
    "dr": "ଡା.",
    "mr.": "ଶ୍ରୀ",
    "mrs.": "ଶ୍ରୀମତୀ",

    // --- DAYS ---
    "mon": "ସୋମ", "tue": "ମଙ୍ଗଳ", "wed": "ବୁଧ", "thu": "ଗୁରୁ",
    "fri": "ଶୁକ୍ର", "sat": "ଶନି", "sun": "ରବି",
    "sunday": "ରବିବାର", "monday": "ସୋମବାର", "tuesday": "ମଙ୍ଗଳବାର",
    "wednesday": "ବୁଧବାର", "thursday": "ଗୁରୁବାର", "friday": "ଶୁକ୍ରବାର",
    "saturday": "ଶନିବାର", "wednessday": "ବୁଧବାର", // Handling typo in API
  };

  // ============================================================
  // 2. TRANSLITERATION ENGINE (English -> Odia Phonetics)
  // ============================================================

  static final Map<String, String> _vowels = {
    'a': 'ଅ',
    'aa': 'ଆ',
    'i': 'ଇ',
    'ee': 'ଈ',
    'u': 'ଉ',
    'oo': 'ଊ',
    'e': 'ଏ',
    'ai': 'ଐ',
    'o': 'ଓ',
    'au': 'ୌ',
  };

  static final Map<String, String> _matras = {
    'a': '',
    'aa': 'ା',
    'i': 'ି',
    'ee': 'ୀ',
    'u': 'ୁ',
    'oo': 'ୂ',
    'e': 'େ',
    'ai': 'ୈ',
    'o': 'ୋ',
    'au': 'ୌ',
  };

  static final Map<String, String> _consonants = {
    'k': 'କ',
    'kh': 'ଖ',
    'g': 'ଗ',
    'gh': 'ଘ',
    'ch': 'ଚ',
    'chh': 'ଛ',
    'j': 'ଜ',
    'jh': 'ଝ',
    't': 'ଟ',
    'th': 'ଥ',
    'd': 'ଦ',
    'dh': 'ଧ',
    'n': 'ନ',
    'p': 'ପ',
    'ph': 'ଫ',
    'f': 'ଫ',
    'b': 'ବ',
    'bh': 'ଭ',
    'm': 'ମ',
    'y': 'ୟ',
    'r': 'ର',
    'l': 'ଲ',
    'w': 'ୱ',
    's': 'ସ',
    'sh': 'ଶ',
    'h': 'ହ',
    'ks': 'କ୍ଷ',
    'v': 'ଭ',
    'z': 'ଜ',
    'x': 'କ୍ସ',
  };

  // ============================================================
  // 3. MAIN FUNCTIONS
  // ============================================================

  static String get(String text, String langCode) {
    if (langCode == 'en' || text.isEmpty) return text;

    // 1. Try Dictionary Lookup (For exact matches like "Pediatrics")
    String cleanText = text.trim();
    String lowerText = cleanText.toLowerCase();

    if (_dictionary.containsKey(lowerText)) {
      return _dictionary[lowerText]!;
    }

    // 2. If not in dictionary, Break sentence into words
    // Example: "Dr. Jyotiranjan Das" -> ["Dr.", "Jyotiranjan", "Das"]
    List<String> words = text.split(' ');
    List<String> translatedWords = [];

    for (String word in words) {
      // Clean word (remove commas, dots unless it's Dr.)
      String rawWord = word;
      String cleanWord = word.replaceAll(RegExp(r'[^\w\s\.]'), '');
      String lowerWord = cleanWord.toLowerCase();

      if (_dictionary.containsKey(lowerWord)) {
        // If "Dr." or "Tihidi" is in dictionary
        translatedWords.add(_dictionary[lowerWord]!);
      } else {
        // Otherwise, Transliterate "Jyotiranjan"
        translatedWords.add(_transliterateToOdia(rawWord));
      }
    }

    return translatedWords.join(' ');
  }

  // Engine to convert "Jyoti" -> "ଜ୍ୟୋତି"
  static String _transliterateToOdia(String input) {
    if (input.isEmpty) return "";
    StringBuffer out = StringBuffer();
    String lower = input.toLowerCase();
    int i = 0;

    while (i < lower.length) {
      String char = lower[i];
      String nextChar = (i + 1 < lower.length) ? lower[i + 1] : "";
      String nextNextChar = (i + 2 < lower.length) ? lower[i + 2] : "";

      // 1. Check Triple chars (ssh, etc - rare but safe to check)
      // 2. Check Double chars (sh, th, ch, bh)
      String doubleChar = "$char$nextChar";

      bool matched = false;

      // Handle Double Consonants
      if (_consonants.containsKey(doubleChar)) {
        out.write(_consonants[doubleChar]);
        i += 2;
        matched = true;
      } else if (_consonants.containsKey(char)) {
        out.write(_consonants[char]);
        i++;
        matched = true;
      }

      // Handle Vowels/Matras logic
      if (matched) {
        // If we just wrote a consonant, check if the *next* thing is a vowel
        if (i < lower.length) {
          String nextVowelCheck = lower[i];
          String nextDoubleVowelCheck = (i + 1 < lower.length)
              ? "$nextVowelCheck${lower[i + 1]}"
              : "";

          if (_matras.containsKey(nextDoubleVowelCheck)) {
            out.write(_matras[nextDoubleVowelCheck]); // e.g. 'aa' -> 'ା'
            i += 2;
          } else if (_matras.containsKey(nextVowelCheck)) {
            out.write(_matras[nextVowelCheck]); // e.g. 'i' -> 'ି'
            i++;
          } else {
            // Default inherent 'a' sound, usually implicit in Odia letters
            // But if we want to kill the inherent sound (Halant), logic goes here.
            // For simple reading, standard letters work fine.
          }
        }
      } else {
        // It's a vowel at the start of word or isolated
        if (_vowels.containsKey(doubleChar)) {
          out.write(_vowels[doubleChar]);
          i += 2;
        } else if (_vowels.containsKey(char)) {
          out.write(_vowels[char]);
          i++;
        } else {
          // Unknown symbol (numbers, punctuation), keep as is
          out.write(input[i]);
          i++;
        }
      }
    }
    return out.toString();
  }
}
