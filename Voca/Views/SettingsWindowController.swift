import Cocoa
import AVFoundation
import ApplicationServices

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private var contentView: SettingsView!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Voca Settings", comment: "")
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        contentView = SettingsView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        window.contentView = contentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        contentView.refresh()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Settings View

class SettingsView: NSView {
    private var hintLabel: NSTextField!
    private var modelPopup: NSPopUpButton!
    private var inputPopup: NSPopUpButton!
    private var shortcutPopup: NSPopUpButton!
    private var micStatusLabel: NSTextField!
    private var micStatusIcon: NSButton!
    private var accessibilityStatusLabel: NSTextField!
    private var accessibilityStatusIcon: NSButton!
    private var historyScrollView: NSScrollView!
    private var historyStackView: NSStackView!
    private var historyContainer: FlippedView!
    private var wordReplacementsTextView: NSTextView!
    private var wordReplacementsScrollView: NSScrollView!

    private let modelManager = ModelManager.shared
    private let audioInputManager = AudioInputManager.shared
    private let historyManager = HistoryManager.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()

        // Subscribe to model download status changes
        modelManager.onStatusChanged = { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.refreshModels()
            }
        }

        // Refresh permissions when app becomes active (e.g., after granting in System Settings)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        // Refresh history when new transcription is added
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(historyDidUpdate),
            name: .historyDidUpdate,
            object: nil
        )
    }

    @objc private func historyDidUpdate() {
        refreshHistory()
    }

    @objc private func appDidBecomeActive() {
        refreshPermissions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Create hint label (shown when downloading)
        hintLabel = NSTextField(labelWithString: NSLocalizedString("Downloading speech recognition model...", comment: ""))
        hintLabel.font = NSFont.systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.alignment = .center
        hintLabel.isHidden = true

        // Create labels and popups
        let modelLabel = createLabel(NSLocalizedString("Language", comment: ""))
        let inputLabel = createLabel(NSLocalizedString("Microphone", comment: ""))
        let shortcutLabel = createLabel(NSLocalizedString("Shortcut", comment: ""))

        modelPopup = createPopup()
        inputPopup = createPopup()
        shortcutPopup = createPopup()

        // Permission indicators (bottom right)
        micStatusLabel = NSTextField(labelWithString: "")
        micStatusLabel.font = NSFont.systemFont(ofSize: 12)

        micStatusIcon = NSButton()
        micStatusIcon.bezelStyle = .inline
        micStatusIcon.isBordered = false
        micStatusIcon.imageScaling = .scaleProportionallyDown
        micStatusIcon.target = self
        micStatusIcon.action = #selector(openMicrophoneSettings)

        accessibilityStatusLabel = NSTextField(labelWithString: "")
        accessibilityStatusLabel.font = NSFont.systemFont(ofSize: 12)

        accessibilityStatusIcon = NSButton()
        accessibilityStatusIcon.bezelStyle = .inline
        accessibilityStatusIcon.isBordered = false
        accessibilityStatusIcon.imageScaling = .scaleProportionallyDown
        accessibilityStatusIcon.target = self
        accessibilityStatusIcon.action = #selector(openAccessibilitySettings)

        // History section
        let historyLabel = NSTextField(labelWithString: NSLocalizedString("History", comment: ""))
        historyLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        historyStackView = NSStackView()
        historyStackView.orientation = .vertical
        historyStackView.alignment = .leading
        historyStackView.spacing = 1
        historyStackView.setHuggingPriority(.defaultHigh, for: .vertical)

        // Use a flipped container so content starts from top
        historyContainer = FlippedView()
        historyContainer.translatesAutoresizingMaskIntoConstraints = false
        historyContainer.addSubview(historyStackView)

        historyScrollView = NSScrollView()
        historyScrollView.documentView = historyContainer
        historyScrollView.hasVerticalScroller = true
        historyScrollView.hasHorizontalScroller = false
        historyScrollView.autohidesScrollers = true
        historyScrollView.borderType = .bezelBorder

        // Word replacements section
        let wordReplacementsLabel = NSTextField(labelWithString: NSLocalizedString("Word Replacements", comment: ""))
        wordReplacementsLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)

        wordReplacementsTextView = NSTextView()
        wordReplacementsTextView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        wordReplacementsTextView.isEditable = true
        wordReplacementsTextView.isRichText = false
        wordReplacementsTextView.allowsUndo = true
        wordReplacementsTextView.delegate = self

        wordReplacementsScrollView = NSScrollView()
        wordReplacementsScrollView.documentView = wordReplacementsTextView
        wordReplacementsScrollView.hasVerticalScroller = true
        wordReplacementsScrollView.hasHorizontalScroller = false
        wordReplacementsScrollView.autohidesScrollers = true
        wordReplacementsScrollView.borderType = .bezelBorder

        let wordReplacementsHint = NSTextField(labelWithString: NSLocalizedString("One per line: find=replace (e.g., gonna=going to)", comment: ""))
        wordReplacementsHint.font = NSFont.systemFont(ofSize: 10)
        wordReplacementsHint.textColor = .secondaryLabelColor

        // Add to view
        addSubview(hintLabel)
        addSubview(modelLabel)
        addSubview(modelPopup)
        addSubview(inputLabel)
        addSubview(inputPopup)
        addSubview(shortcutLabel)
        addSubview(shortcutPopup)
        addSubview(micStatusLabel)
        addSubview(micStatusIcon)
        addSubview(accessibilityStatusLabel)
        addSubview(accessibilityStatusIcon)
        addSubview(historyLabel)
        addSubview(historyScrollView)
        addSubview(wordReplacementsLabel)
        addSubview(wordReplacementsScrollView)
        addSubview(wordReplacementsHint)

        // Layout with Auto Layout
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        modelPopup.translatesAutoresizingMaskIntoConstraints = false
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        inputPopup.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutPopup.translatesAutoresizingMaskIntoConstraints = false
        micStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        micStatusIcon.translatesAutoresizingMaskIntoConstraints = false
        accessibilityStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        accessibilityStatusIcon.translatesAutoresizingMaskIntoConstraints = false
        historyLabel.translatesAutoresizingMaskIntoConstraints = false
        historyScrollView.translatesAutoresizingMaskIntoConstraints = false
        historyStackView.translatesAutoresizingMaskIntoConstraints = false
        wordReplacementsLabel.translatesAutoresizingMaskIntoConstraints = false
        wordReplacementsScrollView.translatesAutoresizingMaskIntoConstraints = false
        wordReplacementsHint.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Hint label (above model row)
            hintLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            hintLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            hintLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),

            // Language row
            modelLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            modelLabel.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 12),
            modelLabel.widthAnchor.constraint(equalToConstant: 100),

            modelPopup.leadingAnchor.constraint(equalTo: modelLabel.trailingAnchor, constant: 10),
            modelPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            modelPopup.centerYAnchor.constraint(equalTo: modelLabel.centerYAnchor),

            // Microphone row
            inputLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            inputLabel.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 16),
            inputLabel.widthAnchor.constraint(equalToConstant: 100),

            inputPopup.leadingAnchor.constraint(equalTo: inputLabel.trailingAnchor, constant: 10),
            inputPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            inputPopup.centerYAnchor.constraint(equalTo: inputLabel.centerYAnchor),

            // Shortcut row
            shortcutLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            shortcutLabel.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 16),
            shortcutLabel.widthAnchor.constraint(equalToConstant: 100),

            shortcutPopup.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 10),
            shortcutPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            shortcutPopup.centerYAnchor.constraint(equalTo: shortcutLabel.centerYAnchor),

            // History section (after shortcut row)
            historyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            historyLabel.topAnchor.constraint(equalTo: shortcutLabel.bottomAnchor, constant: 16),

            historyScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            historyScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            historyScrollView.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 8),
            historyScrollView.heightAnchor.constraint(equalToConstant: 60),

            // Stack view in flipped container (top-aligned)
            historyStackView.leadingAnchor.constraint(equalTo: historyContainer.leadingAnchor),
            historyStackView.trailingAnchor.constraint(equalTo: historyContainer.trailingAnchor),
            historyStackView.topAnchor.constraint(equalTo: historyContainer.topAnchor),
            historyStackView.bottomAnchor.constraint(lessThanOrEqualTo: historyContainer.bottomAnchor),

            // Word replacements section (after history)
            wordReplacementsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            wordReplacementsLabel.topAnchor.constraint(equalTo: historyScrollView.bottomAnchor, constant: 12),

            wordReplacementsScrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            wordReplacementsScrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            wordReplacementsScrollView.topAnchor.constraint(equalTo: wordReplacementsLabel.bottomAnchor, constant: 8),
            wordReplacementsScrollView.heightAnchor.constraint(equalToConstant: 60),

            wordReplacementsHint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            wordReplacementsHint.topAnchor.constraint(equalTo: wordReplacementsScrollView.bottomAnchor, constant: 4),

            // Permission indicators (bottom right)
            accessibilityStatusIcon.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            accessibilityStatusIcon.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            accessibilityStatusIcon.widthAnchor.constraint(equalToConstant: 16),
            accessibilityStatusIcon.heightAnchor.constraint(equalToConstant: 16),

            accessibilityStatusLabel.trailingAnchor.constraint(equalTo: accessibilityStatusIcon.leadingAnchor, constant: -4),
            accessibilityStatusLabel.centerYAnchor.constraint(equalTo: accessibilityStatusIcon.centerYAnchor),

            micStatusIcon.trailingAnchor.constraint(equalTo: accessibilityStatusLabel.leadingAnchor, constant: -16),
            micStatusIcon.centerYAnchor.constraint(equalTo: accessibilityStatusIcon.centerYAnchor),
            micStatusIcon.widthAnchor.constraint(equalToConstant: 16),
            micStatusIcon.heightAnchor.constraint(equalToConstant: 16),

            micStatusLabel.trailingAnchor.constraint(equalTo: micStatusIcon.leadingAnchor, constant: -4),
            micStatusLabel.centerYAnchor.constraint(equalTo: accessibilityStatusIcon.centerYAnchor),
        ])

        // Set actions
        modelPopup.target = self
        modelPopup.action = #selector(modelChanged(_:))
        inputPopup.target = self
        inputPopup.action = #selector(inputChanged(_:))
        shortcutPopup.target = self
        shortcutPopup.action = #selector(shortcutChanged(_:))

        refresh()
    }

    private func createLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13)
        label.alignment = .right
        return label
    }

    private func createPopup() -> NSPopUpButton {
        let popup = NSPopUpButton(frame: .zero, pullsDown: false)
        popup.font = NSFont.systemFont(ofSize: 13)
        return popup
    }

    func refresh() {
        refreshModels()
        refreshInputDevices()
        refreshShortcuts()
        refreshPermissions()
        refreshHistory()
        refreshWordReplacements()
    }

    // MARK: - Language/Models

    private func refreshModels() {
        modelPopup.removeAllItems()

        let currentModel = AppSettings.shared.selectedModel
        var isDownloading = false

        for model in ASRModel.availableModels {
            let status = modelManager.modelStatus[model] ?? .notDownloaded
            var title = model.languageOption

            switch status {
            case .notDownloaded:
                title += " ↓"
            case .downloading(let progress):
                title += " (\(Int(progress * 100))%)"
                if model == currentModel {
                    isDownloading = true
                }
            case .downloaded:
                title += " ✓"
            case .error:
                title += " ⚠"
            }

            modelPopup.addItem(withTitle: title)
            modelPopup.lastItem?.representedObject = model

            if model == currentModel {
                modelPopup.select(modelPopup.lastItem)
            }
        }

        // Show hint while downloading
        hintLabel.isHidden = !isDownloading
    }

    private func refreshInputDevices() {
        inputPopup.removeAllItems()

        let devices = audioInputManager.getInputDevices()
        let currentUID = AppSettings.shared.inputDeviceUID

        // Add "System Default" first, showing what the current default is
        var systemDefaultTitle = NSLocalizedString("System Default", comment: "")
        if let defaultID = audioInputManager.getDefaultInputDevice(),
           let defaultDevice = devices.first(where: { $0.id == defaultID }) {
            systemDefaultTitle += " (\(defaultDevice.name))"
        }
        inputPopup.addItem(withTitle: systemDefaultTitle)
        inputPopup.lastItem?.representedObject = ""

        // Add all hardware devices
        for device in devices {
            inputPopup.addItem(withTitle: device.name)
            inputPopup.lastItem?.representedObject = device.uid
        }

        // Select saved device, or default to built-in mic if no preference
        var selected = false
        if !currentUID.isEmpty {
            for i in 0..<inputPopup.numberOfItems {
                if let uid = inputPopup.item(at: i)?.representedObject as? String, uid == currentUID {
                    inputPopup.selectItem(at: i)
                    selected = true
                    break
                }
            }
        }
        if !selected {
            // Default to built-in microphone
            if let builtIn = audioInputManager.getBuiltInMicrophone() {
                for i in 0..<inputPopup.numberOfItems {
                    if let uid = inputPopup.item(at: i)?.representedObject as? String, uid == builtIn.uid {
                        inputPopup.selectItem(at: i)
                        AppSettings.shared.inputDeviceUID = builtIn.uid
                        selected = true
                        break
                    }
                }
            }
            // Fall back to System Default if no built-in found
            if !selected {
                inputPopup.selectItem(at: 0)
            }
        }
    }

    private func refreshShortcuts() {
        shortcutPopup.removeAllItems()

        let currentHotkey = AppSettings.shared.recordHotkey

        for preset in Hotkey.presets {
            shortcutPopup.addItem(withTitle: preset.name)
            shortcutPopup.lastItem?.representedObject = preset.hotkey

            if preset.hotkey == currentHotkey {
                shortcutPopup.select(shortcutPopup.lastItem)
            }
        }
    }

    // MARK: - Actions

    @objc private func modelChanged(_ sender: NSPopUpButton) {
        guard let model = sender.selectedItem?.representedObject as? ASRModel else { return }

        // If model not downloaded, start download
        if !modelManager.isModelDownloaded(model) {
            modelManager.downloadModel(model)
            // Refresh to show download progress
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.refreshModels()
            }
            return
        }

        AppSettings.shared.selectedModel = model
        // Notify the app to reload the model
        NotificationCenter.default.post(name: .modelChanged, object: model)
    }

    @objc private func inputChanged(_ sender: NSPopUpButton) {
        guard let uid = sender.selectedItem?.representedObject as? String else { return }
        AppSettings.shared.inputDeviceUID = uid
    }

    @objc private func shortcutChanged(_ sender: NSPopUpButton) {
        guard let hotkey = sender.selectedItem?.representedObject as? Hotkey else { return }
        AppSettings.shared.recordHotkey = hotkey
    }

    // MARK: - Permissions

    private func refreshPermissions() {
        // Microphone permission
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        micStatusLabel.stringValue = NSLocalizedString("Microphone", comment: "")

        if micStatus == .authorized {
            micStatusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
            micStatusIcon.contentTintColor = .systemGreen
        } else {
            micStatusIcon.image = NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "Not Granted")
            micStatusIcon.contentTintColor = .systemYellow
        }

        // Accessibility permission
        accessibilityStatusLabel.stringValue = NSLocalizedString("Accessibility", comment: "")

        let accessibilityGranted = AXIsProcessTrusted()
        if accessibilityGranted {
            accessibilityStatusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
            accessibilityStatusIcon.contentTintColor = .systemGreen
        } else {
            accessibilityStatusIcon.image = NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: "Not Granted")
            accessibilityStatusIcon.contentTintColor = .systemYellow
        }
    }

    @objc private func openMicrophoneSettings() {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshPermissions()
                }
            }
        } else {
            // Open System Settings > Privacy > Microphone
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc private func openAccessibilitySettings() {
        // Open System Settings directly without showing Apple's popup
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - History

    private func refreshHistory() {
        // Clear existing items
        historyStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let items = historyManager.getAllItems()

        if items.isEmpty {
            let emptyLabel = NSTextField(labelWithString: NSLocalizedString("No transcriptions yet", comment: ""))
            emptyLabel.font = NSFont.systemFont(ofSize: 12)
            emptyLabel.textColor = .secondaryLabelColor
            historyStackView.addArrangedSubview(emptyLabel)
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        for (index, item) in items.enumerated() {
            let rowView = createHistoryRow(item: item, index: index, dateFormatter: dateFormatter)
            historyStackView.addArrangedSubview(rowView)
        }
    }

    private func createHistoryRow(item: HistoryItem, index: Int, dateFormatter: DateFormatter) -> NSView {
        let rowView = NSView()
        rowView.translatesAutoresizingMaskIntoConstraints = false

        // Time label
        let timeLabel = NSTextField(labelWithString: dateFormatter.string(from: item.timestamp))
        timeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = .secondaryLabelColor
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        // Text label (truncated)
        let text = item.text.replacingOccurrences(of: "\n", with: " ")
        let truncated = text.count > 60 ? String(text.prefix(60)) + "..." : text
        let textLabel = NSTextField(labelWithString: truncated)
        textLabel.font = NSFont.systemFont(ofSize: 12)
        textLabel.textColor = .labelColor
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.toolTip = item.text  // Full text on hover

        rowView.addSubview(timeLabel)
        rowView.addSubview(textLabel)

        // Play button if audio exists
        if item.audioURL != nil {
            let playButton = NSButton(image: NSImage(systemSymbolName: "play.circle", accessibilityDescription: "Play")!, target: self, action: #selector(playHistoryItem(_:)))
            playButton.bezelStyle = .inline
            playButton.isBordered = false
            playButton.tag = index
            playButton.translatesAutoresizingMaskIntoConstraints = false
            rowView.addSubview(playButton)

            NSLayoutConstraint.activate([
                timeLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                timeLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                timeLabel.widthAnchor.constraint(equalToConstant: 120),

                textLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
                textLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -8),

                playButton.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                playButton.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                playButton.widthAnchor.constraint(equalToConstant: 24),

                rowView.heightAnchor.constraint(equalToConstant: 20),
                rowView.widthAnchor.constraint(equalToConstant: 440),
            ])
        } else {
            NSLayoutConstraint.activate([
                timeLabel.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                timeLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                timeLabel.widthAnchor.constraint(equalToConstant: 120),

                textLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 8),
                textLabel.centerYAnchor.constraint(equalTo: rowView.centerYAnchor),
                textLabel.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),

                rowView.heightAnchor.constraint(equalToConstant: 20),
                rowView.widthAnchor.constraint(equalToConstant: 440),
            ])
        }

        return rowView
    }

    @objc private func playHistoryItem(_ sender: NSButton) {
        historyManager.playAudio(at: sender.tag)
    }

    // MARK: - Word Replacements

    private func refreshWordReplacements() {
        let replacements = AppSettings.shared.wordReplacements
        let lines = replacements.map { "\($0.key)=\($0.value)" }.sorted()
        wordReplacementsTextView.string = lines.joined(separator: "\n")
    }

    private func saveWordReplacements() {
        let text = wordReplacementsTextView.string
        var replacements: [String: String] = [:]

        for line in text.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            // Parse "find=replace" format
            let parts = trimmed.components(separatedBy: "=")
            if parts.count >= 2 {
                let find = parts[0].trimmingCharacters(in: .whitespaces)
                let replace = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
                if !find.isEmpty {
                    replacements[find] = replace
                }
            }
        }

        AppSettings.shared.wordReplacements = replacements
    }
}

// MARK: - NSTextViewDelegate

extension SettingsView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        guard notification.object as? NSTextView === wordReplacementsTextView else { return }
        saveWordReplacements()
    }
}

// Flipped view for top-aligned scroll content
class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

// Notification for model change
extension Notification.Name {
    static let modelChanged = Notification.Name("modelChanged")
    static let historyDidUpdate = Notification.Name("historyDidUpdate")
}
