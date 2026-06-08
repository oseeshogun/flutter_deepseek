import 'dart:convert';

import '../models/stream_chunk.dart';

/// Parses Server-Sent Events lines from DeepSeek streaming responses.
class SseParser {
  const SseParser();

  /// Parses a single SSE `data:` payload (without the `data: ` prefix).
  ///
  /// Returns `null` when the stream should terminate (`[DONE]`).
  /// Returns optional empty chunk marker when JSON is valid but has no content.
  StreamChunk? parseDataLine(String data) {
    if (data == '[DONE]') return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return StreamChunk.fromJson(json);
    } catch (_) {
      return const StreamChunk(id: '', choices: []);
    }
  }

  /// Extracts token content from a parsed chunk, or null if empty.
  String? contentFromChunk(StreamChunk chunk) {
    if (chunk.choices.isEmpty) return null;
    final content = chunk.choices.first.delta.content;
    if (content == null || content.isEmpty) return null;
    return content;
  }

  /// Strips the `data: ` prefix from an SSE line, if present.
  String? lineToData(String line) {
    if (!line.startsWith('data: ')) return null;
    return line.substring(6).trim();
  }
}
