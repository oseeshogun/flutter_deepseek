import 'dart:io';

/// Base exception for all DeepSeek API errors.
class DeepSeekException extends HttpException {
  DeepSeekException(this.statusCode, String message) : super(message);

  final int statusCode;

  @override
  String toString() => 'DeepSeekException($statusCode): $message';
}

/// Thrown when the request body or parameters are invalid (HTTP 400).
class DeepSeekRequestException extends DeepSeekException {
  DeepSeekRequestException(String message) : super(400, message);
}

/// Thrown when the DeepSeek service is unavailable (HTTP 503).
class DeepSeekServerException extends DeepSeekException {
  DeepSeekServerException(String message) : super(503, message);
}
