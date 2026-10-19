import 'dart:convert';

import 'package:flutter_deepseek/flutter_deepseek.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

ToolCall call(String name, String arguments, {String id = 'call_1'}) =>
    ToolCall(
      id: id,
      type: 'function',
      function: FunctionCall(name: name, arguments: arguments),
    );

void main() {
  late MockHttpClient mockClient;
  late DeepSeekClient client;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.deepseek.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    client = DeepSeekClient(apiKey: 'test-key', httpClient: mockClient);
  });

  tearDown(() => client.dispose());

  void stubPost(http.Response response) {
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((_) async => response);
  }

  group('ChatMessage tool calls', () {
    test('parses tool_calls from an assistant message', () {
      final message = ChatMessage.fromJson({
        'role': 'assistant',
        'content': null,
        'tool_calls': [
          {
            'id': 'call_1',
            'type': 'function',
            'function': {'name': 'web_search', 'arguments': '{"query":"x"}'},
          },
        ],
      });

      expect(message.content, '');
      expect(message.toolCalls, hasLength(1));
      expect(message.toolCalls!.first.id, 'call_1');
      expect(message.toolCalls!.first.function.name, 'web_search');
    });

    test('serializes tool_calls and tool results', () {
      final assistant = ChatMessage(
        role: 'assistant',
        content: '',
        toolCalls: [call('web_search', '{"query":"x"}')],
      );
      expect(assistant.toJson()['tool_calls'], hasLength(1));

      final tool =
          ChatMessage.tool(toolCallId: 'call_1', content: 'result').toJson();
      expect(tool['role'], 'tool');
      expect(tool['tool_call_id'], 'call_1');
      expect(
          ChatMessage.user('hi').toJson().containsKey('tool_calls'), isFalse);
    });
  });

  group('WebToolExecutor', () {
    test('exposes search only by default', () {
      final executor = WebToolExecutor(client);
      expect(executor.tools.map((t) => t.function.name), ['web_search']);
    });

    test('exposes fetch when enabled', () {
      final executor = WebToolExecutor(client, enableFetch: true);
      expect(executor.tools.map((t) => t.function.name),
          ['web_search', 'fetch_url']);
    });

    test('web_search returns truncated results with an untrusted note',
        () async {
      stubPost(http.Response(
        jsonEncode({
          'results': [
            {
              'title': 'T',
              'url': 'https://example.com',
              'snippet': 'snip',
              'content': 'a' * 50,
            },
          ],
        }),
        200,
      ));

      final out = jsonDecode(await WebToolExecutor(client, maxContentChars: 10)
          .execute(call('web_search', '{"query":"hello"}'))) as Map;

      expect(out['note'], contains('untrusted'));
      final result = (out['results'] as List).single as Map;
      expect(result['url'], 'https://example.com');
      expect((result['content'] as String).length, 10);

      final body = jsonDecode(verify(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured.single as String) as Map;
      expect(body['query'], 'hello');
      expect(body['need_content'], true);
      expect(body['count'], 5);
    });

    test('returns an error for malformed arguments without calling the API',
        () async {
      final executor = WebToolExecutor(client);

      for (final args in ['not json', '[]', '{}', '{"query":"  "}']) {
        final out =
            jsonDecode(await executor.execute(call('web_search', args))) as Map;
        expect(out, contains('error'), reason: args);
      }
      verifyNever(() => mockClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('rejects disabled and unknown tools', () async {
      final executor = WebToolExecutor(client);
      for (final name in ['fetch_url', 'rm_rf']) {
        final out = jsonDecode(await executor
            .execute(call(name, '{"url":"https://example.com"}'))) as Map;
        expect(out['error'], contains('Unknown tool'), reason: name);
      }
      verifyNever(() => mockClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));
    });

    test('fetch_url validates the scheme and fetches http(s) pages', () async {
      final executor = WebToolExecutor(client, enableFetch: true);

      final bad = jsonDecode(await executor
          .execute(call('fetch_url', '{"url":"file:///etc/passwd"}'))) as Map;
      expect(bad, contains('error'));
      verifyNever(() => mockClient.post(any(),
          headers: any(named: 'headers'), body: any(named: 'body')));

      stubPost(
          http.Response(jsonEncode({'title': 'Ex', 'content': '# Ex'}), 200));
      final ok = jsonDecode(await executor
          .execute(call('fetch_url', '{"url":"https://example.com"}'))) as Map;
      expect(ok['title'], 'Ex');
      expect(ok['content'], '# Ex');
    });

    test('lets API failures propagate', () async {
      stubPost(http.Response('{"error":{"message":"bad key"}}', 401));
      expect(
        () => WebToolExecutor(client)
            .execute(call('web_search', '{"query":"x"}')),
        throwsA(isA<DeepSeekAuthException>()),
      );
    });
  });
}
