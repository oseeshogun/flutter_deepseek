import 'function_call.dart';
import 'message.dart';

/// Request body for the `/chat/completions` endpoint.
class ChatCompletionRequest {
  /// Creates a chat completion request.
  const ChatCompletionRequest({
    required this.messages,
    required this.model,
    this.temperature = 1.0,
    this.maxTokens,
    this.topP = 1.0,
    this.stream = false,
    this.tools,
    this.toolChoice,
    this.extra,
  });

  /// Conversation messages sent to the model.
  final List<ChatMessage> messages;

  /// Model id, e.g. [DeepSeekModel.chat].
  final String model;

  /// Sampling temperature between 0 and 2.
  final double temperature;

  /// Maximum tokens to generate.
  final int? maxTokens;

  /// Nucleus sampling parameter.
  final double topP;

  /// Whether to stream the response as SSE.
  final bool stream;

  /// Optional function tools for tool calling.
  final List<DeepSeekTool>? tools;

  /// Tool choice mode or named tool.
  final String? toolChoice;

  /// Extra JSON fields merged into the request body.
  final Map<String, dynamic>? extra;

  /// Converts this request to JSON for the HTTP body.
  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'top_p': topP,
      'stream': stream,
    };
    if (maxTokens != null) body['max_tokens'] = maxTokens;
    if (tools != null && tools!.isNotEmpty) {
      body['tools'] = tools!.map((t) => t.toJson()).toList();
    }
    if (toolChoice != null) body['tool_choice'] = toolChoice;
    if (extra != null) body.addAll(extra!);
    return body;
  }
}
