import Cocoa
import AVFoundation
import ApplicationServices
import QuartzCore

// MARK: - Circular Progress View

class CircularProgressView: NSView {
    var progress: Double = 0 {
        didSet {
            progressLayer.strokeEnd = CGFloat(progress)
        }
    }

    var trackColor: NSColor = .separatorColor {
        didSet { trackLayer.strokeColor = trackColor.cgColor }
    }

    var progressColor: NSColor = .controlAccentColor {
        didSet { progressLayer.strokeColor = progressColor.cgColor }
    }

    var lineWidth: CGFloat = 6 {
        didSet {
            trackLayer.lineWidth = lineWidth
            progressLayer.lineWidth = lineWidth
        }
    }

    private let trackLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        wantsLayer = true

        trackLayer.fillColor = nil
        trackLayer.strokeColor = trackColor.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round

        progressLayer.fillColor = nil
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0

        layer?.addSublayer(trackLayer)
        layer?.addSublayer(progressLayer)
    }

    override func layout() {
        super.layout()
        updatePaths()
    }

    private func updatePaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2

        // Start from top (π/2 in standard coords), go clockwise
        let path = CGMutablePath()
        path.addArc(center: center, radius: radius, startAngle: .pi / 2, endAngle: .pi / 2 - .pi * 2, clockwise: true)

        trackLayer.path = path
        progressLayer.path = path
    }
}

// MARK: - Onboarding Window Controller

class OnboardingWindowController: NSWindowController {
    static let shared = OnboardingWindowController()

