import Foundation
import Combine

enum AppTab: Hashable { case home, projects, services, studio, more }

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var catalog: Catalog?
    @Published private(set) var catalogUnavailable = false
    @Published private(set) var favorites: Set<String>
    @Published private(set) var completedSteps: Set<String>
    @Published var inquiry = Inquiry() { didSet { scheduleInquirySave() } }
    @Published var rememberInquiry = false { didSet { scheduleInquirySave() } }
    @Published var inquiryDraftNotice: String?
    private let inquiryPersistence: InquiryDraftPersistence
    private var inquiryRevision = 0
    private var inquirySaveTask: Task<Void, Never>?
    private var restoringInquiry = false
    @Published var inquiryPresented = false
    @Published var selectedTab: AppTab = .home
    @Published var studioRequested = false
    @Published var introductionReplayRequested = false
    private let defaults: UserDefaults

    static let planningSteps = [
        "Define the rooms or spaces you want to change",
        "Collect inspiration from completed projects",
        "Decide your priorities and a comfortable budget",
        "Consider when you would like work to begin",
        "Prepare questions for your first conversation"
    ]

    init(defaults: UserDefaults = .standard, inquiryPersistence: InquiryDraftPersistence = InquiryDraftPersistence()) {
        self.defaults = defaults
        self.inquiryPersistence = inquiryPersistence
        favorites = Set(defaults.stringArray(forKey: "linart.favorites") ?? [])
        completedSteps = Set(defaults.stringArray(forKey: "linart.planningSteps") ?? [])
        reloadCatalog()
    }

    func loadInquiryDraft() async {
        let revision = inquiryRevision
        do {
            if let draft = try await inquiryPersistence.load(), revision == inquiryRevision {
                restoringInquiry = true; inquiry = draft; rememberInquiry = true; restoringInquiry = false
            }
        } catch { inquiryDraftNotice = "A saved inquiry could not be opened. It remains on this device; use Settings to clear it if you no longer need it." }
    }
    private func scheduleInquirySave() {
        guard !restoringInquiry else { return }
        inquiryRevision += 1
        inquirySaveTask?.cancel()
        // A damaged file is not overwritten merely by opening the form.
        guard inquiryDraftNotice == nil else { return }
        inquirySaveTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            await self?.flushInquiryDraft()
        }
    }
    func flushInquiryDraft() async {
        inquirySaveTask?.cancel()
        guard inquiryDraftNotice == nil else { return }
        do { try await inquiryPersistence.update(rememberInquiry ? inquiry : nil, revision: inquiryRevision) }
        catch { inquiryDraftNotice = "Inquiry draft changes could not be saved. Check available device storage." }
    }
    func clearSavedInquiry() async throws {
        inquirySaveTask?.cancel(); inquiryRevision += 1
        try await inquiryPersistence.update(nil, revision: inquiryRevision)
        restoringInquiry = true; rememberInquiry = false; inquiry = Inquiry(); restoringInquiry = false
        inquiryDraftNotice = nil
    }

    func reloadCatalog() {
        do {
            catalog = try Catalog.load()
            catalogUnavailable = false
        } catch {
            catalog = nil
            catalogUnavailable = true
        }
    }

    func toggleFavorite(_ id: String) {
        if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) }
        defaults.set(favorites.sorted(), forKey: "linart.favorites")
    }

    func toggleStep(_ step: String) {
        if completedSteps.contains(step) { completedSteps.remove(step) } else { completedSteps.insert(step) }
        defaults.set(completedSteps.sorted(), forKey: "linart.planningSteps")
    }

    func startInquiry(service: String? = nil) {
        if let service, Inquiry.serviceOptions.contains(service) { inquiry.service = service }
        inquiryPresented = true
    }

    func clearLocalData() {
        favorites = []
        completedSteps = []
        defaults.removeObject(forKey: "linart.favorites")
        defaults.removeObject(forKey: "linart.planningSteps")
        inquiry = Inquiry()
    }
}
