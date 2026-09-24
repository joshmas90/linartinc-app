import SwiftUI
import PhotosUI
import UIKit

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedPage = 0

    private var savedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { store.favorites.contains($0.id) }
    }
    private var completed: Int { store.completedSteps.intersection(Set(AppStore.planningSteps)).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "A thoughtful beginning", title: "My Project")
                Picker("My Project section", selection: $selectedPage) {
                    Text("Checklist").tag(0)
                    Text("Saved Ideas").tag(1)
                }.pickerStyle(.segmented)
                if selectedPage == 0 {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Before we talk").font(.headline)
                            Spacer()
                            Text("\(completed) of \(AppStore.planningSteps.count)").font(.subheadline).foregroundStyle(Brand.secondary)
                        }
                        ProgressView(value: Double(completed), total: Double(AppStore.planningSteps.count))
                            .tint(Brand.brass).accessibilityLabel("Planning checklist progress")
                        ForEach(AppStore.planningSteps, id: \.self) { step in
                            Button { store.toggleStep(step) } label: {
                                HStack(alignment: .top, spacing: 14) {
                                    Image(systemName: store.completedSteps.contains(step) ? "checkmark.square.fill" : "square")
                                        .font(.title2).foregroundStyle(Brand.brass)
                                    Text(step).foregroundStyle(Brand.ink).multilineTextAlignment(.leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }.frame(minHeight: 44, alignment: .leading)
                            }.buttonStyle(.plain)
                                .accessibilityValue(store.completedSteps.contains(step) ? "Completed" : "Not completed")
                                .accessibilityHint("Double tap to change completion")
                        }
                    }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
                    VStack(alignment: .leading, spacing: 12) {
                        Text("“A little preparation leads to a better conversation — and a better result.”")
                            .font(.system(.title3, design: .serif)).lineSpacing(5)
                        Text("— The LINART Team").font(.caption).foregroundStyle(Brand.secondary)
                    }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.gold.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
                } else if savedProjects.isEmpty {
                    ContentUnavailableView("Your inspiration starts here", systemImage: "heart", description: Text("Save the projects you love. You’ll find them here whenever you’re ready."))
                    Button("Explore Projects") { store.selectedTab = 1 }.buttonStyle(SecondaryButtonStyle())
                } else {
                    ForEach(savedProjects) { project in
                        NavigationLink { ProjectDetailView(project: project) } label: {
                            ProjectCard(project: project)
                        }.buttonStyle(.plain)
                    }
                }
                Button { store.studioRequested = true } label: {
                    MenuRow(title: "Project Studio", subtitle: "Photos, ideas and the details that matter to you", symbol: "square.and.pencil")
                }.buttonStyle(.plain)
                Text("Your Studio is optional. Save your ideas privately and share when you’re ready.")
                    .font(.caption).foregroundStyle(Brand.secondary)
                Button("Start a Project Inquiry") { store.startInquiry() }.buttonStyle(PrimaryButtonStyle())
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("My Project").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $store.studioRequested) { ProjectStudioView() }
    }
}

// Private, on-device draft. No photo or note is uploaded merely by entering the studio.
struct StudioReference: Codable, Identifiable, Equatable {
    var id = UUID()
    var url: String
    var note: String
}

struct StudioPhoto: Codable, Identifiable, Equatable {
    var id = UUID()
    var filename: String
    var purpose: String
    var note: String = ""
}

