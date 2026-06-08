# Publish `flutter_deepseek` to pub.dev

Step-by-step for **you** (the package author). Developers who *use* the package only run `flutter pub add flutter_deepseek`.

## Before you publish

### 1. Pub.dev account

1. Open [https://pub.dev](https://pub.dev) and sign in with Google.
2. Complete publisher setup if prompted ([verified publisher](https://dart.dev/tools/pub/verified-publishers) is optional but helps trust).

### 2. Log in from the CLI

```bash
dart pub login
```

Follow the browser flow. You only need this once per machine.

### 3. GitHub repo is public

pub.dev links `homepage` / `repository` to GitHub. Push all package files:

- `lib/`, `test/`, `example/`, `README.md`, `CHANGELOG.md`, `LICENSE`, `pubspec.yaml`

Commit and push before publishing so README images and docs match what users see.

### 4. Pre-flight checks (run in package root)

```bash
flutter pub get
dart format lib/ test/
dart analyze lib/
flutter test
flutter pub publish --dry-run
```

Fix anything the dry-run reports. Archive size should be **well under 1 MB** (no `build/` folder).

### 5. Version and changelog

For every publish:

1. Bump `version:` in `pubspec.yaml` (semver: `0.1.1`, `0.2.0`, `1.0.0`, …).
2. Add a dated section to `CHANGELOG.md`.

You cannot re-upload the same version.

## Publish

From the package root (not `example/`):

```bash
flutter pub publish
```

Type `y` when asked to confirm. First publish may take a minute to appear on [pub.dev/packages/flutter_deepseek](https://pub.dev/packages/flutter_deepseek).

## After publish

1. Tag the release: `git tag v0.1.0 && git push origin v0.1.0`
2. Optional: GitHub **Release** with notes from `CHANGELOG.md`
3. Attach a **demo GIF** to the release (see `doc/media/HOW_TO_RECORD.md`)

## GIFs and videos (for developers on pub.dev)

pub.dev does **not** host video files inside the package. Use:

| Where | What to add |
|--------|-------------|
| **README.md** (shown on pub.dev) | GIF via GitHub URL, e.g. `doc/media/demo.gif` committed to repo |
| **pubspec `screenshots`** | PNG/JPEG paths (shown on package page) |
| **GitHub README / Releases** | Full GIF or MP4 walkthrough |
| **YouTube** | Link in README: “Watch setup (2 min)” |

After you record a real GIF from the example app, update README:

```markdown
![Streaming demo](https://raw.githubusercontent.com/HammadAhmad200/flutter_deepseek/main/doc/media/demo.gif)
```

Replace the placeholder screenshot until then.

## What developers see on pub.dev

- **Description** — from `pubspec.yaml`
- **README** — install, BYOK, streaming examples
- **Scores** — tests, analysis, documentation (keep `flutter test` green)
- **Example** — tab pointing at `example/`
- **Topics** — `deepseek`, `ai`, `llm`, etc.

## Common rejections

| Issue | Fix |
|--------|-----|
| `publish_to: 'none'` | Remove that line from `pubspec.yaml` |
| Huge package size | Add `build/`, `.dart_tool/` to `.pubignore` |
| Missing LICENSE | Keep MIT `LICENSE` file |
| API key in repo | Never commit keys; BYOK only |
| Name taken | Package name must be unique on pub.dev |

## Ongoing maintenance

- Respond to issues on GitHub
- Bump version + changelog for fixes/features
- Re-run `flutter pub publish` for each release

---

Built by Mohammad Hammad — [mhammad.app](https://mhammad.app)
