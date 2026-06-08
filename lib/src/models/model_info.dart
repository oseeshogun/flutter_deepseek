class ModelInfo {
  const ModelInfo({
    required this.id,
    this.object,
    this.created,
    this.ownedBy,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json) {
    return ModelInfo(
      id: json['id'] as String? ?? '',
      object: json['object'] as String?,
      created: (json['created'] as num?)?.toInt(),
      ownedBy: json['owned_by'] as String?,
    );
  }

  final String id;
  final String? object;
  final int? created;
  final String? ownedBy;
}

/// DeepSeek model identifier constants.
class DeepSeekModel {
  static const String chat = 'deepseek-chat';
  static const String reasoner = 'deepseek-reasoner';
}
