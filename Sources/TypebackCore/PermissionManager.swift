import AppKit
import ApplicationServices
import Foundation

public protocol PermissionManaging {
    var hasAccessibilityPermission: Bool { get }
    func requestAccessibilityPermissionPrompt()
    func openAccessibilitySettings()
}

public final class AccessibilityPermissionManager: PermissionManaging {
    public init() {}

    public var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessibilityPermissionPrompt() {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
