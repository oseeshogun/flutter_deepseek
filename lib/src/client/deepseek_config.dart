import 'package:http/http.dart' as http;

/// Configuration for [DeepSeekClient].
class DeepSeekConfig {
  const DeepSeekConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.deepseek.com',
    this.timeout = const Duration(seconds: 60),
    this.httpClient,
  });

  final String apiKey;
  final String baseUrl;
  final Duration timeout;
  final http.Client? httpClient;
}
