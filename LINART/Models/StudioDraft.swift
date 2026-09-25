import Foundation

// Stable navigation identifiers are kept outside the client brief / upload payload.
enum StudioSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case details, photos, links, timing, review
    var id: String { rawValue }
    var number: Int { (Self.allCases.firstIndex(of: self) ?? 0) + 1 }
    var previous: Self? { number > 1 ? Self.allCases[number - 2] : nil }
    var next: Self? { number < Self.allCases.count ? Self.allCases[number] : nil }
    var title: String {
        switch self {
        case .details: "Your project"
        case .photos: "Photos of your space"
        case .links: "Ideas & inspiration"
        case .timing: "Budget & timing"
        case .review: "Review & send"
        }
    }
    var symbol: String {
        switch self {
        case .details: "house"
        case .photos: "photo.on.rectangle"
        case .links: "lightbulb"
        case .timing: "calendar"
        case .review: "doc.text.magnifyingglass"
        }
    }
    var subtitle: String {
        switch self {
        case .details: "Start with the space you would like to change. A sentence or two is enough."
        case .photos: "A wide view of the room is a great start. Add inspiration or drawings if you have them."
        case .links: "Show us what you like. Add a web link or choose ideas from LINART projects."
        case .timing: "Share a comfortable budget and when you would like to begin. It is fine to be undecided."
        case .review: "Check your details, make any changes, then choose how to share your brief."
        }
    }
    func hasContent(in draft: StudioDraft) -> Bool {
        switch self {
        case .details:
            [draft.projectType, draft.goals, draft.existingConditions, draft.style,
             draft.priorities, draft.constraints, draft.other, draft.inquiryEmail]
                .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .photos: !draft.photos.isEmpty
        case .links: !draft.references.isEmpty || !draft.ideas.isEmpty
        case .timing:
            [draft.investment, draft.timeline].contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .review: false // Opening the review never implies a submission.
        }
    }
}

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
    var hasProjectContent: Bool { StudioSection.allCases.contains { $0.hasContent(in: self) } }
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
