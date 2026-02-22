# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What is Voca

Voca is a macOS menu bar app for on-device voice-to-text transcription. Users press a hotkey (default: hold Option ⌥), speak, and the transcribed text is auto-pasted at the cursor. All processing is local via CoreML — no audio leaves the device. Other hotkey presets include double-tap Option/Command/Control and hold combinations.

## Architecture (By Design — Do Not Refactor)

Voca uses a **3-layer parallel project** architecture. This is intentional:

```
┌──────────────────────────────────┐
│  VocaApp.xcodeproj               │  ← Xcode project: code signing, notarization, Sparkle
│  (VocaApp/main.swift entry)      │     framework linking, release builds
├──────────────────────────────────┤
│  Package.swift (VocaLib)         │  ← SPM library: AI-friendly editing, `swift build`,
│  (Voca/ source tree)             │     CI builds, all Swift source code lives here
├──────────────────────────────────┤
│  VoicePipeline.xcframework       │  ← Kotlin Multiplatform (KMP): ASR engine, model
│  + libonnxruntime.1.17.0.dylib   │     inference via ONNX Runtime + CoreML
└──────────────────────────────────┘
```

**Why parallel project?** Both Package.swift and VocaApp.xcodeproj reference the same `Voca/` source files. Package.swift is for `swift build` and AI-driven development. Xcode handles signing, entitlements, and framework linking (VoicePipeline.xcframework can't be linked via SPM alone). When adding new Swift files, they must be added to BOTH Package.swift and the Xcode project.

**Why KMP at the bottom?** The VoicePipeline framework encapsulates all ASR logic in Kotlin, enabling future Android/cross-platform reuse. Swift talks to it via `ASREngine` (from `import VoicePipeline`).

## Build & Development

```bash
# CLI build (for quick iteration, no signing)
swift build

# Xcode build (for signed builds, framework linking, release)
xcodebuild build \
  -project VocaApp.xcodeproj \
  -scheme Voca \
  -configuration Release \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO

# Release: push a tag → CI/CD handles everything
git tag v1.x.x && git push origin v1.x.x
```

There are no tests in this project currently.

## CI/CD Pipeline

- **`.github/workflows/build.yml`** — Runs on push/PR to main. Builds for arm64 and x86_64 without signing.
- **`.github/workflows/release.yml`** — Triggered by `v*` tags. Full pipeline: build → sign (Developer ID) → re-sign Sparkle binaries → notarize → create DMG → sign with Sparkle EdDSA → update appcast.xml → create GitHub Release → update Homebrew cask.

**Critical CI/CD detail:** The re-signing step must preserve entitlements. The `--entitlements VocaApp/VocaApp.entitlements` flag on the final `codesign` call is what grants microphone permission (`com.apple.security.device.audio-input`). Without it, the released app silently fails to access the mic.

## Key Source Layout

```
Voca/
├── App/VoiceTranslatorApp.swift   # AppDelegate, main recording flow, paste logic
├── Services/
│   ├── AudioRecorder.swift        # AVAudioEngine recording, VAD-based speech segmentation
│   ├── Transcriber.swift          # Bridges Swift ↔ KMP ASREngine, chunking, audio loading
│   ├── ModelManager.swift         # Downloads/manages CoreML models from GitHub Releases
│   ├── HotkeyMonitor.swift        # Global hotkey detection (hold/double-tap modes)
│   ├── HistoryManager.swift       # Transcription history with audio playback
│   ├── LicenseManager.swift       # Weekly rotating token validation (offline, no server)
│   ├── AudioInputManager.swift    # System audio device selection
│   └── UpdateChecker.swift        # Sparkle update delegate
├── Views/
│   ├── StatusBarController.swift  # Menu bar icon, menu, history display
│   ├── RecordingOverlay.swift     # Floating waveform visualization
│   ├── SettingsWindowController.swift  # Model selection, hotkey config, device picker
│   ├── OnboardingWindowController.swift
│   ├── LicenseWindowController.swift / LicenseView.swift
│   └── AboutWindow.swift
├── Settings/AppSettings.swift     # UserDefaults: model, hotkey, input device
└── Resources/
    ├── assets/                    # Bundled tokenizer files (BPE model, mel filterbank, vocab)
    └── {en,zh-Hans,ja,ko,es}.lproj/  # Localization (5 languages)

VocaApp/
├── main.swift                     # Entry point: `VocaLib.VocaApp.main()`
├── Info.plist                     # Bundle config, Sparkle feed URL, permissions
└── VocaApp.entitlements           # audio-input entitlement (critical for mic access)

Frameworks/
├── VoicePipeline.xcframework      # KMP-built ASR engine
└── libonnxruntime.1.17.0.dylib    # ONNX Runtime for model inference
```

## ASR Models

Models are CoreML, downloaded on first run to `~/Library/Application Support/Voca/models/`:

| Model | Key | Languages | Notes |
|-------|-----|-----------|-------|
| SenseVoice | `sensevoice` | CN/EN/JA/KO/Cantonese | Default. Does NOT support hot words injection |
| Whisper Turbo | `whisper` | 99+ languages | Fastest. Supports hot words via token injection |
| Parakeet v2 | `parakeet` | English only | Best English accuracy. Supports hot words |

Model files hosted at: `github.com/zhengyishen0/voca-app/releases/download/models-v1/`

## Recording & Transcription Flow

1. **Hotkey detected** → `HotkeyMonitor` fires `onRecordStart`
2. **Recording starts** → `AudioRecorder` captures 16kHz mono via `AVAudioEngine`, runs energy-based VAD
3. **Incremental mode** → Speech segments (after 1.2s silence) sent to `Transcriber.transcribeSamples()` → live preview in overlay
4. **Hotkey released** → Remaining buffer flushed, pending segments awaited
5. **Post-processing** → Filler word removal (multi-language), punctuation normalization, CJK-aware formatting
6. **Auto-paste** → Text copied to clipboard, `Cmd+V` simulated via `CGEvent` (Maccy-style implementation)

## Auto-Update (Sparkle)

- Feed URL: `https://voca.zhengyishen.com/appcast.xml` (configured in `VocaApp/Info.plist`)
- EdDSA public key in Info.plist, private key in GitHub Secrets (`SPARKLE_PRIVATE_KEY`)
- `appcast.xml` updated automatically by release CI — must be committed to main branch
- Release workflow re-signs all Sparkle XPC services/binaries with the Developer ID certificate

## Known Issues / Active Bugs

1. **Audio cut-off** — Last segment of speech sometimes dropped. Likely related to the incremental transcription overlay feature (showing text while recording). Need to check if audio is not recorded vs not transcribed — each segment's audio is saved in `~/Library/Application Support/Voca/recordings/`.
2. **Microphone permission in CI/CD** — Fixed in v1.2.8 by preserving entitlements during re-signing. The `--entitlements` flag was missing from the final codesign call in release.yml.

## Conventions

- **Singleton pattern** used for managers: `ModelManager.shared`, `HistoryManager.shared`, `LicenseManager.shared`, `AppSettings.shared`
- **Notification-based communication** between components: `.modelChanged`, `.historyDidUpdate`, `.licenseStatusChanged`, `.updateAvailabilityChanged`
- **Bundle ID**: `com.zhengyishen.voca`
- **Minimum deployment**: macOS 13.0 (Ventura)
- **Universal binary**: arm64 + x86_64
- **Localization**: Use `NSLocalizedString()` — strings in 5 `.lproj` dirs
