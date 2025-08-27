import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: DashboardView()) { Label("Dashboard", systemImage: "speedometer") }
                NavigationLink(destination: ImagesView())     { Label("Images", systemImage: "photo.stack") }
                NavigationLink(destination: TTSView())        { Label("TTS", systemImage: "waveform") }
                NavigationLink(destination: AssembleView())   { Label("Assemble", systemImage: "film.stack") }
                NavigationLink(destination: PublishView())    { Label("Publish", systemImage: "square.and.arrow.up") }
                NavigationLink(destination: SettingsView())   { Label("Settings", systemImage: "gear") }
            }
            .listStyle(.sidebar)
        } detail: {
            DashboardView()
        }
    }
}
