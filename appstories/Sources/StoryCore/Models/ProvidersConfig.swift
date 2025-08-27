import Foundation

public struct ProvidersConfig: Codable {
    public var llm: String
    public var images: String
    public var tts: String

    public init(llm: String, images: String, tts: String) {
        self.llm = llm
        self.images = images
        self.tts = tts
    }
}
