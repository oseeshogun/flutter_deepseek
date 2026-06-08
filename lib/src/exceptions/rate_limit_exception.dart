import 'deepseek_exception.dart';

/// Thrown when rate limits are exceeded (HTTP 429).
class DeepSeekRateLimitException extends DeepSeekException {
  /// Creates a rate limit error.
  DeepSeekRateLimitException(String message) : super(429, message);

  @override
  String toString() => 'DeepSeekRateLimitException: $message';
}
