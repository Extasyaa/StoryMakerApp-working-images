import XCTest
@testable import StoryCore

final class LoggerTests: XCTestCase {
    func testLogAppendsToFile() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let logURL = dir.appendingPathComponent("pipeline.log")
        let logger = Logger(logURL: logURL)
        await logger.log("hello", level: .info, category: "TEST")
        let text = try String(contentsOf: logURL)
        XCTAssertTrue(text.contains("hello"))
    }
}
