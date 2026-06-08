import 'dart:io';

/// Base exception for all DeepSeek API errors.
class DeepSeekException extends HttpException {
  /// Creates an exception with [statusCode] and [message].
  DeepSeekException(this.statusCode, String message) : super(message);

  /// HTTP status code, or `0` for network failures.
  final int statusCode;

  @override
  String toString() => 'DeepSeekException($statusCode): $message';
}

/// Thrown when the request body or parameters are invalid (HTTP 400).
class DeepSeekRequestException extends DeepSeekException {
  /// Creates a 400 request error.
  DeepSeekRequestException(String message) : super(400, message);
}

/// Thrown when the DeepSeek service is unavailable (HTTP 503).
class DeepSeekServerException extends DeepSeekException {
  /// Creates a 503 server error.
  DeepSeekServerException(String message) : super(503, message);
}
