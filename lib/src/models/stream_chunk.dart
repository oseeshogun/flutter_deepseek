import 'usage.dart';

/// Incremental message fields in a streaming chunk.
class StreamDelta {
  /// Creates a stream delta.
  const StreamDelta({
    this.content,
    this.reasoningContent,
    this.role,
  });

  /// Parses a delta object from JSON.
  factory StreamDelta.fromJson(Map<String, dynamic> json) {
    return StreamDelta(
      content: json['content'] as String?,
      reasoningContent: json['reasoning_content'] as String?,
      role: json['role'] as String?,
    );
  }

  /// Partial assistant content token(s).
  final String? content;

  /// Partial reasoning content for the reasoner model.
  final String? reasoningContent;

  /// Role field when present on the first chunk.
  final String? role;
}

/// One streaming choice with a [StreamDelta].
class StreamChoice {
  /// Creates a streaming choice.
  const StreamChoice({
    required this.index,
    required this.delta,
    this.finishReason,
  });

  /// Parses a streaming choice from JSON.
  factory StreamChoice.fromJson(Map<String, dynamic> json) {
    return StreamChoice(
      index: (json['index'] as num?)?.toInt() ?? 0,
      delta: StreamDelta.fromJson(
        json['delta'] as Map<String, dynamic>? ?? {},
      ),
      finishReason: json['finish_reason'] as String?,
    );
  }

  /// Choice index.
  final int index;

  /// Token delta for this chunk.
  final StreamDelta delta;

  /// Present on the final chunk when generation ends.
  final String? finishReason;
}

/// One Server-Sent Events JSON payload from a streaming completion.
class StreamChunk {
  /// Creates a stream chunk.
  const StreamChunk({
    required this.id,
    required this.choices,
    this.usage,
  });

  /// Parses a chunk from SSE JSON.
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

  /// Completion id for this stream.
  final String id;

  /// Streaming choices in this chunk.
  final List<StreamChoice> choices;

  /// Usage stats on the optional final usage chunk.
  final TokenUsage? usage;

  /// Text delta from the first choice, if any.
  String? get contentDelta {
    if (choices.isEmpty) return null;
    return choices.first.delta.content;
  }
}
