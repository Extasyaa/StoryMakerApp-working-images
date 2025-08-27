import Foundation

public struct RenderProfile: Codable {
    public var aspect: String
    public var resolution: String
    public var fps: Int
    public var subtitles: Bool

    public init(aspect: String, resolution: String, fps: Int = 30, subtitles: Bool = true) {
        self.aspect = aspect
        self.resolution = resolution
        self.fps = fps
        self.subtitles = subtitles
    }
}
