# Record a demo GIF or video for pub.dev / GitHub

Use the **example app** so the recording matches what developers will run.

## Quick GIF (macOS)

1. Run the app:

   ```bash
   cd example
   flutter run
   ```

2. Enter **your** API key, enable **Stream**, send a short message.
3. Record the screen:
   - **macOS:** QuickTime → File → New Screen Recording, or `Cmd+Shift+5`
   - **iOS Simulator:** `xcrun simctl io booted recordVideo demo.mov`
4. Convert to GIF (smaller for README):

   ```bash
   # ffmpeg (install via brew install ffmpeg)
   ffmpeg -i demo.mov -vf "fps=12,scale=720:-1" -loop 0 doc/media/demo.gif
   ```

5. Commit `doc/media/demo.gif` and push to GitHub.
6. Link in root `README.md`:

   ```markdown
   ![Streaming demo](https://raw.githubusercontent.com/HammadAhmad200/flutter_deepseek/main/doc/media/demo.gif)
   ```

## Video (YouTube)

1. Record a 1–3 minute walkthrough: install → API key → streaming chat → reasoner.
2. Upload unlisted or public on YouTube.
3. Add to README:

   ```markdown
   ## Video walkthrough
   [Watch on YouTube](https://youtu.be/YOUR_ID)
   ```

## pub.dev screenshots (static PNG)

Screenshots are declared in `pubspec.yaml` under `screenshots:`.

Requirements:

- PNG or JPEG
- Paths inside the repo (e.g. `doc/screenshots/chat.png`)
- Short `description` per image

Re-run `flutter pub publish` after adding images.
