import 'package:http/http.dart' as http;

/// Configuration for [DeepSeekClient].
class DeepSeekConfig {
  /// Creates client configuration.
  const DeepSeekConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.timeout = const Duration(seconds: 60),
    this.httpClient,
  });

  /// DeepSeek API key (Bearer token).
  final String apiKey;

  /// API base URL without trailing slash.
  final String baseUrl;

  /// Default timeout for HTTP calls.
  final Duration timeout;

  /// Optional injected HTTP client for tests.
  final http.Client? httpClient;
}
