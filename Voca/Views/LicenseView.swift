//
//  LicenseView.swift
//  Voca
//
//  Copyright 2026 Zhengyi Shen. All rights reserved.
//

import SwiftUI
import AppKit

// Custom NSTextField that handles Cmd+V directly
class PastableNSTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) {
            switch event.charactersIgnoringModifiers {
            case "v":
                // Handle paste directly
                if let string = NSPasteboard.general.string(forType: .string) {
                    self.stringValue = string
                    // Notify delegate of change
                    if let _ = self.delegate as? NSTextFieldDelegate {
                        NotificationCenter.default.post(
                            name: NSControl.textDidChangeNotification,
                            object: self
                        )
                    }
                    return true
                }
            case "c":
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self.stringValue, forType: .string)
                return true
            case "a":
                self.selectText(nil)
                return true
            case "x":
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(self.stringValue, forType: .string)
                self.stringValue = ""
                NotificationCenter.default.post(
                    name: NSControl.textDidChangeNotification,
                    object: self
                )
                return true
            default:
                break
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}

// NSTextField wrapper that properly handles Cmd+V paste
struct LicenseTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = PastableNSTextField()
        textField.placeholderString = placeholder
        textField.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textField.alignment = .center
        textField.bezelStyle = .roundedBezel
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.isSelectable = true

        // Make sure it can become first responder
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: LicenseTextField

        init(_ parent: LicenseTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }
    }
}

struct LicenseView: View {
    @State private var licenseKey: String = ""
    @State private var showError: Bool = false
    @State private var showSuccess: Bool = false
    @State private var activatedKey: String = ""
    @State private var copied: Bool = false
    @Environment(\.dismiss) private var dismiss

    private let isAlreadyLicensed = LicenseManager.shared.isLicensed

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: isAlreadyLicensed ? "checkmark.seal.fill" : "key.fill")
                .font(.system(size: 48))
                .foregroundColor(isAlreadyLicensed ? .green : .primary)

            // Title
            Text(isAlreadyLicensed ? "Licensed" : "Enter License")
                .font(.system(size: 20, weight: .semibold))

            if isAlreadyLicensed {
                // Already licensed view
                VStack(spacing: 12) {
                    Text("Thank you for purchasing Voca!")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    if let storedKey = LicenseManager.shared.storedLicense {
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(storedKey, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(storedKey)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.primary)

                                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 11))
                                    .foregroundColor(copied ? .green : .secondary)
                            }
                            .padding(10)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        if copied {
                            Text("Copied!")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                        }
                    }
                }
            } else {
                // License input view
                VStack(spacing: 16) {
                    if showSuccess {
                        // Success state
                        VStack(spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.green)

                            Text("License activated!")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.green)

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(activatedKey, forType: .string)
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    copied = false
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text(activatedKey)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)

                                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 11))
                                        .foregroundColor(copied ? .green : .secondary)
                                }
                                .padding(10)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)

                            if copied {
                                Text("Copied!")
                                    .font(.system(size: 11))
                                    .foregroundColor(.green)
                            }

                            Button("Done") {
                                dismiss()
                                NotificationCenter.default.post(name: .licenseStatusChanged, object: nil)
                            }
                            .keyboardShortcut(.defaultAction)
                        }
                    } else {
                        // Input state
                        Text("Paste your license key below")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        LicenseTextField(text: $licenseKey, placeholder: "XXXX-XXXX-XXXX-XXXX")
                            .frame(width: 260, height: 24)
                            .onChange(of: licenseKey) { _ in
                                showError = false
                            }

                        if showError {
                            Text("Invalid license key")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }

                        HStack(spacing: 12) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .keyboardShortcut(.cancelAction)

                            Button("Activate") {
                                activateLicense()
                            }
                            .keyboardShortcut(.defaultAction)
                            .disabled(licenseKey.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        Divider()
                            .padding(.top, 8)

                        Button(action: {
                            if let url = URL(string: "https://buy.stripe.com/bJecN5aoodW97Js2PR5EY05") {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Text("Purchase License")
                                .font(.system(size: 13))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()
        }
        .padding(30)
        .frame(width: 340, height: isAlreadyLicensed ? 220 : 320)
    }

    private func activateLicense() {
        if LicenseManager.shared.activate(key: licenseKey) {
            activatedKey = licenseKey
            showSuccess = true
            showError = false
        } else {
            showError = true
            showSuccess = false
        }
    }
}

// Notification for license status changes
extension Notification.Name {
    static let licenseStatusChanged = Notification.Name("licenseStatusChanged")
}

struct LicenseView_Previews: PreviewProvider {
    static var previews: some View {
        LicenseView()
    }
}
