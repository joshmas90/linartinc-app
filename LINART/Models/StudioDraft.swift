import Foundation

struct StudioReference: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var url: String
    var note: String
}

struct StudioPhoto: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var filename: String
    var purpose: String
    var note: String = ""
    var thumbnailFilename: String { "thumb-" + filename }
}

struct StudioIdea: Codable, Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var note = ""
}

struct StudioDraft: Codable, Equatable, Sendable {
    var inquiryEmail = ""
    var projectType = ""
    var goals = ""
    var existingConditions = ""
    var style = ""
    var priorities = ""
    var investment = ""
    var timeline = ""
    var constraints = ""
    var other = ""
    var references: [StudioReference] = []
    var photos: [StudioPhoto] = []
    var ideas: [StudioIdea] = []

    init() { }

    // Decode legacy local drafts without discarding them when a field is added.
    private enum CodingKeys: String, CodingKey {
        case inquiryEmail, projectType, goals, existingConditions, style, priorities
        case investment, timeline, constraints, other, references, photos, ideas
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        inquiryEmail = try c.decodeIfPresent(String.self, forKey: .inquiryEmail) ?? ""
        projectType = try c.decodeIfPresent(String.self, forKey: .projectType) ?? ""
        goals = try c.decodeIfPresent(String.self, forKey: .goals) ?? ""
        existingConditions = try c.decodeIfPresent(String.self, forKey: .existingConditions) ?? ""
        style = try c.decodeIfPresent(String.self, forKey: .style) ?? ""
        priorities = try c.decodeIfPresent(String.self, forKey: .priorities) ?? ""
        investment = try c.decodeIfPresent(String.self, forKey: .investment) ?? ""
        timeline = try c.decodeIfPresent(String.self, forKey: .timeline) ?? ""
        constraints = try c.decodeIfPresent(String.self, forKey: .constraints) ?? ""
        other = try c.decodeIfPresent(String.self, forKey: .other) ?? ""
        references = try c.decodeIfPresent([StudioReference].self, forKey: .references) ?? []
        photos = try c.decodeIfPresent([StudioPhoto].self, forKey: .photos) ?? []
        ideas = try c.decodeIfPresent([StudioIdea].self, forKey: .ideas) ?? []
    }

    var completedTopics: Int {
        [goals, existingConditions, style, priorities, investment, timeline, constraints]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }
    var isEmpty: Bool { self == StudioDraft() }
    var displayTitle: String { projectType.isEmpty ? "Your next chapter at home" : projectType }
    var brief: String {
        var sections = [
            "LINART PROJECT STUDIO — CLIENT-SHARED BRIEF",
            "Email used for inquiry: \(inquiryEmail.isEmpty ? "Not provided" : inquiryEmail)",
            "Project type: \(projectType.isEmpty ? "Not provided" : projectType)"
        ]
        for (label, value) in [
            ("What I want to achieve", goals), ("Current space / existing conditions", existingConditions),
            ("Style and materials", style), ("Top priorities", priorities),
            ("Investment considerations", investment), ("Desired timing", timeline),
            ("Constraints, plans or permits", constraints), ("Other information", other)
        ] { sections.append("\(label)\n\(value.isEmpty ? "Not provided" : value)") }
        sections.append("SAVED PROJECT IDEAS\n" + (ideas.isEmpty ? "None" : ideas.map { "\($0.title)\n\($0.note)" }.joined(separator: "\n\n")))
        sections.append("INSPIRATION LINKS\n" + (references.isEmpty ? "None" : references.map { "\($0.url)\n\($0.note)" }.joined(separator: "\n\n")))
        sections.append("PHOTOGRAPHS\n" + (photos.isEmpty ? "None" : photos.enumerated().map { "\($0.offset + 1). \($0.element.purpose)\n\($0.element.note)" }.joined(separator: "\n\n")))
        sections.append("Prepared by the homeowner. This is a project brief, not an estimate, booking or delivery receipt.")
        return sections.joined(separator: "\n\n")
    }
}

struct StudioEnvelope: Codable, Sendable {
    let schemaVersion: Int
    let savedAt: Date
    let draft: StudioDraft
}
