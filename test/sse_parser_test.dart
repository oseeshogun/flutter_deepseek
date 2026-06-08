import 'package:flutter_deepseek/flutter_deepseek.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SseParser', () {
    const parser = SseParser();

    test('parse valid SSE line yields correct StreamChunk', () {
      const payload = '''
{"id":"cmpl-1","choices":[{"index":0,"delta":{"content":"Hello"}}]}
''';
      final chunk = parser.parseDataLine(payload.trim());
      expect(chunk, isNotNull);
      expect(chunk!.id, 'cmpl-1');
      expect(parser.contentFromChunk(chunk), 'Hello');
    });

    test('[DONE] terminates stream', () {
      expect(parser.parseDataLine('[DONE]'), isNull);
    });

    test('malformed line is skipped gracefully', () {
      final chunk = parser.parseDataLine('{not-json');
      expect(parser.contentFromChunk(chunk!), isNull);
    });

    test('empty delta is not yielded as content', () {
      const payload =
          '{"id":"x","choices":[{"index":0,"delta":{"content":""}}]}';
      final chunk = parser.parseDataLine(payload);
      expect(parser.contentFromChunk(chunk!), isNull);
    });

    test('lineToData strips data prefix', () {
      expect(
        parser.lineToData('data: {"id":"1","choices":[]}'),
        '{"id":"1","choices":[]}',
      );
      expect(parser.lineToData('event: ping'), isNull);
    });
  });
}
