import Cocoa

enum RecordingState {
    case idle
    case recording
    case processing
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var hintItem: NSMenuItem!

    private let onModelChange: (ASRModel) -> Void
    private let historyManager: HistoryManager

    init(onModelChange: @escaping (ASRModel) -> Void,
         historyManager: HistoryManager) {
        self.onModelChange = onModelChange
        self.historyManager = historyManager

        super.init()

        setupStatusItem()
        setupMenu()
        setupNotifications()
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

        // Hint at top - shows current shortcut
        hintItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        hintItem.isEnabled = false
        updateHintText()
        menu.addItem(hintItem)

        // History section - separator, header, and items added dynamically in menuWillOpen
        // Tag 200 marks the position where history section starts
        let historySeparator = NSMenuItem.separator()
        historySeparator.tag = 200
        menu.addItem(historySeparator)

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(title: NSLocalizedString("Settings...", comment: ""), action: #selector(settingsClicked), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        // Check for Updates
        let updateItem = NSMenuItem(title: NSLocalizedString("Check for Updates...", comment: ""), action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        // About
        let aboutItem = NSMenuItem(title: NSLocalizedString("About Voca", comment: ""), action: #selector(aboutClicked), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        // Quit
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        menu.delegate = self
    }

    private func createHistoryHeader() -> NSMenuItem {
        let item = NSMenuItem(title: NSLocalizedString("History", comment: ""), action: nil, keyEquivalent: "v")
        item.keyEquivalentModifierMask = [.control, .option]
        item.isEnabled = false
        return item
    }

    private func setupNotifications() {
        // Listen for model changes from Settings window
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModelChanged(_:)),
            name: .modelChanged,
            object: nil
        )
    }

    @objc private func handleModelChanged(_ notification: Notification) {
        if let model = notification.object as? ASRModel {
            onModelChange(model)
        }
    }

    private func updateHintText() {
        let hotkey = AppSettings.shared.recordHotkey
        if hotkey.isDoubleTap {
            hintItem.title = String(format: NSLocalizedString("Double-tap %@ to record", comment: ""), hotkey.symbolString)
        } else {
            hintItem.title = String(format: NSLocalizedString("Hold %@ to record", comment: ""), hotkey.symbolString)
        }
    }

    @objc private func settingsClicked() {
        SettingsWindowController.shared.show()
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
                    self.showUpdateAlert(title: NSLocalizedString("Update Check Failed", comment: ""),
                                        message: String(format: NSLocalizedString("Could not check for updates: %@", comment: ""), error.localizedDescription))
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tagName = json["tag_name"] as? String else {
                    self.showUpdateAlert(title: NSLocalizedString("Update Check Failed", comment: ""),
                                        message: NSLocalizedString("Could not parse update information.", comment: ""))
                    return
                }

                let latestVersion = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

                if self.isVersion(latestVersion, newerThan: currentVersion) {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Update Available", comment: "")
                    alert.informativeText = String(format: NSLocalizedString("A new version (%@) is available. You are currently running version %@.", comment: ""), latestVersion, currentVersion)
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: NSLocalizedString("Download", comment: ""))
                    alert.addButton(withTitle: NSLocalizedString("Later", comment: ""))

                    if alert.runModal() == .alertFirstButtonReturn {
                        if let downloadURL = URL(string: "https://github.com/zhengyishen0/voca-app/releases/latest") {
                            NSWorkspace.shared.open(downloadURL)
                        }
                    }
                } else {
                    self.showUpdateAlert(title: NSLocalizedString("You're Up to Date", comment: ""),
                                        message: String(format: NSLocalizedString("Voca %@ is the latest version.", comment: ""), currentVersion))
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
        // Update hint text in case shortcut changed
        updateHintText()

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
