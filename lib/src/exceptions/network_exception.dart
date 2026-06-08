import 'deepseek_exception.dart';

/// Thrown when a network-level failure occurs before a valid HTTP response.
class DeepSeekNetworkException extends DeepSeekException {
  /// Creates a network error with [statusCode] `0`.
  DeepSeekNetworkException(String message) : super(0, message);

  @override
  String toString() => 'DeepSeekNetworkException: $message';
}
