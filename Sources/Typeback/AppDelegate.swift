import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: AppController!
    private var statusBarController: StatusBarController!
    private let settingsWindowController = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        controller = AppController()
        statusBarController = StatusBarController(
            controller: controller,
            settingsWindowController: settingsWindowController
        )
        controller.onStatusChanged = { [weak self] in
            self?.statusBarController.refreshMenu()
        }
        controller.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        controller?.refreshSystemState()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
