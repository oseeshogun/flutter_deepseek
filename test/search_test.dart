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

  group('DeepSeekClient.search', () {
    test('posts the query and parses results', () async {
      stubPost(http.Response(
        jsonEncode({
          'results': [
            {
              'rerank_score': 2.4,
              'title': 'DeepSeek V4 model released',
              'url': 'https://example.com/deepseek-v4',
              'snippet': 'snippet',
              'summary': 'summary',
              'content': 'content',
              'site_name': 'Example News',
              'site_icon': null,
              'date': '2026-06-01T00:00:00+00:00',
              'authority': 3,
            },
          ],
        }),
        200,
      ));

      final response =
          await client.search('DeepSeek V4', count: 5, needContent: true);

      expect(response.results, hasLength(1));
      final result = response.results.first;
      expect(result.title, 'DeepSeek V4 model released');
      expect(result.url, 'https://example.com/deepseek-v4');
      expect(result.content, 'content');
      expect(result.rerankScore, 2.4);
      expect(result.siteIcon, isNull);
      expect(result.authority, 3);

      final captured = verify(() => mockClient.post(
            captureAny(),
            headers: captureAny(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      expect(
          captured[0].toString(), 'https://api.deepseek.com/v1/tools/search');
      expect((captured[1] as Map)['Authorization'], 'Bearer test-key');
      expect(jsonDecode(captured[2] as String), {
        'query': 'DeepSeek V4',
        'count': 5,
        'need_content': true,
      });
    });

    test('returns an empty list when there are no results', () async {
      stubPost(http.Response(jsonEncode({'results': []}), 200));
      expect((await client.search('nothing')).results, isEmpty);
    });

    test('throws DeepSeekAuthException on 401', () async {
      stubPost(http.Response(
        jsonEncode({
          'error': {'message': 'bad key'},
        }),
        401,
      ));
      expect(
        () => client.search('x'),
        throwsA(isA<DeepSeekAuthException>()),
      );
    });

    test('throws DeepSeekException with status on 402', () async {
      stubPost(http.Response('{"error":{"message":"no balance"}}', 402));
      expect(
        () => client.search('x'),
        throwsA(isA<DeepSeekException>()
            .having((e) => e.statusCode, 'statusCode', 402)),
      );
    });
  });

  group('DeepSeekClient.fetch', () {
    test('posts the url and parses the page', () async {
      stubPost(http.Response(
        jsonEncode({'title': 'Example', 'content': '# Example'}),
        200,
      ));

      final response = await client.fetch('https://example.com');

      expect(response.title, 'Example');
      expect(response.content, '# Example');
      final captured = verify(() => mockClient.post(
            captureAny(),
            headers: any(named: 'headers'),
            body: captureAny(named: 'body'),
          )).captured;
      expect(captured[0].toString(), 'https://api.deepseek.com/v1/tools/fetch');
      expect(jsonDecode(captured[1] as String), {'url': 'https://example.com'});
    });

    test('throws DeepSeekRateLimitException on 429', () async {
      stubPost(http.Response('{"error":{"message":"slow down"}}', 429));
      expect(
        () => client.fetch('https://example.com'),
        throwsA(isA<DeepSeekRateLimitException>()),
      );
    });
  });
}
