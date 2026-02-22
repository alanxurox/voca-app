# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture (Do Not Refactor)

3-layer parallel project:

1. **VocaApp.xcodeproj** — Xcode project for signing, entitlements, Sparkle framework linking, release builds. Entry: `VocaApp/main.swift`
2. **Package.swift (VocaLib)** — SPM library wrapping all Swift source in `Voca/`. Used for `swift build` and AI editing. `swift build` will fail on Sparkle imports — use xcodebuild for full builds.
3. **VoicePipeline.xcframework + libonnxruntime** — KMP-built ASR engine. Swift calls it via `import VoicePipeline` → `ASREngine`.

**New Swift files must be added to BOTH Package.swift and VocaApp.xcodeproj.**

## Build

```bash
# Full build (use this)
xcodebuild build -project VocaApp.xcodeproj -scheme Voca -configuration Debug CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO

# Release: tag triggers CI
git tag v1.x.x && git push upstream v1.x.x
```

No tests exist.

## CI/CD

- `build.yml` — push/PR to main, unsigned arm64+x86_64 build
- `release.yml` — `v*` tag trigger: build → sign → re-sign Sparkle → notarize → DMG → EdDSA sign → appcast.xml commit → GitHub Release → Homebrew cask

**Critical:** Final codesign MUST include `--entitlements VocaApp/VocaApp.entitlements` or mic permission is silently stripped.

## Source Layout

```
Voca/App/VoiceTranslatorApp.swift    — AppDelegate, recording lifecycle, auto-paste
Voca/Services/AudioRecorder.swift    — AVAudioEngine, 16kHz mono, energy VAD (1.2s silence threshold)
Voca/Services/Transcriber.swift      — Swift↔KMP bridge, audio chunking
Voca/Services/ModelManager.swift     — Model download from GitHub Releases
Voca/Services/HotkeyMonitor.swift    — Global hotkey (hold/double-tap modes)
Voca/Services/HistoryManager.swift   — Last 10 transcriptions + audio files
Voca/Services/LicenseManager.swift   — 7-day trial, weekly rotating tokens, offline
Voca/Settings/AppSettings.swift      — UserDefaults: model, hotkey (default: hold ⌥), device
Voca/Views/StatusBarController.swift — Menu bar, history display
Voca/Views/RecordingOverlay.swift    — Waveform + live transcription preview
VocaApp/VocaApp.entitlements         — com.apple.security.device.audio-input
```

## ASR Models

CoreML, downloaded to `~/Library/Application Support/Voca/models/`:

| Model | Key | Languages | Hot Words |
|-------|-----|-----------|-----------|
| SenseVoice | `sensevoice` | CN/EN/JA/KO/Cantonese | No |
| Whisper Turbo | `whisper` | 99+ | Yes (fastest) |
| Parakeet v2 | `parakeet` | EN only | Yes (best EN accuracy) |

## Recording Flow

Hotkey → `AudioRecorder` (16kHz mono, energy VAD) → speech segments on 1.2s silence → `Transcriber.transcribeSamples()` (incremental, live overlay) → hotkey release → flush remaining buffer → await pending segments → post-process (filler removal, CJK punctuation) → clipboard + CGEvent Cmd+V paste

## Conventions

- Singletons: `*.shared` (`ModelManager`, `HistoryManager`, `LicenseManager`, `AppSettings`)
- Notifications for cross-component events: `.modelChanged`, `.historyDidUpdate`, `.licenseStatusChanged`
- Bundle ID: `com.zhengyishen.voca`
- macOS 13.0+, universal binary (arm64 + x86_64)
- Localization: `NSLocalizedString()`, 5 languages (en, zh-Hans, ja, ko, es)
- Sparkle feed: `https://voca.zhengyishen.com/appcast.xml`
- Git remotes: `origin` = fork, `upstream` = `zhengyishen0/voca-app`
