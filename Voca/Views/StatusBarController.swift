import Cocoa

enum RecordingState {
    case idle
    case recording
    case processing
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!

    // Model menu items (for updating state/progress)
    private var modelMenuItems: [ASRModel: NSMenuItem] = [:]

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

        // Hint at top
        let hintItem = NSMenuItem(title: "⌘⌘ to record", action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        menu.addItem(hintItem)

        menu.addItem(NSMenuItem.separator())

        // Models section header
        let modelsHeader = NSMenuItem(title: "Models", action: nil, keyEquivalent: "")
        modelsHeader.isEnabled = false
        menu.addItem(modelsHeader)

        // Model items (only available models)
        for model in ASRModel.availableModels {
            let item = NSMenuItem(
                title: "  \(model.shortName)",
                action: #selector(modelSelected(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = model
            item.indentationLevel = 1
            modelMenuItems[model] = item
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
        let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        item.isEnabled = false

        // Create attributed string with "History" on left and "⌃⌥V" on right
        let title = "History"
        let shortcut = "⌃⌥V"

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: 120)]

        let attributed = NSMutableAttributedString(
            string: "\(title)\t\(shortcut)",
            attributes: [
                .font: NSFont.menuFont(ofSize: 0),
                .paragraphStyle: paragraphStyle
            ]
        )

        // Make shortcut gray
        let shortcutRange = (attributed.string as NSString).range(of: shortcut)
        attributed.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: shortcutRange)

        item.attributedTitle = attributed
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
        guard let item = modelMenuItems[model] else { return }

        let isSelected = AppSettings.shared.selectedModel == model

        switch status {
        case .notDownloaded:
            item.attributedTitle = createModelTitle(model.shortName, rightText: "↓")
            item.state = isSelected ? .on : .off
            item.isEnabled = true

        case .downloading(let progress):
            let percent = Int(progress * 100)
            item.attributedTitle = createModelTitle(model.shortName, rightText: "\(percent)%")
            item.state = .off
            item.isEnabled = false

        case .downloaded:
            item.title = "  \(model.shortName)"
            item.attributedTitle = nil
            item.state = isSelected ? .on : .off
            item.isEnabled = true

        case .error(let message):
            item.attributedTitle = createModelTitle(model.shortName, rightText: "✗")
            item.toolTip = message
            item.state = isSelected ? .on : .off
            item.isEnabled = true
        }
    }

    private func createModelTitle(_ name: String, rightText: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .right, location: 120)]

        return NSAttributedString(
            string: "  \(name)\t\(rightText)",
            attributes: [
                .font: NSFont.menuFont(ofSize: 0),
                .paragraphStyle: paragraphStyle
            ]
        )
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
        for (itemModel, item) in modelMenuItems {
            item.state = itemModel == model ? .on : .off
        }
    }

    @objc private func modelSelected(_ sender: NSMenuItem) {
        guard let model = sender.representedObject as? ASRModel else { return }

        // If model not downloaded, start download
        if !modelManager.isModelDownloaded(model) {
            modelManager.downloadModel(model)
            return
        }

        // Model is downloaded, select it
        AppSettings.shared.selectedModel = model
        updateSelectedModel(model)
        onModelChange(model)
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

        // Only show history section if there's history
        if !history.isEmpty {
            var insertIndex = separatorIndex + 1

            // Add header
            let header = createHistoryHeader()
            header.tag = 204
            menu.insertItem(header, at: insertIndex)
            insertIndex += 1

            // Add history items
            for (i, text) in history.prefix(3).enumerated() {
                let preview = String(text.prefix(35)) + (text.count > 35 ? "..." : "")
                let item = NSMenuItem(
                    title: "  \(i + 1). \(preview)",
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
}
