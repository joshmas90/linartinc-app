import Foundation

enum StudioStorageError: LocalizedError {
    case staleOperation, unreadableDraft, newerVersion, missingPhoto, unsafeFilename
    var errorDescription: String? {
        switch self {
        case .staleOperation: return "This operation was cancelled because the Studio changed."
        case .unreadableDraft: return "Your saved Studio could not be opened. It has been kept intact. Try again or recover the previous saved copy."
        case .newerVersion: return "This Studio was saved by a newer app version. Update the app before editing it."
        case .missingPhoto: return "A saved photo is unavailable. Remove or re-add it before exporting."
        case .unsafeFilename: return "A Studio file reference is invalid. The saved draft has not been changed."
        }
    }
}

actor StudioPersistence {
    nonisolated let directory: URL
    nonisolated let exportsDirectory: URL
    private var generation = 0
    private var latestRevision = 0
    private let manager: FileManager

    init(directory: URL? = nil, exportsDirectory: URL? = nil, manager: FileManager = .default) {
        self.manager = manager
        self.directory = directory ?? manager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LINARTProjectStudio", isDirectory: true)
        self.exportsDirectory = exportsDirectory ?? manager.temporaryDirectory.appendingPathComponent("LINARTExports", isDirectory: true)
    }

    private var draftURL: URL { directory.appendingPathComponent("draft.json") }
    private var backupURL: URL { directory.appendingPathComponent("draft.previous.json") }

    static func decode(_ data: Data) throws -> StudioEnvelope {
        let decoder = JSONDecoder()
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw StudioStorageError.unreadableDraft }
        if object["schemaVersion"] != nil {
            let envelope = try decoder.decode(StudioEnvelope.self, from: data)
            guard envelope.schemaVersion == 1 else { throw StudioStorageError.newerVersion }
            return envelope
        }
        guard object["photos"] != nil, object["goals"] != nil else { throw StudioStorageError.unreadableDraft }
        return StudioEnvelope(schemaVersion: 1, savedAt: .distantPast, draft: try decoder.decode(StudioDraft.self, from: data))
    }

    func load() throws -> StudioEnvelope? {
        guard manager.fileExists(atPath: draftURL.path) else { return nil }
        do { return try Self.decode(Data(contentsOf: draftURL)) }
        catch StudioStorageError.newerVersion { throw StudioStorageError.newerVersion }
        catch { throw StudioStorageError.unreadableDraft }
    }

    func save(_ draft: StudioDraft, generation expected: Int, revision: Int) throws -> Date {
        guard expected == generation, revision >= latestRevision else { throw StudioStorageError.staleOperation }
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let date = Date()
        let data = try JSONEncoder().encode(StudioEnvelope(schemaVersion: 1, savedAt: date, draft: draft))
        if manager.fileExists(atPath: draftURL.path) {
            let previous = try Data(contentsOf: draftURL)
            _ = try Self.decode(previous)
            try previous.write(to: backupURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        }
        try data.write(to: draftURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        latestRevision = revision
        return date
    }

    func recoverPrevious() throws -> StudioEnvelope {
        let recovered = try Self.decode(Data(contentsOf: backupURL))
        if manager.fileExists(atPath: draftURL.path) {
            let preserved = directory.appendingPathComponent("unreadable-\(UUID().uuidString).json")
            try manager.copyItem(at: draftURL, to: preserved)
        }
        let data = try JSONEncoder().encode(recovered)
        try data.write(to: draftURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        return recovered
    }

    func reset(to nextGeneration: Int) throws {
        generation = nextGeneration
        latestRevision = 0
        // A failed reset is reported. It never silently marks the in-memory draft empty.
        if manager.fileExists(atPath: exportsDirectory.path) { try manager.removeItem(at: exportsDirectory) }
        if manager.fileExists(atPath: directory.path) { try manager.removeItem(at: directory) }
    }

    nonisolated func photoURL(_ filename: String) throws -> URL {
        guard !filename.isEmpty, filename == (filename as NSString).lastPathComponent,
              !filename.contains(".."), !filename.contains("\\"), filename.hasSuffix(".jpg") else {
            throw StudioStorageError.unsafeFilename
        }
        return directory.appendingPathComponent(filename)
    }

    func addPhoto(_ image: NormalizedStudioImage, purpose: String, generation expected: Int) throws -> StudioPhoto {
        guard expected == generation else { throw StudioStorageError.staleOperation }
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
        let photo = StudioPhoto(filename: UUID().uuidString + ".jpg", purpose: purpose)
        let fullURL = try photoURL(photo.filename)
        do {
            try image.full.write(to: fullURL, options: [.atomic, .completeFileProtectionUnlessOpen])
            try image.thumbnail.write(to: photoURL(photo.thumbnailFilename), options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            try? manager.removeItem(at: fullURL)
            throw error
        }
        return photo
    }

    func removePhoto(_ photo: StudioPhoto, generation expected: Int) throws {
        guard expected == generation else { throw StudioStorageError.staleOperation }
        // Missing files are already deleted; other failures remain visible and retryable.
        for name in [photo.filename, photo.thumbnailFilename] {
            let url = try photoURL(name)
            if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
        }
    }

    func export(_ draft: StudioDraft, mode: StudioExportMode, generation expected: Int) throws -> URL {
        guard expected == generation else { throw StudioStorageError.staleOperation }
        try manager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        return try StudioPDF.create(draft: draft, mode: mode, photoDirectory: directory, outputDirectory: exportsDirectory)
    }

    func removeExport(_ url: URL) throws {
        guard url.deletingLastPathComponent().standardizedFileURL == exportsDirectory.standardizedFileURL else { return }
        if manager.fileExists(atPath: url.path) { try manager.removeItem(at: url) }
    }

    func cleanExpiredExports(now: Date = Date()) throws {
        guard manager.fileExists(atPath: exportsDirectory.path) else { return }
        for url in try manager.contentsOfDirectory(at: exportsDirectory, includingPropertiesForKeys: [.creationDateKey]) {
            let date = try url.resourceValues(forKeys: [.creationDateKey]).creationDate ?? .distantPast
            if now.timeIntervalSince(date) > 86_400 { try manager.removeItem(at: url) }
        }
    }
}
