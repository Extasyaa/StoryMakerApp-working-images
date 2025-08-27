import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var queue: JobQueue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button("Doctor") { queue.enqueue(Job(type: .doctor)) }
                Button("Smoke")  { queue.enqueue(Job(type: .smoke)) }
            }

            List {
                ForEach(queue.jobs) { job in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(job.type.rawValue.uppercased())
                                .font(.headline)
                            Spacer()
                            Text(job.status.rawValue).foregroundStyle(color(for: job.status))
                        }
                        if !job.log.isEmpty {
                            ScrollView(.vertical) {
                                Text(job.log)
                                    .font(.system(.caption, design: .monospaced))
                                    .textSelection(.enabled)
                            }
                            .frame(minHeight: 60, maxHeight: 180)
                        }
                        Text(job.createdAt.formatted()).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .navigationTitle("Dashboard")
    }

    private func color(for s: JobStatus) -> Color {
        switch s {
        case .queued: return .secondary
        case .running: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }
}
