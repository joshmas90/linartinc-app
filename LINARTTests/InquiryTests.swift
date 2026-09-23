import XCTest
@testable import LINART

final class InquiryTests: XCTestCase {
    private func validInquiry() -> Inquiry {
        Inquiry(name: "Test Homeowner", email: "test@example.com", phone: "609-555-0100", city: "Ocean County")
    }

    func testRequiredFieldsAndOptionalDetails() {
        XCTAssertEqual(Set(Inquiry().validationErrors.keys), Set(["name", "email", "phone", "city"]))
        XCTAssertTrue(validInquiry().validationErrors.isEmpty)
    }

    func testRejectsInvalidOptionsAndOversizedMessage() {
        var inquiry = validInquiry()
        inquiry.service = "Invalid"
        inquiry.timing = "Tomorrow"
        inquiry.contact = "Fax"
        inquiry.message = String(repeating: "a", count: 1001)
        XCTAssertEqual(Set(inquiry.validationErrors.keys), Set(["service", "timing", "contact", "message"]))
    }

    func testRequestIdentitySurvivesNormalizationAndOptionalContact() {
        var inquiry = validInquiry()
        inquiry.contact = ""
        XCTAssertTrue(inquiry.validationErrors.isEmpty)
        XCTAssertEqual(inquiry.request_id, inquiry.normalized.request_id)
        XCTAssertNotEqual(inquiry.request_id, Inquiry().request_id)
    }

    func testOnlineBriefDecodesWithoutClientSuppliedLinkIdentity() throws {
        let json = #"{"answers":{"goals":"Daylight"},"links":[{"url":"https://example.com","note":"Window"}],"revision":2,"submitted_at":null,"submitted_revision":null}"#
        let brief = try JSONDecoder().decode(RemoteStudio.self, from: Data(json.utf8))
        XCTAssertEqual(brief.links.first?.note, "Window")
        XCTAssertEqual(brief.revision, 2)
    }

    func testNormalizationAndEmailEncoding() throws {
        var inquiry = validInquiry()
        inquiry.name = "  Test Homeowner\n"
        inquiry.message = "A kitchen & bath + storage?\nYes #1"
        XCTAssertEqual(inquiry.normalized.name, "Test Homeowner")
        let url = try XCTUnwrap(inquiry.emailURL)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.scheme, "mailto")
        XCTAssertEqual(components.path, Company.email)
        XCTAssertEqual(components.queryItems?.first(where: { $0.name == "body" })?.value, inquiry.brief)
    }

    func testEncodedPayloadMatchesServerFields() throws {
        let data = try JSONEncoder().encode(validInquiry())
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(Set(json.keys), Set(["name", "email", "phone", "city", "service", "timing", "contact", "message", "company", "request_id"]))
        XCTAssertEqual(json["company"] as? String, "")
    }

    @MainActor
    func testSavedProjectsSurviveReloadAndClear() throws {
        let suite = "LINARTTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = AppStore(defaults: defaults)
        store.toggleFavorite("kitchen")
        store.toggleStep(AppStore.planningSteps[0])
        let reloaded = AppStore(defaults: defaults)
        XCTAssertTrue(reloaded.favorites.contains("kitchen"))
        XCTAssertTrue(reloaded.completedSteps.contains(AppStore.planningSteps[0]))
        reloaded.clearLocalData()
        XCTAssertTrue(AppStore(defaults: defaults).favorites.isEmpty)
        XCTAssertTrue(AppStore(defaults: defaults).completedSteps.isEmpty)
    }

    func testStudioDraftKeepsOptionalFieldsAndReferencesSeparateFromInquiry() throws {
        var draft = StudioDraft()
        draft.inquiryEmail = "homeowner@example.com"
        draft.projectType = "Kitchen Remodeling"
        draft.goals = "More daylight and storage"
        draft.references = [StudioReference(url: "https://example.com/kitchen", note: "Cabinet layout")]
        draft.photos = [StudioPhoto(filename: "example.jpg", purpose: "Existing space", note: "North wall")]

        let restored = try JSONDecoder().decode(StudioDraft.self, from: JSONEncoder().encode(draft))
        XCTAssertEqual(restored, draft)
        XCTAssertTrue(restored.brief.contains("More daylight and storage"))
        XCTAssertTrue(restored.brief.contains("https://example.com/kitchen"))
        XCTAssertTrue(restored.brief.contains("North wall"))
        XCTAssertTrue(Inquiry().validationErrors.keys.contains("phone"))
    }

    func testStudioDirectoriesAreBoundToInquiryNotGlobalSelection() {
        let first = "10000000-0000-4000-8000-000000000001"
        let second = "10000000-0000-4000-8000-000000000002"
        XCTAssertNotEqual(StudioDraft.directory(for: first), StudioDraft.directory(for: second))
        XCTAssertEqual(StudioDraft.directory(for: first).lastPathComponent, first)
    }

    func testEmptyStudioNeverRequiresASecondSubmission() throws {
        let draft = StudioDraft()
        XCTAssertTrue(draft.goals.isEmpty)
        XCTAssertTrue(draft.photos.isEmpty)
        XCTAssertTrue(draft.references.isEmpty)
        XCTAssertTrue(draft.brief.contains("Not provided"))
        XCTAssertTrue(draft.brief.contains("No additional notes") == false)
    }

    func testBundledCatalogIsComplete() throws {
        let catalog = try Catalog.load()
        XCTAssertEqual(catalog.projects.count, 7)
        XCTAssertEqual(catalog.services.count, 7)
        XCTAssertEqual(Set(catalog.projects.map(\.id)).count, catalog.projects.count)
        XCTAssertTrue(catalog.projects.allSatisfy { !$0.photos.isEmpty && Inquiry.serviceOptions.contains($0.service) })
    }
}
