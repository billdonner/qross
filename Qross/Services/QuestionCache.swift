import Foundation

/// Caches questions locally for offline play
actor QuestionCache {
    static let shared = QuestionCache()

    private let cacheDir: URL = {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("QrossQuestions")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Sanitize topic ID for safe use as a filename
    private func safeFilename(for topicId: String) -> String {
        let sanitized = topicId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "..", with: "_")
        return "\(sanitized).json"
    }

    /// Save questions for a topic
    func save(questions: [Challenge], forTopic topicId: String) throws {
        let url = cacheDir.appendingPathComponent(safeFilename(for: topicId))
        let data = try encoder.encode(questions)
        try data.write(to: url)
    }

    /// Load cached questions for a topic
    func load(topicId: String) -> [Challenge]? {
        let url = cacheDir.appendingPathComponent(safeFilename(for: topicId))
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode([Challenge].self, from: data)
    }

    /// Check if we have cached questions for topics
    func hasCached(topicIds: [String]) -> Bool {
        topicIds.allSatisfy { id in
            FileManager.default.fileExists(atPath: cacheDir.appendingPathComponent(safeFilename(for: id)).path)
        }
    }

    /// Clear all cached questions
    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDir)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }
}
