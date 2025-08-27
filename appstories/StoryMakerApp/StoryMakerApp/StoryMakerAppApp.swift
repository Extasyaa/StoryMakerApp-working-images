import SwiftUI

@main
struct StoryMakerAppApp: App {
    // ЕДИНСТВЕННЫЕ экземпляры ObservableObject на всё приложение
    @StateObject private var settings = SettingsStore.shared
    @StateObject private var jobQueue = JobQueue.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
                .environmentObject(jobQueue)
        }
        .commands { AppCommands() }
    }
}
