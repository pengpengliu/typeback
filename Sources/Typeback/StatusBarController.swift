import AppKit

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let controller: AppController
    private let settingsWindowController: SettingsWindowController
    private let statusItem: NSStatusItem

    init(
        controller: AppController,
        settingsWindowController: SettingsWindowController
    ) {
        self.controller = controller
        self.settingsWindowController = settingsWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        configureStatusItem()
        refreshMenu()
    }

    func refreshMenu() {
        statusItem.menu = makeMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        controller.refreshSystemState()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }

        if let image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Typeback") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "TB"
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        let enabledItem = NSMenuItem(
            title: "启用自动切换",
            action: #selector(toggleEnabled),
            keyEquivalent: ""
        )
        enabledItem.target = self
        enabledItem.state = controller.preferences.enabled ? .on : .off
        menu.addItem(enabledItem)

        let statusItem = NSMenuItem(title: controller.statusMessage, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        if !controller.hasAccessibilityPermission {
            let permissionItem = NSMenuItem(
                title: "打开 Accessibility 设置...",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            permissionItem.target = self
            menu.addItem(permissionItem)
        }

        menu.addItem(.separator())

        let targetItem = NSMenuItem(
            title: "自动切换到：\(controller.targetInputSourceName)",
            action: nil,
            keyEquivalent: ""
        )
        targetItem.isEnabled = false
        menu.addItem(targetItem)

        let idleItem = NSMenuItem(
            title: "闲置时间：\(controller.preferences.idleSeconds) 秒",
            action: nil,
            keyEquivalent: ""
        )
        idleItem.isEnabled = false
        menu.addItem(idleItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        let quitItem = NSMenuItem(
            title: "退出 Typeback",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func toggleEnabled() {
        controller.setEnabled(!controller.preferences.enabled)
    }

    @objc private func openSettings() {
        settingsWindowController.show(controller: controller)
    }

    @objc private func openAccessibilitySettings() {
        controller.openAccessibilitySettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
