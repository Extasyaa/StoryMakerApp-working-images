import XCTest
@testable import StoryCore

final class FileSystemServiceTests: XCTestCase {
    func testWriteAndReadProject() throws {
        let service = FileSystemService()
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let url = tempDir.appendingPathComponent("project.json")
        let project = Project(
            title: "Test",
            userInput: .init(topic: "topic", tone: "tone", minutes: 1, language: "ru"),
            providerLLM: "grok",
            providerImages: "openai",
            tts: .init(provider: "avspeech", voice: "ru"),
            render: RenderProfile(aspect: "9:16", resolution: "1080x1920")
        )
        try service.write(project, to: url)
        let loaded: Project = try service.read(Project.self, from: url)
        XCTAssertEqual(loaded.title, project.title)
    }
}
