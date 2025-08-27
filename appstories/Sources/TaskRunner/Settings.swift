import Foundation
#if canImport(Security)
import Security
#endif
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum SettingsError: Error {
    case saveError
    case readError
}

public struct Settings {
    private static let key = "StoryMaker.OPENAI_API_KEY"

    public static func saveAPIKey(_ value: String) throws {
#if canImport(Security)
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw SettingsError.saveError }
#else
        // Fallback: store in a dotfile
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".storymaker_api_key")
        try value.write(to: url, atomically: true, encoding: .utf8)
#endif
    }

    public static func readAPIKey() throws -> String? {
#if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { return nil }
        guard let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
#else
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".storymaker_api_key")
        return try? String(contentsOf: url, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
#endif
    }

    public static func checkAccess() async -> Bool {
        guard let key = (try? readAPIKey()) ?? nil else { return false }
        var req = URLRequest(url: URL(string: "https://api.openai.com/v1/models")!)
        req.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse {
                return http.statusCode == 200
            }
        } catch {}
        return false
    }
}
