import Foundation

@MainActor
final class Diagnostics {
    enum Event: String { case draftLoadFailed, draftSaveFailed, photoImportFailed, photoRemovalFailed, pdfExportFailed, exportCleanupFailed, resetFailed, inquiryOffline, inquiryUnconfirmed, inquiryRejected }
    static let shared = Diagnostics()
    private var events: [(Date, Event)] = []
    func record(_ event: Event) {
        events.append((Date(), event))
        events = Array(events.suffix(50))
    }
    func clear() { events = [] }
    var summary: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "LINART app diagnostics\nVersion \(version) (\(build))\nContains event categories only; no customer answers, photos, addresses or credentials.\n\n" +
            (events.isEmpty ? "No errors recorded in this session." : events.map { "\($0.0.ISO8601Format())  \($0.1.rawValue)" }.joined(separator: "\n"))
    }
}
