import 'deepseek_exception.dart';

/// Thrown when rate limits are exceeded (HTTP 429).
class DeepSeekRateLimitException extends DeepSeekException {
  DeepSeekRateLimitException(String message) : super(429, message);

  @override
  String toString() => 'DeepSeekRateLimitException: $message';
}
