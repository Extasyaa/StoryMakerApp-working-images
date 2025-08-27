import SwiftUI

struct StoryView: View {
    @State private var prompt: String = ""
    @State private var genre: String = ""
    @State private var targetDuration: Double = 5
    @State private var scenesMin: Int = 3
    @State private var scenesMax: Int = 5
    @State private var preview: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                TextEditor(text: $prompt)
                    .frame(minHeight: 100)
                    .border(Color.gray)
                    .padding(.bottom)
                TextField("Genre", text: $genre)
                HStack {
                    Text("Target duration (min)")
                    Slider(value: $targetDuration, in: 1...20, step: 1)
                    Text("\(Int(targetDuration))")
                }
                HStack {
                    Stepper("Scenes min: \(scenesMin)", value: $scenesMin, in: 1...20)
                    Stepper("Scenes max: \(scenesMax)", value: $scenesMax, in: 1...20)
                }
                Button("Generate Story JSON", action: generateStory)
            }
            if !preview.isEmpty {
                Text("Preview:")
                    .font(.headline)
                ScrollView {
                    Text(preview)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
    }

    func generateStory() {
        let story = [
            "prompt": prompt,
            "genre": genre,
            "targetDuration": targetDuration,
            "scenesMin": scenesMin,
            "scenesMax": scenesMax
        ] as [String : Any]
        do {
            let data = try JSONSerialization.data(withJSONObject: story, options: [.prettyPrinted])
            let slug = prompt.replacingOccurrences(of: " ", with: "-").lowercased()
            let url = URL(fileURLWithPath: "stories/\(slug).json", relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url)
            preview = String(decoding: data, as: UTF8.self)
        } catch {
            preview = "Error: \(error.localizedDescription)"
        }
    }
}
