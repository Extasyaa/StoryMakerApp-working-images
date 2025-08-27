import Foundation

public struct Timeline: Codable {
    public var version: String
    public var aspect: String
    public var fps: Int
    public var scenes: [Scene]

    public init(version: String = "1.1", aspect: String, fps: Int = 30, scenes: [Scene]) {
        self.version = version
        self.aspect = aspect
        self.fps = fps
        self.scenes = scenes
    }
}
