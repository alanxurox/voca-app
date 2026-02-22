import Cocoa
import Sparkle
import ServiceManagement

enum RecordingState {
    case idle
    case recording
    case processing
}

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var hintItem: NSMenuItem!
    private var updateItem: NSMenuItem!
    private var loginItem: NSMenuItem!

    private let updater: SPUUpdater
    private let onModelChange: (ASRModel) -> Void
    private var historyManager: HistoryManager { HistoryManager.shared }

    init(updater: SPUUpdater, onModelChange: @escaping (ASRModel) -> Void) {
        self.updater = updater
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

        // Launch at Login
        loginItem = NSMenuItem(title: NSLocalizedString("Launch at Login", comment: ""), action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        updateLoginItemState()
        menu.addItem(loginItem)

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
        updateItem = NSMenuItem(title: NSLocalizedString("Check for Updates...", comment: ""), action: #selector(checkForUpdates), keyEquivalent: "")
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

        // Listen for update availability changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUpdateAvailabilityChanged(_:)),
            name: .updateAvailabilityChanged,
            object: nil
        )
    }

    @objc private func handleUpdateAvailabilityChanged(_ notification: Notification) {
        guard let isAvailable = notification.object as? Bool else { return }
        if isAvailable {
            updateItem.title = NSLocalizedString("New Updates", comment: "")
        } else {
            updateItem.title = NSLocalizedString("Check for Updates...", comment: "")
        }
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

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            print("Failed to toggle login item: \(error)")
        }
        updateLoginItemState()
    }

    private func updateLoginItemState() {
        let service = SMAppService.mainApp
        loginItem.state = service.status == .enabled ? .on : .off
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
        guard let dict = sender.representedObject as? [String: Any],
              let text = dict["text"] as? String else { return }

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

    @objc private func playHistoryAudio(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let audioURL = dict["audioURL"] as? URL else { return }
        historyManager.playAudio(url: audioURL)
    }

    private func makeAudioSubmenu(representedObject: [String: Any]) -> NSMenu {
        let submenu = NSMenu()

        let copyItem = NSMenuItem(
            title: NSLocalizedString("Copy to Clipboard", comment: ""),
            action: #selector(historyItemClicked(_:)),
            keyEquivalent: ""
        )
        copyItem.target = self
        copyItem.representedObject = representedObject

        let playItem = NSMenuItem(
            title: NSLocalizedString("Play Audio", comment: ""),
            action: #selector(playHistoryAudio(_:)),
            keyEquivalent: ""
        )
        playItem.target = self
        playItem.representedObject = representedObject

        submenu.addItem(copyItem)
        submenu.addItem(playItem)
        return submenu
    }

    // MARK: - Update Checker

    @objc private func checkForUpdates() {
        updater.checkForUpdates()
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

        // Remove old history items (tags 201–210) and header (tag 204)
        for tag in 201...210 {
            while let item = menu.item(withTag: tag) {
                menu.removeItem(item)
            }
        }

        let historyItems = historyManager.allItems

        // Find insertion point (after separator with tag 200)
        guard let separatorIndex = menu.items.firstIndex(where: { $0.tag == 200 }) else { return }

        var insertIndex = separatorIndex + 1

        // Always show history header (with right-aligned shortcut)
        let header = createHistoryHeader()
        header.tag = 204
        menu.insertItem(header, at: insertIndex)
        insertIndex += 1

        // Add history items - with submenu for audio, simple click to paste otherwise
        for (i, historyItem) in historyItems.prefix(5).enumerated() {
            let preview = truncateToWidth(historyItem.text, maxWidth: 200)
            var representedObject: [String: Any] = ["text": historyItem.text]
            if let audioURL = historyItem.audioURL {
                representedObject["audioURL"] = audioURL
            }

            let item = NSMenuItem(
                title: "  \(preview)",
                action: #selector(historyItemClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = representedObject
            item.tag = 201 + i

            if historyItem.audioURL != nil {
                item.submenu = makeAudioSubmenu(representedObject: representedObject)
                item.action = nil
            }

            menu.insertItem(item, at: insertIndex)
            insertIndex += 1
        }
    }
}
