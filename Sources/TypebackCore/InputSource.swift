import Foundation

public struct InputSource: Identifiable, Hashable, Sendable {
    public let id: String
    public let localizedName: String

    public init(id: String, localizedName: String) {
        self.id = id
        self.localizedName = localizedName
    }
}
