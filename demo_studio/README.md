# flutter_deepseek Studio Demo

Polished chat UI for **recording marketing demos** of the [flutter_deepseek](https://pub.dev/packages/flutter_deepseek) package.

## Setup

1. Add your API key:

   ```bash
   cp lib/secrets.example.dart lib/secrets.dart
   ```

   Edit `lib/secrets.dart` and set `kDeepSeekApiKey`.

2. Run:

   ```bash
   cd demo_studio
   flutter pub get
   flutter run
   ```

## LinkedIn record mode

Turn on capture overlays (badge, code strip, compact layout, blinking stream cursor):

- Tap the **camera** icon in the app bar, or
- Launch with:

  ```bash
  flutter run --dart-define=RECORD_MODE=true
  ```

Then record **5–10s of video** while a reply is **still streaming** (partial text + blinking `▍`).

## Web search

Tap the **Search** chip to let the model call `web_search` through
`chatWithTools` and `WebToolExecutor`. Each search shows up as an italic status
line before the answer. Search is non-streaming, so **Stream** is disabled while
it is on, and it is unavailable for the reasoner model. DeepSeek bills each
search to your account.

## Recording tips

- **Video first** — stream a prompt live; pause mid-response for screenshots.
- Keep **Stream** ON and **Record mode** ON for LinkedIn assets.
- Crop to ~4:5 or 9:16 for mobile feed if needed in your editor.
- Debug banner is already hidden.

## Package dependency

Uses `flutter_deepseek` via path `../` while developing the monorepo. For a standalone clone, switch `pubspec.yaml` to:

```yaml
flutter_deepseek: ^0.1.2
```
