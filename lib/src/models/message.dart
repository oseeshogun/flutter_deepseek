class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.name,
    this.reasoningContent,
  });

  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);

  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
    );
  }

  final String role;
  final String content;
  final String? toolCallId;
  final String? name;
  final String? reasoningContent;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'role': role,
      'content': content,
    };
    if (toolCallId != null) map['tool_call_id'] = toolCallId;
    if (name != null) map['name'] = name;
    if (reasoningContent != null) {
      map['reasoning_content'] = reasoningContent;
    }
    return map;
  }
}
