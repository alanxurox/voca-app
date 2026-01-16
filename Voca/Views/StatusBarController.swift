import Cocoa

enum RecordingState {
    case idle
    case recording
    case processing
}

// MARK: - Custom View for Model Menu Items

class ModelMenuItemView: NSView {
    private let leftLabel = NSTextField(labelWithString: "")
    private let rightLabel = NSTextField(labelWithString: "")
    private let checkmark = NSTextField(labelWithString: "")

    var isSelected: Bool = false {
        didSet { checkmark.stringValue = isSelected ? "✓" : "" }
    }

    var rightText: String = "" {
        didSet { rightLabel.stringValue = rightText }
    }

    var onClicked: (() -> Void)?

    private var isHighlighted = false {
        didSet { needsDisplay = true }
    }

    init(title: String, width: CGFloat = 250) {
        // Width matches menu with keyEquivalent column (~250 for alignment with ⌘Q)
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: 22))

        // Checkmark on the left
        checkmark.font = NSFont.menuFont(ofSize: 0)
        checkmark.textColor = .labelColor
        checkmark.alignment = .left
        checkmark.isBordered = false
        checkmark.isEditable = false
        checkmark.backgroundColor = .clear
        checkmark.frame = NSRect(x: 6, y: 2, width: 16, height: 18)
        addSubview(checkmark)

        // Model name
        leftLabel.stringValue = title
        leftLabel.font = NSFont.menuFont(ofSize: 0)
        leftLabel.textColor = .labelColor
        leftLabel.alignment = .left
        leftLabel.isBordered = false
        leftLabel.isEditable = false
        leftLabel.backgroundColor = .clear
        leftLabel.frame = NSRect(x: 24, y: 2, width: 120, height: 18)
        addSubview(leftLabel)

        // Right indicator - positioned to align with keyEquivalent column (⌘Q)
        rightLabel.font = NSFont.menuFont(ofSize: 0)
        rightLabel.textColor = .secondaryLabelColor
        rightLabel.alignment = .right
        rightLabel.isBordered = false
        rightLabel.isEditable = false
        rightLabel.backgroundColor = .clear
        rightLabel.frame = NSRect(x: width - 45, y: 2, width: 35, height: 18)
        addSubview(rightLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        if isHighlighted {
            NSColor.selectedContentBackgroundColor.setFill()
            bounds.fill()
            leftLabel.textColor = .white
            checkmark.textColor = .white
            rightLabel.textColor = .white.withAlphaComponent(0.8)
        } else {
            leftLabel.textColor = .labelColor
            checkmark.textColor = .labelColor
            rightLabel.textColor = .secondaryLabelColor
        }
    }

    override func mouseEntered(with event: NSEvent) {
        isHighlighted = true
    }

    override func mouseExited(with event: NSEvent) {
        isHighlighted = false
    }

    override func mouseUp(with event: NSEvent) {
        onClicked?()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInActiveApp],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    // Model menu items and views (for updating state/progress)
    private var modelMenuItems: [ASRModel: NSMenuItem] = [:]
    private var modelMenuViews: [ASRModel: ModelMenuItemView] = [:]

    private let onModelChange: (ASRModel) -> Void
    private let historyManager: HistoryManager
    private let modelManager = ModelManager.shared

    init(onModelChange: @escaping (ASRModel) -> Void,
         historyManager: HistoryManager) {
        self.onModelChange = onModelChange
        self.historyManager = historyManager

        super.init()

        setupStatusItem()
        setupMenu()
        setupModelManagerCallbacks()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = createIcon("waveform.circle.fill", size: 18)
            button.image?.isTemplate = true
        }
    }

    private func createIcon(_ name: String, size: CGFloat) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: size, weight: .regular)
        return NSImage(systemSymbolName: name, accessibilityDescription: "Voca")?
            .withSymbolConfiguration(config)
    }

    private func setupMenu() {
        menu = NSMenu()

        // Hint at top - show ⌘ on the right
        let hintItem = NSMenuItem(title: "Double-\u{2318} and hold to record", action: nil, keyEquivalent: "\u{2318}")
        hintItem.isEnabled = false
        menu.addItem(hintItem)

        menu.addItem(NSMenuItem.separator())

        // Models section header
        let modelsHeader = NSMenuItem(title: "Models", action: nil, keyEquivalent: "")
        modelsHeader.isEnabled = false
        menu.addItem(modelsHeader)

        // Model items (using custom views to prevent menu dismissal)
        for model in ASRModel.availableModels {
            let item = NSMenuItem()
            let view = ModelMenuItemView(title: model.shortName)
            view.onClicked = { [weak self] in
                self?.handleModelClick(model)
            }
            item.view = view
            modelMenuItems[model] = item
            modelMenuViews[model] = view
            menu.addItem(item)
        }

        // History section - separator, header, and items added dynamically in menuWillOpen
        // Tag 200 marks the position where history section starts
        let historySeparator = NSMenuItem.separator()
        historySeparator.tag = 200
        menu.addItem(historySeparator)

        menu.addItem(NSMenuItem.separator())

        // Check for Updates
        let updateItem = NSMenuItem(title: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        // About
        let aboutItem = NSMenuItem(title: "About Voca", action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        menu.delegate = self
    }

    private func createHistoryHeader() -> NSMenuItem {
        let item = NSMenuItem(title: "History", action: nil, keyEquivalent: "v")
        item.keyEquivalentModifierMask = [.control, .option]
        item.isEnabled = false
        return item
    }

    private func setupModelManagerCallbacks() {
        modelManager.onStatusChanged = { [weak self] model, status in
            DispatchQueue.main.async {
                self?.updateModelMenuItem(model, status: status)
            }
        }
    }

    private func updateModelMenuItem(_ model: ASRModel, status: ModelStatus) {
        guard let view = modelMenuViews[model] else { return }

        let isSelected = AppSettings.shared.selectedModel == model
        view.isSelected = isSelected

        switch status {
        case .notDownloaded:
            view.rightText = "↓"
        case .downloading(let progress):
            let percent = Int(progress * 100)
            view.rightText = "\(percent)%"
        case .downloaded:
            view.rightText = ""
        case .error:
            view.rightText = "✗"
        }
    }

    private func handleModelClick(_ model: ASRModel) {
        // If model not downloaded, start download (menu stays open)
        if !modelManager.isModelDownloaded(model) {
            modelManager.downloadModel(model)
            return
        }

        // Model is downloaded, select it
        AppSettings.shared.selectedModel = model
        updateSelectedModel(model)
        onModelChange(model)
    }

    @objc private func aboutClicked() {
        AboutWindowController.shared.show()
    }

    func setState(_ state: RecordingState) {
        guard let button = statusItem.button else { return }

        switch state {
        case .idle:
            button.image = createIcon("waveform.circle.fill", size: 18)
            button.image?.isTemplate = true
            button.contentTintColor = nil

        case .recording:
            button.image = createIcon("record.circle.fill", size: 18)
            button.image?.isTemplate = false
            button.contentTintColor = .systemRed

        case .processing:
            button.image = createIcon("circle.dashed", size: 18)
            button.image?.isTemplate = false
            button.contentTintColor = .systemOrange
        }
    }

    func updateSelectedModel(_ model: ASRModel) {
        for (itemModel, view) in modelMenuViews {
            view.isSelected = itemModel == model
        }
    }

    @objc private func quitClicked() {
        NSApp.terminate(nil)
    }

    @objc private func historyItemClicked(_ sender: NSMenuItem) {
        guard let text = sender.representedObject as? String else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let source = CGEventSource(stateID: .hidSystemState)
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            keyDown?.flags = .maskCommand
            keyUp?.flags = .maskCommand
            keyDown?.post(tap: .cghidEventTap)
            keyUp?.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Update Checker

    @objc private func checkForUpdates() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        let url = URL(string: "https://api.github.com/repos/zhengyishen0/voca-app/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.showUpdateAlert(title: "Update Check Failed",
                                        message: "Could not check for updates: \(error.localizedDescription)")
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.showUpdateAlert(title: "Update Check Failed",
                                        message: "Could not parse update information.")
                    return
                }

                let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

                if self.isVersion(latestVersion, newerThan: currentVersion) {
                    let alert = NSAlert()
                    alert.messageText = "Update Available"
                    alert.informativeText = "A new version (\(latestVersion)) is available. You are currently running version \(currentVersion)."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Download")
                    alert.addButton(withTitle: "Later")

                    if alert.runModal() == .alertFirstButtonReturn {
                        if let downloadURL = URL(string: "https://github.com/zhengyishen0/voca-app/releases/latest") {
                            NSWorkspace.shared.open(downloadURL)
                        }
                    }
                } else {
                    self.showUpdateAlert(title: "You're Up to Date",
                                        message: "Voca \(currentVersion) is the latest version.")
                }
            }
        }.resume()
    }

    private func showUpdateAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func isVersion(_ version1: String, newerThan version2: String) -> Bool {
        let v1 = version1.split(separator: ".").compactMap { Int($0) }
        let v2 = version2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(v1.count, v2.count) {
            let n1 = i < v1.count ? v1[i] : 0
            let n2 = i < v2.count ? v2[i] : 0
            if n1 > n2 { return true }
            if n1 < n2 { return false }
        }
        return false
    }

    /// Truncate string to fit within maxWidth pixels (handles CJK vs Latin width differences)
    private func truncateToWidth(_ text: String, maxWidth: CGFloat) -> String {
        let font = NSFont.menuFont(ofSize: 0)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        // Check if full text fits
        let fullSize = (text as NSString).size(withAttributes: attributes)
        if fullSize.width <= maxWidth {
            return text
        }

        // Binary search for the right length
        var low = 0
        var high = text.count
        var result = ""

        while low < high {
            let mid = (low + high + 1) / 2
            let truncated = String(text.prefix(mid))
            let size = (truncated as NSString).size(withAttributes: attributes)

            if size.width <= maxWidth - 15 { // Leave room for "..."
                result = truncated
                low = mid
            } else {
                high = mid - 1
            }
        }

        return result.isEmpty ? String(text.prefix(10)) : result + "..."
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update model statuses
        modelManager.checkAllModelStatus()
        for model in ASRModel.availableModels {
            if let status = modelManager.modelStatus[model] {
                updateModelMenuItem(model, status: status)
            }
        }

        // Remove old history items (tags 201+)
        while let item = menu.item(withTag: 201) {
            menu.removeItem(item)
        }
        while let item = menu.item(withTag: 202) {
            menu.removeItem(item)
        }
        while let item = menu.item(withTag: 203) {
            menu.removeItem(item)
        }
        while let item = menu.item(withTag: 204) {  // Header
            menu.removeItem(item)
        }

        // Get history
        let history = historyManager.getAll()

        // Find insertion point (after separator with tag 200)
        guard let separatorIndex = menu.items.firstIndex(where: { $0.tag == 200 }) else { return }

        var insertIndex = separatorIndex + 1

        // Always show history header (with right-aligned shortcut)
        let header = createHistoryHeader()
        header.tag = 204
        menu.insertItem(header, at: insertIndex)
        insertIndex += 1

        // Add history items if any
        for (i, text) in history.prefix(3).enumerated() {
            let preview = truncateToWidth(text, maxWidth: 300)
            let item = NSMenuItem(
                title: "  \(preview)",
                action: #selector(historyItemClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = text
            item.tag = 201 + i
            menu.insertItem(item, at: insertIndex)
            insertIndex += 1
        }
    }
}