struct StudioDraft: Codable, Equatable {
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

    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("LINARTProjectStudio", isDirectory: true)
    }

    static func load() -> StudioDraft {
        let url = directory.appendingPathComponent("draft.json")
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(StudioDraft.self, from: data) else { return StudioDraft() }
        return decoded
    }

    func save() throws {
        try FileManager.default.createDirectory(at: Self.directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(self)
        try data.write(to: Self.directory.appendingPathComponent("draft.json"), options: [.atomic, .completeFileProtectionUnlessOpen])
    }

    static func clear() throws {
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
    }

    var brief: String {
        let referencesText = references.enumerated().map { index, item in
            "  \(index + 1). \(item.url)\n     \(item.note)"
        }.joined(separator: "\n")
        let photoText = photos.enumerated().map { index, item in
            "  \(index + 1). \(item.purpose): \(item.note.isEmpty ? "No note" : item.note)"
        }.joined(separator: "\n")
        return """
        LINART PROJECT STUDIO — CLIENT-SHARED BRIEF

        Email used for original inquiry: \(inquiryEmail.isEmpty ? "Not provided" : inquiryEmail)
        Project type: \(projectType.isEmpty ? "Not provided" : projectType)
        What I want to achieve: \(goals.isEmpty ? "Not provided" : goals)
        Current space / existing conditions: \(existingConditions.isEmpty ? "Not provided" : existingConditions)
        Style and materials: \(style.isEmpty ? "Not provided" : style)
        Top priorities: \(priorities.isEmpty ? "Not provided" : priorities)
        Investment considerations: \(investment.isEmpty ? "Not provided" : investment)
        Desired timing: \(timeline.isEmpty ? "Not provided" : timeline)
        Constraints, plans or permits: \(constraints.isEmpty ? "Not provided" : constraints)
        Other information: \(other.isEmpty ? "Not provided" : other)

        INSPIRATION LINKS
        \(referencesText.isEmpty ? "None" : referencesText)

        ATTACHED PHOTOGRAPHS
        \(photoText.isEmpty ? "None" : photoText)

        This brief was prepared by the client and shared voluntarily. It is not a construction estimate, appointment booking, or confirmation of server delivery.
        """
    }
}

private enum StudioSection: String, CaseIterable, Identifiable {
    case space, inspiration, links, details, timing, review
    var id: String { rawValue }
    var title: String {
        switch self {
        case .space: return "Your Space"
        case .inspiration: return "Inspiration Photos"
        case .links: return "Inspiration Links"
        case .details: return "Project Details"
        case .timing: return "Budget & Timing"
        case .review: return "Review & Share"
        }
    }
    var subtitle: String {
        switch self {
        case .space: return "Add photos of your home or drawings"
        case .inspiration: return "Gather the spaces and details you love"
        case .links: return "Keep ideas from Pinterest, Houzz and more"
        case .details: return "Your vision, style and priorities"
        case .timing: return "A starting point for the conversation"
        case .review: return "Preview your brief and choose how to share"
        }
    }
    var symbol: String {
        switch self {
        case .space: return "camera"
        case .inspiration: return "photo.on.rectangle"
        case .links: return "link"
        case .details: return "square.and.pencil"
        case .timing: return "clock"
        case .review: return "doc.text.magnifyingglass"
        }
    }
}

struct ProjectStudioView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(eyebrow: "Your vision, beautifully organized", title: "Project Studio")
                Text("Add the details that make it yours. Everything here is optional, and you can return anytime.")
                    .foregroundStyle(Brand.secondary).lineSpacing(4)
                VStack(spacing: 12) {
                    ForEach(StudioSection.allCases) { section in
                        NavigationLink { StudioEditorView(section: section) } label: {
                            MenuRow(title: section.title, subtitle: section.subtitle, symbol: section.symbol)
                        }.buttonStyle(.plain)
                    }
                }
                Label("Saved privately on this device until you choose to share.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(Brand.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Project Studio").navigationBarTitleDisplayMode(.inline)
    }
}

private struct StudioEditorView: View {
    let section: StudioSection
    @State private var draft = StudioDraft.load()
    @State private var pickedPhotos: [PhotosPickerItem] = []
    @State private var newReference = ""
    @State private var newReferenceNote = ""
    @State private var photoPurpose = "Existing space"
    @State private var notice: String?
    @State private var shareURL: URL?
    @State private var sharing = false
    @State private var suppressNextSave = false
    @State private var showReview = false
    @State private var confirmClear = false
    @State private var importing = false

    init(section: StudioSection) {
        self.section = section
        _photoPurpose = State(initialValue: section == .inspiration ? "Inspiration" : "Existing space")
    }