    private var contentView: OnboardingView!

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = NSLocalizedString("Welcome to Voca", comment: "")
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        contentView = OnboardingView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        contentView.onComplete = { [weak self] in
            self?.window?.close()
        }
        window.contentView = contentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        contentView.reset()
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Show only the permissions step (called when user tries to record without permissions)
    func showPermissionsStep() {
        contentView.showStep(1)  // Step 1 is permissions
        window?.center()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Check if onboarding should be shown (first launch or no model downloaded)
    static func shouldShowOnboarding() -> Bool {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let hasAnyModel = ModelManager.shared.isAnyModelDownloaded()
        return !hasCompletedOnboarding || !hasAnyModel
    }

    static func markOnboardingComplete() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding View

class OnboardingView: NSView {
    private var currentStep = 0
    private let totalSteps = 6

    // Step containers
    private var stepViews: [NSView] = []

    // Step 0: Language selection
    private var languagePopup: NSPopUpButton!
    private var selectedModel: ASRModel = .senseVoice

    // Step 1: Permissions
    private var micPermissionIcon: NSImageView!
    private var micPermissionButton: NSButton!
    private var accessibilityPermissionIcon: NSImageView!
    private var accessibilityPermissionButton: NSButton!

    // Step 2: Shortcut selection
    private var shortcutPopup: NSPopUpButton!
    private var shortcutDescLabel: NSTextField!

    // Step 3: Transcription history (mock menu)

    // Step 4: Download progress
    private var progressRing: CircularProgressView!
    private var progressLabel: NSTextField!

    // Navigation
    private var backButton: NSButton!
    private var nextButton: NSButton!
    private var stepIndicator: NSTextField!

    var onComplete: (() -> Void)?

    private let modelManager = ModelManager.shared

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()

        // Listen for model download progress
        modelManager.onStatusChanged = { [weak self] model, status in
            DispatchQueue.main.async {
                self?.updateDownloadProgress(model: model, status: status)
            }
        }

        // Refresh permissions when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshPermissions),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        currentStep = 0
        showStep(0)
    }

    private func setupUI() {
        // Create all step views
        stepViews = [
            createStep0LanguageView(),
            createStep1PermissionsView(),
            createStep2ShortcutView(),
            createStep3HistoryView(),
            createStep4DownloadView(),
            createStep5ReadyView()
        ]

        // Add all step views (hidden initially)
        for (index, stepView) in stepViews.enumerated() {
            addSubview(stepView)
            stepView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                stepView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
                stepView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
                stepView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
                stepView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -70)
            ])
            stepView.isHidden = index != 0
        }

        // Navigation buttons
        backButton = NSButton(title: NSLocalizedString("Back", comment: ""), target: self, action: #selector(goBack))
        backButton.bezelStyle = .rounded

        nextButton = NSButton(title: NSLocalizedString("Next", comment: ""), target: self, action: #selector(goNext))
        nextButton.bezelStyle = .rounded
        nextButton.keyEquivalent = "\r"

        stepIndicator = NSTextField(labelWithString: "")
        stepIndicator.font = NSFont.systemFont(ofSize: 11)
        stepIndicator.textColor = .secondaryLabelColor
        stepIndicator.alignment = .center

        addSubview(backButton)
        addSubview(nextButton)
        addSubview(stepIndicator)

        backButton.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        stepIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            nextButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            nextButton.widthAnchor.constraint(equalToConstant: 100),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            backButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            backButton.widthAnchor.constraint(equalToConstant: 100),

            stepIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            stepIndicator.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -26)
        ])

        showStep(0)
    }

    // MARK: - Step 0: Language Selection

    private func createStep0LanguageView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Choose Your Language", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        let descLabel = NSTextField(labelWithString: NSLocalizedString("Select the primary language you'll use for dictation.\nThis helps us download the right speech recognition model.", comment: ""))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.maximumNumberOfLines = 0
        descLabel.lineBreakMode = .byWordWrapping

        languagePopup = NSPopUpButton(frame: .zero, pullsDown: false)
        languagePopup.font = NSFont.systemFont(ofSize: 14)

        // Add placeholder item
        languagePopup.addItem(withTitle: NSLocalizedString("Choose your language...", comment: ""))
        languagePopup.lastItem?.representedObject = nil

        for model in ASRModel.availableModels {
            languagePopup.addItem(withTitle: model.languageOption)
            languagePopup.lastItem?.representedObject = model
        }

        // Select placeholder by default
        languagePopup.selectItem(at: 0)
        selectedModel = .senseVoice  // Default fallback

        languagePopup.target = self
        languagePopup.action = #selector(languageChanged(_:))

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(languagePopup)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        languagePopup.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            languagePopup.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 30),
            languagePopup.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            languagePopup.widthAnchor.constraint(equalToConstant: 300)
        ])

        return container
    }

    @objc private func languageChanged(_ sender: NSPopUpButton) {
        if let model = sender.selectedItem?.representedObject as? ASRModel {
            selectedModel = model
        }
        updateNextButtonState()
    }

    // MARK: - Step 1: Permissions

    private func createStep1PermissionsView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Grant Permissions", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        let descLabel = NSTextField(labelWithString: NSLocalizedString("Voca needs these permissions to work properly.", comment: ""))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center

        // Microphone row
        let micLabel = NSTextField(labelWithString: NSLocalizedString("Microphone", comment: ""))
        micLabel.font = NSFont.systemFont(ofSize: 14)

        let micDesc = NSTextField(labelWithString: NSLocalizedString("Required to record your voice", comment: ""))
        micDesc.font = NSFont.systemFont(ofSize: 12)
        micDesc.textColor = .secondaryLabelColor

        micPermissionIcon = NSImageView()
        micPermissionIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
        micPermissionIcon.contentTintColor = .systemGreen
        micPermissionIcon.isHidden = true

        micPermissionButton = NSButton(title: NSLocalizedString("Grant", comment: ""), target: self, action: #selector(grantMicPermission))
        micPermissionButton.bezelStyle = .rounded

        // Accessibility row
        let accessLabel = NSTextField(labelWithString: NSLocalizedString("Accessibility", comment: ""))
        accessLabel.font = NSFont.systemFont(ofSize: 14)

        let accessDesc = NSTextField(labelWithString: NSLocalizedString("Required to auto-paste transcribed text", comment: ""))
        accessDesc.font = NSFont.systemFont(ofSize: 12)
        accessDesc.textColor = .secondaryLabelColor

        accessibilityPermissionIcon = NSImageView()
        accessibilityPermissionIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Granted")
        accessibilityPermissionIcon.contentTintColor = .systemGreen
        accessibilityPermissionIcon.isHidden = true

        accessibilityPermissionButton = NSButton(title: NSLocalizedString("Grant", comment: ""), target: self, action: #selector(grantAccessibilityPermission))
        accessibilityPermissionButton.bezelStyle = .rounded

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(micLabel)
        container.addSubview(micDesc)
        container.addSubview(micPermissionIcon)
        container.addSubview(micPermissionButton)
        container.addSubview(accessLabel)
        container.addSubview(accessDesc)
        container.addSubview(accessibilityPermissionIcon)
        container.addSubview(accessibilityPermissionButton)

        for view in container.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            // Microphone row
            micLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
            micLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 40),

            micDesc.topAnchor.constraint(equalTo: micLabel.bottomAnchor, constant: 2),
            micDesc.leadingAnchor.constraint(equalTo: micLabel.leadingAnchor),

            micPermissionButton.centerYAnchor.constraint(equalTo: micLabel.bottomAnchor),
            micPermissionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -40),
            micPermissionButton.widthAnchor.constraint(equalToConstant: 80),

            micPermissionIcon.centerYAnchor.constraint(equalTo: micPermissionButton.centerYAnchor),
            micPermissionIcon.centerXAnchor.constraint(equalTo: micPermissionButton.centerXAnchor),
            micPermissionIcon.widthAnchor.constraint(equalToConstant: 24),
            micPermissionIcon.heightAnchor.constraint(equalToConstant: 24),

            // Accessibility row
            accessLabel.topAnchor.constraint(equalTo: micDesc.bottomAnchor, constant: 24),
            accessLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 40),

            accessDesc.topAnchor.constraint(equalTo: accessLabel.bottomAnchor, constant: 2),
            accessDesc.leadingAnchor.constraint(equalTo: accessLabel.leadingAnchor),

            accessibilityPermissionButton.centerYAnchor.constraint(equalTo: accessLabel.bottomAnchor),
            accessibilityPermissionButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -40),
            accessibilityPermissionButton.widthAnchor.constraint(equalToConstant: 80),

            accessibilityPermissionIcon.centerYAnchor.constraint(equalTo: accessibilityPermissionButton.centerYAnchor),
            accessibilityPermissionIcon.centerXAnchor.constraint(equalTo: accessibilityPermissionButton.centerXAnchor),
            accessibilityPermissionIcon.widthAnchor.constraint(equalToConstant: 24),
            accessibilityPermissionIcon.heightAnchor.constraint(equalToConstant: 24)
        ])

        return container
    }

    @objc private func grantMicPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshPermissions()
                }
            }
        } else {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    @objc private func grantAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func refreshPermissions() {
        // Microphone
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .authorized {
            micPermissionIcon.isHidden = false
            micPermissionButton.isHidden = true
        } else {
            micPermissionIcon.isHidden = true
            micPermissionButton.isHidden = false
        }

        // Accessibility
        let accessGranted = AXIsProcessTrusted()
        if accessGranted {
            accessibilityPermissionIcon.isHidden = false
            accessibilityPermissionButton.isHidden = true
        } else {
            accessibilityPermissionIcon.isHidden = true
            accessibilityPermissionButton.isHidden = false
        }

        updateNextButtonState()
    }

    // MARK: - Step 2: Shortcut Selection

    private func createStep2ShortcutView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Recording Shortcut", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        let descLabel = NSTextField(labelWithString: NSLocalizedString("Choose a shortcut to start recording.\nRelease to transcribe and paste.", comment: ""))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.maximumNumberOfLines = 0

        // Shortcut dropdown
        shortcutPopup = NSPopUpButton(frame: .zero, pullsDown: false)
        shortcutPopup.font = NSFont.systemFont(ofSize: 14)

        let currentHotkey = AppSettings.shared.recordHotkey
        for preset in Hotkey.presets {
            shortcutPopup.addItem(withTitle: preset.name)
            shortcutPopup.lastItem?.representedObject = preset.hotkey
            if preset.hotkey == currentHotkey {
                shortcutPopup.select(shortcutPopup.lastItem)
            }
        }

        shortcutPopup.target = self
        shortcutPopup.action = #selector(shortcutChanged(_:))

        // Description that updates based on selection
        shortcutDescLabel = NSTextField(labelWithString: "")
        shortcutDescLabel.font = NSFont.systemFont(ofSize: 13)
        shortcutDescLabel.textColor = .tertiaryLabelColor
        shortcutDescLabel.alignment = .center
        shortcutDescLabel.maximumNumberOfLines = 0
        updateShortcutDescription()

        let hintLabel = NSTextField(labelWithString: NSLocalizedString("You can change this in Settings anytime.", comment: ""))
        hintLabel.font = NSFont.systemFont(ofSize: 12)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.alignment = .center

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(shortcutPopup)
        container.addSubview(shortcutDescLabel)
        container.addSubview(hintLabel)

        for view in container.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            shortcutPopup.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 30),
            shortcutPopup.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            shortcutPopup.widthAnchor.constraint(equalToConstant: 220),

            shortcutDescLabel.topAnchor.constraint(equalTo: shortcutPopup.bottomAnchor, constant: 16),
            shortcutDescLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            shortcutDescLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),

            hintLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            hintLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        return container
    }

    @objc private func shortcutChanged(_ sender: NSPopUpButton) {
        guard let hotkey = sender.selectedItem?.representedObject as? Hotkey else { return }
        AppSettings.shared.recordHotkey = hotkey
        updateShortcutDescription()
    }

    private func updateShortcutDescription() {
        let hotkey = AppSettings.shared.recordHotkey
        if hotkey.isDoubleTap {
            shortcutDescLabel.stringValue = NSLocalizedString("Double-tap the key quickly to start recording.", comment: "")
        } else {
            shortcutDescLabel.stringValue = NSLocalizedString("Hold the key to record, release to transcribe.", comment: "")
        }
    }

    // MARK: - Step 3: Transcription History

    private func createStep3HistoryView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Transcription History", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        let descLabel = NSTextField(labelWithString: NSLocalizedString("Access your recent transcriptions from the menu bar.", comment: ""))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center

        // Mock menu container with border
        let mockMenuContainer = NSView()
        mockMenuContainer.wantsLayer = true
        mockMenuContainer.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        mockMenuContainer.layer?.borderColor = NSColor.separatorColor.cgColor
        mockMenuContainer.layer?.borderWidth = 1
        mockMenuContainer.layer?.cornerRadius = 6
        mockMenuContainer.shadow = NSShadow()
        mockMenuContainer.shadow?.shadowColor = NSColor.black.withAlphaComponent(0.2)
        mockMenuContainer.shadow?.shadowOffset = NSSize(width: 0, height: -2)
        mockMenuContainer.shadow?.shadowBlurRadius = 8

        // Mock menu items
        let mockItem1 = createMockMenuItem("Hello, this is a sample transcription...")
        let mockItem2 = createMockMenuItem("Another previous dictation text...")
        let mockItem3 = createMockMenuItem("Your transcription history appears here")

        let separator1 = NSBox()
        separator1.boxType = .separator

        let historyLabel = NSTextField(labelWithString: NSLocalizedString("History", comment: ""))
        historyLabel.font = NSFont.systemFont(ofSize: 12)
        historyLabel.textColor = .secondaryLabelColor

        let shortcutHint = NSTextField(labelWithString: "⌃⌥V")
        shortcutHint.font = NSFont.systemFont(ofSize: 12)
        shortcutHint.textColor = .tertiaryLabelColor

        mockMenuContainer.addSubview(mockItem1)
        mockMenuContainer.addSubview(mockItem2)
        mockMenuContainer.addSubview(mockItem3)
        mockMenuContainer.addSubview(separator1)
        mockMenuContainer.addSubview(historyLabel)
        mockMenuContainer.addSubview(shortcutHint)

        // Bottom hint
        let bottomHint = NSTextField(labelWithString: NSLocalizedString("Click any item to copy it, or press ⌃⌥V to paste the last transcription.", comment: ""))
        bottomHint.font = NSFont.systemFont(ofSize: 12)
        bottomHint.textColor = .tertiaryLabelColor
        bottomHint.alignment = .center
        bottomHint.maximumNumberOfLines = 0

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(mockMenuContainer)
        container.addSubview(bottomHint)

        for view in container.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        for view in mockMenuContainer.subviews {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            mockMenuContainer.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 20),
            mockMenuContainer.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            mockMenuContainer.widthAnchor.constraint(equalToConstant: 280),
            mockMenuContainer.heightAnchor.constraint(equalToConstant: 130),

            // Mock menu items layout
            historyLabel.topAnchor.constraint(equalTo: mockMenuContainer.topAnchor, constant: 8),
            historyLabel.leadingAnchor.constraint(equalTo: mockMenuContainer.leadingAnchor, constant: 12),

            shortcutHint.centerYAnchor.constraint(equalTo: historyLabel.centerYAnchor),
            shortcutHint.trailingAnchor.constraint(equalTo: mockMenuContainer.trailingAnchor, constant: -12),

            separator1.topAnchor.constraint(equalTo: historyLabel.bottomAnchor, constant: 6),
            separator1.leadingAnchor.constraint(equalTo: mockMenuContainer.leadingAnchor, constant: 8),
            separator1.trailingAnchor.constraint(equalTo: mockMenuContainer.trailingAnchor, constant: -8),

            mockItem1.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 4),
            mockItem1.leadingAnchor.constraint(equalTo: mockMenuContainer.leadingAnchor, constant: 8),
            mockItem1.trailingAnchor.constraint(equalTo: mockMenuContainer.trailingAnchor, constant: -8),
            mockItem1.heightAnchor.constraint(equalToConstant: 24),

            mockItem2.topAnchor.constraint(equalTo: mockItem1.bottomAnchor, constant: 2),
            mockItem2.leadingAnchor.constraint(equalTo: mockMenuContainer.leadingAnchor, constant: 8),
            mockItem2.trailingAnchor.constraint(equalTo: mockMenuContainer.trailingAnchor, constant: -8),
            mockItem2.heightAnchor.constraint(equalToConstant: 24),

            mockItem3.topAnchor.constraint(equalTo: mockItem2.bottomAnchor, constant: 2),
            mockItem3.leadingAnchor.constraint(equalTo: mockMenuContainer.leadingAnchor, constant: 8),
            mockItem3.trailingAnchor.constraint(equalTo: mockMenuContainer.trailingAnchor, constant: -8),
            mockItem3.heightAnchor.constraint(equalToConstant: 24),

            bottomHint.topAnchor.constraint(equalTo: mockMenuContainer.bottomAnchor, constant: 16),
            bottomHint.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            bottomHint.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])

        return container
    }

    private func createMockMenuItem(_ text: String) -> NSView {
        let itemView = NSView()
        itemView.wantsLayer = true
        itemView.layer?.cornerRadius = 4

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail

        itemView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: itemView.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: itemView.trailingAnchor, constant: -8),
            label.centerYAnchor.constraint(equalTo: itemView.centerYAnchor)
        ])

        return itemView
    }

    // MARK: - Step 4: Download Progress

    private func createStep4DownloadView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("Downloading Model", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        let descLabel = NSTextField(labelWithString: NSLocalizedString("Please wait while we download the speech recognition model.\nThis may take a few minutes depending on your connection.", comment: ""))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.maximumNumberOfLines = 0

        // Circular progress ring
        progressRing = CircularProgressView()
        progressRing.lineWidth = 6
        progressRing.progressColor = .controlAccentColor

        progressLabel = NSTextField(labelWithString: "0%")
        progressLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 18, weight: .medium)
        progressLabel.alignment = .center

        container.addSubview(titleLabel)
        container.addSubview(descLabel)
        container.addSubview(progressRing)
        container.addSubview(progressLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        progressRing.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            progressRing.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 40),
            progressRing.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            progressRing.widthAnchor.constraint(equalToConstant: 80),
            progressRing.heightAnchor.constraint(equalToConstant: 80),

            progressLabel.topAnchor.constraint(equalTo: progressRing.bottomAnchor, constant: 12),
            progressLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])

        return container
    }

    private func updateDownloadProgress(model: ASRModel, status: ModelStatus) {
        guard model == selectedModel, currentStep == 4 else { return }

        switch status {
        case .downloading(let progress):
            progressRing.progress = progress
            progressLabel.stringValue = "\(Int(progress * 100))%"
        case .downloaded:
            progressRing.progress = 1.0
            progressLabel.stringValue = "100%"
            // Auto-advance to next step
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.goNext()
            }
        case .error(let message):
            progressLabel.stringValue = NSLocalizedString("Error", comment: "")
            print("Download error: \(message)")
        default:
            break
        }
    }

    // MARK: - Step 5: Ready

    private func createStep5ReadyView() -> NSView {
        let container = NSView()

        let titleLabel = NSTextField(labelWithString: NSLocalizedString("You're All Set!", comment: ""))
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.alignment = .center

        // Checkmark icon
        let checkIcon = NSImageView()
        checkIcon.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "Ready")
        checkIcon.contentTintColor = .systemGreen
        checkIcon.symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 64, weight: .regular)

        let currentHotkey = AppSettings.shared.recordHotkey
        let hotkeyName = Hotkey.presets.first { $0.hotkey == currentHotkey }?.name ?? currentHotkey.symbolString

        let descLabel = NSTextField(labelWithString: String(format: NSLocalizedString("Voca is ready to use!\n\nPress %@ to start dictating.", comment: ""), hotkeyName))
        descLabel.font = NSFont.systemFont(ofSize: 14)
        descLabel.textColor = .secondaryLabelColor
        descLabel.alignment = .center
        descLabel.maximumNumberOfLines = 0

        container.addSubview(titleLabel)
        container.addSubview(checkIcon)
        container.addSubview(descLabel)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        checkIcon.translatesAutoresizingMaskIntoConstraints = false
        descLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            checkIcon.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            checkIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            checkIcon.widthAnchor.constraint(equalToConstant: 80),
            checkIcon.heightAnchor.constraint(equalToConstant: 80),

            descLabel.topAnchor.constraint(equalTo: checkIcon.bottomAnchor, constant: 20),
            descLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            descLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20)
        ])

        return container
    }

    // MARK: - Navigation

    func showStep(_ step: Int) {
        currentStep = step

        for (index, view) in stepViews.enumerated() {
            view.isHidden = index != step
        }

        // Update navigation
        backButton.isHidden = step == 0
        stepIndicator.stringValue = "\(step + 1) / \(totalSteps)"

        switch step {
        case 0:
            nextButton.title = NSLocalizedString("Next", comment: "")
        case 1:
            nextButton.title = NSLocalizedString("Next", comment: "")
            refreshPermissions()
            // Start download in background immediately after language selection
            startBackgroundDownload()
        case 2:
            nextButton.title = NSLocalizedString("Next", comment: "")
        case 3:
            nextButton.title = NSLocalizedString("Next", comment: "")
        case 4:
            nextButton.title = NSLocalizedString("Skip", comment: "")
            backButton.isHidden = true
            showDownloadProgress()
        case 5:
            nextButton.title = NSLocalizedString("Done", comment: "")
            backButton.isHidden = true
        default:
            break
        }

        updateNextButtonState()
    }

    private func updateNextButtonState() {
        // Enable next button based on step requirements
        switch currentStep {
        case 0:
            // Language step - must select a language (not placeholder)
            let hasSelectedLanguage = languagePopup.selectedItem?.representedObject != nil
            nextButton.isEnabled = hasSelectedLanguage
        case 1:
            // Permissions step - always allow to proceed (permissions are optional but recommended)
            nextButton.isEnabled = true
        case 4:
            // Download step - enable skip/next if downloaded
            let status = modelManager.modelStatus[selectedModel] ?? .notDownloaded
            if case .downloaded = status {
                nextButton.title = NSLocalizedString("Next", comment: "")
            }
            nextButton.isEnabled = true
        default:
            nextButton.isEnabled = true
        }
    }

    private func startBackgroundDownload() {
        // Start download in background (don't start if already downloaded or downloading)
        if modelManager.isModelDownloaded(selectedModel) {
            return
        }

        let status = modelManager.modelStatus[selectedModel] ?? .notDownloaded
        if case .downloading = status {
            return  // Already downloading
        }

        // Start download
        AppSettings.shared.selectedModel = selectedModel
        modelManager.downloadModel(selectedModel)
    }

    private func showDownloadProgress() {
        // Check if already downloaded
        if modelManager.isModelDownloaded(selectedModel) {
            progressRing.progress = 1.0
            progressLabel.stringValue = "100%"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.goNext()
            }
            return
        }

        // Show current progress
        let status = modelManager.modelStatus[selectedModel] ?? .notDownloaded
        if case .downloading(let progress) = status {
            progressRing.progress = progress
            progressLabel.stringValue = "\(Int(progress * 100))%"
        } else {
            progressRing.progress = 0
            progressLabel.stringValue = "0%"
        }
    }

    @objc private func goBack() {
        if currentStep > 0 {
            showStep(currentStep - 1)
        }
    }

    @objc private func goNext() {
        if currentStep < totalSteps - 1 {
            showStep(currentStep + 1)
        } else {
            // Complete onboarding
            OnboardingWindowController.markOnboardingComplete()
            onComplete?()
        }
    }
}
