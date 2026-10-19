## 0.1.2

- Add `DeepSeekClient.search()` and `DeepSeekClient.fetch()` for DeepSeek's
  server-side web search and page fetch (`SearchResponse`, `SearchResult`,
  `FetchResponse`).
- Add `DeepSeekClient.chatWithTools()`, a bounded tool-calling loop that emits
  `ToolCallRequested`, `ToolCallCompleted` and `ChatAnswer` events.
- Add `ToolExecutor`, `WebToolExecutor` (search on, fetch off by default) and
  `CompositeToolExecutor`, plus ready-made `DeepSeekTools` definitions.
- Add `ChatMessage.tool()` and `ChatMessage.toolCalls` so tool exchanges can be
  kept in conversation history.
- Example and studio demo apps gain a web search toggle.
- Document web search, fetch and the tool-calling loop in the README.

## 0.1.1

- Shorten `pubspec.yaml` description for pub.dev search limits.
- Add dartdoc on public API for improved pub points.

## 0.1.0

- Initial release.
- Non-streaming and token-by-token `Stream<String>` chat completions.
- `deepseek-reasoner` support via `reason()`.
- Function calling with typed tools.
- `listModels()` and `getBalance()` utilities.
- Typed exceptions and full test coverage.
