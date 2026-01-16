import Cocoa
import VoicePipeline

private var appDelegateRef: AppDelegate?

@main
struct VocaApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        appDelegateRef = delegate
        app.delegate = delegate
        app.run()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyMonitor: HotkeyMonitor!
    private var audioRecorder: AudioRecorder!
    private var transcriber: Transcriber!
    private var historyManager: HistoryManager!
    private var recordingOverlay: RecordingOverlay!
    private var asrEngine: ASREngine!

    private var totalStartTime: Date?
    private var isTranscribing = false
    private var escMonitor: Any?

    // Model paths - CoreML models downloaded to Application Support, assets bundled
    private var modelDir: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Voca/models").path
    }
    private var assetsDir: String {
        // Try multiple locations for SPM resource bundle
        // 1. App bundle's Resources folder (for packaged .app)
        if let resourceURL = Bundle.main.resourceURL {
            let bundlePath = resourceURL.appendingPathComponent("Voca_Voca.bundle")
            if let resourceBundle = Bundle(url: bundlePath),
               let assetsPath = resourceBundle.resourceURL?.appendingPathComponent("assets").path,
               FileManager.default.fileExists(atPath: assetsPath) {
                return assetsPath
            }
        }
        // 2. Check next to executable (for development builds)
        let executableURL = Bundle.main.executableURL!.deletingLastPathComponent()
        let bundlePath = executableURL.appendingPathComponent("Voca_Voca.bundle")
        if let resourceBundle = Bundle(url: bundlePath),
           let assetsPath = resourceBundle.resourceURL?.appendingPathComponent("assets").path,
           FileManager.default.fileExists(atPath: assetsPath) {
            return assetsPath
        }
        // 3. Last resort
        fatalError("Could not find Voca_Voca.bundle/assets in any expected location")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Set app icon (waveform.circle.fill)
        setAppIcon()

        // Initialize ASR engine (loads CoreML models once at startup)
        print("Loading ASR models...")
        let loadStart = Date()
        asrEngine = ASREngine(modelDir: modelDir, assetsDir: assetsDir)
        if asrEngine.initialize() {
            let loadTime = Int(Date().timeIntervalSince(loadStart) * 1000)
            print("ASR engine initialized in \(loadTime)ms")
        } else {
            print("WARNING: ASR engine failed to initialize")
        }

        historyManager = HistoryManager()
        transcriber = Transcriber(engine: asrEngine)
        audioRecorder = AudioRecorder()
        recordingOverlay = RecordingOverlay()

        hotkeyMonitor = HotkeyMonitor(
            onRecordStart: { [weak self] in
                self?.startRecording()
            },
            onRecordStop: { [weak self] in
                self?.stopRecordingAndTranscribe()
            },
            onHistoryPaste: { [weak self] in
                self?.pasteFromHistory()
            }
        )

        statusBarController = StatusBarController(
            onModelChange: { [weak self] model in
                self?.transcriber.setModel(model)
            },
            historyManager: historyManager
        )

        let settings = AppSettings.shared
        transcriber.setModel(settings.selectedModel)
        statusBarController.updateSelectedModel(settings.selectedModel)

        print("Voca started")
        print("Double-tap ⌘ to record, release to transcribe")
        print("ESC to cancel | ⌃⌥V for history")
        print("─────────────────────────────────────")
    }

    private func startRecording() {
        print("🎤 Recording...")
        statusBarController.setState(.recording)
        recordingOverlay.show()

        // Connect audio level to waveform visualization
        audioRecorder.onAudioLevel = { [weak self] level in
            self?.recordingOverlay.updateLevel(level)
        }

        audioRecorder.startRecording()
    }

    private func stopRecordingAndTranscribe() {
        totalStartTime = Date()  // Start total timing when CMD released
        recordingOverlay.hide()
        audioRecorder.onAudioLevel = nil

        audioRecorder.stopRecording { [weak self] audioURL in
            guard let self = self, let url = audioURL else {
                print("✗ No audio")
                self?.statusBarController.setState(.idle)
                return
            }

            self.startTranscription(audioURL: url)
        }
    }

    private func startTranscription(audioURL: URL) {
        isTranscribing = true
        statusBarController.setState(.processing)

        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 0x35 {
                self?.cancelTranscription()
            }
        }

        transcriber.transcribe(audioURL: audioURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, self.isTranscribing else { return }
                self.finishTranscription(result: result)
            }
        }
    }

    private func cancelTranscription() {
        guard isTranscribing else { return }
        isTranscribing = false
        removeEscMonitor()
        statusBarController.setState(.idle)
        print("✗ Cancelled")
    }

    private func finishTranscription(result: TranscriptionResult) {
        isTranscribing = false
        removeEscMonitor()

        let totalTime = totalStartTime.map { Date().timeIntervalSince($0) } ?? 0
        let modelTime = result.modelTime

        if let text = result.text, !text.isEmpty {
            // Clean up model artifacts (emotion tags from SenseVoice)
            let cleanedText = text
                .replacingOccurrences(of: "<|EMO_UNKNOWN|>", with: "")
                .replacingOccurrences(of: "<|NEUTRAL|>", with: "")
                .replacingOccurrences(of: "<|HAPPY|>", with: "")
                .replacingOccurrences(of: "<|SAD|>", with: "")
                .replacingOccurrences(of: "<|ANGRY|>", with: "")
                .trimmingCharacters(in: .whitespaces)

            guard !cleanedText.isEmpty else {
                print("✗ Empty after cleanup")
                statusBarController.setState(.idle)
                return
            }

            let modelMs = Int(modelTime * 1000)
            let totalMs = Int(totalTime * 1000)
            print("✓ \(cleanedText)")
            print("  ⏱ model: \(modelMs)ms | total: \(totalMs)ms")
            historyManager.add(cleanedText)
            pasteText(cleanedText)
        } else {
            print("✗ No result (model: \(Int(modelTime * 1000))ms)")
        }

        statusBarController.setState(.idle)
    }

    private func removeEscMonitor() {
        if let monitor = escMonitor {
            NSEvent.removeMonitor(monitor)
            escMonitor = nil
        }
    }

    private func pasteFromHistory() {
        if let text = historyManager.getNext() {
            pasteText(text)
        }
    }

    private func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeEscMonitor()
    }

    private func setAppIcon() {
        // Create app icon from SF Symbol
        if let symbol = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Voca") {
            let config = NSImage.SymbolConfiguration(pointSize: 512, weight: .regular)
            if let configuredSymbol = symbol.withSymbolConfiguration(config) {
                // Render to specific size
                let size = NSSize(width: 512, height: 512)
                let icon = NSImage(size: size)
                icon.lockFocus()

                // Draw with accent color
                NSColor.controlAccentColor.set()
                let rect = NSRect(origin: .zero, size: size)
                configuredSymbol.draw(in: rect)

                icon.unlockFocus()
                NSApp.applicationIconImage = icon
            }
        }
    }
}
