import Cocoa
import VoicePipeline
import ApplicationServices
import AVFoundation

private var appDelegateRef: AppDelegate?

public enum VocaApp {
    public static func main() {
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
            let bundlePath = resourceURL.appendingPathComponent("Voca_VocaLib.bundle")
            if let resourceBundle = Bundle(url: bundlePath),
               let assetsPath = resourceBundle.resourceURL?.appendingPathComponent("Resources/assets").path,
               FileManager.default.fileExists(atPath: assetsPath) {
                return assetsPath
            }
        }
        // 2. Check next to executable (for development builds)
        let executableURL = Bundle.main.executableURL!.deletingLastPathComponent()
        let bundlePath = executableURL.appendingPathComponent("Voca_VocaLib.bundle")
        if let resourceBundle = Bundle(url: bundlePath),
           let assetsPath = resourceBundle.resourceURL?.appendingPathComponent("Resources/assets").path,
           FileManager.default.fileExists(atPath: assetsPath) {
            return assetsPath
        }
        // 3. Last resort
        fatalError("Could not find Voca_VocaLib.bundle/Resources/assets in any expected location")
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

        print("Voca started")
        print("Double-tap ⌘ to record, release to transcribe")
        print("ESC to cancel | ⌃⌥V for history")
        print("─────────────────────────────────────")

        // Show onboarding if first launch or no model downloaded
        checkAndShowOnboarding()
    }

    private func checkAndShowOnboarding() {
        if OnboardingWindowController.shouldShowOnboarding() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                OnboardingWindowController.shared.show()
            }
        }
    }

    private func startRecording() {
        // Check if selected model is downloaded
        let selectedModel = AppSettings.shared.selectedModel
        if !ModelManager.shared.isModelDownloaded(selectedModel) {
            print("⚠️ Model not downloaded, opening settings...")
            SettingsWindowController.shared.show()
            return
        }

        // Check permissions - show onboarding permission page if not granted
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        let accessibilityGranted = AXIsProcessTrusted()

        if micStatus != .authorized || !accessibilityGranted {
            print("⚠️ Permissions required, showing onboarding...")
            OnboardingWindowController.shared.showPermissionsStep()
            return
        }

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
            // Clean up model artifacts (tags like <|EMO_UNKNOWN|>, <|jp|>, <|en|>, etc.)
            let cleanedText = text
                .replacingOccurrences(of: "<\\|[^|]+\\|>", with: "", options: .regularExpression)
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
        // Copy to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        print("📋 Clipboard set: \(success), text length: \(text.count)")

        // Check accessibility permission
        let trusted = AXIsProcessTrusted()
        print("🔐 Accessibility trusted: \(trusted)")

        guard trusted else {
            print("⚠️ Accessibility not granted - text copied to clipboard, please paste manually")
            return
        }

        // Simulate Cmd+V after a delay to ensure focus returns to target app
        print("⏳ Scheduling paste in 0.1s...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    private func simulatePaste() {
        print("🎹 simulatePaste() called")

        // Based on Maccy clipboard manager implementation
        // https://github.com/p0deje/Maccy/blob/master/Maccy/Clipboard.swift
        let vKeyCode: CGKeyCode = 0x09  // V key

        // Use combinedSessionState like Maccy does
        let source = CGEventSource(stateID: .combinedSessionState)
        print("  - Event source created: \(source != nil)")

        // Configure event filtering during suppression (key for hardened runtime)
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        print("  - KeyDown event: \(keyDown != nil), KeyUp event: \(keyUp != nil)")

        // Command flag with non-coalesced marker (0x000008) as used by Maccy
        let cmdFlag = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x000008)
        keyDown?.flags = cmdFlag
        keyUp?.flags = cmdFlag

        // Post to cgSessionEventTap
        keyDown?.post(tap: .cgSessionEventTap)
        keyUp?.post(tap: .cgSessionEventTap)
        print("  - Events posted to cgSessionEventTap")
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
