import 'function_call.dart';

/// A chat message in a DeepSeek conversation.
class ChatMessage {
  /// Creates a message with the given [role] and [content].
  const ChatMessage({
    required this.role,
    required this.content,
    this.toolCallId,
    this.name,
    this.reasoningContent,
    this.toolCalls,
  });

  /// User message factory.
  factory ChatMessage.user(String content) =>
      ChatMessage(role: 'user', content: content);

  /// Assistant message factory.
  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: 'assistant', content: content);

  /// Tool result message answering the call identified by [toolCallId].
  factory ChatMessage.tool({
    required String toolCallId,
    required String content,
    String? name,
  }) =>
      ChatMessage(
        role: 'tool',
        content: content,
        toolCallId: toolCallId,
        name: name,
      );

  /// System message factory.
  factory ChatMessage.system(String content) =>
      ChatMessage(role: 'system', content: content);

  /// Parses a message from DeepSeek JSON.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      toolCallId: json['tool_call_id'] as String?,
      name: json['name'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      toolCalls: (json['tool_calls'] as List<dynamic>?)
          ?.map((c) => ToolCall.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Message role: `user`, `assistant`, `system`, or `tool`.
  final String role;

  /// Text content of the message.
  final String content;

  /// Tool call id when [role] is `tool`.
  final String? toolCallId;

  /// Optional participant name.
  final String? name;

  /// Chain-of-thought text for the reasoner model.
  final String? reasoningContent;

  /// Tool calls requested by the assistant, if any.
  ///
  /// An assistant message carrying tool calls must be sent back in the
  /// history, followed by one [ChatMessage.tool] per call.
  final List<ToolCall>? toolCalls;

  /// Serializes this message for the API request body.
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
    if (toolCalls != null && toolCalls!.isNotEmpty) {
      map['tool_calls'] = toolCalls!.map((c) => c.toJson()).toList();
    }
    return map;
  }
}
