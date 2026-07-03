enum MessageType { text, options, recommendation, error }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final MessageType type;
  // 🔴 CHANGED: Now expects a list of maps, e.g., [{"label": "Fever", "icon": "thermometer"}]
  final List<Map<String, String>>? options;
  final Map<String, dynamic>? doctorData;
  final String? retryPayload;

  ChatMessage({
    required this.id,
    this.text = '',
    required this.isUser,
    this.type = MessageType.text,
    this.options,
    this.doctorData,
    this.retryPayload,
  });
}
