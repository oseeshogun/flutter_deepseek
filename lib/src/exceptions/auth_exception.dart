import 'deepseek_exception.dart';

/// Thrown when authentication fails (HTTP 401).
class DeepSeekAuthException extends DeepSeekException {
  DeepSeekAuthException(String message) : super(401, message);

  @override
  String toString() => 'DeepSeekAuthException: $message';
}
