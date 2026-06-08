import 'function_call.dart';
import 'message.dart';

class ChatCompletionRequest {
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

  final List<ChatMessage> messages;
  final String model;
  final double temperature;
  final int? maxTokens;
  final double topP;
  final bool stream;
  final List<DeepSeekTool>? tools;
  final String? toolChoice;
  final Map<String, dynamic>? extra;

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
