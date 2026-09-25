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
    var displayTitle: String { projectType.isEmpty ? "Your project brief" : projectType }
    var contentSummary: String {
        var parts: [String] = []
        if StudioSection.details.hasContent(in: self) { parts.append("Project details saved") }
        if !photos.isEmpty { parts.append("\(photos.count) \(photos.count == 1 ? "photo" : "photos")") }
        if !ideas.isEmpty { parts.append("\(ideas.count) \(ideas.count == 1 ? "portfolio idea" : "portfolio ideas")") }
        if !references.isEmpty { parts.append("\(references.count) \(references.count == 1 ? "inspiration link" : "inspiration links")") }
        if StudioSection.timing.hasContent(in: self) { parts.append("Planning horizon noted") }
        return parts.isEmpty ? "Your brief is ready for a first detail" : parts.joined(separator: " · ")
    }
    var unansweredSections: [StudioSection] {
        StudioSection.allCases.filter { $0 != .review && !$0.hasContent(in: self) }
    }
    var guidance: ProjectGuidance { ProjectGuidance.forType(projectType) }
    var brief: String {
        var sections = [
            "LINART — CLIENT-SHARED PROJECT BRIEF",
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

// Presentation copy only: changing the project type never overwrites client answers.
struct ProjectGuidance {
    let goal: String
    let currentSpace: String
    let style: String
    let priorities: String
    let photos: String

    static func forType(_ type: String) -> Self {
        switch type {
        case "Kitchen Remodeling":
            return Self(goal: "For example, a brighter kitchen with more storage.",
                        currentSpace: "How do the layout, storage and work surfaces work for you today?",
                        style: "For example, warm wood cabinetry and simple stone finishes.",
                        priorities: "More storage, easier cooking, or room to gather?",
                        photos: "Show the full kitchen, the cabinets and any walls or areas you would like to change.")
        case "Bathroom Remodeling":
            return Self(goal: "For example, a calmer bathroom with a walk-in shower.",
                        currentSpace: "What would you change about the shower, vanity or layout?",
                        style: "For example, soft-toned tile and warm metal fixtures.",
                        priorities: "Easier access, better storage, or a larger shower?",
                        photos: "Show the room from the doorway, then the shower, vanity and areas you want to improve.")
        case "Home Addition":
            return Self(goal: "For example, more living space connected to the kitchen.",
                        currentSpace: "Where might the addition connect to your existing home?",
                        style: "Should the addition match your home or introduce a different feel?",
                        priorities: "More family space, a new bedroom, or better indoor-outdoor access?",
                        photos: "Show the outside of your home, the proposed area and the rooms it would connect to.")
        case "Whole-Home Renovation":
            return Self(goal: "For example, a more connected layout and consistent finishes throughout.",
                        currentSpace: "Which rooms work well, and which feel ready for a change?",
                        style: "What materials or finishes would you like to carry through the home?",
                        priorities: "Better flow, updated systems, or renovating in stages?",
                        photos: "Start with the main living spaces and the connections between rooms you want to change.")
        case "New Custom Home Construction":
            return Self(goal: "For example, a light-filled home with room for family and guests.",
                        currentSpace: "Tell us about your lot or where you are in the search for one.",
                        style: "What architecture, materials or homes inspire you?",
                        priorities: "Room count, accessibility, outdoor space, or room to grow?",
                        photos: "Add lot photos, inspiration or early drawings if you have them. A site is not required to start planning.")
        case "Basement Finishing":
            return Self(goal: "For example, a comfortable family room and a separate workspace.",
                        currentSpace: "Describe the current space, ceiling height and anything that needs attention.",
                        style: "For example, warm flooring and bright, comfortable lighting.",
                        priorities: "Storage, a guest area, entertainment, or a quiet workspace?",
                        photos: "Show wide views, stairs, windows and any utilities or areas that need attention.")
        case "Deck / Patio Construction":
            return Self(goal: "For example, an outdoor dining area with room to relax.",
                        currentSpace: "How does the outdoor space connect to your home today?",
                        style: "For example, natural wood tones, simple railings or stone paving.",
                        priorities: "Dining, shade, easier access, or low-maintenance materials?",
                        photos: "Show the back of your home, existing doors and the yard or area you want to use.")
        default:
            return Self(goal: "Tell us what you would like to create. A sentence or two is enough.",
                        currentSpace: "Tell us what works and what you would like to change.",
                        style: "Describe any finishes, materials or spaces you like.",
                        priorities: "What would make the biggest difference to how you use your home?",
                        photos: "A wide view is a useful start. Add details, inspiration or drawings if you have them.")
        }
    }
}
