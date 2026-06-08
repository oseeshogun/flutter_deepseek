/// Token usage statistics for a completion request.
class TokenUsage {
  /// Creates usage stats.
  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  /// Parses usage from a DeepSeek JSON object.
  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      promptTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
      completionTokens: (json['completion_tokens'] as num?)?.toInt() ?? 0,
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
    );
  }

  /// Tokens in the prompt.
  final int promptTokens;

  /// Tokens in the completion.
  final int completionTokens;

  /// Sum of prompt and completion tokens.
  final int totalTokens;

  /// Serializes usage to JSON.
  Map<String, dynamic> toJson() => {
        'prompt_tokens': promptTokens,
        'completion_tokens': completionTokens,
        'total_tokens': totalTokens,
      };
}