    private let types = ["Existing space", "Inspiration", "Plans or drawings"]
    private let services = Inquiry.serviceOptions

    private var tailoredPrompt: String {
        switch draft.projectType {
        case "Kitchen Remodeling": return "What would you change about the layout, storage, appliances or entertaining space?"
        case "Bathroom Remodeling": return "What would you change about the shower, bath, storage, accessibility or fixtures?"
        case "New Custom Home Construction": return "What kind of home, rooms, site and architectural character are you envisioning?"
        case "Home Addition": return "What new rooms or square footage do you need, and how should the addition connect to your home?"
        case "Whole-Home Renovation": return "Which spaces need to change, and what should remain as it is?"
        case "Basement Finishing": return "How would you use the finished basement, and are there any known moisture or ceiling-height concerns?"
        case "Deck / Patio Construction": return "How would you use the outdoor space, and what are your preferences for materials, shade and access?"
        default: return "What would you love to change or create, and how should the finished space feel?"
        }
    }

    private var progress: Int {
        [draft.goals, draft.existingConditions, draft.style, draft.priorities, draft.investment, draft.timeline, draft.constraints]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow(title: "An invitation to imagine")
                    Text(section.title).font(.system(.title, design: .serif))
                    Text(section.subtitle)
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Text("\(progress) of 7 planning topics explored").font(.caption).foregroundStyle(.secondary)
                    }
                    ProgressView(value: Double(progress), total: 7).tint(Brand.bronze)
                    Label("Private on this device until you choose to share", systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(Brand.bronze)
                }.padding(.vertical, 7)
            }
            if section == .details {
                Section("Your starting point · optional") {
                    TextField("Email used for your inquiry (optional)", text: $draft.inquiryEmail)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    Picker("Project type", selection: $draft.projectType) {
                        Text("Not decided").tag("")
                        ForEach(services, id: \.self) { Text($0).tag($0) }
                    }
                    studioField(tailoredPrompt, text: $draft.goals)
                    studioField("What does the space look like today?", text: $draft.existingConditions)
                }
            }
            if section == .space || section == .inspiration {
                Section {
                    Picker("Photos you are adding", selection: $photoPurpose) {
                        ForEach(types, id: \.self) { Text($0).tag($0) }
                    }
                    PhotosPicker(selection: $pickedPhotos, maxSelectionCount: max(1, 8 - draft.photos.count), matching: .images) {
                        Label(importing ? "Adding photos…" : "Add photos from your device", systemImage: "photo.on.rectangle.angled")
                    }
                    .disabled(importing || draft.photos.count >= 8)
                    Text("Up to 8 photos. Choose pictures of your space, saved inspiration images or drawings. You control what gets shared.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach($draft.photos) { $photo in
                        HStack(alignment: .top, spacing: 12) {
                            if let image = UIImage(contentsOfFile: StudioDraft.directory.appendingPathComponent(photo.filename).path) {
                                Image(uiImage: image).resizable().scaledToFill()
                                    .frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 9))
                                    .accessibilityLabel(photo.purpose)
                            }
                            VStack(alignment: .leading, spacing: 7) {
                                Text(photo.purpose).font(.subheadline.weight(.semibold))
                                TextField("What should LINART notice? (optional)", text: $photo.note, axis: .vertical)
                                    .lineLimit(1...3)
                            }
                            Spacer(minLength: 0)
                            Button(role: .destructive) { removePhoto(photo) } label: {
                                Image(systemName: "trash").accessibilityLabel("Remove photo")
                            }
                        }
                    }
                } header: { Text("Your spaces & inspiration") }
            }
            if section == .links {
                Section("Ideas from the internet · optional") {
                    TextField("https://example.com/inspiration", text: $newReference)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("What appeals to you about this example?", text: $newReferenceNote, axis: .vertical)
                        .lineLimit(2...4)
                    Button("Add inspiration link", systemImage: "link.badge.plus") { addReference() }
                        .disabled(draft.references.count >= 10 || newReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Paste a web link from Pinterest, Houzz or another site. LINART receives the link, not a copy of the website image.")
                        .font(.caption).foregroundStyle(.secondary)
                    ForEach(draft.references) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            Text(item.url).font(.footnote).foregroundStyle(Brand.bronze).textSelection(.enabled)
                            if !item.note.isEmpty { Text(item.note).font(.subheadline) }
                            Button("Remove link", role: .destructive) {
                                draft.references.removeAll { $0.id == item.id }
                            }.font(.caption)
                        }
                    }
                }
            }
            if section == .details {
                Section("Considered details · all optional") {
                    studioField("Style, finishes or materials you like", text: $draft.style)
                    studioField("What matters most to you?", text: $draft.priorities)
                    studioField("Existing plans, constraints or site access", text: $draft.constraints)
                    studioField("Anything else we should know?", text: $draft.other)
                }
            }
            if section == .timing {
                Section("Looking ahead · optional") {
                    studioField("Investment range or budget considerations", text: $draft.investment)
                    studioField("Ideal project timing", text: $draft.timeline)
                }
            }
            if section == .review {
                Section("Your project brief") {
                    Text(draft.brief).font(.subheadline).textSelection(.enabled)
                }
            }
            Section {
                Button("Review your project brief", systemImage: "doc.text.magnifyingglass") {
                    showReview = true
                }.buttonStyle(PrimaryButtonStyle())
                Text("Reviewing does not send anything. You can save and return later, or leave the studio without sharing.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Save my progress", systemImage: "square.and.arrow.down") { saveDraft() }
                Button("Clear my private studio", role: .destructive) { confirmClear = true }
            }
            if let notice {
                Section {
                    Label(notice, systemImage: "info.circle").font(.footnote)
                }
            }
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(Brand.cream)
        .onChange(of: draft) { _, _ in
            if suppressNextSave { suppressNextSave = false } else { saveDraft(silent: true) }
        }
        .onChange(of: pickedPhotos) { _, _ in
            Task { await importPhotos() }
        }
        .sheet(isPresented: $showReview, onDismiss: {
            if shareURL != nil { sharing = true }
        }) { reviewSheet }
        .sheet(isPresented: $sharing, onDismiss: { shareURL = nil }) {
            if let shareURL { StudioShareSheet(items: [shareURL]) }
        }
        .confirmationDialog("Remove your saved studio?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Remove all photos and answers", role: .destructive) {
                do { try StudioDraft.clear(); suppressNextSave = true; draft = StudioDraft(); notice = "The local studio was cleared." }
                catch { notice = "Could not clear all files. Please try again." }
            }
        } message: { Text("This deletes the private studio draft on this device. It does not alter an inquiry already sent to LINART.") }
    }

    @ViewBuilder private func studioField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            TextField("Share your thoughts (optional)", text: text, axis: .vertical)
                .lineLimit(2...5)
        }.padding(.vertical, 4)
    }

    private var reviewSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeading(eyebrow: "A considered beginning", title: "Your project, in your words.")
                    Text(draft.brief).font(.subheadline).textSelection(.enabled)
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
                    Text("Nothing has been submitted from this studio. Choose Share below, select your email app, address the message to \(Company.email), and send the attached PDF. Your device may offer other sharing destinations.")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("Prepare brief and photos to share", systemImage: "square.and.arrow.up") {
                        prepareBrief()
                    }.buttonStyle(PrimaryButtonStyle())
                    Button("Keep planning for now") { showReview = false }.buttonStyle(.bordered)
                }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }
            .background(Brand.cream)
            .navigationTitle("Review brief").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showReview = false } } }
        }
    }

    private func saveDraft(silent: Bool = false) {
        do { try draft.save(); if !silent { notice = "Your studio was saved privately on this device." } }
        catch { notice = "Unable to save your studio on this device. Check available storage." }
    }

    private func addReference() {
        let raw = newReference.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URLComponents(string: raw),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, host.contains("."), raw.count <= 1000 else {
            notice = "Enter a complete http or https web address."
            return
        }
        draft.references.append(StudioReference(url: raw, note: String(newReferenceNote.prefix(500))))
        newReference = ""
        newReferenceNote = ""
        notice = nil
    }

    @MainActor private func importPhotos() async {
        guard !importing, !pickedPhotos.isEmpty else { return }
        importing = true
        defer { importing = false; pickedPhotos = [] }
        var added = 0
        for item in pickedPhotos.prefix(max(0, 8 - draft.photos.count)) {
            guard let bytes = try? await item.loadTransferable(type: Data.self),
                  bytes.count <= 25_000_000,
                  let source = UIImage(data: bytes),
                  source.size.width > 0, source.size.height > 0 else { continue }
            let scale = min(1, 1600 / max(source.size.width, source.size.height))
            let size = CGSize(width: source.size.width * scale, height: source.size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            let normalized = renderer.image { _ in source.draw(in: CGRect(origin: .zero, size: size)) }
            guard let jpg = normalized.jpegData(compressionQuality: 0.78) else { continue }
            let name = UUID().uuidString + ".jpg"
            do {
                try FileManager.default.createDirectory(at: StudioDraft.directory, withIntermediateDirectories: true)
                try jpg.write(to: StudioDraft.directory.appendingPathComponent(name), options: [.atomic, .completeFileProtectionUnlessOpen])
                draft.photos.append(StudioPhoto(filename: name, purpose: photoPurpose))
                added += 1
            } catch { notice = "A photo could not be saved on this device." }
        }
        notice = added > 0 ? "\(added) photo\(added == 1 ? "" : "s") added privately to your studio." : "No photos were added. Choose standard images under 25 MB and try again."
    }

    private func removePhoto(_ photo: StudioPhoto) {
        try? FileManager.default.removeItem(at: StudioDraft.directory.appendingPathComponent(photo.filename))
        draft.photos.removeAll { $0.id == photo.id }
    }

    private func prepareBrief() {
        saveDraft(silent: true)
        do {
            let url = try StudioPDF.create(draft: draft)
            showReview = false
            shareURL = url
        } catch { notice = "The PDF could not be prepared. Check storage and try again." }
    }
}

