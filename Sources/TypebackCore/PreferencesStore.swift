import Combine
import Foundation

public struct TypebackPreferences: Equatable {
    public static let defaultTargetInputSourceID = "com.apple.keylayout.ABC"
    public static let defaultIdleSeconds = 10
    public static let minimumIdleSeconds = 1
    public static let maximumIdleSeconds = 3_600

    public var enabled: Bool
    public var idleSeconds: Int
    public var targetInputSourceID: String
    public var launchAtLogin: Bool

    public init(
        enabled: Bool = true,
        idleSeconds: Int = Self.defaultIdleSeconds,
        targetInputSourceID: String = Self.defaultTargetInputSourceID,
        launchAtLogin: Bool = false
    ) {
        self.enabled = enabled
        self.idleSeconds = Self.clampedIdleSeconds(idleSeconds)
        self.targetInputSourceID = targetInputSourceID
        self.launchAtLogin = launchAtLogin
    }

    public static func clampedIdleSeconds(_ value: Int) -> Int {
        min(max(value, minimumIdleSeconds), maximumIdleSeconds)
    }
}

@MainActor
public final class PreferencesStore: ObservableObject {
    @Published public private(set) var enabled: Bool
    @Published public private(set) var idleSeconds: Int
    @Published public private(set) var targetInputSourceID: String
    @Published public private(set) var launchAtLogin: Bool

    private enum Key {
        static let enabled = "enabled"
        static let idleSeconds = "idleSeconds"
        static let targetInputSourceID = "targetInputSourceID"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Key.enabled) == nil {
            enabled = true
        } else {
            enabled = defaults.bool(forKey: Key.enabled)
        }

        if defaults.object(forKey: Key.idleSeconds) == nil {
            idleSeconds = TypebackPreferences.defaultIdleSeconds
        } else {
            idleSeconds = TypebackPreferences.clampedIdleSeconds(defaults.integer(forKey: Key.idleSeconds))
        }

        let storedTarget = defaults.string(forKey: Key.targetInputSourceID)
        targetInputSourceID = storedTarget?.isEmpty == false
            ? storedTarget!
            : TypebackPreferences.defaultTargetInputSourceID

        if defaults.object(forKey: Key.launchAtLogin) == nil {
            launchAtLogin = false
        } else {
            launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        }
    }

    public var preferences: TypebackPreferences {
        TypebackPreferences(
            enabled: enabled,
            idleSeconds: idleSeconds,
            targetInputSourceID: targetInputSourceID,
            launchAtLogin: launchAtLogin
        )
    }

    public func setEnabled(_ value: Bool) {
        enabled = value
        defaults.set(value, forKey: Key.enabled)
    }

    public func setIdleSeconds(_ value: Int) {
        let clampedValue = TypebackPreferences.clampedIdleSeconds(value)
        idleSeconds = clampedValue
        defaults.set(clampedValue, forKey: Key.idleSeconds)
    }

    public func setTargetInputSourceID(_ value: String) {
        guard !value.isEmpty else { return }
        targetInputSourceID = value
        defaults.set(value, forKey: Key.targetInputSourceID)
    }

    public func setLaunchAtLogin(_ value: Bool) {
        launchAtLogin = value
        defaults.set(value, forKey: Key.launchAtLogin)
    }
}
