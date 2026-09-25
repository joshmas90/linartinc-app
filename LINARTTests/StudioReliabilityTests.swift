import XCTest
import UIKit
import PDFKit
import ImageIO
@testable import LINART

final class StudioReliabilityTests: XCTestCase {
    @MainActor func testGuidedPlanningResumesWithoutChangingTheBrief() async throws {
        let name = "LINARTJourneyTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let disk = persistence()
        let store = StudioStore(persistence: disk, defaults: defaults)
        await store.load()
        XCTAssertEqual(store.currentSection, .details)
        store.draft.goals = "Keep the kitchen notes"
        store.draft.references = [StudioReference(url: "https://example.com/kitchen", note: "Warm finishes")]
        await store.flush()
        let before = store.draft
        store.move(to: .links)
        XCTAssertEqual(store.draft, before)
        XCTAssertFalse(store.hasUnsavedChanges)

        let reopened = StudioStore(persistence: disk, defaults: defaults)
        await reopened.load()
        XCTAssertEqual(reopened.currentSection, .links)
        XCTAssertEqual(reopened.draft, before)
        reopened.move(to: .review)
        XCTAssertEqual(reopened.draft, before)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(reopened.draft)) as? [String: Any])
        XCTAssertNil(json["currentSection"], "Navigation must not become part of a client submission")

        try await reopened.clear()
        let cleared = StudioStore(persistence: disk, defaults: defaults)
        await cleared.load()
        XCTAssertEqual(cleared.currentSection, .details)
        XCTAssertTrue(cleared.draft.isEmpty)
    }

    @MainActor func testSkippingOptionalStepsDoesNotCreateAnswersOrAReceipt() async throws {
        let name = "LINARTJourneyTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let store = StudioStore(persistence: persistence(), defaults: defaults)
        await store.load()
        for section in StudioSection.allCases { store.move(to: section) }
        XCTAssertEqual(store.currentSection, .review)
        XCTAssertTrue(store.draft.isEmpty)
        XCTAssertFalse(store.draft.hasProjectContent)
        XCTAssertNil(store.savedAt)
        XCTAssertFalse(store.hasUnsavedChanges)
        let saved = try await store.persistence.load()
        XCTAssertNil(saved)
        store.draft.goals = " \n "
        XCTAssertFalse(store.draft.hasProjectContent)
        store.draft.ideas = [StudioIdea(id: "kitchen", title: "A kitchen idea")]
        XCTAssertTrue(store.draft.hasProjectContent)
        XCTAssertFalse(StudioSection.review.hasContent(in: store.draft))
        try await store.clear()
    }

    func testGuidanceAndReviewDoNotChangeStoredClientAnswers() throws {
        var draft = StudioDraft()
        draft.projectType = "Kitchen Remodeling"
        draft.goals = "Keep my own wording."
        draft.photos = [StudioPhoto(filename: "room.jpg", purpose: "My space")]
        let before = draft
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let original = try encoder.encode(draft)
        XCTAssertTrue(draft.guidance.photos.contains("kitchen"))
        XCTAssertEqual(draft.unansweredSections, [.links, .timing])
        XCTAssertTrue(draft.contentSummary.contains("1 photo"))
        XCTAssertFalse(draft.contentSummary.contains("complete"))
        XCTAssertEqual(try encoder.encode(draft), original)
        XCTAssertEqual(draft, before)
        draft.projectType = "Bathroom Remodeling"
        XCTAssertTrue(draft.guidance.photos.contains("shower"))
        XCTAssertEqual(draft.goals, before.goals)
        XCTAssertEqual(draft.photos, before.photos)
        let decoded = try JSONDecoder().decode(StudioDraft.self, from: encoder.encode(draft))
        XCTAssertEqual(decoded, draft)
        for service in Inquiry.serviceOptions {
            XCTAssertFalse(ProjectGuidance.forType(service).photos.isEmpty)
        }
    }

    private func persistence() -> StudioPersistence {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("LINARTTests-\(UUID().uuidString)")
        return StudioPersistence(directory: root.appendingPathComponent("draft"), exportsDirectory: root.appendingPathComponent("exports"))
    }
    func testLegacyDraftAndFutureVersionAreHandled() throws {
        var draft = StudioDraft(); draft.goals = "Keep my notes"
        let decoded = try StudioPersistence.decode(JSONEncoder().encode(draft))
        XCTAssertEqual(decoded.draft.goals, draft.goals)
        XCTAssertThrowsError(try StudioPersistence.decode(Data("{}".utf8)))
        let future = StudioEnvelope(schemaVersion: 2, savedAt: Date(), draft: draft)
        XCTAssertThrowsError(try StudioPersistence.decode(JSONEncoder().encode(future)))
    }
    func testResetRejectsDelayedWritesAndImports() async throws {
        let persistence = persistence()
        var draft = StudioDraft(); draft.goals = "Must stay deleted"
        _ = try await persistence.save(draft, generation: 0, revision: 1)
        try await persistence.reset(to: 1)
        do { _ = try await persistence.save(draft, generation: 0, revision: 2); XCTFail("Stale write accepted") }
        catch StudioStorageError.staleOperation { }
        do { _ = try await persistence.addPhoto(NormalizedStudioImage(full: Data(), thumbnail: Data()), purpose: "My space", generation: 0); XCTFail("Stale import accepted") }
        catch StudioStorageError.staleOperation { }
        let restored = try await persistence.load()
        XCTAssertNil(restored)
        XCTAssertFalse(FileManager.default.fileExists(atPath: persistence.directory.path))
    }
    func testOlderRevisionCannotOverwriteNewerDraft() async throws {
        let persistence = persistence()
        var draft = StudioDraft(); draft.goals = "Latest"
        _ = try await persistence.save(draft, generation: 0, revision: 4)
        do { _ = try await persistence.save(StudioDraft(), generation: 0, revision: 3); XCTFail("Old save accepted") }
        catch StudioStorageError.staleOperation { }
        let restored = try await persistence.load()
        XCTAssertEqual(restored?.draft.goals, "Latest")
        try await persistence.reset(to: 1)
    }
    func testCorruptionPreservesOriginalAndRecoversPrevious() async throws {
        let persistence = persistence()
        var draft = StudioDraft(); draft.goals = "First"
        _ = try await persistence.save(draft, generation: 0, revision: 1)
        draft.goals = "Second"
        _ = try await persistence.save(draft, generation: 0, revision: 2)
        let file = persistence.directory.appendingPathComponent("draft.json")
        try Data("broken".utf8).write(to: file)
        do { _ = try await persistence.load(); XCTFail("Corruption treated as empty") } catch StudioStorageError.unreadableDraft { }
        XCTAssertEqual(try String(contentsOf: file, encoding: .utf8), "broken")
        let recovered = try await persistence.recoverPrevious()
        XCTAssertEqual(recovered.draft.goals, "First")
        let files = try FileManager.default.contentsOfDirectory(atPath: persistence.directory.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("unreadable-") })
        try await persistence.reset(to: 1)
    }
    @MainActor func testSharedStoreRemainsEmptyAfterPendingSaveAndReset() async throws {
        let store = StudioStore(persistence: persistence())
        await store.load(); store.draft.goals = "Pending save"
        try await store.clear()
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertTrue(store.draft.isEmpty)
        let persisted = try await store.persistence.load()
        XCTAssertNil(persisted)
    }
    func testPhotoNormalizationUsesPixelsAndStripsMetadata() throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 3
        let source = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 600), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 900, height: 600))
        }
        let normalized = try StudioImageProcessor.normalize(XCTUnwrap(source.jpegData(compressionQuality: 1)))
        for (bytes, maximum) in [(normalized.full, 1600), (normalized.thumbnail, 240)] {
            let source = try XCTUnwrap(CGImageSourceCreateWithData(bytes as CFData, nil))
            let props = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
            XCTAssertLessThanOrEqual((props[kCGImagePropertyPixelWidth] as? Int) ?? Int.max, maximum)
            XCTAssertLessThanOrEqual((props[kCGImagePropertyPixelHeight] as? Int) ?? Int.max, maximum)
            XCTAssertNil(props[kCGImagePropertyGPSDictionary])
        }
    }
    func testPDFPreservesVeryLongParagraphAndPhotoNote() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        var draft = StudioDraft()
        draft.goals = String(repeating: "Every detail matters to this homeowner. ", count: 700) + "UNIQUEENDMARKER"
        let url = try StudioPDF.create(draft: draft, mode: .projectBook, photoDirectory: root, outputDirectory: root)
        let pdf = try XCTUnwrap(PDFDocument(url: url))
        XCTAssertGreaterThan(pdf.pageCount, 3)
        XCTAssertTrue(pdf.string?.contains("UNIQUEENDMARKER") == true)
        draft.photos = [StudioPhoto(filename: "missing.jpg", purpose: "My space")]
        XCTAssertThrowsError(try StudioPDF.create(draft: draft, mode: .projectBook, photoDirectory: root, outputDirectory: root))
    }
    func testPhotoPathCannotEscapeStudio() throws {
        let persistence = persistence()
        for path in ["../private.jpg", "/secret.jpg", "..\\private.jpg", "data.json"] { XCTAssertThrowsError(try persistence.photoURL(path)) }
    }
    func testClearedInquiryRejectsDelayedSave() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let persistence = InquiryDraftPersistence(url: root.appendingPathComponent("inquiry.json"))
        try await persistence.update(Inquiry(name: "Temporary"), revision: 1)
        try await persistence.update(nil, revision: 3)
        try await persistence.update(Inquiry(name: "Stale"), revision: 2)
        let restored = try await persistence.load()
        XCTAssertNil(restored)
        try FileManager.default.removeItem(at: root)
    }
}
