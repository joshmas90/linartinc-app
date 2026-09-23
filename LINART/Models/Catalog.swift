import Foundation

struct ProjectPhoto: Codable, Hashable, Identifiable {
    var asset: String
    var caption: String
    var id: String { asset }
}

struct PortfolioProject: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let category: String
    let location: String
    let scope: String
    let stage: String
    let service: String
    let photos: [ProjectPhoto]
}

struct Service: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let inquiryType: String
    let summary: String
    let introduction: String
    let planning: String
    let photo: ProjectPhoto
    let details: [String]
    let priorities: [[String]]
}

struct Catalog: Codable {
    let projects: [PortfolioProject]
    let services: [Service]

    static func load(bundle: Bundle = .main) throws -> Catalog {
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw CatalogError.missingResource
        }
        let catalog = try JSONDecoder().decode(Catalog.self, from: Data(contentsOf: url))
        guard !catalog.projects.isEmpty, !catalog.services.isEmpty,
              catalog.projects.allSatisfy({ !$0.photos.isEmpty }),
              catalog.services.allSatisfy({ $0.priorities.allSatisfy { $0.count == 2 } }) else {
            throw CatalogError.invalidContent
        }
        return catalog
    }
}

enum CatalogError: Error {
    case missingResource
    case invalidContent
}

enum Company {
    static let website = URL(string: "https://linartinc.com")!
    static let projects = URL(string: "https://linartinc.com/projects")!
    static let inquiryEndpoint = URL(string: "https://linartinc.com/contact.php")!
    static let phone = "609-209-7810"
    static let phoneURL = URL(string: "tel:+16092097810")!
    static let email = "services@linartinc.com"
    static let emailURL = URL(string: "mailto:services@linartinc.com")!
    static let coreCounties = ["Atlantic", "Burlington", "Camden", "Gloucester", "Ocean"]
    static let extendedCounties = ["Mercer", "Middlesex", "Monmouth", "Cape May", "Cumberland", "Salem"]
    static let occasionalCounties = ["Hunterdon", "Somerset", "Union", "Bergen", "Essex", "Hudson", "Morris", "Passaic", "Sussex", "Warren"]
}
