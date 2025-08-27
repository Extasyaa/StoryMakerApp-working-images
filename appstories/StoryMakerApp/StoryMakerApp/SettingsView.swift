import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var openAIKeyInput: String = ""

    var body: some View {
        Form {
            Section(header: Text("Engine")) {
                HStack {
                    Text("Path to run_engine.sh")
                    TextField("/Users/.../appstories/scripts/run_engine.sh", text: $settings.engineScriptPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    Text("Releases folder")
                    TextField("releases", text: $settings.releasesPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section(header: Text("OpenAI")) {
                HStack {
                    Text("API Key")
                    Spacer()
                    Text(settings.openAIKeyMasked.isEmpty ? "—" : settings.openAIKeyMasked)
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    TextField("sk-...", text: $openAIKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Save") {
                        settings.saveOpenAIKey(openAIKeyInput)
                        openAIKeyInput = ""
                    }
                    Button("Clear") {
                        settings.saveOpenAIKey("")
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Settings")
    }
}
