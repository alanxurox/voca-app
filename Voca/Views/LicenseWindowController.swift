//
//  LicenseWindowController.swift
//  Voca
//
//  Copyright 2026 Zhengyi Shen. All rights reserved.
//

import Cocoa
import SwiftUI

class LicenseWindowController {
    static let shared = LicenseWindowController()

    private var window: NSWindow?

    func showLicenseWindow() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let licenseView = LicenseView()
        let hostingController = NSHostingController(rootView: licenseView)

        let height: CGFloat = LicenseManager.shared.isLicensed ? 220 : 320

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        newWindow.title = LicenseManager.shared.isLicensed ? "License" : "Enter License"
        newWindow.contentViewController = hostingController
        newWindow.center()
        newWindow.isReleasedWhenClosed = false

        window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow() {
        window?.close()
    }
}
