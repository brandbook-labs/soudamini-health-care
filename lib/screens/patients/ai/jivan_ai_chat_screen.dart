import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';

// Ensure these point to your actual file locations
import 'package:my_new_app/screens/patients/ai/widgets/doctor_recommendation_card.dart';
import 'package:my_new_app/screens/patients/ai/widgets/error_fallback_card.dart';
import 'models/chat_message.dart';
import 'widgets/chat_header.dart';
import 'widgets/chat_bubbles.dart';
import 'widgets/suggestion_pills.dart';
import 'widgets/typing_indicator.dart';
import 'widgets/chat_input_area.dart';

class JivanAiChatScreen extends StatefulWidget {
  const JivanAiChatScreen({super.key});

  @override
  State<JivanAiChatScreen> createState() => _JivanAiChatScreenState();
}

class _JivanAiChatScreenState extends State<JivanAiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _spokenText = "";

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isInputMode = false;

  // The strict "Happy Path" pills used for the initial state and the fallback state
  final List<Map<String, String>> _baseSymptomPills = [
    {"label": "Fever, Cold or Cough", "icon": "thermometer"},
    {"label": "Body or Joint Pain", "icon": "bone"},
    {"label": "Stomach & Digestion", "icon": "stomach"},
    {"label": "Something else...", "icon": "search"},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAI();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isListening = true;
      _spokenText = "";
    });

    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _spokenText = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListeningAndSend();
        }
      },
    );
  }

  void _stopListeningAndSend() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });

    if (_spokenText.trim().isNotEmpty) {
      HapticFeedback.lightImpact();
      _addMessage(
        ChatMessage(
          id: DateTime.now().toString(),
          text: _spokenText,
          isUser: true,
        ),
      );
      _processPayload(_spokenText);
      _spokenText = "";
    }
  }

  void _cancelListening() async {
    await _speechToText.stop();
    HapticFeedback.lightImpact();
    setState(() {
      _isListening = false;
      _spokenText = "";
    });
  }

  void _initializeAI() {
    _addMessage(
      ChatMessage(
        id: "1",
        isUser: false,
        // 🚀 Improved formatting for empathy
        text:
            "Hi there. I'm here to help you find the absolute best care.\n\nHow are you feeling today?",
        type: MessageType.options,
        options: _baseSymptomPills,
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addMessage(ChatMessage msg) {
    setState(() => _messages.add(msg));
    _scrollToBottom();
  }

  void _openTextInput() {
    setState(() => _isInputMode = true);
    _focusNode.requestFocus();
  }

  void _closeTextInput() {
    setState(() => _isInputMode = false);
    _focusNode.unfocus();
  }

  void _handleOptionSelect(String optionLabel) {
    if (_isTyping) return;
    if (_isInputMode) {
      _closeTextInput();
    }

    if (optionLabel == "Something else...") {
      HapticFeedback.selectionClick();
      _openTextInput();
      return;
    }

    _addMessage(
      ChatMessage(
        id: DateTime.now().toString(),
        text: optionLabel,
        isUser: true,
      ),
    );
    _processPayload(optionLabel);
  }

  void _handleTextInput() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isTyping) return;
    _textController.clear();
    _closeTextInput();
    _addMessage(
      ChatMessage(id: DateTime.now().toString(), text: text, isUser: true),
    );
    _processPayload(text);
  }

  // ==========================================
  // 🧠 MOCK BACKEND INTENT PARSER (Advanced Multi-Turn)
  // ==========================================
  Future<void> _processPayload(String userInput) async {
    setState(() => _isTyping = true);
    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 1500));

    final inputLower = userInput.toLowerCase();
    ChatMessage newAiMessage;

    // 🛑 STATE 1: INTENT GUARDRAILS
    final outOfBoundsKeywords = [
      "fuck",
      "shit",
      "bitch",
      "politics",
      "weather",
      "movie",
      "recipe",
      "sports",
    ];
    bool isOutOfBounds = outOfBoundsKeywords.any(
      (keyword) => inputLower.contains(keyword),
    );

    if (isOutOfBounds) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "I specialize strictly in your health and medical well-being.\n\nLet's get back to finding the right care for you. What symptoms are you experiencing?",
        type: MessageType.options,
        options: _baseSymptomPills,
      );
    }
    // 🔴 STATE 2: Error Handling
    else if (inputLower.contains("error network")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text: "network",
        type: MessageType.error,
      );
    } else if (inputLower.contains("error time")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text: "timeout",
        type: MessageType.error,
      );
    } else if (inputLower.contains("error server")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text: "server",
        type: MessageType.error,
      );
    } else if (inputLower.contains("error")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text: "unknown",
        type: MessageType.error,
      );
    }
    // 🎨 STATE 3: Poem / Generic Text
    else if (inputLower.contains("poem") || inputLower.contains("joke")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Health is a journey, not just a race,\nTake a deep breath and go at your pace.\nDrink plenty of water, get plenty of rest,\nI'm here to help you feel your best!\n\nNow, how are you feeling physically today?",
        type: MessageType.text,
      );
    }
    // =========================================================
    // 🟢 STATE 4: FEVER ROUTE
    // =========================================================
    else if (inputLower.contains("fever") ||
        inputLower.contains("cold") ||
        inputLower.contains("cough")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Dealing with a fever or cold can be absolutely draining. It's important to get plenty of rest right now.\n\nTo get you feeling better quickly, I highly recommend consulting a General Physician.",
        type: MessageType.recommendation,
      );
    }
    // =========================================================
    // 🟢 STATE 5: STOMACH ROUTE (Deep Data Collection Tree)
    // =========================================================
    // Step 5A: Initial Selection
    else if (inputLower.contains("stomach") ||
        inputLower.contains("digestion")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "I'm so sorry your stomach is giving you trouble. Digestive issues can be really exhausting.\n\nTo help me understand better, what specific symptom is bothering you the most?",
        type: MessageType.options,
        options: [
          {"label": "Acidity or Heartburn", "icon": "flame"},
          {"label": "Severe Cramps", "icon": "activity"},
          {"label": "Nausea or Vomiting", "icon": "alert"},
        ],
      );
    }
    // Step 5B: Branch -> Acidity
    else if (inputLower.contains("acidity") ||
        inputLower.contains("heartburn")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Acidity can be quite painful. Let's figure this out together.\n\nHow often have you been experiencing this burning sensation?",
        type: MessageType.options,
        options: [
          {"label": "Just today", "icon": "clock"},
          {"label": "A few times a week", "icon": "calendar"},
          {"label": "Almost every day", "icon": "alert"},
        ],
      );
    }
    // Step 5C: Branch -> Acidity (Follow up)
    else if (inputLower.contains("every day") ||
        inputLower.contains("few times a week")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Since this is happening frequently, we need to be thorough.\n\nAre you experiencing any of these other symptoms alongside the acidity?",
        type: MessageType.options,
        options: [
          {"label": "Difficulty swallowing", "icon": "activity"},
          {"label": "Chest pressure", "icon": "alert"},
          {"label": "Just the burning", "icon": "flame"},
        ],
      );
    }
    // Step 5D: Branch -> Acidity (Critical Recommendation)
    else if (inputLower.contains("swallowing") ||
        inputLower.contains("chest pressure")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Thank you for sharing that. Because you are experiencing these additional symptoms, it's very important to have a specialist evaluate this properly.\n\nI highly recommend consulting a Gastroenterologist as soon as possible.",
        type: MessageType.recommendation,
      );
    }
    // Step 5E: Branch -> Cramps
    else if (inputLower == "severe cramps" ||
        (inputLower.contains("cramps") && !inputLower.contains("menstrual"))) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Stomach cramps can be very distressing. Let's narrow down the cause.\n\nWhere exactly is the pain located?",
        type: MessageType.options,
        options: [
          {"label": "Upper stomach", "icon": "activity"},
          {"label": "Lower stomach", "icon": "activity"},
          {"label": "All over", "icon": "alert"},
        ],
      );
    }
    // Step 5F: Branch -> Cramps (Follow up)
    else if (inputLower.contains("upper stomach") ||
        inputLower.contains("lower stomach") ||
        inputLower.contains("all over")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Got it. And how did this pain start?\n\nWas it sudden, or has it been building up over a few days?",
        type: MessageType.options,
        options: [
          {"label": "Started suddenly today", "icon": "alert"},
          {"label": "Building up for days", "icon": "calendar_days"},
        ],
      );
    }
    // Step 5G: Branch -> Nausea
    else if (inputLower.contains("nausea") || inputLower.contains("vomiting")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Feeling nauseous is awful. I want to make sure you stay hydrated.\n\nAre you able to keep water and fluids down?",
        type: MessageType.options,
        options: [
          {"label": "Yes, I can drink water", "icon": "droplet"},
          {"label": "No, throwing everything up", "icon": "alert"},
        ],
      );
    }
    // Step 5H: Branch -> Nausea (Critical)
    else if (inputLower.contains("throwing everything up")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "This is concerning, as it can lead to dehydration quickly.\n\nPlease visit a clinic or consult a General Physician immediately for medication to stop the vomiting.",
        type: MessageType.recommendation,
      );
    }
    // Step 5I: Generic Catch-all for Stomach Tree ending in GP
    else if (inputLower.contains("can drink water") ||
        inputLower.contains("started suddenly") ||
        inputLower.contains("building up") ||
        inputLower.contains("just today") ||
        inputLower.contains("just the burning")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Thank you for providing those details. Based on your symptoms, a General Physician can evaluate you and prescribe the right medication to get your stomach settled.",
        type: MessageType.recommendation,
      );
    }
    // =========================================================
    // 🟢 STATE 6: JOINT PAIN ROUTE
    // =========================================================
    else if ((inputLower.contains("body") ||
            inputLower.contains("joint") ||
            inputLower.contains("pain")) &&
        !inputLower.contains("sharp") &&
        !inputLower.contains("dull") &&
        !inputLower.contains("swelling")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "I'm so sorry you're dealing with pain. It can really disrupt your day.\n\nTo help me find the absolute best specialist for you, how long have you been experiencing this?",
        type: MessageType.options,
        options: [
          {"label": "Just started today", "icon": "clock"},
          {"label": "A few days", "icon": "calendar"},
          {"label": "Over a week", "icon": "calendar_days"},
        ],
      );
    } else if (inputLower == "just started today") {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Since it just started, a General Physician can evaluate it quickly and provide immediate relief.",
        type: MessageType.recommendation,
      );
    } else if (inputLower == "a few days" || inputLower == "over a week") {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "I see. Dealing with pain for that long is tough.\n\nCould you describe the exact nature of the pain to me?",
        type: MessageType.options,
        options: [
          {"label": "Sharp and Sudden", "icon": "activity"},
          {"label": "Dull and Aching", "icon": "activity"},
          {"label": "Accompanied by Swelling", "icon": "alert"},
        ],
      );
    } else if (inputLower.contains("sharp and sudden") ||
        inputLower.contains("dull and aching") ||
        inputLower.contains("swelling")) {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "Thank you for sharing those details.\n\nGiven the persistence and specific nature of your pain, I strongly recommend seeing an Orthopedic Specialist for a proper evaluation.",
        type: MessageType.recommendation,
      );
    }
    // =========================================================
    // 💬 STATE 7: Generic Default (Catch-all for typed input)
    // =========================================================
    else {
      newAiMessage = ChatMessage(
        id: DateTime.now().toString(),
        isUser: false,
        text:
            "I want to make sure you get the best possible care for that.\n\nCould you tell me how long this has been bothering you?",
        type: MessageType.options,
        options: [
          {"label": "Just started today", "icon": "clock"},
          {"label": "A few days", "icon": "calendar"},
          {"label": "Over a week", "icon": "calendar_days"},
        ],
      );
    }

    _addMessage(newAiMessage);
    setState(() => _isTyping = false);
    _scrollToBottom();
  }

  Widget _buildListeningBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: GestureDetector(
                onTap: _cancelListening,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 100,
                  minHeight: 24,
                ),
                child: SingleChildScrollView(
                  reverse: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      _spokenText.isEmpty
                          ? "Listening to your symptoms..."
                          : _spokenText,
                      style: TextStyle(
                        color: _spokenText.isEmpty
                            ? Colors.grey
                            : (isDark ? Colors.white : Colors.black),
                        fontSize: 16,
                        height: 1.3,
                        fontStyle: _spokenText.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: GestureDetector(
                onTap: _stopListeningAndSend,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedInputBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF09090B) : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade300,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                _openTextInput();
              },
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Icon(
                  LucideIcons.keyboard,
                  size: 22,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: _startListening,
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1660FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1660FF).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.mic,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF09090B)
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            ChatHeader(onClose: () => Navigator.pop(context)),
            Expanded(
              child: GestureDetector(
                onTap: _isInputMode ? _closeTextInput : null,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return const TypingIndicator();
                    }

                    final msg = _messages[index];

                    if (msg.isUser) {
                      return UserBubble(text: msg.text);
                    }

                    final bool isLastMessage = index == _messages.length - 1;
                    final bool canInteract = isLastMessage && !_isTyping;

                    if (msg.type == MessageType.error) {
                      AiErrorType currentError = AiErrorType.unknown;
                      if (msg.text == 'network') {
                        currentError = AiErrorType.network;
                      }
                      if (msg.text == 'timeout') {
                        currentError = AiErrorType.timeout;
                      }
                      if (msg.text == 'server') {
                        currentError = AiErrorType.server;
                      }

                      return ErrorFallbackCard(
                        errorType: currentError,
                        cachedPayload: "I feel sick",
                        onRetry: (payload) {
                          _processPayload(payload);
                        },
                      );
                    }

                    if (msg.type == MessageType.recommendation) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AiBubble(text: msg.text),
                          const SizedBox(height: 0),
                          const DoctorRecommendationCard(doctor: {}),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiBubble(text: msg.text),
                        if (msg.options != null)
                          IgnorePointer(
                            ignoring: !canInteract,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: canInteract ? 1.0 : 0.45,
                              child: SuggestionPills(
                                options: msg.options!,
                                onSelect: _handleOptionSelect,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.1),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              ),
              child: _isListening
                  ? _buildListeningBar(isDark)
                  : (_isInputMode
                        ? ChatInputArea(
                            key: const ValueKey("expanded"),
                            controller: _textController,
                            focusNode: _focusNode,
                            isTyping: _isTyping,
                            onSubmitted: _handleTextInput,
                            onVoiceTap: () {
                              _closeTextInput();
                              _startListening();
                            },
                            onClose: _closeTextInput,
                          )
                        : _buildCollapsedInputBar(isDark)),
            ),
          ],
        ),
      ),
    );
  }
}
