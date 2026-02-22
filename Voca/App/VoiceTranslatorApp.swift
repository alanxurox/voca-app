import Cocoa
import VoicePipeline
import ApplicationServices
import AVFoundation
import Sparkle

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
    private var historyManager: HistoryManager { HistoryManager.shared }
    private var recordingOverlay: RecordingOverlay!
    private var asrEngine: ASREngine!

    // Sparkle updater
    private var updaterController: SPUStandardUpdaterController!

    private var totalStartTime: Date?
    private var isTranscribing = false
    private var escMonitor: Any?
    private var transcriptionTimeoutTask: DispatchWorkItem?
    private let transcriptionTimeoutSeconds: TimeInterval = 30
    private var currentAudioURL: URL?  // Track audio URL for history

    // Incremental transcription state
    private var incrementalText: [String] = []  // Accumulated text from speech segments
    private var isIncrementalMode = false
    private var pendingSegments = 0  // Track in-flight transcriptions

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

        transcriber = Transcriber(engine: asrEngine)
        audioRecorder = AudioRecorder()
        recordingOverlay = RecordingOverlay()

        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: UpdateChecker.shared, userDriverDelegate: nil)
        UpdateChecker.shared.configure(with: updaterController.updater)

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
            updater: updaterController.updater,
            onModelChange: { [weak self] model in
                self?.transcriber.setModel(model)
            }
        )

        let settings = AppSettings.shared
        transcriber.setModel(settings.selectedModel)

        print("Voca started")
        print("Hold ⌥ to record, release to transcribe")
        print("ESC to cancel | ⌃⌥V for history")
        print("─────────────────────────────────────")

        // Check license status
        checkLicenseStatus()

        // Show onboarding if first launch or no model downloaded
        checkAndShowOnboarding()
    }

    private func checkLicenseStatus() {
        if !LicenseManager.shared.canUseApp {
            // Trial expired and not licensed - show license window
            print("⚠️ Trial expired, showing license window...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                LicenseWindowController.shared.showLicenseWindow()
            }
        } else if !LicenseManager.shared.isLicensed {
            print("📋 Trial: \(LicenseManager.shared.trialDaysRemaining) days remaining")
        } else {
            print("✓ Licensed")
        }
    }

    private func checkAndShowOnboarding() {
        if OnboardingWindowController.shouldShowOnboarding() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                OnboardingWindowController.shared.show()
            }
        }
    }

    private func startRecording() {
        // Check license status
        if !LicenseManager.shared.canUseApp {
            print("⚠️ Trial expired, showing license window...")
            LicenseWindowController.shared.showLicenseWindow()
            return
        }

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

        // Apply selected input device (if user chose a specific one)
        let selectedUID = AppSettings.shared.inputDeviceUID
        if !selectedUID.isEmpty {
            if let deviceID = AudioInputManager.shared.getDeviceID(forUID: selectedUID) {
                // Save current default so we can restore it after recording
                AudioInputManager.shared.saveCurrentDefault()
                AudioInputManager.shared.setDefaultInputDevice(deviceID)
            } else {
                print("⚠️ Selected device not found, using system default")
            }
        }

        print("🎤 Recording...")
        statusBarController.setState(.recording)
        recordingOverlay.show()

        // Reset incremental transcription state
        incrementalText = []
        isIncrementalMode = true
        pendingSegments = 0

        // Connect audio level to waveform visualization
        audioRecorder.onAudioLevel = { [weak self] level in
            self?.recordingOverlay.updateLevel(level)
        }

        // Connect speech segment callback for incremental transcription
        audioRecorder.onSpeechSegment = { [weak self] samples in
            self?.handleSpeechSegment(samples)
        }

        audioRecorder.startRecording()
    }

    private func handleSpeechSegment(_ samples: [Float]) {
        guard isIncrementalMode else { return }

        pendingSegments += 1
        print("📝 Transcribing segment (\(samples.count) samples)...")

        transcriber.transcribeSamples(samples) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.pendingSegments -= 1

                if let text = result, !text.isEmpty {
                    // Clean up model artifacts
                    let cleanedText = text
                        .replacingOccurrences(of: "<\\|[^|]+\\|>", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespaces)

                    if !cleanedText.isEmpty {
                        // Strip leading punctuation from segment (ASR often adds it)
                        let strippedText = cleanedText.replacingOccurrences(
                            of: "^[。.，,？?！!、]+\\s*",
                            with: "",
                            options: .regularExpression
                        )
                        guard !strippedText.isEmpty else { return }
                        self.incrementalText.append(strippedText)

                        // Combine all segments and apply post-processing
                        let combinedText = self.incrementalText.joined(separator: " ")
                        let processedText = self.postProcessText(combinedText)

                        print("✓ Incremental: \(cleanedText) → Full: \(processedText)")

                        // Show in overlay as preview (don't paste yet)
                        self.recordingOverlay.updateTranscription(processedText)
                    }
                }
            }
        }
    }

    /// Post-process transcribed text: filler removal and formatting
    private func postProcessText(_ text: String) -> String {
        var result = text

        // 1. Remove basic filler words (multiple languages)
        // English: um, uh, er, ah, hmm
        // Chinese: 呃, 嗯, 啊, 那个
        // Japanese: えーと, あの, えー
        // Korean: 음, 어
        let fillerWords = ["um", "uh", "er", "ah", "hmm", "呃", "嗯", "啊", "那个", "えーと", "あの", "えー", "음", "어"]
        for filler in fillerWords {
            // Remove filler surrounded by spaces
            result = result.replacingOccurrences(of: " \(filler) ", with: " ", options: .caseInsensitive)
            // Remove filler at start
            result = result.replacingOccurrences(of: "^\(filler) ", with: "", options: [.caseInsensitive, .regularExpression])
            // Remove filler followed by comma
            result = result.replacingOccurrences(of: " \(filler),", with: ",", options: .caseInsensitive)
        }

        // 2. Fix spacing and punctuation
        result = result.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)  // Multiple spaces
        result = result.replacingOccurrences(of: " ,", with: ",")  // Space before comma
        result = result.replacingOccurrences(of: " \\.", with: ".", options: .regularExpression)  // Space before period

        // 3. Clean up duplicate/mixed punctuation
        // Detect if text is primarily Chinese (contains CJK characters)
        let isChinese = result.range(of: "\\p{Han}", options: .regularExpression) != nil

        if isChinese {
            // Chinese text: normalize to Chinese punctuation
            // Handle mixed punctuation with optional spaces: ... 。 or 。 . or 。。. etc.
            result = result.replacingOccurrences(of: "[。.\\s]*[。.][。.\\s]*", with: "。", options: .regularExpression)
            result = result.replacingOccurrences(of: "[，,\\s]*[，,][，,\\s]*", with: "，", options: .regularExpression)
            result = result.replacingOccurrences(of: "[？?\\s]*[？?][？?\\s]*", with: "？", options: .regularExpression)
            result = result.replacingOccurrences(of: "[！!\\s]*[！!][！!\\s]*", with: "！", options: .regularExpression)
            // Remove comma before period: ，。 → 。
            result = result.replacingOccurrences(of: "，。", with: "。")
            result = result.replacingOccurrences(of: "。，", with: "。")
            // Remove period after question/exclamation: ？。 → ？, ！。 → ！
            result = result.replacingOccurrences(of: "？[。.]", with: "？", options: .regularExpression)
            result = result.replacingOccurrences(of: "！[。.]", with: "！", options: .regularExpression)
            result = result.replacingOccurrences(of: "\\?[。.]", with: "？", options: .regularExpression)
            result = result.replacingOccurrences(of: "![。.]", with: "！", options: .regularExpression)
        } else {
            // English text: normalize to English punctuation
            result = result.replacingOccurrences(of: "[.\\s]*\\.[.\\s]*", with: ". ", options: .regularExpression)
            result = result.replacingOccurrences(of: ",+", with: ",", options: .regularExpression)
            result = result.replacingOccurrences(of: ",\\s*\\.", with: ".", options: .regularExpression)  // Comma before period → period
            result = result.replacingOccurrences(of: "\\.\\s*,", with: ",", options: .regularExpression)  // Period before comma → comma
            result = result.replacingOccurrences(of: "\\?+", with: "?", options: .regularExpression)
            result = result.replacingOccurrences(of: "!+", with: "!", options: .regularExpression)
        }

        // Clean up any remaining multiple spaces
        result = result.replacingOccurrences(of: "\\s{2,}", with: " ", options: .regularExpression)

        // 4. Capitalize first letter (for English text)
        if let first = result.first {
            result = first.uppercased() + result.dropFirst()
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    private func stopRecordingAndTranscribe() {
        totalStartTime = Date()  // Start total timing when CMD released
        audioRecorder.onAudioLevel = nil
        // Keep onSpeechSegment active - stopRecording will flush remaining audio

        // Switch overlay to processing mode instead of hiding
        recordingOverlay.showProcessing()

        audioRecorder.stopRecording { [weak self] audioURL in
            guard let self = self else { return }

            // Don't null onSpeechSegment yet — a VAD segment dispatched to main just before
            // stopRecording may still arrive. finishIncrementalTranscription will clean up
            // after all pending segments complete. isIncrementalMode stays true so late-
            // arriving dispatches from the audio thread are still processed.

            // If we got incremental results (or have pending segments), use those
            if !self.incrementalText.isEmpty || self.pendingSegments > 0 {
                self.finishIncrementalTranscription(audioURL: audioURL)
                return
            }

            // No incremental results — clean up and fall back to full transcription
            self.audioRecorder.onSpeechSegment = nil
            self.isIncrementalMode = false
            guard let url = audioURL else {
                print("✗ No audio")
                self.recordingOverlay.hide()
                self.statusBarController.setState(.idle)
                return
            }

            self.startTranscription(audioURL: url)
        }
    }

    private func finishIncrementalTranscription(audioURL: URL?) {
        // Wait for any pending segment transcriptions
        if pendingSegments > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.finishIncrementalTranscription(audioURL: audioURL)
            }
            return
        }

        // All segments processed — safe to clean up callbacks now
        audioRecorder.onSpeechSegment = nil
        isIncrementalMode = false

        recordingOverlay.hide()
        statusBarController.setState(.idle)

        // Restore the original system default input device
        AudioInputManager.shared.restoreSavedDefault()

        let combinedText = incrementalText.joined(separator: " ")
        let processedText = postProcessText(combinedText)
        let totalTime = totalStartTime.map { Date().timeIntervalSince($0) } ?? 0

        if !processedText.isEmpty {
            print("✓ Final: \(processedText)")
            print("  ⏱ total: \(Int(totalTime * 1000))ms (incremental)")
            historyManager.add(processedText, audioURL: audioURL)
            // Paste final text only once at the end
            pasteText(processedText)
        } else {
            print("✗ No incremental results")
        }

        // Clean up
        incrementalText = []
        asrEngine.collectGarbage()
    }

    private func startTranscription(audioURL: URL) {
        isTranscribing = true
        currentAudioURL = audioURL  // Save for history
        statusBarController.setState(.processing)

        escMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 0x35 {
                self?.cancelTranscription()
            }
        }

        // Set up timeout to prevent indefinite hangs
        let timeoutTask = DispatchWorkItem { [weak self] in
            guard let self = self, self.isTranscribing else { return }
            print("⚠️ Transcription timed out after \(Int(self.transcriptionTimeoutSeconds))s")
            self.cancelTranscription()
        }
        transcriptionTimeoutTask = timeoutTask
        DispatchQueue.main.asyncAfter(deadline: .now() + transcriptionTimeoutSeconds, execute: timeoutTask)

        transcriber.transcribe(audioURL: audioURL) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, self.isTranscribing else { return }
                self.transcriptionTimeoutTask?.cancel()
                self.transcriptionTimeoutTask = nil
                self.finishTranscription(result: result)
            }
        }
    }

    private func cancelTranscription() {
        guard isTranscribing else { return }
        isTranscribing = false
        transcriptionTimeoutTask?.cancel()
        transcriptionTimeoutTask = nil
        removeEscMonitor()
        recordingOverlay.hide()
        statusBarController.setState(.idle)
        // Restore the original system default input device
        AudioInputManager.shared.restoreSavedDefault()
        // Clean up any partial memory allocations
        asrEngine.collectGarbage()
        print("✗ Cancelled")
    }

    private func finishTranscription(result: TranscriptionResult) {
        isTranscribing = false
        removeEscMonitor()
        recordingOverlay.hide()

        // Restore the original system default input device
        AudioInputManager.shared.restoreSavedDefault()

        // Clean up Kotlin/Native memory after transcription
        asrEngine.collectGarbage()

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
            historyManager.add(cleanedText, audioURL: currentAudioURL)
            currentAudioURL = nil
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
        transcriptionTimeoutTask?.cancel()
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
