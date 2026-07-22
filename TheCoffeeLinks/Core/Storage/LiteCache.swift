import Foundation

actor LiteCache {
    struct Snapshot: Codable, Equatable {
        let member: Member
        let history: HistoryPage
        let savedAt: Date
    }

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            self.fileURL = directory.appendingPathComponent("loyalty-lite-cache.json")
        }
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() -> Snapshot? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func save(member: Member, history: HistoryPage) {
        let snapshot = Snapshot(member: member, history: history, savedAt: Date())
        guard let data = try? encoder.encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func clear() { try? FileManager.default.removeItem(at: fileURL) }
}
