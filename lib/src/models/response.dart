import '../utils/json_utils.dart';
import 'message.dart';
import 'usage.dart';

/// A single completion choice returned by the API.
class Choice {
  /// Creates a choice.
  const Choice({
    required this.index,
    required this.message,
    required this.finishReason,
  });

  /// Parses a choice from JSON.
  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      index: (json['index'] as num?)?.toInt() ?? 0,
      message: ChatMessage.fromJson(
        json['message'] as Map<String, dynamic>? ?? {},
      ),
      finishReason: json['finish_reason'] as String? ?? '',
    );
  }

  /// Index of this choice in the response list.
  final int index;

  /// The assistant message for this choice.
  final ChatMessage message;

  /// Why generation stopped, e.g. `stop` or `length`.
  final String finishReason;
}

/// Non-streaming chat completion response.
class ChatCompletionResponse {
  /// Creates a response.
  const ChatCompletionResponse({
    required this.id,
    required this.choices,
    required this.usage,
    required this.created,
    this.model,
  });

  /// Parses a completion response from JSON.
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

  /// Unique completion id.
  final String id;

  /// Completion choices (usually one).
  final List<Choice> choices;

  /// Token usage for this request.
  final TokenUsage usage;

  /// When the completion was created.
  final DateTime created;

  /// Model id used for the completion.
  final String? model;

  /// First assistant reply text, or empty if there are no choices.
  String get text => choices.isNotEmpty ? choices.first.message.content : '';
}

/// Response from the [DeepSeekModel.reasoner] model.
class ReasonerResponse {
  /// Creates a reasoner result.
  const ReasonerResponse({
    required this.reasoningContent,
    required this.content,
    required this.usage,
  });

  /// Model chain-of-thought before the final answer.
  final String reasoningContent;

  /// Final assistant answer.
  final String content;

  /// Token usage for the request.
  final TokenUsage usage;
}
