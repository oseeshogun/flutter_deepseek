# flutter_deepseek example

Minimal chat app that shows how to integrate the package with **bring your own API key (BYOK)**.

## Run

```bash
cd example
flutter pub get
flutter run
```

## What it demonstrates

- API key field (in memory only — not persisted)
- Model picker: `deepseek-chat` / `deepseek-reasoner`
- Streaming toggle → `chatStream()` token-by-token UI
- Non-streaming → `chat()`
- Web search toggle → `chatWithTools()` with `WebToolExecutor` (non-streaming; each search is shown as a status line)
- Reasoner → `reason()` with reasoning + answer in one bubble
- `DeepSeekAuthException` / `DeepSeekRateLimitException` snackbars

## Copy into your project

1. Add `flutter_deepseek` to your app `pubspec.yaml`.
2. Reuse the streaming `StringBuffer` + `setState` pattern from `lib/main.dart`.
3. Move API key entry to Settings or `flutter_secure_storage`.

Parent package: [flutter_deepseek](https://github.com/HammadAhmad200/flutter_deepseek).
