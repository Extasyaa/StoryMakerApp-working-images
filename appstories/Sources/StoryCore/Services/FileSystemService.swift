import Foundation

public struct FileSystemService {
    private let fm: FileManager

    public init(fileManager: FileManager = .default) {
        self.fm = fileManager
    }

    @discardableResult
    public func createDirectory(at url: URL) throws -> URL {
        try fm.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    public func fileExists(at url: URL) -> Bool {
        fm.fileExists(atPath: url.path)
    }

    public func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try createDirectory(at: url.deletingLastPathComponent())
        try data.write(to: url, options: .atomic)
    }

    public func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
