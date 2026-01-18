#!/usr/bin/env swift

import Cocoa

// Generate app icon - black circle with white waveform (like About page)
let sizes = [16, 32, 64, 128, 256, 512, 1024]
let iconsetPath = "AppIcon.iconset"

// Create iconset directory
try? FileManager.default.removeItem(atPath: iconsetPath)
try! FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    // Create image at exact size
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    // Black circle background
    NSColor.black.setFill()
    let circlePath = NSBezierPath(ovalIn: NSRect(x: 0, y: 0, width: size, height: size))
    circlePath.fill()

    // Draw white waveform symbol
    if let symbol = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.5, weight: .medium)
        if let configuredSymbol = symbol.withSymbolConfiguration(config) {
            // Center the symbol
            let symbolSize = configuredSymbol.size
            let x = (CGFloat(size) - symbolSize.width) / 2
            let y = (CGFloat(size) - symbolSize.height) / 2

            // Draw in white
            let tintedSymbol = configuredSymbol.copy() as! NSImage
            tintedSymbol.lockFocus()
            NSColor.white.set()
            NSRect(origin: .zero, size: symbolSize).fill(using: .sourceAtop)
            tintedSymbol.unlockFocus()

            tintedSymbol.draw(at: NSPoint(x: x, y: y), from: .zero, operation: .sourceOver, fraction: 1.0)
        }
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for size \(size)")
        continue
    }

    // Standard naming: icon_16x16.png, icon_16x16@2x.png, etc.
    if size <= 512 {
        let filename = "\(iconsetPath)/icon_\(size)x\(size).png"
        try! pngData.write(to: URL(fileURLWithPath: filename))
        print("Created \(filename)")
    }
    if size >= 32 {
        let halfSize = size / 2
        let filename = "\(iconsetPath)/icon_\(halfSize)x\(halfSize)@2x.png"
        try! pngData.write(to: URL(fileURLWithPath: filename))
        print("Created \(filename)")
    }
}

print("Done! Converting to icns...")
