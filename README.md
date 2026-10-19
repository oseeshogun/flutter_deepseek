# flutter_deepseek

[![pub package](https://img.shields.io/pub/v/flutter_deepseek.svg)](https://pub.dev/packages/flutter_deepseek)
[![likes](https://img.shields.io/pub/likes/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)
[![pub points](https://img.shields.io/pub/points/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)
[![downloads](https://img.shields.io/pub/dm/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)

The complete DeepSeek API client for Flutter — true token-by-token streaming, reasoner model support, function calling, and typed errors. Production-ready and actively maintained.

**Bring your own API key** — no hosted backend; developers use their own [DeepSeek](https://platform.deepseek.com) account.

## Demo

![Example app — streaming chat with BYOK](https://github.com/user-attachments/assets/734289ba-7aaf-48c4-8206-6c49397334b7)



## Table of contents

- [Why this package?](#why-this-package)
- [Installation](#installation)
- [Bring your own API key (BYOK)](#bring-your-own-api-key-byok)
- [Quick start](#quick-start--non-streaming)
- [Streaming](#quick-start--streaming)
- [Reasoner](#reasoner-model)
- [Function calling](#function-calling)
- [Web search & fetch](#web-search--fetch)
- [Tool-calling loop](#tool-calling-loop)
- [Storing the API key in your app](#storing-the-api-key-in-your-app)
- [Error handling](#error-handling)
- [Models & utilities](#models)
- [Example app](#example-app)
- [API reference](#api-reference)

## Why this package?

| Feature | flutter_deepseek | deepseek_api | deepseek_client |
|---------|-----------------|--------------|-----------------|
| True `Stream<String>` | ✅ | ❌ | ❌ |
| Reasoner model | ✅ | ❌ | ❌ |
| Function calling | ✅ | ❌ | ❌ |
| Maintained 2025 | ✅ | ❌ | ❌ |
| No Dio dependency | ✅ | ❌ | ✅ |
| Typed exceptions | ✅ | ✅ | ❌ |
| Test coverage | ✅ | ❌ | ❌ |

## Installation

Add `flutter_deepseek` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_deepseek: ^0.1.1
```

Then run:

```bash
flutter pub get
```

## Bring your own API key (BYOK)

This package **does not** ship an API key, proxy, or hosted backend. Every developer (and every app they ship) uses **their own** [DeepSeek API key](https://platform.deepseek.com/api_keys).

Typical flow:

1. Create a key on the DeepSeek platform (billing stays on that account).
2. Pass it into `DeepSeekClient(apiKey: ...)`.
3. In a real app, load the key from **your** UX—not from this repo—e.g. a Settings screen, `--dart-define=DEEPSEEK_API_KEY=...` for local dev, or `flutter_secure_storage` after the user pastes it once.

The **example app** mirrors that: it asks for a key at runtime and keeps it in memory only (nothing is sent to the package author). Copy that pattern or replace it with secure storage / env vars in your product.

**Do not** commit keys to git or hardcode them in open-source sample code.

## Storing the API key in your app

| Approach | When to use |
|----------|-------------|
| **Settings screen** | Apps where each user pastes their own key (same as the example). |
| **`--dart-define`** | Local dev: `flutter run --dart-define=DEEPSEEK_API_KEY=sk-...` and read via `String.fromEnvironment('DEEPSEEK_API_KEY')`. |
| **`flutter_secure_storage`** | Production BYOK — persist key encrypted on device. |
| **Your backend** | Optional: *your* server holds the key; Flutter calls your API instead of DeepSeek directly. |

```dart
const apiKey = String.fromEnvironment('DEEPSEEK_API_KEY');
final client = DeepSeekClient(apiKey: apiKey);
```

## Quick start — non-streaming

```dart
import 'package:flutter_deepseek/flutter_deepseek.dart';

final client = DeepSeekClient(apiKey: 'YOUR_API_KEY');

final response = await client.chat(
  messages: [ChatMessage.user('Explain Flutter in one sentence.')],
);

print(response.text);
client.dispose();
```

## Quick start — streaming

Token-by-token output for chat UIs:

```dart
final client = DeepSeekClient(apiKey: 'YOUR_API_KEY');
final buffer = StringBuffer();

await for (final token in client.chatStream(
  messages: [ChatMessage.user('Write a haiku about Dart.')],
)) {
  buffer.write(token);
  setState(() => _assistantText = buffer.toString());
}

client.dispose();
```

## Reasoner model

Use `deepseek-reasoner` for chain-of-thought plus final answer:

```dart
final result = await client.reason(
  prompt: 'What is 17 × 23? Show your reasoning.',
);

print('Thinking:\n${result.reasoningContent}');
print('Answer:\n${result.content}');
print('Tokens: ${result.usage.totalTokens}');
```

## Function calling

```dart
final tools = [
  DeepSeekTool(
    function: FunctionDefinition(
      name: 'get_weather',
      description: 'Get weather for a city',
      parameters: {
        'type': 'object',
        'properties': {
          'city': {'type': 'string'},
        },
        'required': ['city'],
      },
    ),
  ),
];

final response = await client.chat(
  messages: [ChatMessage.user('Weather in Lahore?')],
  tools: tools,
  toolChoice: 'auto',
);
```

## Web search & fetch

DeepSeek exposes server-side web tools. Call them directly:

```dart
final results = await client.search(
  'latest Flutter release',
  count: 5,
  needContent: true, // also return page content
);
for (final r in results.results) {
  print('${r.title} — ${r.url}');
}

final page = await client.fetch('https://flutter.dev');
print(page.content); // Markdown
```

`query` must be 1–128 characters and `count` between 1 and 50. `fetch` accepts
`http`/`https` URLs of at most 8192 characters. **Each successful request is
billed by DeepSeek** to your account.

## Tool-calling loop

`chatWithTools` runs the whole loop for you: it sends your tools, executes the
calls the model makes, sends the results back, and repeats until the model
answers. Give it a `ToolExecutor`; `WebToolExecutor` exposes `web_search` (and,
optionally, `fetch_url`) to the model:

```dart
final executor = WebToolExecutor(client); // search on, fetch off

await for (final event in client.chatWithTools(
  messages: [ChatMessage.user('Who won the latest F1 race?')],
  executor: executor,
)) {
  switch (event) {
    case ToolCallRequested(:final call):
      print('Running ${call.function.name}…');
    case ToolCallCompleted():
      break;
    case ChatAnswer(:final text, :final newMessages):
      print(text);
      history.addAll(newMessages); // keep context for the next turn
  }
}
```

Your own tools: implement `ToolExecutor` (`tools` + `execute`). Combine several
executors with `CompositeToolExecutor([WebToolExecutor(client), MyTools()])`;
a call goes to the first executor that declares that tool name.

Things to know:

- **Cost is bounded.** `maxRounds` (default 3) limits requests that may use
  tools, then one last request without tools forces an answer. `maxToolCalls`
  (default 6) caps total tool calls; extra calls get an error instead of running.
- **Fetching is off by default** (`enableFetch: false`) because it lets the model
  read pages you have not vetted.
- **Prompt injection.** Web results are returned with a note that they are
  untrusted data. This reduces, but does not remove, the risk that a page
  steers the model — don't give a web-enabled model tools with side effects
  you wouldn't trust a stranger to trigger.
- Each round is non-streaming. Exceptions from the API or your executor
  propagate through the stream.

## Error handling

```dart
try {
  await client.chat(messages: [ChatMessage.user('Hi')]);
} on DeepSeekAuthException catch (e) {
  // Invalid API key (401)
} on DeepSeekRateLimitException catch (e) {
  // Too many requests (429)
} on DeepSeekRequestException catch (e) {
  // Bad request (400)
} on DeepSeekServerException catch (e) {
  // Service unavailable (503)
} on DeepSeekNetworkException catch (e) {
  // Socket / timeout / client errors
} on DeepSeekException catch (e) {
  // Other API errors
}
```

## Models

| Constant | Model ID | Description |
|----------|----------|-------------|
| `DeepSeekModel.chat` | `deepseek-chat` | General chat |
| `DeepSeekModel.reasoner` | `deepseek-reasoner` | Chain-of-thought reasoning |

List available models from the API:

```dart
final models = await client.listModels();
```

Check account balance:

```dart
final balance = await client.getBalance();
print('${balance.currency} ${balance.totalBalance}');
```

## API reference

### `DeepSeekClient`

| Member | Description |
|--------|-------------|
| `DeepSeekClient({required apiKey, baseUrl, timeout, httpClient})` | Creates a client. Inject `httpClient` for tests. |
| `Future<ChatCompletionResponse> chat({...})` | Non-streaming chat completion. |
| `Stream<String> chatStream({...})` | SSE streaming; each event is a text token chunk. |
| `Future<ReasonerResponse> reason({required prompt, maxTokens})` | Reasoner model with separate reasoning and answer fields. |
| `Future<List<ModelInfo>> listModels()` | Lists models. |
| `Future<UserBalance> getBalance()` | Returns account balance. |
| `Future<SearchResponse> search(query, {count, needContent, oriQuestion, localization})` | Server-side web search (billed). |
| `Future<FetchResponse> fetch(url)` | Fetches a page as Markdown (billed). |
| `Stream<ChatEvent> chatWithTools({messages, executor, ...})` | Extension method: tool-calling loop. |
| `void dispose()` | Closes the underlying `http.Client` when owned by the client. |

### Key types

- `ChatMessage` — `user`, `assistant`, `system` factories; optional `toolCallId`, `name`.
- `ChatCompletionResponse` — `text` getter for the first assistant reply.
- `ReasonerResponse` — `reasoningContent`, `content`, `usage`.
- `DeepSeekTool` / `FunctionDefinition` — JSON-schema function tools.
- `TokenUsage`, `ModelInfo`, `UserBalance`, `StreamChunk`.
- `SearchResponse` / `SearchResult` / `FetchResponse` — web tool results.
- `ToolExecutor`, `WebToolExecutor`, `CompositeToolExecutor`, `DeepSeekTools` — tools for `chatWithTools`.
- `ChatEvent` (`ToolCallRequested`, `ToolCallCompleted`, `ChatAnswer`) — events from `chatWithTools`.
- `ChatMessage.tool(...)` and `ChatMessage.toolCalls` — tool messages in history.

## Example app

```bash
cd example
flutter pub get
flutter run
```

The example includes API key entry, model selector, streaming toggle, a web search toggle (`chatWithTools`), reasoner display, and error snackbars.

## Contributing

Issues and pull requests are welcome on [GitHub](https://github.com/HammadAhmad200/flutter_deepseek).

Please run before submitting:

```bash
dart analyze lib/
dart format lib/ test/
dart test
```

## License

MIT — see [LICENSE](LICENSE).

---

Built by Mohammad Hammad — [mhammad.app](https://mhammad.app)
