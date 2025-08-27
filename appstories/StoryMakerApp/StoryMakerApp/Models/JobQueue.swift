import Foundation
import Combine

final class JobQueue: ObservableObject {
    static let shared = JobQueue()

    @Published private(set) var jobs: [Job] = []
    private let runner = EngineRunner.shared
    private let worker = DispatchQueue(label: "app.jobqueue.worker")

    private init() {}

    func enqueue(_ job: Job) {
        DispatchQueue.main.async {
            self.jobs.insert(job, at: 0)
            self.start(job.id)
        }
    }

    private func start(_ id: UUID) {
        guard let idx = jobs.firstIndex(where: { $0.id == id }) else { return }
        jobs[idx].status = .running

        let job = jobs[idx]
        worker.async { [weak self] in
            self?.runner.run(job: job) { result in
                guard let self = self, let i = self.jobs.firstIndex(where: { $0.id == id }) else { return }
                switch result {
                case .success(let out):
                    self.jobs[i].status = .success
                    self.jobs[i].log = out
                case .failure(let err):
                    self.jobs[i].status = .failed
                    self.jobs[i].log = String(describing: err)
                }
            }
        }
    }
}
