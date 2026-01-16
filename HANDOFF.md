# Voca - Handoff Document

## Project Overview

Voca is a macOS menu bar app for voice-to-text transcription. Double-tap ⌘ to record, release to transcribe and auto-paste.

## Current State

**Working:**
- Menu bar app with waveform icon
- Double-tap ⌘ hotkey to record
- Animated floating waveform overlay (responds to audio levels)
- Transcription via KMP VoicePipeline.framework
- History with ⌃⌥V hotkey
- About window

**Build & Run:**
```bash
cd /Users/zhengyishen/Codes/voca-app
swift build
.build/debug/Voca
```

## Architecture

```
voca-app/
├── Frameworks/
│   └── VoicePipeline.framework    # Pre-built KMP framework (~10MB)
├── Voca/
│   ├── App/
│   │   └── VoiceTranslatorApp.swift   # Main app, AppDelegate
│   ├── Services/
│   │   ├── AudioRecorder.swift        # AVAudioEngine recording
│   │   ├── Transcriber.swift          # Calls ASREngine
│   │   ├── HotkeyMonitor.swift        # Double-tap ⌘, ⌃⌥V
│   │   └── HistoryManager.swift       # Last 10 transcriptions
│   ├── Views/
│   │   ├── StatusBarController.swift  # Menu bar icon & dropdown
│   │   ├── RecordingOverlay.swift     # Animated waveform pill
│   │   └── AboutWindow.swift          # About dialog
│   ├── Settings/
│   │   └── AppSettings.swift          # UserDefaults wrapper
│   └── Resources/
│       ├── Info.plist
│       └── assets/                    # Vocabulary files (bundled)
├── Package.swift
└── .gitignore
```

## Key Technical Details

### KMP Framework
- `VoicePipeline.framework` is pre-built from `/Users/zhengyishen/Codes/claude-code/voice/pipelines/kmp/`
- Exposes `ASREngine` class with `initialize()` and `transcribe()` methods
- Do NOT modify the pipeline code - it's experimental and lives in claude-code

### Model Storage
- **Assets** (vocab.json, bpe.model, mel_filterbank.bin): Bundled in `Voca/Resources/assets/` (~1MB)
- **CoreML Models**: To be downloaded to `~/Library/Application Support/Voca/models/`
  - SenseVoice: ~448MB
  - Whisper Turbo: ~618MB

### Current Model Path (in VoiceTranslatorApp.swift)
```swift
private var modelDir: String {
    let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    return appSupport.appendingPathComponent("Voca/models").path
}
```

## TODO - Pending Tasks

### 1. Clean Up Transcription Prefix
Remove `<|EMO_UNKNOWN|>` prefix from transcription results in post-processing.

**Location:** `Voca/App/VoiceTranslatorApp.swift` in `finishTranscription()` method
```swift
// Add something like:
let cleanedText = text.replacingOccurrences(of: "<|EMO_UNKNOWN|>", with: "").trimmingCharacters(in: .whitespaces)
```

### 2. Refine Dropdown Menu (StatusBarController.swift)
Current: Has submenus for Model and History
Desired: Flat structure with sections

**New menu structure:**
```
⌘⌘ to record          <- Hint at top (disabled item)
─────────────────
Models                 <- Section header
  ○ SenseVoice         <- Radio selection, show download progress if not downloaded
  ○ Whisper Turbo
─────────────────
History    ⌃⌥V         <- Section header with shortcut hint on right
  1. First transcription...
  2. Second transcription...
  3. Third transcription...
─────────────────
About Voca
Quit
```

**Requirements:**
- Only show 2 models: SenseVoice and Whisper Turbo
- Show last 3 transcriptions (not 10)
- If model not downloaded, show download progress on right side when clicked
- Show "⌃⌥V" shortcut hint after "History" header

### 3. Model Download Manager
Create a new service to handle model downloads.

**Location:** Create `Voca/Services/ModelManager.swift`

**Responsibilities:**
- Check if model exists in `~/Library/Application Support/Voca/models/`
- Download from GitHub Releases URL
- Report download progress (0-100%)
- Unzip after download

**GitHub Releases URL pattern:**
```
https://github.com/USER/voca-app/releases/download/v1.0/sensevoice.zip
https://github.com/USER/voca-app/releases/download/v1.0/whisper-turbo.zip
```

**Model files after unzip:**
```
~/Library/Application Support/Voca/models/
├── SenseVoiceSmall.mlmodelc/
└── WhisperTurbo.mlmodelc/
```

### 4. GitHub Setup (Manual Steps)
1. Create GitHub repo `voca-app`
2. Push code: `git remote add origin git@github.com:USER/voca-app.git && git push -u origin main`
3. Zip models from `/Users/zhengyishen/Codes/claude-code/voice/models/coreml/`
4. Create Release v1.0 and upload zipped models

## Design Guidelines

- **Colors:** Black and white only (matches project theme)
- **Icons:** Use SF Symbols
- **Menu bar states:**
  - Idle: `waveform.circle.fill` (template)
  - Recording: `record.circle.fill` (red)
  - Processing: `circle.dashed` (orange)
- **Waveform overlay:** Bottom of screen, pill shape, "Listening" text

## Dependencies

- macOS 13+
- Swift 5.9
- VoicePipeline.framework (bundled)
- No external Swift packages

## Notes

- The KMP pipeline in `claude-code` is for experiments - don't modify it
- Both models require download (app should be lightweight)
- Framework is ~10MB, acceptable to bundle
- User preferred GitHub Releases for model hosting
