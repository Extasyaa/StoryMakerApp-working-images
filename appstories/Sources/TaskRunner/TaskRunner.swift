import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor TaskRunner {
    public private(set) var logs: [String] = []
    public private(set) var progress: Double = 0
    private let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    public init() {}

    // MARK: - Generate Story
    private let schemaJSON = """
{
  "type": "object",
  "required": ["title","genre","target_minutes","scenes"],
  "properties": {
    "title": {"type":"string"},
    "genre": {"type":"string"},
    "target_minutes": {"type":"integer","minimum":1,"maximum":30},
    "scenes": {
      "type":"array",
      "minItems": 8,
      "maxItems": 20,
      "items": {
        "type":"object",
        "required":["text","image_prompt"],
        "properties":{
          "text":{"type":"string"},
          "image_prompt":{"type":"string"}
        }
      }
    }
  }
}
"""

    public func generateStory(slug: String, genre: String, targetMinutes: Int, regenerate: Bool = false) async throws -> URL {
        let outURL = root.appendingPathComponent("stories/\(slug).json")
        if FileManager.default.fileExists(atPath: outURL.path), !regenerate {
            logs.append("Story exists, skipping")
            progress += 0.2
            return outURL
        }
        let schemaData = schemaJSON.data(using: .utf8)!
        let schema = try JSONSerialization.jsonObject(with: schemaData)
        let prompt = "Create a compact \(genre) story for \(targetMinutes) minutes with 8-20 scenes. For each scene provide text and image_prompt. image_prompt requirements: center composition with safe margins; warm soft light; 35mm f/2.8; photorealistic; avoid text/watermarks/logos; suitable for 16:9 framing. Respond with JSON only."
        var messages: [[String: Any]] = [["role":"user","content":prompt]]
        let bodyBase: [String: Any] = [
            "model": "gpt-4.1-mini",
            "messages": messages,
            "response_format": ["type": "json_schema", "json_schema": schema]
        ]
        guard let apiKey = try Settings.readAPIKey() else { throw RunnerError.missingAPIKey }
        var attempt = 0
        var content: String? = nil
        while attempt < 3 && content == nil {
            do {
                let data = try JSONSerialization.data(withJSONObject: bodyBase)
                var req = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
                req.httpMethod = "POST"
                req.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                req.addValue("application/json", forHTTPHeaderField: "Content-Type")
                req.httpBody = data
                let (respData, _) = try await URLSession.shared.data(for: req)
                if let json = try JSONSerialization.jsonObject(with: respData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let text = message["content"] as? String,
                   let _ = try? JSONSerialization.jsonObject(with: Data(text.utf8)) {
                    content = text
                } else {
                    messages.append(["role":"user","content":"return valid JSON matching the schema"])
                    attempt += 1
                    let delay = UInt64(pow(2.0, Double(attempt)) * 1_000_000_000)
                    try await Task.sleep(nanoseconds: delay)
                }
            } catch {
                attempt += 1
                let delay = UInt64(pow(2.0, Double(attempt)) * 1_000_000_000)
                try await Task.sleep(nanoseconds: delay)
                if attempt >= 3 { throw error }
            }
        }
        guard let jsonText = content else { throw RunnerError.invalidJSON }
        try jsonText.write(to: outURL, atomically: true, encoding: .utf8)
        logs.append("Story saved to \(outURL.path)")
        progress += 0.2
        return outURL
    }

    // MARK: - Render Images
    public func renderImages(storyJSON: URL, releaseID: String, overwrite: Bool = false, force16x9: Bool = false) throws -> URL {
        let outDir = root.appendingPathComponent("build/images/\(releaseID)")
        if FileManager.default.fileExists(atPath: outDir.path), !overwrite {
            logs.append("Images exist, skipping")
            progress += 0.2
            return outDir
        }
        try runCommand(
            launchPath: "/usr/bin/env",
            arguments: ["python3", "images_comfy.py", "--scenes", storyJSON.path, "--out", outDir.path, "--width", "1920", "--height", "1080", "--overwrite"],
            env: [:]
        )
        if force16x9 {
            try enforce16x9(in: outDir)
        }
        progress += 0.2
        return outDir
    }

    private func enforce16x9(in dir: URL) throws {
        let fm = FileManager.default
        let items = try fm.contentsOfDirectory(atPath: dir.path)
        for item in items where item.hasSuffix(".png") || item.hasSuffix(".jpg") {
            let path = dir.appendingPathComponent(item).path
            try runCommand(
                launchPath: "/usr/bin/env",
                arguments: ["ffmpeg", "-y", "-i", path, "-vf", "scale=1920:1080:force_original_aspect_ratio=cover", path],
                env: [:]
            )
        }
    }

    // MARK: - Render TTS
    public func renderTTS(releaseID: String, textPath: String = "./story_for_tts.txt", localFile: URL? = nil, overwrite: Bool = false) throws -> URL {
        let outDir = root.appendingPathComponent("build/audio")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let out = outDir.appendingPathComponent("\(releaseID).mp3")
        if let local = localFile, FileManager.default.fileExists(atPath: local.path) {
            if !overwrite, FileManager.default.fileExists(atPath: out.path) {
                logs.append("Audio exists, skipping")
            } else {
                try? FileManager.default.removeItem(at: out)
                try FileManager.default.copyItem(at: local, to: out)
            }
            progress += 0.2
            return out
        }
        if FileManager.default.fileExists(atPath: out.path), !overwrite {
            logs.append("Audio exists, skipping")
            progress += 0.2
            return out
        }
        let script = FileManager.default.fileExists(atPath: "run.py") ? "run.py" : "tts.py"
        var args: [String] = []
        if script == "run.py" {
            args = ["tts", "--text", textPath, "--out", out.path]
        } else {
            args = [script, "--text", textPath, "--out", out.path]
        }
        try runCommand(
            launchPath: "/usr/bin/env",
            arguments: ["python3"] + args,
            env: [:]
        )
        progress += 0.2
        return out
    }

    // MARK: - Assemble Video
    public func assembleVideo(releaseID: String, audioPath: URL, durationPerImage: String = "auto", overwrite: Bool = false) throws -> URL {
        let outDir = root.appendingPathComponent("out")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let out = outDir.appendingPathComponent("\(releaseID).mp4")
        if FileManager.default.fileExists(atPath: out.path), !overwrite {
            logs.append("Video exists, skipping")
            progress += 0.1
            return out
        }
        let imgDir = root.appendingPathComponent("build/images/\(releaseID)").path
        let args = ["assemble_video.py", "--images", imgDir, "--audio", audioPath.path, "--out", out.path, "--fps", "30", "--duration-per-image", durationPerImage]
        try runCommand(
            launchPath: "/usr/bin/env",
            arguments: ["python3"] + args,
            env: [:]
        )
        progress += 0.1
        return out
    }

    // MARK: - Publish
    public func publish(releaseID: String, storyPath: URL, audioPath: URL, videoPath: URL) throws -> URL {
        let releaseDir = root.appendingPathComponent("releases/\(releaseID)")
        if FileManager.default.fileExists(atPath: releaseDir.path) {
            logs.append("Release folder exists, skipping copy")
            progress += 0.1
            return releaseDir
        }
        try FileManager.default.createDirectory(at: releaseDir, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: storyPath, to: releaseDir.appendingPathComponent("story.json"))
        try FileManager.default.copyItem(at: audioPath, to: releaseDir.appendingPathComponent("audio.mp3"))
        try FileManager.default.copyItem(at: videoPath, to: releaseDir.appendingPathComponent("video.mp4"))
        let imagesSrc = root.appendingPathComponent("build/images/\(releaseID)")
        let imagesDst = releaseDir.appendingPathComponent("images")
        try FileManager.default.copyItem(at: imagesSrc, to: imagesDst)
        let report = releaseDir.appendingPathComponent("report.md")
        try "Release \(releaseID)".write(to: report, atomically: true, encoding: .utf8)
        progress += 0.1
        return releaseDir
    }

    // MARK: - Helpers
    private func runCommand(launchPath: String, arguments: [String], env: [String: String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        var environment = ProcessInfo.processInfo.environment
        if let key = (try? Settings.readAPIKey()) ?? nil {
            environment["OPENAI_API_KEY"] = key
        }
        env.forEach { environment[$0.key] = $0.value }
        process.environment = environment
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        stdout.fileHandleForReading.readabilityHandler = { [weak self] handle in
            if let str = String(data: handle.availableData, encoding: .utf8), !str.isEmpty {
                Task { await self?.appendLog(str) }
            }
        }
        stderr.fileHandleForReading.readabilityHandler = { [weak self] handle in
            if let str = String(data: handle.availableData, encoding: .utf8), !str.isEmpty {
                Task { await self?.appendLog(str) }
            }
        }
        try process.run()
        process.waitUntilExit()
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil
        if process.terminationStatus != 0 {
            throw RunnerError.commandFailed(code: process.terminationStatus)
        }
    }

    private func appendLog(_ line: String) {
        logs.append(line)
    }

    public enum RunnerError: Error {
        case commandFailed(code: Int32)
        case invalidJSON
        case missingAPIKey
    }
}