private struct StudioShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}

private enum StudioPDF {
    static func create(draft: StudioDraft) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let pdf: Data = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 44
            let title = UIFont(name: "Georgia-Bold", size: 21) ?? UIFont.boldSystemFont(ofSize: 21)
            let normal = UIFont.systemFont(ofSize: 11)
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 3
            "LINART · PROJECT STUDIO".draw(at: CGPoint(x: 42, y: y), withAttributes: [.font: title])
            y += 42
            for rawLine in draft.brief.components(separatedBy: "\n") {
                let text = rawLine.isEmpty ? " " : rawLine
                let attrs: [NSAttributedString.Key: Any] = [.font: normal, .paragraphStyle: paragraph]
                let bounding = (text as NSString).boundingRect(with: CGSize(width: 528, height: CGFloat.greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                let height = max(16, ceil(bounding.height) + 4)
                if y + height > 748 { context.beginPage(); y = 45 }
                (text as NSString).draw(in: CGRect(x: 42, y: y, width: 528, height: height), withAttributes: attrs)
                y += height
            }
            for (index, photo) in draft.photos.enumerated() {
                guard let image = UIImage(contentsOfFile: StudioDraft.directory.appendingPathComponent(photo.filename).path) else { continue }
                context.beginPage()
                let heading = "PHOTO \(index + 1) · \(photo.purpose)"
                (heading as NSString).draw(at: CGPoint(x: 42, y: 43), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
                let available = CGSize(width: 528, height: 570)
                let factor = min(available.width / image.size.width, available.height / image.size.height)
                let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
                image.draw(in: CGRect(x: (612 - size.width) / 2, y: 88, width: size.width, height: size.height))
                let caption = photo.note.isEmpty ? "No additional notes." : photo.note
                (caption as NSString).draw(in: CGRect(x: 42, y: 682, width: 528, height: 68),
                                           withAttributes: [.font: normal])
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LINART-Project-Brief-\(UUID().uuidString).pdf")
        try pdf.write(to: url, options: .atomic)
        return url
    }
}

