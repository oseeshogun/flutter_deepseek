import 'package:flutter_deepseek/flutter_deepseek.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models', () {
    test('ChatMessage.user sets role correctly', () {
      final message = ChatMessage.user('Hi');
      expect(message.role, 'user');
      expect(message.content, 'Hi');
    });

    test('ChatCompletionResponse.text getter works', () {
      final response = ChatCompletionResponse(
        id: 'id-1',
        choices: [
          Choice(
            index: 0,
            message: ChatMessage.assistant('Answer'),
            finishReason: 'stop',
          ),
        ],
        usage: const TokenUsage(
          promptTokens: 1,
          completionTokens: 2,
          totalTokens: 3,
        ),
        created: DateTime.utc(2024, 1, 1),
      );
      expect(response.text, 'Answer');
    });

    test('TokenUsage parses correctly', () {
      final usage = TokenUsage.fromJson({
        'prompt_tokens': 10,
        'completion_tokens': 20,
        'total_tokens': 30,
      });
      expect(usage.promptTokens, 10);
      expect(usage.completionTokens, 20);
      expect(usage.totalTokens, 30);
    });
  });
}
