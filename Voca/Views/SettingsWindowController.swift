import Cocoa

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()

    private var contentView: SettingsView!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 200),
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
    private var modelPopup: NSPopUpButton!
    private var inputPopup: NSPopUpButton!
    private var shortcutPopup: NSPopUpButton!

    private let modelManager = ModelManager.shared
    private let audioInputManager = AudioInputManager.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Create labels and popups
        let modelLabel = createLabel(NSLocalizedString("Model", comment: ""))
        let inputLabel = createLabel(NSLocalizedString("Audio Input", comment: ""))
        let shortcutLabel = createLabel(NSLocalizedString("Shortcut", comment: ""))

        modelPopup = createPopup()
        inputPopup = createPopup()
        shortcutPopup = createPopup()

        // Add to view
        addSubview(modelLabel)
        addSubview(modelPopup)
        addSubview(inputLabel)
        addSubview(inputPopup)
        addSubview(shortcutLabel)
        addSubview(shortcutPopup)

        // Layout with Auto Layout
        modelLabel.translatesAutoresizingMaskIntoConstraints = false
        modelPopup.translatesAutoresizingMaskIntoConstraints = false
        inputLabel.translatesAutoresizingMaskIntoConstraints = false
        inputPopup.translatesAutoresizingMaskIntoConstraints = false
        shortcutLabel.translatesAutoresizingMaskIntoConstraints = false
        shortcutPopup.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Model row
            modelLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            modelLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            modelLabel.widthAnchor.constraint(equalToConstant: 100),

            modelPopup.leadingAnchor.constraint(equalTo: modelLabel.trailingAnchor, constant: 10),
            modelPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            modelPopup.centerYAnchor.constraint(equalTo: modelLabel.centerYAnchor),

            // Audio Input row
            inputLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            inputLabel.topAnchor.constraint(equalTo: modelLabel.bottomAnchor, constant: 20),
            inputLabel.widthAnchor.constraint(equalToConstant: 100),

            inputPopup.leadingAnchor.constraint(equalTo: inputLabel.trailingAnchor, constant: 10),
            inputPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            inputPopup.centerYAnchor.constraint(equalTo: inputLabel.centerYAnchor),

            // Shortcut row
            shortcutLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            shortcutLabel.topAnchor.constraint(equalTo: inputLabel.bottomAnchor, constant: 20),
            shortcutLabel.widthAnchor.constraint(equalToConstant: 100),

            shortcutPopup.leadingAnchor.constraint(equalTo: shortcutLabel.trailingAnchor, constant: 10),
            shortcutPopup.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            shortcutPopup.centerYAnchor.constraint(equalTo: shortcutLabel.centerYAnchor),
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
    }

    // MARK: - Models

    private func refreshModels() {
        modelPopup.removeAllItems()

        let currentModel = AppSettings.shared.selectedModel

        for model in ASRModel.availableModels {
            let status = modelManager.modelStatus[model] ?? .notDownloaded
            var title = model.shortName

            switch status {
            case .notDownloaded:
                title += " (\(model.languageHint)) ↓"
            case .downloading(let progress):
                title += " (\(Int(progress * 100))%)"
            case .downloaded:
                title += " (\(model.languageHint))"
            case .error:
                title += " (\(NSLocalizedString("Error", comment: "")))"
            }

            modelPopup.addItem(withTitle: title)
            modelPopup.lastItem?.representedObject = model

            if model == currentModel {
                modelPopup.select(modelPopup.lastItem)
            }
        }
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
}

// Notification for model change
extension Notification.Name {
    static let modelChanged = Notification.Name("modelChanged")
}
