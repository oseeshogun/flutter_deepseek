/// DeepSeek API client for Flutter.
///
/// Create a [DeepSeekClient] with your API key, then call [DeepSeekClient.chat]
/// or [DeepSeekClient.chatStream]. See the README for BYOK and examples.
library flutter_deepseek;

export 'src/client/deepseek_client.dart';
export 'src/client/deepseek_config.dart';
export 'src/exceptions/auth_exception.dart';
export 'src/exceptions/deepseek_exception.dart'
    show DeepSeekException, DeepSeekRequestException, DeepSeekServerException;
export 'src/exceptions/network_exception.dart';
export 'src/exceptions/rate_limit_exception.dart';
export 'src/models/balance.dart';
export 'src/models/function_call.dart';
export 'src/models/message.dart';
export 'src/models/model_info.dart';
export 'src/models/request.dart';
export 'src/models/response.dart';
export 'src/models/stream_chunk.dart';
export 'src/models/usage.dart';
export 'src/utils/sse_parser.dart';
