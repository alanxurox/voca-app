import Cocoa
import AVFoundation
import ApplicationServices

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private var contentView: SettingsView!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 180),
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
    private var micStatusIcon: NSImageView!
    private var micButton: NSButton!
    private var accessibilityStatusLabel: NSTextField!
    private var accessibilityStatusIcon: NSImageView!
    private var accessibilityButton: NSButton!

    private let modelManager = ModelManager.shared
    private let audioInputManager = AudioInputManager.shared

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
        micStatusLabel.font = NSFont.systemFont(ofSize: 13)
        micStatusLabel.textColor = .labelColor

        micStatusIcon = NSImageView()
        micStatusIcon.imageScaling = .scaleProportionallyDown

        micButton = NSButton(title: NSLocalizedString("Grant", comment: ""), target: self, action: #selector(openMicrophoneSettings))
        micButton.bezelStyle = .inline
        micButton.font = NSFont.systemFont(ofSize: 11)

        accessibilityStatusLabel = NSTextField(labelWithString: "")
        accessibilityStatusLabel.font = NSFont.systemFont(ofSize: 13)
        accessibilityStatusLabel.textColor = .labelColor

        accessibilityStatusIcon = NSImageView()
        accessibilityStatusIcon.imageScaling = .scaleProportionallyDown

        accessibilityButton = NSButton(title: NSLocalizedString("Grant", comment: ""), target: self, action: #selector(openAccessibilitySettings))
        accessibilityButton.bezelStyle = .inline
        accessibilityButton.font = NSFont.systemFont(ofSize: 11)

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
        addSubview(micButton)
        addSubview(accessibilityStatusLabel)
        addSubview(accessibilityStatusIcon)
        addSubview(accessibilityButton)

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
        micButton.translatesAutoresizingMaskIntoConstraints = false
        accessibilityStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        accessibilityStatusIcon.translatesAutoresizingMaskIntoConstraints = false
        accessibilityButton.translatesAutoresizingMaskIntoConstraints = false

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

            // Permission indicators (right-aligned with dropdown edge)
            // Layout: [Mic Label] [Icon/Button] [Access Label] [Icon/Button]

            // Accessibility: [Label] [Icon] [Button] - aligned with dropdown trailing edge
            accessibilityButton.trailingAnchor.constraint(equalTo: shortcutPopup.trailingAnchor),
            accessibilityButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),

            accessibilityStatusIcon.trailingAnchor.constraint(equalTo: shortcutPopup.trailingAnchor),
            accessibilityStatusIcon.centerYAnchor.constraint(equalTo: accessibilityButton.centerYAnchor),
            accessibilityStatusIcon.widthAnchor.constraint(equalToConstant: 16),
            accessibilityStatusIcon.heightAnchor.constraint(equalToConstant: 16),

            accessibilityStatusLabel.trailingAnchor.constraint(equalTo: accessibilityStatusIcon.leadingAnchor, constant: -4),
            accessibilityStatusLabel.centerYAnchor.constraint(equalTo: accessibilityButton.centerYAnchor),

            // Microphone: [Label] [Icon] [Button] - reduced spacing (8pt instead of 16pt)
            micButton.trailingAnchor.constraint(equalTo: accessibilityStatusLabel.leadingAnchor, constant: -12),
            micButton.centerYAnchor.constraint(equalTo: accessibilityButton.centerYAnchor),

            micStatusIcon.trailingAnchor.constraint(equalTo: accessibilityStatusLabel.leadingAnchor, constant: -12),
            micStatusIcon.centerYAnchor.constraint(equalTo: accessibilityButton.centerYAnchor),
            micStatusIcon.widthAnchor.constraint(equalToConstant: 16),
            micStatusIcon.heightAnchor.constraint(equalToConstant: 16),

            micStatusLabel.trailingAnchor.constraint(equalTo: micStatusIcon.leadingAnchor, constant: -4),
            micStatusLabel.centerYAnchor.constraint(equalTo: accessibilityButton.centerYAnchor),
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

        for device in devices {
            inputPopup.addItem(withTitle: device.name)
            inputPopup.lastItem?.representedObject = device.uid

            let isSelected = (device.uid == currentUID) ||
                            (device.uid.isEmpty && currentUID.isEmpty)
            if isSelected {
                inputPopup.select(inputPopup.lastItem)
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
        micStatusLabel.textColor = .labelColor

        switch micStatus {
        case .authorized:
            micStatusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
            micStatusIcon.contentTintColor = .systemGreen
            micStatusIcon.isHidden = false
            micButton.isHidden = true
        default:
            micStatusIcon.isHidden = true
            micButton.isHidden = false
        }

        // Accessibility permission
        accessibilityStatusLabel.stringValue = NSLocalizedString("Accessibility", comment: "")
        accessibilityStatusLabel.textColor = .labelColor

        let accessibilityGranted = AXIsProcessTrusted()
        if accessibilityGranted {
            accessibilityStatusIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
            accessibilityStatusIcon.contentTintColor = .systemGreen
            accessibilityStatusIcon.isHidden = false
            accessibilityButton.isHidden = true
        } else {
            accessibilityStatusIcon.isHidden = true
            accessibilityButton.isHidden = false
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
        // Prompt for accessibility permission
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Also open System Settings > Privacy > Accessibility
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}

// Notification for model change
extension Notification.Name {
    static let modelChanged = Notification.Name("modelChanged")
}
