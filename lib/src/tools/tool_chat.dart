import '../client/deepseek_client.dart';
import '../models/function_call.dart';
import '../models/message.dart';
import 'tool_executor.dart';

/// An event emitted by [DeepSeekToolChat.chatWithTools].
sealed class ChatEvent {
  const ChatEvent();
}

/// The model asked to run [call]. Emitted before it runs.
class ToolCallRequested extends ChatEvent {
  /// Creates the event.
  const ToolCallRequested(this.call);

  /// The requested call.
  final ToolCall call;
}

/// [call] finished and [result] is being sent back to the model.
class ToolCallCompleted extends ChatEvent {
  /// Creates the event.
  const ToolCallCompleted(this.call, this.result);

  /// The call that ran.
  final ToolCall call;

  /// The text returned to the model.
  final String result;
}

/// The model's final answer. Always the last event of a successful run.
class ChatAnswer extends ChatEvent {
  /// Creates the event.
  const ChatAnswer(this.text, this.newMessages);

  /// The answer text.
  final String text;

  /// Every message produced during this turn, in order: assistant tool-call
  /// messages, tool results and the final assistant message.
  ///
  /// Append these to your history so later turns keep the context.
  final List<ChatMessage> newMessages;
}

/// Tool-calling loop on top of [DeepSeekClient.chat].
extension DeepSeekToolChat on DeepSeekClient {
  /// Chats with [executor]'s tools until the model gives a final answer.
  ///
  /// Each round is a non-streaming request. When the model asks for tools,
  /// they run through [executor] and their results are sent back.
  ///
  /// The loop is bounded because tool calls such as web search are billed:
  /// - [maxRounds] limits the number of requests that may offer tools. After
  ///   that, one last request is made without tools so the model must answer.
  /// - [maxToolCalls] limits the total number of tool calls. Calls beyond it
  ///   are answered with an error instead of being run.
  ///
  /// Emits [ToolCallRequested] and [ToolCallCompleted] while tools run, then
  /// a single [ChatAnswer]. Exceptions from [executor] and the API propagate
  /// through the stream. Cancel the subscription to stop between steps.
  Stream<ChatEvent> chatWithTools({
    required List<ChatMessage> messages,
    required ToolExecutor executor,
    String model = DeepSeekModel.chat,
    String? systemPrompt,
    double temperature = 1.0,
    int? maxTokens,
    int maxRounds = 3,
    int maxToolCalls = 6,
  }) async* {
    final tools = executor.tools;
    final history = [...messages];
    final produced = <ChatMessage>[];
    var toolCallsUsed = 0;

    // Rounds 1..maxRounds may use tools; the extra round forces an answer.
    for (var round = 0; round <= maxRounds; round++) {
      final canUseTools = round < maxRounds && tools.isNotEmpty;

      final response = await chat(
        messages: history,
        model: model,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        tools: canUseTools ? tools : null,
      );
      if (response.choices.isEmpty) {
        throw StateError('DeepSeek returned no choices.');
      }

      final message = response.choices.first.message;
      final calls = message.toolCalls ?? const <ToolCall>[];

      if (!canUseTools || calls.isEmpty) {
        final answer = ChatMessage.assistant(message.content);
        produced.add(answer);
        yield ChatAnswer(message.content, List.unmodifiable(produced));
        return;
      }

      history.add(message);
      produced.add(message);

      for (final call in calls) {
        yield ToolCallRequested(call);

        final String result;
        if (toolCallsUsed >= maxToolCalls) {
          result = '{"error":"Tool call limit reached. Answer with what you '
              'already know."}';
        } else {
          toolCallsUsed++;
          result = await executor.execute(call);
        }

        final toolMessage = ChatMessage.tool(
          toolCallId: call.id,
          name: call.function.name,
          content: result,
        );
        history.add(toolMessage);
        produced.add(toolMessage);
        yield ToolCallCompleted(call, result);
      }
    }
  }
}
