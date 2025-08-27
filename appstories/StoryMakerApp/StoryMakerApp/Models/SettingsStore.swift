import Foundation
import Combine

/// Храним и публикуем настройки приложения.
/// - Путь к скрипту движка
/// - Папка releases
/// - OpenAI API Key (в Keychain; нужен как fallback-провайдер)
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    // MARK: - Published

    @Published var engineScriptPath: String
    @Published var releasesPath: String

    // Маскированное отображение ключа в UI
    @Published private(set) var openAIKeyMasked: String = ""

    // MARK: - Const

    private let defaults = UserDefaults.standard
    private let dScriptKey = "engineScriptPath"
    private let dReleasesKey = "releasesPath"

    private let keychainService = "StoryMakerApp"
    private let keychainAccountOpenAI = "OPENAI_API_KEY"

    // MARK: - Init

    private init() {
        // дефолты
        let defaultScript = NSString(string: "~/Downloads/App/appstories/scripts/run_engine.sh").expandingTildeInPath
        let defaultReleases = NSString(string: "~/Downloads/App/appstories/releases").expandingTildeInPath

        self.engineScriptPath = defaults.string(forKey: dScriptKey) ?? defaultScript
        self.releasesPath = defaults.string(forKey: dReleasesKey) ?? defaultReleases

        refreshOpenAIMasked()
    }

    // MARK: - Persist

    func saveScriptPath(_ path: String) {
        engineScriptPath = path
        defaults.set(path, forKey: dScriptKey)
    }

    func saveReleasesPath(_ path: String) {
        releasesPath = path
        defaults.set(path, forKey: dReleasesKey)
    }

    // MARK: - OpenAI Key (Keychain)

    func saveOpenAIKey(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // пустая строка — удаляем ключ
            _ = KeychainHelper.delete(service: keychainService, account: keychainAccountOpenAI)
        } else {
            _ = KeychainHelper.save(service: keychainService, account: keychainAccountOpenAI, value: trimmed)
        }
        refreshOpenAIMasked()
    }

    func getOpenAIKeyRaw() -> String? {
        KeychainHelper.read(service: keychainService, account: keychainAccountOpenAI)
    }

    private func refreshOpenAIMasked() {
        if let raw = getOpenAIKeyRaw(), !raw.isEmpty {
            openAIKeyMasked = maskKey(raw)
        } else {
            openAIKeyMasked = ""
        }
    }

    private func maskKey(_ s: String) -> String {
        guard s.count > 8 else { return "••••" }
        let head = s.prefix(4)
        let tail = s.suffix(4)
        return "\(head)••••\(tail)"
    }
}
