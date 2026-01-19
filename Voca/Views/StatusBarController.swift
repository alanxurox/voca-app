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
    private var historyManager: HistoryManager { HistoryManager.shared }

    init(onModelChange: @escaping (ASRModel) -> Void) {
        self.onModelChange = onModelChange

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

        // License status
        let licenseItem = NSMenuItem(title: LicenseManager.shared.statusText, action: #selector(showLicense), keyEquivalent: "")
        licenseItem.target = self
        if !LicenseManager.shared.isLicensed && !LicenseManager.shared.isTrialActive {
            licenseItem.attributedTitle = NSAttributedString(
                string: "Trial Expired",
                attributes: [.foregroundColor: NSColor.systemRed]
            )
        }
        menu.addItem(licenseItem)

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

        // Listen for license status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLicenseChanged),
            name: .licenseStatusChanged,
            object: nil
        )
    }

    @objc private func handleLicenseChanged() {
        // Rebuild menu to reflect new license status
        setupMenu()
    }

    @objc private func showLicense() {
        LicenseWindowController.shared.showLicenseWindow()
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
        // Handle both old format (string) and new format (dictionary)
        let text: String
        if let dict = sender.representedObject as? [String: Any],
           let t = dict["text"] as? String {
            text = t
        } else if let t = sender.representedObject as? String {
            text = t
        } else {
            return
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Simulate Cmd+V using cgSessionEventTap (based on Maccy implementation)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let vKeyCode: CGKeyCode = 0x09  // V key

            // Use combinedSessionState like Maccy does
            let source = CGEventSource(stateID: .combinedSessionState)

            // Configure event filtering during suppression (key for hardened runtime)
            source?.setLocalEventsFilterDuringSuppressionState(
                [.permitLocalMouseEvents, .permitSystemDefinedEvents],
                state: .eventSuppressionStateSuppressionInterval
            )

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)

            let cmdFlag = CGEventFlags(rawValue: CGEventFlags.maskCommand.rawValue | 0x000008)
            keyDown?.flags = cmdFlag
            keyUp?.flags = cmdFlag

            keyDown?.post(tap: .cgSessionEventTap)
            keyUp?.post(tap: .cgSessionEventTap)
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
                        // Direct download URL for the DMG
                        let dmgURL = "https://github.com/zhengyishen0/voca-app/releases/download/\(tagName)/Voca-\(latestVersion).dmg"
                        if let downloadURL = URL(string: dmgURL) {
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
        for tag in 201...210 {
            while let item = menu.item(withTag: tag) {
                menu.removeItem(item)
            }
        }
        while let item = menu.item(withTag: 204) {  // Header
            menu.removeItem(item)
        }

        // Get history items
        let historyItems = historyManager.getAllItems()

        // Find insertion point (after separator with tag 200)
        guard let separatorIndex = menu.items.firstIndex(where: { $0.tag == 200 }) else { return }

        var insertIndex = separatorIndex + 1

        // Always show history header (with right-aligned shortcut)
        let header = createHistoryHeader()
        header.tag = 204
        menu.insertItem(header, at: insertIndex)
        insertIndex += 1

        // Add history items - simple click to paste
        for (i, historyItem) in historyItems.prefix(5).enumerated() {
            let preview = truncateToWidth(historyItem.text, maxWidth: 200)

            let item = NSMenuItem(
                title: "  \(preview)",
                action: #selector(historyItemClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = historyItem.text
            item.tag = 201 + i

            menu.insertItem(item, at: insertIndex)
            insertIndex += 1
        }
    }
}
