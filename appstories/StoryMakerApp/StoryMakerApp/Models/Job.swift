import Foundation

enum JobType: String, Codable {
    case doctor
    case smoke
    case renderImages
}

enum JobStatus: String, Codable {
    case queued
    case running
    case success
    case failed
}

struct Job: Identifiable, Codable {
    let id: UUID
    let type: JobType
    var status: JobStatus
    var log: String
    let createdAt: Date
    var args: [String]

    init(id: UUID = UUID(), type: JobType, status: JobStatus = .queued, log: String = "", createdAt: Date = Date(), args: [String] = []) {
        self.id = id
        self.type = type
        self.status = status
        self.log = log
        self.createdAt = createdAt
        self.args = args
    }
}
