import Foundation

actor InquiryDraftPersistence {
    private let url: URL
    private var revision = 0
    init(url: URL? = nil) {
        self.url = url ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("LINARTInquiry/draft.json")
    }
    func load() throws -> Inquiry? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(Inquiry.self, from: Data(contentsOf: url))
    }
    func update(_ draft: Inquiry?, revision expected: Int) throws {
        guard expected >= revision else { return }
        revision = expected
        if let draft {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(draft).write(to: url, options: [.atomic, .completeFileProtectionUnlessOpen])
        } else if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
}
