/// Metadata for a model from `GET /models`.
class ModelInfo {
  /// Creates model info.
  const ModelInfo({
    required this.id,
    this.object,
    this.created,
    this.ownedBy,
  });

  /// Parses a model entry from JSON.
  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String? ?? '',
      object: json['object'] as String?,
      created: (json['created'] as num?)?.toInt(),
      ownedBy: json['owned_by'] as String?,
    );
  }

  /// Model id string passed to chat requests.
  final String id;

  /// Object type from the API.
  final String? object;

  /// Unix creation timestamp when provided.
  final int? created;

  /// Owner field from the API.
  final String? ownedBy;
}

/// DeepSeek model identifier constants.
class DeepSeekModel {
  /// General-purpose chat model (`deepseek-chat`).
  static const String chat = 'deepseek-chat';

  /// Reasoning model with chain-of-thought (`deepseek-reasoner`).
  static const String reasoner = 'deepseek-reasoner';
}
