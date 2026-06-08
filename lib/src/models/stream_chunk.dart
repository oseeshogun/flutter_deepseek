import 'usage.dart';

class StreamDelta {
  const StreamDelta({
    this.content,
    this.reasoningContent,
    this.role,
  });

  factory StreamDelta.fromJson(Map<String, dynamic> json) {
    return StreamDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      role: json['role'] as String?,
    );
  }

  final String? content;
  final String? reasoningContent;
  final String? role;
}

class StreamChoice {
  const StreamChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  factory StreamChoice.fromJson(Map<String, dynamic> json) {
    return StreamChoice(
      index: (json['index'] as num?)?.toInt() ?? 0,
      delta: StreamDelta.fromJson(
        json['delta'] as Map<String, dynamic>? ?? {},
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }

  final int index;
  final StreamDelta delta;
  final String? finishReason;
}

class StreamChunk {
  const StreamChunk({
    required this.id,
    required this.choices,
    this.usage,
  });

  factory StreamChunk.fromJson(Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>? ?? [];
    return StreamChunk(
      id: json['id'] as String? ?? '',
      choices: choicesJson
          .map((c) => StreamChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
      usage: json['usage'] != null
          ? TokenUsage.fromJson(json['usage'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final List<StreamChoice> choices;
  final TokenUsage? usage;

  /// Text delta from the first choice, if any.
  String? get contentDelta {
    if (choices.isEmpty) return null;
    return choices.first.delta.content;
  }
}
