import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../exceptions/auth_exception.dart';
import '../exceptions/deepseek_exception.dart';
import '../exceptions/network_exception.dart';
import '../exceptions/rate_limit_exception.dart';
import '../models/balance.dart';
import '../models/function_call.dart';
import '../models/message.dart';
import '../models/model_info.dart';
import '../models/request.dart';
import '../models/response.dart';
import '../utils/sse_parser.dart';
import 'deepseek_config.dart';

export '../models/model_info.dart' show DeepSeekModel;

/// Client for the DeepSeek chat completions and utility API.
class DeepSeekClient {
  /// Creates a client.
  ///
  /// Pass [httpClient] to inject a mock in tests. Call [dispose] when done.
  DeepSeekClient({
    required String apiKey,
    String baseUrl = 'https://api.deepseek.com',
    Duration timeout = const Duration(seconds: 60),
    http.Client? httpClient,
  }) : _config = DeepSeekConfig(
          apiKey: apiKey,
          baseUrl: baseUrl,
          timeout: timeout,
          httpClient: httpClient,
        ) {
    _ownsClient = httpClient == null;
    _httpClient = httpClient ?? http.Client();
  }

  final DeepSeekConfig _config;
  late final http.Client _httpClient;
  late final bool _ownsClient;
  final SseParser _sseParser = const SseParser();

  String get _baseUrl => _config.baseUrl.endsWith('/')
      ? _config.baseUrl.substring(0, _config.baseUrl.length - 1)
      : _config.baseUrl;

  Map<String, String> get _authHeaders => {
        'Authorization': 'Bearer ${_config.apiKey}',
        'Content-Type': 'application/json',
      };

  List<ChatMessage> _withSystemPrompt(
    List<ChatMessage> messages,
    String? systemPrompt,
  ) {
    if (systemPrompt == null || systemPrompt.isEmpty) {
      return messages;
    }
    return [
      ChatMessage.system(systemPrompt),
      ...messages,
    ];
  }

  Map<String, dynamic> _buildChatBody({
    required List<ChatMessage> messages,
    required String model,
    required double temperature,
    required int? maxTokens,
    required double topP,
    required bool stream,
    List<DeepSeekTool>? tools,
    String? toolChoice,
    Map<String, dynamic>? extra,
  }) {
    final request = ChatCompletionRequest(
      messages: messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: stream,
      tools: tools,
      toolChoice: toolChoice,
      extra: extra,
    );
    return request.toJson();
  }

  /// Sends a non-streaming chat completion request.
  Future<ChatCompletionResponse> chat({
    required List<ChatMessage> messages,
    String model = DeepSeekModel.chat,
    double temperature = 1.0,
    int? maxTokens,
    double topP = 1.0,
    String? systemPrompt,
    List<DeepSeekTool>? tools,
    String? toolChoice,
    Map<String, dynamic>? extra,
  }) async {
    final body = _buildChatBody(
      messages: _withSystemPrompt(messages, systemPrompt),
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: false,
      tools: tools,
      toolChoice: toolChoice,
      extra: extra,
    );

    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/chat/completions'),
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(_config.timeout);

      if (response.statusCode != 200) {
        _handleError(response.statusCode, response.body);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return ChatCompletionResponse.fromJson(json);
    } on DeepSeekException {
      rethrow;
    } on SocketException catch (e) {
      throw DeepSeekNetworkException(e.message);
    } on TimeoutException {
      throw DeepSeekNetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw DeepSeekNetworkException(e.message);
    }
  }

  /// Streams assistant text token-by-token as each SSE chunk arrives.
  Stream<String> chatStream({
    required List<ChatMessage> messages,
    String model = DeepSeekModel.chat,
    double temperature = 1.0,
    int? maxTokens,
    double topP = 1.0,
    String? systemPrompt,
    List<DeepSeekTool>? tools,
  }) async* {
    final body = _buildChatBody(
      messages: _withSystemPrompt(messages, systemPrompt),
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      topP: topP,
      stream: true,
      tools: tools,
    );

    http.StreamedResponse response;
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/chat/completions'),
      );
      request.headers.addAll({
        ..._authHeaders,
        'Accept': 'text/event-stream',
      });
      request.body = jsonEncode(body);

      response = await _httpClient.send(request).timeout(_config.timeout);
    } on SocketException catch (e) {
      throw DeepSeekNetworkException(e.message);
    } on TimeoutException {
      throw DeepSeekNetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw DeepSeekNetworkException(e.message);
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      _handleError(response.statusCode, errorBody);
    }

    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())) {
      final data = _sseParser.lineToData(line);
      if (data == null) continue;

      if (data == '[DONE]') return;

      try {
        final chunk = _sseParser.parseDataLine(data);
        if (chunk == null) return;
        final content = _sseParser.contentFromChunk(chunk);
        if (content != null) {
          yield content;
        }
      } catch (_) {
        continue;
      }
    }
  }

  /// Runs [DeepSeekModel.reasoner] and splits reasoning from the final answer.
  Future<ReasonerResponse> reason({
    required String prompt,
    int? maxTokens,
  }) async {
    final response = await chat(
      messages: [ChatMessage.user(prompt)],
      model: DeepSeekModel.reasoner,
      maxTokens: maxTokens,
    );

    final message =
        response.choices.isNotEmpty ? response.choices.first.message : null;

    return ReasonerResponse(
      reasoningContent: message?.reasoningContent ?? '',
      content: message?.content ?? '',
      usage: response.usage,
    );
  }

  /// Lists models available to your API key.
  Future<List<ModelInfo>> listModels() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/models'),
            headers: _authHeaders,
          )
          .timeout(_config.timeout);

      if (response.statusCode != 200) {
        _handleError(response.statusCode, response.body);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as List<dynamic>? ?? [];
      return data
          .map((m) => ModelInfo.fromJson(m as Map<String, dynamic>))
          .toList();
    } on DeepSeekException {
      rethrow;
    } on SocketException catch (e) {
      throw DeepSeekNetworkException(e.message);
    } on TimeoutException {
      throw DeepSeekNetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw DeepSeekNetworkException(e.message);
    }
  }

  /// Returns the current account balance.
  Future<UserBalance> getBalance() async {
    try {
      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/user/balance'),
            headers: _authHeaders,
          )
          .timeout(_config.timeout);

      if (response.statusCode != 200) {
        _handleError(response.statusCode, response.body);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserBalance.fromJson(json);
    } on DeepSeekException {
      rethrow;
    } on SocketException catch (e) {
      throw DeepSeekNetworkException(e.message);
    } on TimeoutException {
      throw DeepSeekNetworkException('Request timed out');
    } on http.ClientException catch (e) {
      throw DeepSeekNetworkException(e.message);
    }
  }

  /// Closes the owned [http.Client] when this client created it.
  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  Never _handleError(int statusCode, String body) {
    String message = 'Unknown error';
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message =
          (json['error'] as Map<String, dynamic>?)?['message'] as String? ??
              message;
    } catch (_) {
      if (body.isNotEmpty) message = body;
    }

    switch (statusCode) {
      case 401:
        throw DeepSeekAuthException(message);
      case 429:
        throw DeepSeekRateLimitException(message);
      case 400:
        throw DeepSeekRequestException(message);
      case 503:
        throw DeepSeekServerException(message);
      default:
        throw DeepSeekException(statusCode, message);
    }
  }
}
