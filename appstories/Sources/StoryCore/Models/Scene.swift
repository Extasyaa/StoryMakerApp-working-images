import Foundation

public struct Scene: Codable, Identifiable {
    public var index: Int
    public var start: String
    public var end: String
    public var durationSec: Double
    public var imagePrompt: String

    public var id: Int { index }

    public init(index: Int, start: String, end: String, durationSec: Double, imagePrompt: String) {
        self.index = index
        self.start = start
        self.end = end
        self.durationSec = durationSec
        self.imagePrompt = imagePrompt
    }
}
