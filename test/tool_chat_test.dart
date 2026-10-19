import 'dart:convert';

import 'package:flutter_deepseek/flutter_deepseek.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeExecutor implements ToolExecutor {
  final executed = <String>[];

  @override
  List<DeepSeekTool> get tools => [DeepSeekTools.webSearch];

  @override
  Future<String> execute(ToolCall call) async {
    executed.add(call.function.arguments);
    return '{"results":[]}';
  }
}

Map<String, dynamic> toolCallResponse(List<String> ids) => {
      'id': 'x',
      'created': 1,
      'choices': [
        {
          'index': 0,
          'finish_reason': 'tool_calls',
          'message': {
            'role': 'assistant',
            'content': null,
            'tool_calls': [
              for (final id in ids)
                {
                  'id': id,
                  'type': 'function',
                  'function': {
                    'name': 'web_search',
                    'arguments': '{"query":"$id"}',
                  },
                },
            ],
          },
        },
      ],
    };

Map<String, dynamic> answerResponse(String text) => {
      'id': 'x',
      'created': 1,
      'choices': [
        {
          'index': 0,
          'finish_reason': 'stop',
          'message': {'role': 'assistant', 'content': text},
        },
      ],
    };

void main() {
  late MockHttpClient mockClient;
  late DeepSeekClient client;
  late List<Map<String, dynamic>> requests;

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://api.deepseek.com'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    client = DeepSeekClient(apiKey: 'k', httpClient: mockClient);
    requests = [];
  });

  tearDown(() => client.dispose());

  /// Answers successive chat requests with [responses] and records bodies.
  void script(List<Map<String, dynamic>> responses) {
    var i = 0;
    when(() => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        )).thenAnswer((inv) async {
      requests.add(jsonDecode(inv.namedArguments[#body] as String)
          as Map<String, dynamic>);
      return http.Response(jsonEncode(responses[i++]), 200);
    });
  }

  test('answers directly when the model uses no tool', () async {
    script([answerResponse('Hi!')]);

    final events = await client.chatWithTools(
        messages: [ChatMessage.user('hello')],
        executor: FakeExecutor()).toList();

    expect(events, hasLength(1));
    final answer = events.single as ChatAnswer;
    expect(answer.text, 'Hi!');
    expect(answer.newMessages.single.role, 'assistant');
    expect(requests.single['tools'], isNotNull);
  });

  test('runs a tool, sends the result back, then answers', () async {
    script([
      toolCallResponse(['c1']),
      answerResponse('Found it')
    ]);
    final executor = FakeExecutor();

    final events = await client.chatWithTools(
        messages: [ChatMessage.user('news?')], executor: executor).toList();

    expect(events.map((e) => e.runtimeType), [
      ToolCallRequested,
      ToolCallCompleted,
      ChatAnswer,
    ]);
    expect(executor.executed, ['{"query":"c1"}']);

    final second = requests[1]['messages'] as List;
    expect(second.map((m) => m['role']), ['user', 'assistant', 'tool']);
    expect(second[1]['tool_calls'], hasLength(1));
    expect(second[2]['tool_call_id'], 'c1');

    final answer = events.last as ChatAnswer;
    expect(answer.newMessages.map((m) => m.role),
        ['assistant', 'tool', 'assistant']);
  });

  test('forces an answer without tools after maxRounds', () async {
    script([
      toolCallResponse(['a']),
      toolCallResponse(['b']),
      answerResponse('done'),
    ]);
    final executor = FakeExecutor();

    final events = await client.chatWithTools(
        messages: [ChatMessage.user('q')],
        executor: executor,
        maxRounds: 2).toList();

    expect(requests, hasLength(3));
    expect(requests[0]['tools'], isNotNull);
    expect(requests[1]['tools'], isNotNull);
    expect(requests[2].containsKey('tools'), isFalse);
    expect((events.last as ChatAnswer).text, 'done');
    expect(executor.executed, hasLength(2));
  });

  test('does not run tool calls beyond maxToolCalls', () async {
    script([
      toolCallResponse(['a', 'b', 'c']),
      answerResponse('ok')
    ]);
    final executor = FakeExecutor();

    final events = await client.chatWithTools(
        messages: [ChatMessage.user('q')],
        executor: executor,
        maxToolCalls: 1).toList();

    expect(executor.executed, ['{"query":"a"}']);
    final completed = events.whereType<ToolCallCompleted>().toList();
    expect(completed, hasLength(3));
    expect(completed[1].result, contains('limit reached'));
  });

  test('propagates API errors', () async {
    when(() => mockClient.post(any(),
            headers: any(named: 'headers'), body: any(named: 'body')))
        .thenAnswer(
            (_) async => http.Response('{"error":{"message":"no"}}', 401));

    expect(
      client.chatWithTools(
          messages: [ChatMessage.user('q')], executor: FakeExecutor()).toList(),
      throwsA(isA<DeepSeekAuthException>()),
    );
  });
}
