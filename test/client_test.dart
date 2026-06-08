import 'dart:convert';

import 'package:flutter_deepseek/flutter_deepseek.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;
  late DeepSeekClient client;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.deepseek.com'));
    registerFallbackValue(
        http.Request('GET', Uri.parse('https://example.com')));
  });

  setUp(() {
    mockClient = MockHttpClient();
    client = DeepSeekClient(
      apiKey: 'test-key',
      httpClient: mockClient,
    );
  });

  tearDown(() {
    client.dispose();
  });

  group('DeepSeekClient.chat', () {
    test('returns correct ChatCompletionResponse', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'id': 'chatcmpl-abc',
            'created': 1700000000,
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': 'Hello there'},
                'finish_reason': 'stop',
              },
            ],
            'usage': {
              'prompt_tokens': 5,
              'completion_tokens': 3,
              'total_tokens': 8,
            },
          }),
          200,
        ),
      );

      final response = await client.chat(
        messages: [ChatMessage.user('Hi')],
      );

      expect(response.id, 'chatcmpl-abc');
      expect(response.text, 'Hello there');
      expect(response.usage.totalTokens, 8);
    });
  });

  group('DeepSeekClient.chatStream', () {
    test('yields correct token sequence', () async {
      const sseBody = '''
data: {"id":"s1","choices":[{"index":0,"delta":{"content":"Hel"}}]}

data: {"id":"s1","choices":[{"index":0,"delta":{"content":"lo"}}]}

data: [DONE]

''';

      when(() => mockClient.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(utf8.encode(sseBody)),
          200,
          headers: {'content-type': 'text/event-stream'},
        ),
      );

      final tokens =
          await client.chatStream(messages: [ChatMessage.user('Hi')]).toList();

      expect(tokens, ['Hel', 'lo']);
    });
  });

  group('DeepSeekClient errors', () {
    test('401 throws DeepSeekAuthException', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Invalid API key'},
          }),
          401,
        ),
      );

      expect(
        () => client.chat(messages: [ChatMessage.user('Hi')]),
        throwsA(isA<DeepSeekAuthException>()),
      );
    });

    test('429 throws DeepSeekRateLimitException', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'error': {'message': 'Rate limit exceeded'},
          }),
          429,
        ),
      );

      expect(
        () => client.chat(messages: [ChatMessage.user('Hi')]),
        throwsA(isA<DeepSeekRateLimitException>()),
      );
    });

    test('network error throws DeepSeekException', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenThrow(http.ClientException('Connection failed'));

      expect(
        () => client.chat(messages: [ChatMessage.user('Hi')]),
        throwsA(isA<DeepSeekException>()),
      );
    });
  });
}
