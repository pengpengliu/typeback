import Combine
import Foundation
import TypebackCore

@MainActor
final class AppController: ObservableObject {
    @Published private(set) var inputSources: [InputSource] = []
    @Published private(set) var hasAccessibilityPermission = false
    @Published private(set) var statusMessage = "正在启动"
    @Published private(set) var lastError: String?

    let preferences: PreferencesStore
    var onStatusChanged: (() -> Void)?

    private let inputSourceManager: InputSourceManaging
    private let permissionManager: PermissionManaging
    private let launchAtLoginManager: LaunchAtLoginManaging
    private let idleMonitor: KeyboardIdleMonitor
    private var cancellables: Set<AnyCancellable> = []

    init(
        preferences: PreferencesStore? = nil,
        inputSourceManager: InputSourceManaging? = nil,
        permissionManager: PermissionManaging? = nil,
        launchAtLoginManager: LaunchAtLoginManaging? = nil,
        idleMonitor: KeyboardIdleMonitor? = nil
    ) {
        self.preferences = preferences ?? PreferencesStore()
        self.inputSourceManager = inputSourceManager ?? SystemInputSourceManager()
        self.permissionManager = permissionManager ?? AccessibilityPermissionManager()
        self.launchAtLoginManager = launchAtLoginManager ?? SystemLaunchAtLoginManager()
        self.idleMonitor = idleMonitor ?? KeyboardIdleMonitor()

        self.preferences.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var targetInputSourceName: String {
        inputSources.first { $0.id == preferences.targetInputSourceID }?.localizedName
            ?? "无效目标"
    }

    var hasValidTargetInputSource: Bool {
        inputSources.contains { $0.id == preferences.targetInputSourceID }
    }

    func start() {
        refreshSystemState()
        applyMonitoringState()
    }

    func refreshSystemState() {
        inputSources = inputSourceManager.availableInputSources()
        hasAccessibilityPermission = permissionManager.hasAccessibilityPermission
        syncLaunchAtLoginPreference()
        updateStatusMessage()
        applyMonitoringState()
        notifyStatusChanged()
    }

    func setEnabled(_ enabled: Bool) {
        preferences.setEnabled(enabled)
        updateStatusMessage()
        applyMonitoringState()
        notifyStatusChanged()
    }

    func setIdleSeconds(_ seconds: Int) {
        preferences.setIdleSeconds(seconds)
        idleMonitor.updateIdleSeconds(preferences.idleSeconds)
        updateStatusMessage()
        notifyStatusChanged()
    }

    func setTargetInputSourceID(_ id: String) {
        preferences.setTargetInputSourceID(id)
        updateStatusMessage()
        notifyStatusChanged()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            preferences.setLaunchAtLogin(launchAtLoginManager.isEnabled)
            lastError = nil
        } catch {
            preferences.setLaunchAtLogin(launchAtLoginManager.isEnabled)
            lastError = error.localizedDescription
        }

        updateStatusMessage()
        notifyStatusChanged()
    }

    func requestAccessibilityPermissionPrompt() {
        permissionManager.requestAccessibilityPermissionPrompt()
        refreshSystemState()
    }

    func openAccessibilitySettings() {
        permissionManager.openAccessibilitySettings()
    }

    private func applyMonitoringState() {
        idleMonitor.updateIdleSeconds(preferences.idleSeconds)

        guard preferences.enabled, hasAccessibilityPermission else {
            idleMonitor.stop()
            return
        }

        idleMonitor.start { [weak self] in
            self?.handleIdleTimeout()
        }
    }

    private func handleIdleTimeout() {
        guard preferences.enabled else { return }

        guard inputSourceManager.containsInputSource(id: preferences.targetInputSourceID) else {
            refreshSystemState()
            lastError = "目标输入源不可用，请重新选择。"
            updateStatusMessage()
            notifyStatusChanged()
            return
        }

        guard inputSourceManager.currentInputSourceID() != preferences.targetInputSourceID else {
            lastError = nil
            updateStatusMessage()
            notifyStatusChanged()
            return
        }

        do {
            try inputSourceManager.selectInputSource(id: preferences.targetInputSourceID)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }

        updateStatusMessage()
        notifyStatusChanged()
    }

    private func syncLaunchAtLoginPreference() {
        let actualState = launchAtLoginManager.isEnabled
        if preferences.launchAtLogin != actualState {
            preferences.setLaunchAtLogin(actualState)
        }
    }

    private func updateStatusMessage() {
        if !preferences.enabled {
            statusMessage = "已停用"
        } else if !hasAccessibilityPermission {
            statusMessage = "需要 Accessibility 权限"
        } else if !hasValidTargetInputSource {
            statusMessage = "目标输入源不可用"
        } else {
            statusMessage = "运行中"
        }
    }

    private func notifyStatusChanged() {
        onStatusChanged?()
    }
}
