# flutter_deepseek

[![pub package](https://img.shields.io/pub/v/flutter_deepseek.svg)](https://pub.dev/packages/flutter_deepseek)
[![likes](https://img.shields.io/pub/likes/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)
[![pub points](https://img.shields.io/pub/points/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)
[![downloads](https://img.shields.io/pub/dm/flutter_deepseek)](https://pub.dev/packages/flutter_deepseek/score)

The complete DeepSeek API client for Flutter — true token-by-token streaming, reasoner model support, function calling, and typed errors. Production-ready and actively maintained.

**Bring your own API key** — no hosted backend; developers use their own [DeepSeek](https://platform.deepseek.com) account.

## Demo

![Example app — streaming chat with BYOK](https://raw.githubusercontent.com/HammadAhmad200/flutter_deepseek/main/doc/screenshots/chat_streaming.png)

> Replace this with a real screen recording GIF after you run the example app — see [doc/media/HOW_TO_RECORD.md](doc/media/HOW_TO_RECORD.md). On pub.dev, use a GitHub `raw` URL once `doc/media/demo.gif` is committed.

## Table of contents

- [Why this package?](#why-this-package)
- [Installation](#installation)
- [Bring your own API key (BYOK)](#bring-your-own-api-key-byok)
- [Quick start](#quick-start--non-streaming)
- [Streaming](#quick-start--streaming)
- [Reasoner](#reasoner-model)
- [Function calling](#function-calling)
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
| `void dispose()` | Closes the underlying `http.Client` when owned by the client. |

### Key types

- `ChatMessage` — `user`, `assistant`, `system` factories; optional `toolCallId`, `name`.
- `ChatCompletionResponse` — `text` getter for the first assistant reply.
- `ReasonerResponse` — `reasoningContent`, `content`, `usage`.
- `DeepSeekTool` / `FunctionDefinition` — JSON-schema function tools.
- `TokenUsage`, `ModelInfo`, `UserBalance`, `StreamChunk`.

## Example app

```bash
cd example
flutter pub get
flutter run
```

The example includes API key entry, model selector, streaming toggle, reasoner display, and error snackbars.

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
