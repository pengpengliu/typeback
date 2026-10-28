import Carbon
import Foundation

public protocol InputSourceManaging {
    func availableInputSources() -> [InputSource]
    func currentInputSourceID() -> String?
    func containsInputSource(id: String) -> Bool
    func selectInputSource(id: String) throws
}

public enum InputSourceError: LocalizedError, Equatable {
    case notFound(String)
    case selectionFailed(String, OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .notFound(id):
            return "Input source not found: \(id)"
        case let .selectionFailed(id, status):
            return "Failed to select input source \(id), status \(status)"
        }
    }
}

public final class SystemInputSourceManager: InputSourceManaging {
    public init() {}

    public func availableInputSources() -> [InputSource] {
        let sources = inputSources(matching: nil)
            .filter { boolProperty($0, kTISPropertyInputSourceIsSelectCapable) == true }
            .filter { boolProperty($0, kTISPropertyInputSourceIsEnabled) == true }
            .compactMap { source -> InputSource? in
                guard
                    let id = stringProperty(source, kTISPropertyInputSourceID),
                    let name = stringProperty(source, kTISPropertyLocalizedName)
                else {
                    return nil
                }

                return InputSource(id: id, localizedName: name)
            }

        return Array(Set(sources)).sorted { lhs, rhs in
            lhs.localizedName.localizedCaseInsensitiveCompare(rhs.localizedName) == .orderedAscending
        }
    }

    public func currentInputSourceID() -> String? {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return nil
        }

        return stringProperty(currentSource, kTISPropertyInputSourceID)
    }

    public func containsInputSource(id: String) -> Bool {
        source(matchingID: id) != nil
    }

    public func selectInputSource(id: String) throws {
        guard let source = source(matchingID: id) else {
            throw InputSourceError.notFound(id)
        }

        let status = TISSelectInputSource(source)
        guard status == noErr else {
            throw InputSourceError.selectionFailed(id, status)
        }
    }

    private func source(matchingID id: String) -> TISInputSource? {
        let filter = [kTISPropertyInputSourceID: id] as CFDictionary
        return inputSources(matching: filter).first
    }

    private func inputSources(matching filter: CFDictionary?) -> [TISInputSource] {
        guard let sourceList = TISCreateInputSourceList(filter, false)?.takeRetainedValue() else {
            return []
        }

        return (sourceList as NSArray).compactMap { $0 as! TISInputSource? }
    }

    private func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }

        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool? {
        guard let pointer = TISGetInputSourceProperty(source, key) else {
            return nil
        }

        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }
}
