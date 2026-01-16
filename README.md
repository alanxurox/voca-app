<p align="center">
	<img width="128" height="128" src="misc/icon.png" alt="Voca Icon">
</p>

<h1 align="center">Voca</h1>

<p align="center">
	<strong>Voice your thoughts.</strong>
</p>

<p align="center">
	<img src="https://img.shields.io/badge/Price-Free_Forever-brightgreen?style=for-the-badge" alt="Free Forever">
</p>

<p align="center">
	<a href="https://github.com/zhengyishen0/voca-app/releases/latest">
		<img src="https://img.shields.io/github/v/release/zhengyishen0/voca-app?style=flat-square&color=blue" alt="Latest Release">
	</a>
	<a href="https://github.com/zhengyishen0/voca-app/releases">
		<img src="https://img.shields.io/github/downloads/zhengyishen0/voca-app/total?style=flat-square&color=brightgreen" alt="Downloads">
	</a>
	<img src="https://img.shields.io/badge/macOS-13.0+-orange?style=flat-square" alt="macOS 13+">
	<img src="https://img.shields.io/badge/Apple_Silicon-required-blue?style=flat-square" alt="Apple Silicon">
	<img src="https://img.shields.io/badge/99+_Languages-blue?style=flat-square" alt="99+ Languages">
</p>

<p align="center">
	<!-- <img src="misc/demo.gif" alt="Voca Demo" width="600"> -->
</p>

---

Turn speech into text instantly. Voca is **100% free**, open source, and runs entirely on your Mac. No cloud. No subscription. No limits.

Supports 99+ languages with on-device AI. Your voice never leaves your Mac.

## Why Voca?

| | Voca | Wispr Flow |
|---|:---:|:---:|
| **Price** | Free forever | $15/month |
| **Open Source** | Yes | No |
| **Privacy** | 100% on-device | Cloud-based |
| **Languages** | 99+ | 100+ |
| **Platform** | macOS (Apple Silicon) | macOS, Windows, iOS |

## Features

- **Lightning Speed** — Optimized CoreML models deliver instant transcription on Apple Silicon
- **99+ Languages** — From English to Chinese, Japanese, Korean, Spanish, and many more
- **100% Private** — All processing happens on-device. Your voice never leaves your Mac
- **Auto-Paste** — Transcribed text is automatically pasted wherever your cursor is
- **Live Waveform** — Animated floating overlay responds to your voice in real-time
- **Customizable Hotkeys** — Double-tap Option, Command, or use custom key combinations

## Installation

**Download**
1. Download the latest [Voca DMG](https://github.com/zhengyishen0/voca-app/releases/latest)
2. Open the DMG and drag Voca to Applications
3. Right-click → Open (first launch only, to bypass Gatekeeper)

**Homebrew** (Optional)
```bash
brew install --cask zhengyishen0/voca/voca
```

## Usage

1. **Press your hotkey** (default: Double-tap ⌥ Option) to start recording
2. **Speak** — Watch the waveform respond to your voice
3. **Release** — Text is transcribed and auto-pasted

### Hotkey Options

| Hotkey | Description |
|--------|-------------|
| ⌥⌥ | Double-tap Option (default) |
| ⌘⌘ | Double-tap Command |
| ⌃⌃ | Double-tap Control |
| ⌥ | Hold Option |
| ⌥⇧ | Option + Shift |
| ⌥⌘ | Option + Command |
| ⌃⌥ | Control + Option |

### Models

Voca includes multiple ASR models optimized for different use cases:

| Model | Languages | Best For |
|-------|-----------|----------|
| SenseVoice | 中/En/日/한/粤 | Chinese, English, Japanese, Korean |
| Whisper Turbo | 99+ | Multi-language support |
| Parakeet | English | Best English accuracy |

## Requirements

- **Apple Silicon** (M1/M2/M3/M4) — required for CoreML acceleration
- **macOS 13.0** (Ventura) or later

## Privacy

Voca processes all audio locally on your Mac using CoreML. No audio data is ever sent to external servers. Your voice stays on your device.

## License

MIT License - Free and open source

---

<p align="center">
	Made by <a href="https://x.com/ZhengyiShen">Zhengyi Shen</a>
</p>
