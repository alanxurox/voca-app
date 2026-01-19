import Cocoa

enum OverlayMode {
    case listening
    case processing
}

class RecordingOverlay {
    private var overlayWindow: NSWindow?
    private var waveformView: WaveformView?

    func show() {
        DispatchQueue.main.async { [weak self] in
            self?.doShow(mode: .listening)
        }
    }

    func showProcessing() {
        DispatchQueue.main.async { [weak self] in
            if self?.overlayWindow != nil {
                // Already showing, just switch mode
                self?.waveformView?.setMode(.processing)
            } else {
                self?.doShow(mode: .processing)
            }
        }
    }

    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.doHide()
        }
    }

    func updateLevel(_ level: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.waveformView?.updateLevel(level)
        }
    }

    private func doShow(mode: OverlayMode) {
        guard overlayWindow == nil else { return }

        guard let screen = NSScreen.main else { return }

        // Floating pill-shaped window at bottom of screen
        let windowWidth: CGFloat = 160
        let windowHeight: CGFloat = 50
        let windowX = (screen.frame.width - windowWidth) / 2
        let windowY: CGFloat = 80  // Near bottom of screen

        let window = NSWindow(
            contentRect: NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .floating
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let waveform = WaveformView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        waveform.setMode(mode)
        window.contentView = waveform
        waveformView = waveform

        window.orderFrontRegardless()
        overlayWindow = window

        // Start animation
        waveformView?.startAnimation()
    }

    private func doHide() {
        waveformView?.stopAnimation()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        waveformView = nil
    }
}

class WaveformView: NSView {
    private let barCount = 5
    private var barHeights: [CGFloat] = []
    private var targetHeights: [CGFloat] = []
    private var displayLink: CVDisplayLink?
    private var lastUpdateTime: CFTimeInterval = 0
    private var currentLevel: Float = 0
    private var mode: OverlayMode = .listening

    private let minBarHeight: CGFloat = 6
    private let maxBarHeight: CGFloat = 24
    private let barWidth: CGFloat = 6
    private let barSpacing: CGFloat = 5
    private let cornerRadius: CGFloat = 3

    // Processing animation state
    private let dotCount = 3
    private var dotOpacities: [CGFloat] = [1.0, 0.5, 0.3]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        barHeights = Array(repeating: minBarHeight, count: barCount)
        targetHeights = Array(repeating: minBarHeight, count: barCount)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func setMode(_ newMode: OverlayMode) {
        mode = newMode
        needsDisplay = true
    }

    func updateLevel(_ level: Float) {
        guard mode == .listening else { return }
        currentLevel = level

        // Update target heights based on audio level with some randomness for natural look
        for i in 0..<barCount {
            let baseHeight = minBarHeight + CGFloat(level) * (maxBarHeight - minBarHeight)
            let variation = CGFloat.random(in: 0.7...1.3)
            targetHeights[i] = min(maxBarHeight, max(minBarHeight, baseHeight * variation))
        }
    }

    func startAnimation() {
        // Use a timer for animation (simpler than CVDisplayLink)
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self, self.window != nil else {
                timer.invalidate()
                return
            }
            self.animateStep()
        }
    }

    func stopAnimation() {
        // Timer will auto-invalidate when window is nil
    }

    private func animateStep() {
        if mode == .processing {
            // Rotating dots animation
            needsDisplay = true
            return
        }

        // Listening mode: smooth interpolation toward target heights
        let smoothing: CGFloat = 0.3
        var needsRedraw = false

        for i in 0..<barCount {
            let diff = targetHeights[i] - barHeights[i]
            if abs(diff) > 0.5 {
                barHeights[i] += diff * smoothing
                needsRedraw = true
            }
        }

        if needsRedraw {
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Draw pill-shaped background
        let bgRect = bounds.insetBy(dx: 2, dy: 2)
        let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: bgRect.height / 2, yRadius: bgRect.height / 2)

        // Black background
        NSColor.black.withAlphaComponent(0.9).setFill()
        bgPath.fill()

        // Subtle white border
        NSColor.white.withAlphaComponent(0.2).setStroke()
        bgPath.lineWidth = 1
        bgPath.stroke()

        if mode == .processing {
            drawProcessingAnimation()
        } else {
            drawWaveformAnimation()
        }
    }

    private func drawWaveformAnimation() {
        // Calculate total width of bars
        let totalBarsWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalBarsWidth) / 2
        let centerY = bounds.height / 2 + 4  // Shift up slightly to make room for text

        // Draw waveform bars in white
        for i in 0..<barCount {
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            let height = barHeights[i]
            let y = centerY - height / 2

            let barRect = NSRect(x: x, y: y, width: barWidth, height: height)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: cornerRadius, yRadius: cornerRadius)

            NSColor.white.setFill()
            barPath.fill()
        }

        // Draw "Listening" text below bars
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.6)
        ]
        let text = "Listening"
        let textSize = text.size(withAttributes: textAttributes)
        let textX = (bounds.width - textSize.width) / 2
        let textY: CGFloat = 6
        text.draw(at: NSPoint(x: textX, y: textY), withAttributes: textAttributes)
    }

    private func drawProcessingAnimation() {
        let centerY = bounds.height / 2 + 4
        let dotSize: CGFloat = 8
        let dotSpacing: CGFloat = 12
        let totalDotsWidth = CGFloat(dotCount) * dotSize + CGFloat(dotCount - 1) * dotSpacing
        let startX = (bounds.width - totalDotsWidth) / 2

        // Animated opacity based on time - creates a "wave" effect
        let time = CACurrentMediaTime()
        let speed = 3.0

        for i in 0..<dotCount {
            let phase = Double(i) * 0.4
            let opacity = (sin(time * speed - phase) + 1.0) / 2.0 * 0.7 + 0.3

            let x = startX + CGFloat(i) * (dotSize + dotSpacing)
            let dotRect = NSRect(x: x, y: centerY - dotSize / 2, width: dotSize, height: dotSize)
            let dotPath = NSBezierPath(ovalIn: dotRect)

            NSColor.white.withAlphaComponent(CGFloat(opacity)).setFill()
            dotPath.fill()
        }

        // Draw "Processing" text below dots
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.6)
        ]
        let text = "Processing"
        let textSize = text.size(withAttributes: textAttributes)
        let textX = (bounds.width - textSize.width) / 2
        let textY: CGFloat = 6
        text.draw(at: NSPoint(x: textX, y: textY), withAttributes: textAttributes)
    }
}
