import SwiftUI

struct AppCommands: Commands {
    var body: some Commands {
        CommandMenu("Engine") {
            Button("Run Doctor") { JobQueue.shared.enqueue(Job(type: .doctor)) }
                .keyboardShortcut("d", modifiers: [.command, .shift])
            Button("Run Smoke")  { JobQueue.shared.enqueue(Job(type: .smoke)) }
                .keyboardShortcut("s", modifiers: [.command, .shift])
        }
    }
}
