import Foundation
import Combine

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var catalog: Catalog?
    @Published private(set) var catalogUnavailable = false
    @Published private(set) var favorites: Set<String>
    @Published private(set) var completedSteps: Set<String>
    @Published var inquiry = Inquiry()
    @Published var inquiryPresented = false
    @Published var selectedTab = 0
    @Published var lastInquiryEmail = ""
    private let defaults: UserDefaults

    static let planningSteps = [
        "Define the rooms or spaces you want to change",
        "Collect inspiration from completed projects",
        "Decide your priorities and a comfortable budget",
        "Consider when you would like work to begin",
        "Prepare questions for your first conversation"
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastInquiryEmail = defaults.string(forKey: "linart.inquiryEmail") ?? ""
        favorites = Set(defaults.stringArray(forKey: "linart.favorites") ?? [])
        completedSteps = Set(defaults.stringArray(forKey: "linart.planningSteps") ?? [])
        reloadCatalog()
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

    func acceptedInquiry(_ inquiry: Inquiry) {
        lastInquiryEmail = inquiry.email
        defaults.set(inquiry.email, forKey: "linart.inquiryEmail")
    }

    func clearRememberedInquiry() {
        lastInquiryEmail = ""
        defaults.removeObject(forKey: "linart.inquiryEmail")
    }

    func clearLocalData() {
        try? StudioCredential.save(nil)
        lastInquiryEmail = ""
        defaults.removeObject(forKey: "linart.inquiryEmail")
        favorites = []
        completedSteps = []
        defaults.removeObject(forKey: "linart.favorites")
        defaults.removeObject(forKey: "linart.planningSteps")
        inquiry = Inquiry()
    }
}
