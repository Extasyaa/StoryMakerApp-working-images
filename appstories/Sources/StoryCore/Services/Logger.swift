import Foundation

public actor Logger {
    public enum Level: String, Codable {
        case debug, info, warning, error
    }

    private let logURL: URL
    private let fm: FileManager
    private let encoder = JSONEncoder()

    public init(logURL: URL, fileManager: FileManager = .default) {
        self.logURL = logURL
        self.fm = fileManager
        try? fm.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    public func log(_ message: String, level: Level = .info, category: String? = nil) {
        let ts = ISO8601DateFormatter().string(from: Date())
        var dict: [String: String] = [
            "ts": ts,
            "level": level.rawValue,
            "message": message
        ]
        if let category { dict["category"] = category }
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              var line = String(data: data, encoding: .utf8) else { return }
        line.append("\n")
        if fm.fileExists(atPath: logURL.path) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                do {
                    try handle.seekToEnd()
                    if let d = line.data(using: .utf8) {
                        try handle.write(contentsOf: d)
                    }
                    try handle.close()
                } catch {
                    try? handle.close()
                }
            }
        } else {
            try? line.write(to: logURL, atomically: true, encoding: .utf8)
        }
    }
}
