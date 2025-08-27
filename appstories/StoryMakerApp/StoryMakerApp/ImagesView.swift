import SwiftUI

struct ImagesView: View {
    @EnvironmentObject private var queue: JobQueue
    @EnvironmentObject private var settings: SettingsStore

    // Режимы ввода
    @State private var useMultiplePrompts: Bool = true

    // Один общий промт
    @State private var singlePrompt: String = "retro film still, warm light"

    // Мульти-промты: одна строка, промты разделены точкой с запятой `;`
    @State private var promptsBlock: String =
"""
девушка у окна, мягкий тёплый свет;
туманный лес, лучи света между деревьями;
город ночью, мокрый асфальт, неон
"""

    // Параметры
    @State private var count: Int = 3
    @State private var seconds: Double = 2.0
    @State private var fps: Int = 24
    @State private var outName: String = "out.mp4"

    // Aspect & durations
    @State private var aspect: String = "1:1"         // 1:1, 16:9, 9:16 …
    @State private var durationsCSV: String = ""      // "2,1.5,3"

    // UI
    @State private var showAlert = false
    @State private var alertMsg = ""

    private let presets = ["1:1", "16:9", "9:16", "4:3", "3:2", "21:9", "Custom…"]
    @State private var presetIndex: Int = 0
    @State private var customAspect: String = "1:1"

    // Подсчёт количества промтов по разделителю ';'
    private var promptsCount: Int {
        splitBySemicolon(promptsBlock).count
    }

    var body: some View {
        Form {
            Section(header: Text("Prompts")) {
                Toggle("Multiple prompts (separated by ';')", isOn: $useMultiplePrompts)

                if useMultiplePrompts {
                    TextEditor(text: $promptsBlock)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 140)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.gray.opacity(0.3)))
                    Text("Count: \(promptsCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    TextField("Describe image…", text: $singlePrompt, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section(header: Text("Aspect Ratio")) {
                Picker("Aspect", selection: $presetIndex) {
                    ForEach(presets.indices, id: \.self) { i in
                        Text(presets[i]).tag(i)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: presetIndex) { newValue in
                    if presets[newValue] == "Custom…" {
                        aspect = customAspect
                    } else {
                        aspect = presets[newValue]
                    }
                }

                if presets[presetIndex] == "Custom…" {
                    HStack {
                        Text("Custom")
                        TextField("e.g. 1:1 or 16:9", text: $customAspect)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: customAspect) { v in aspect = v }
                    }
                }

                Text("Current: \(aspect)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(header: Text("Durations")) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Per-frame (comma separated)")
                    TextField("e.g. 2,1.5,3", text: $durationsCSV)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .help("Если пусто — применяется Seconds each ко всем кадрам.")
                }
            }

            Section(header: Text("Options")) {
                Stepper("Images: \(effectiveCount())", value: $count, in: 1...32)
                    .disabled(useMultiplePrompts) // при мульти-промтах количество берётся из ';'
                Stepper("Seconds each: \(String(format: "%.2f", seconds))",
                        value: $seconds, in: 0.25...20, step: 0.25)
                Stepper("FPS: \(fps)", value: $fps, in: 12...60)
                HStack {
                    Text("Output file")
                    TextField("out.mp4", text: $outName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Button("Generate & Assemble") {
                runJob()
            }
        }
        .padding()
        .navigationTitle("Images")
        .alert("Ошибка параметров", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: { Text(alertMsg) }
        .onAppear {
            presetIndex = 0
            aspect = presets[presetIndex]
        }
    }

    // MARK: - Helpers

    private func splitBySemicolon(_ s: String) -> [String] {
        s.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: ";")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func effectiveCount() -> Int {
        useMultiplePrompts ? max(1, promptsCount) : count
    }

    private func runJob() {
        if useMultiplePrompts {
            let items = splitBySemicolon(promptsBlock)
            guard !items.isEmpty else {
                alertMsg = "Введите хотя бы один prompt и разделяйте их точкой с запятой ';'."
                showAlert = true; return
            }
        } else {
            let trimmed = singlePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                alertMsg = "Введите текст в поле Prompt."
                showAlert = true; return
            }
        }

        let releases = (settings.releasesPath as NSString).expandingTildeInPath
        let outPath = (releases as NSString).appendingPathComponent(outName)

        var args: [String] = ["render-images"]

        if useMultiplePrompts {
            // Передаём одним аргументом — CLI сам делит по ';'
            let block = promptsBlock.trimmingCharacters(in: .whitespacesAndNewlines)
            args += ["--prompts", block]
        } else {
            args += ["--prompt", singlePrompt.trimmingCharacters(in: .whitespacesAndNewlines)]
            args += ["--num", "\(count)"]
        }

        args += ["--seconds", "\(seconds)"]
        args += ["--fps", "\(fps)"]
        args += ["--out", outPath]

        let asp = aspect.trimmingCharacters(in: .whitespacesAndNewlines)
        if !asp.isEmpty { args += ["--aspect", asp] }

        let csv = durationsCSV.trimmingCharacters(in: .whitespacesAndNewlines)
        if !csv.isEmpty {
            let parts = csv.split(whereSeparator: { $0 == "," || $0 == " " || $0 == ";" })
            if !parts.isEmpty {
                args.append("--durations")
                args.append(contentsOf: parts.map { String($0) })
            }
        }

        queue.enqueue(Job(type: .renderImages, args: args))
    }
}
