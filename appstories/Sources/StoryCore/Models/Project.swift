import Foundation

public struct Project: Codable {
    public struct UserInput: Codable {
        public var topic: String
        public var tone: String
        public var minutes: Int
        public var language: String

        public init(topic: String, tone: String, minutes: Int, language: String) {
            self.topic = topic
            self.tone = tone
            self.minutes = minutes
            self.language = language
        }
    }

    public struct TTSConfig: Codable {
        public var provider: String
        public var voice: String
        public var speed: Double
        public var pitch: Double

        public init(provider: String, voice: String, speed: Double = 1.0, pitch: Double = 0.0) {
            self.provider = provider
            self.voice = voice
            self.speed = speed
            self.pitch = pitch
        }
    }

    public var title: String
    public var createdAt: Date
    public var userInput: UserInput
    public var providerLLM: String
    public var providerImages: String
    public var tts: TTSConfig
    public var render: RenderProfile
    public var useAspectParam: Bool

    public init(title: String,
                createdAt: Date = Date(),
                userInput: UserInput,
                providerLLM: String,
                providerImages: String,
                tts: TTSConfig,
                render: RenderProfile,
                useAspectParam: Bool = true) {
        self.title = title
        self.createdAt = createdAt
        self.userInput = userInput
        self.providerLLM = providerLLM
        self.providerImages = providerImages
        self.tts = tts
        self.render = render
        self.useAspectParam = useAspectParam
    }
}
