import Foundation

enum EngineRunnerError: Error, LocalizedError {
    case scriptNotConfigured
    case fileNotExecutable(String)
    case processFailed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .scriptNotConfigured:
            return "В Настройках не задан путь к scripts/run_engine.sh"
        case .fileNotExecutable(let p):
            return "Файл не найден или не исполняемый: \(p)"
        case .processFailed(let code, let out):
            return "Движок завершился с кодом \(code).\n\(out)"
        }
    }
}

final class EngineRunner {
    static let shared = EngineRunner()
    private init() {}

    func run(job: Job, completion: @escaping (Result<String, Error>) -> Void) {
        let settings = SettingsStore.shared
        let script = settings.engineScriptPath.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !script.isEmpty else {
            DispatchQueue.main.async { completion(.failure(EngineRunnerError.scriptNotConfigured)) }
            return
        }

        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: script, isDirectory: &isDir), !isDir.boolValue else {
            DispatchQueue.main.async { completion(.failure(EngineRunnerError.fileNotExecutable(script))) }
            return
        }
        // сделать исполняемым при необходимости
        if let attrs = try? FileManager.default.attributesOfItem(atPath: script),
           let perm = attrs[.posixPermissions] as? NSNumber,
           (perm.uint16Value & 0o111) == 0 {
            _ = try? Process.run(URL(fileURLWithPath: "/bin/chmod"), arguments: ["+x", script])
        }

        // аргументы
        var args: [String] = []
        switch job.type {
        case .doctor:
            args = ["doctor"]
        case .smoke:
            let releases = (settings.releasesPath as NSString).expandingTildeInPath
            try? FileManager.default.createDirectory(atPath: releases, withIntermediateDirectories: true)
            args = ["smoke", "--out", "\(releases)/smoke_test.mp4"]
        case .renderImages:
            args = job.args
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: script)
        process.arguments = args

        // рабочая директория: корень движка (…/appstories)
        let scriptURL = URL(fileURLWithPath: script)
        let rootURL = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
        process.currentDirectoryURL = rootURL

        // окружение
        var env = ProcessInfo.processInfo.environment

        // Keychain → OPENAI_API_KEY (если используется OpenAI как fallback)
        if let apiKey = SettingsStore.shared.getOpenAIKeyRaw(), !apiKey.isEmpty {
            env["OPENAI_API_KEY"] = apiKey
        }

        // PYTHONPATH, чтобы -m appstories.cli находился
        var pyPath = env["PYTHONPATH"] ?? ""
        if !pyPath.split(separator: ":").contains(Substring(rootURL.path)) {
            pyPath = pyPath.isEmpty ? rootURL.path : "\(rootURL.path):\(pyPath)"
        }
        env["PYTHONPATH"] = pyPath

        // Локаль (устраняет кракозябры в выводе)
        env["LC_ALL"] = env["LC_ALL"] ?? "en_US.UTF-8"
        env["LANG"] = env["LANG"] ?? "en_US.UTF-8"

        process.environment = env

        // вывод
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        process.terminationHandler = { proc in
            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let outStr = String(data: outData, encoding: .utf8) ?? ""
            let errStr = String(data: errData, encoding: .utf8) ?? ""
            let result: Result<String, Error> =
                (proc.terminationStatus == 0)
                ? .success(outStr.isEmpty ? errStr : outStr)
                : .failure(EngineRunnerError.processFailed(proc.terminationStatus, outStr + errStr))
            // Всегда возвращаемся на главный поток — иначе SwiftUI ругается
            DispatchQueue.main.async { completion(result) }
        }
    }
}
