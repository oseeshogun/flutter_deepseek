import '../utils/json_utils.dart';
import 'message.dart';
import 'usage.dart';

class Choice {
  const Choice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: (json['index'] as num?)?.toInt() ?? 0,
      message: ChatMessage.fromJson(
        json['message'] as Map<String, dynamic>? ?? {},
      ),
      finishReason: json['finish_reason'] as String? ?? '',
    );
  }

  final int index;
  final ChatMessage message;
  final String finishReason;
}

class ChatCompletionResponse {
  const ChatCompletionResponse({
    required this.id,
    required this.choices,
    required this.usage,
    required this.created,
    this.model,
  });

  factory ChatCompletionResponse.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>? ?? [];
    return ChatCompletionResponse(
      id: json['id'] as String? ?? '',
      choices: choicesJson
          .map((c) => Choice.fromJson(c as Map<String, dynamic>))
          .toList(),
      usage: TokenUsage.fromJson(
        json['usage'] as Map<String, dynamic>? ?? {},
      ),
      created: dateTimeFromEpochSeconds(json['created']),
      model: json['model'] as String?,
    );
  }

  final String id;
  final List<Choice> choices;
  final TokenUsage usage;
  final DateTime created;
  final String? model;

  String get text => choices.isNotEmpty ? choices.first.message.content : '';
}

class ReasonerResponse {
  const ReasonerResponse({
    required this.reasoningContent,
    required this.content,
    required this.usage,
  });

  final String reasoningContent;
  final String content;
  final TokenUsage usage;
}
