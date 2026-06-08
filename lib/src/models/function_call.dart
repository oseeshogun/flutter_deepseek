class FunctionDefinition {
  const FunctionDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  factory FunctionDefinition.fromJson(Map<String, dynamic> json) {
    return FunctionDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      parameters: (json['parameters'] as Map<String, dynamic>?) ?? {},
    );
  }

  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'parameters': parameters,
      };
}

class DeepSeekTool {
  const DeepSeekTool({
    this.type = 'function',
    required this.function,
  });

  factory DeepSeekTool.fromJson(Map<String, dynamic> json) {
    return DeepSeekTool(
      type: json['type'] as String? ?? 'function',
      function: FunctionDefinition.fromJson(
        json['function'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final String type;
  final FunctionDefinition function;

  Map<String, dynamic> toJson() => {
        'type': type,
        'function': function.toJson(),
      };
}

class FunctionCall {
  const FunctionCall({
    required this.name,
    required this.arguments,
  });

  factory FunctionCall.fromJson(Map<String, dynamic> json) {
    return FunctionCall(
      name: json['name'] as String? ?? '',
      arguments: json['arguments'] as String? ?? '',
    );
  }

  final String name;
  final String arguments;

  Map<String, dynamic> toJson() => {
        'name': name,
        'arguments': arguments,
      };
}

class ToolCall {
  const ToolCall({
    required this.id,
    required this.type,
    required this.function,
  });

  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'function',
      function: FunctionCall.fromJson(
        json['function'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final String id;
  final String type;
  final FunctionCall function;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'function': function.toJson(),
      };
}
