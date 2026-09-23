import SwiftUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore

    private var savedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { store.favorites.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "Your next chapter", title: "Make room for what’s next.")
                Text("A thoughtful home begins with a clear idea. Explore, plan and share only when you are ready.")
                    .foregroundStyle(.secondary).lineSpacing(4)

                NavigationLink {
                    StudioAccessView()
                } label: {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("YOUR PRIVATE PROJECT STUDIO", systemImage: "square.stack.3d.up")
                            .font(.caption.weight(.semibold)).tracking(1.1).foregroundStyle(Brand.gold)
                        Text("Bring your vision to life.")
                            .font(.system(.title, design: .serif)).foregroundStyle(.white)
                        Text("Gather inspiration, add photos of your space and shape a brief at your own pace. Every question is optional.")
                            .foregroundStyle(.white.opacity(0.84))
                        Label("Open Project Studio", systemImage: "arrow.up.right")
                            .font(.headline).foregroundStyle(Brand.gold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background { Image("home-hero").resizable().scaledToFill().overlay(Brand.ink.opacity(0.72)) }.clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 18) {
                    Text("Before we talk").font(.system(.title2, design: .serif))
                    ProgressView(value: Double(store.completedSteps.intersection(Set(AppStore.planningSteps)).count), total: Double(AppStore.planningSteps.count))
                        .accessibilityLabel("Planning checklist progress")
                    ForEach(AppStore.planningSteps, id: \.self) { step in
                        Button { store.toggleStep(step) } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: store.completedSteps.contains(step) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3).foregroundStyle(Brand.bronze)
                                Text(step).foregroundStyle(Brand.ink).multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }.padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)
                        .accessibilityValue(store.completedSteps.contains(step) ? "Completed" : "Not completed")
                        .accessibilityHint("Double tap to change completion")
                    }
                }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))

                Button { store.startInquiry() } label: {
                    Label("Start a project inquiry", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
                Text("Your initial inquiry stands on its own. The Project Studio is always optional and does not delay contacting LINART.")
                    .font(.caption).foregroundStyle(.secondary)
                SectionHeading(eyebrow: "Saved inspiration", title: "A home that feels like you.")
                if savedProjects.isEmpty {
                    ContentUnavailableView("Your inspiration starts here", systemImage: "heart", description: Text("Tap the heart on any project to save it for later."))
                    Button("Explore projects") { store.selectedTab = 1 }.buttonStyle(.bordered)
                } else {
                    ForEach(savedProjects) { project in
                        NavigationLink { ProjectDetailView(project: project) } label: { ProjectCard(project: project) }
                            .buttonStyle(.plain)
                    }
                }
                ContactActions()
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("My Project").navigationBarTitleDisplayMode(.inline)
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
    var cloudRevision: Int?
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

    static var directory: URL { directory(for: nil) }

    static func directory(for inquiryID: String?) -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let root = base.appendingPathComponent("LINARTProjectStudio", isDirectory: true)
        guard let inquiryID, UUID(uuidString: inquiryID) != nil else { return root }
        return root.appendingPathComponent(inquiryID.lowercased(), isDirectory: true)
    }

    static func load(inquiryID: String? = nil) -> StudioDraft {
        let url = directory(for: inquiryID).appendingPathComponent("draft.json")
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(StudioDraft.self, from: data) else { return StudioDraft() }
        return decoded
    }

    func save(inquiryID: String? = nil) throws {
        let directory = Self.directory(for: inquiryID)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(self)
        try data.write(to: directory.appendingPathComponent("draft.json"), options: [.atomic, .completeFileProtection])
        var folder=directory; var values=URLResourceValues(); values.isExcludedFromBackup=true
        try folder.setResourceValues(values)
    }

    static func clear(inquiryID: String? = nil) throws {
        let directory = Self.directory(for: inquiryID)
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

struct ProjectStudioView: View {
    let inquiryID: String
    @State private var remote: StudioEnvelope?
    @State private var cloudBusy = false
    @State private var cloudNotice: String?
    @State private var showDocumentPicker = false
    @State private var confirmReload = false
    @State private var confirmDelete = false
    @State private var pdfEnabled = false
    @State private var detailsExpanded = false
    @State private var linksExpanded = false
    @State private var draft: StudioDraft
    private var directory: URL { StudioDraft.directory(for: inquiryID) }
    init(inquiryID: String) {
        self.inquiryID = inquiryID
        _draft = State(initialValue: StudioDraft.load(inquiryID: inquiryID))
    }
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
                    Text("Your vision, beautifully organized.").font(.system(.title, design: .serif))
                    Text("Add as much or as little as you wish. Your initial inquiry is already separate from this studio.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    HStack {
                        Text("\(progress) of 7 planning topics explored").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("No required questions").font(.caption).foregroundStyle(Brand.bronze)
                    }
                    ProgressView(value: Double(progress), total: 7).tint(Brand.bronze)
                    Label("You control when your ideas are saved online", systemImage: "lock.shield")
                        .font(.caption).foregroundStyle(Brand.bronze)
                }.padding(.vertical, 7)
            }
            Section("Your private project") {
                Text("Your initial inquiry is already with LINART. Save online when you want the team to see your progress; submit after reviewing. Every planning question is optional.").font(.subheadline)
                if let remote {
                    Text(remote.project.contact["service"] ?? "Your project").font(.headline)
                    Text(remote.studio.submitted_at == nil ? "Studio draft · not yet submitted" : "A brief has been submitted. You may save changes and submit an update.").font(.caption).foregroundStyle(.secondary)
                }
                if let cloudNotice { Text(cloudNotice).font(.footnote).foregroundStyle(Brand.bronze) }
                Button("Reload saved online brief") { confirmReload = true }.disabled(cloudBusy)
            }
            Section("Your starting point · optional") {
                Text("The verified inquiry connects this brief securely to your project.").font(.caption).foregroundStyle(.secondary)
                Picker("Project type", selection: $draft.projectType) {
                    Text("Not decided").tag("")
                    ForEach(services, id: \.self) { Text($0).tag($0) }
                }
                studioField(tailoredPrompt, text: $draft.goals)
                studioField("What does the space look like today?", text: $draft.existingConditions)
            }
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
                        if let image = UIImage(contentsOfFile: directory.appendingPathComponent(photo.filename).path) {
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
                ForEach((remote?.assets ?? []).filter { $0.mime.hasPrefix("image/") }) { asset in
                    VStack(alignment:.leading,spacing:4) {
                        Text("\(asset.purpose) · \(asset.state == "ready" ? "Saved online" : "Transfer pending")").font(.caption)
                        Button("Remove online photo", role:.destructive) { Task { await deleteAsset(asset.id) } }.disabled(cloudBusy)
                    }
                }
            } header: { Text("Your spaces & inspiration") }
            Section {
                DisclosureGroup("Ideas from the internet · optional", isExpanded: $linksExpanded) {
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
            Section {
                DisclosureGroup("Considered details · all optional", isExpanded: $detailsExpanded) {
                studioField("Style, finishes or materials you like", text: $draft.style)
                studioField("What matters most to you?", text: $draft.priorities)
                studioField("Investment range or budget considerations", text: $draft.investment)
                studioField("Ideal project timing", text: $draft.timeline)
                studioField("Existing plans, constraints or site access", text: $draft.constraints)
                studioField("Anything else we should know?", text: $draft.other)
                }
            }
            Section("Plans & documents · optional") {
                Text(pdfEnabled ? "Up to four PDF documents, 10 MB each. Documents upload when selected; review the file before choosing it." : "PDF uploads are not enabled. Describe available plans above or add a photograph of a drawing.").font(.caption)
                if pdfEnabled { Button("Choose and upload a PDF") { showDocumentPicker = true }.disabled(cloudBusy) }
                ForEach((remote?.assets ?? []).filter { $0.mime == "application/pdf" }) { asset in
                    Text("PDF · \(asset.state == "ready" ? "Saved privately" : "Transfer pending")").font(.subheadline)
                    if !asset.note.isEmpty { Text(asset.note).font(.caption) }
                    Button("Remove document", role: .destructive) { Task { await deleteAsset(asset.id) } }.disabled(cloudBusy)
                }
            }
            Section {
                Button("Review your project brief", systemImage: "doc.text.magnifyingglass") {
                    showReview = true
                }.buttonStyle(PrimaryButtonStyle())
                Text("Reviewing does not send anything. You can save and return later, or leave the studio without sharing.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Save progress online", systemImage: "icloud.and.arrow.up") { Task { await saveOnline(submit: false) } }.disabled(cloudBusy || importing || remote == nil)
                Text("Saving online uploads selected photos, notes and links to your private project. LINART can view saved drafts.").font(.caption).foregroundStyle(.secondary)
                Button("Save on this device", systemImage: "square.and.arrow.down") { saveDraft() }
                Button("Request deletion of online project", role: .destructive) { confirmDelete = true }.disabled(cloudBusy)
                Button("Clear my private studio", role: .destructive) { confirmClear = true }
            }
            if let notice {
                Section {
                    Label(notice, systemImage: "info.circle").font(.footnote)
                }
            }
        }
        .task { await connect() }
        .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.pdf]) { result in
            Task { await importDocument(result) }
        }
        .confirmationDialog("Replace this device’s draft with the online version?", isPresented: $confirmReload, titleVisibility: .visible) {
            Button("Load online version") { Task { await loadOnline() } }
        } message: { Text("Unsaved local changes will be replaced. You can keep planning locally instead.") }
        .confirmationDialog("Request deletion of this online project?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Request deletion", role: .destructive) { Task { await requestDeletion() } }
        } message: { Text("Online client access will close immediately. LINART will review the deletion request, including any records that need to be retained. This does not cancel your original inquiry.") }
        .scrollDismissesKeyboard(.interactively)
        .disabled(cloudBusy)
        .navigationTitle("Project Studio")
        .navigationBarTitleDisplayMode(.inline)
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
        .sheet(isPresented: $sharing, onDismiss: { if let shareURL { try? FileManager.default.removeItem(at: shareURL) }; shareURL = nil }) {
            if let shareURL { StudioShareSheet(items: [shareURL]) }
        }
        .confirmationDialog("Remove your saved studio?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Remove all photos and answers", role: .destructive) {
                do { try StudioDraft.clear(inquiryID: inquiryID); suppressNextSave = true; draft = StudioDraft(); notice = "The local studio was cleared." }
                catch { notice = "Could not clear all files. Please try again." }
            }
        } message: { Text("This deletes the private studio draft on this device. It does not alter an inquiry already sent to LINART.") }
    }

    @ViewBuilder private func studioField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            TextField("Share your thoughts (optional)", text: text, axis: .vertical)
                .lineLimit(2...5)
                .onChange(of: text.wrappedValue) { _, value in if value.count > 4000 { text.wrappedValue = String(value.prefix(4000)) } }
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
                    Text("Submit sends this brief and selected photos to LINART under your original inquiry. A partial brief is welcome. Sharing a PDF is a separate, optional action.")
                        .font(.footnote).foregroundStyle(.secondary)
                    if let cloudNotice { Text(cloudNotice).font(.footnote) }
                    ForEach(draft.photos) { photo in
                        if let image = UIImage(contentsOfFile: directory.appendingPathComponent(photo.filename).path) {
                            Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 260).accessibilityLabel(photo.note.isEmpty ? photo.purpose : photo.note)
                        }
                    }
                    ForEach((remote?.assets ?? []).filter { asset in asset.mime.hasPrefix("image/") && !draft.photos.contains(where: { photo in photo.id.uuidString.lowercased() == asset.id.lowercased() }) }) { asset in
                        StudioRemotePhoto(inquiryID: inquiryID, asset: asset)
                    }
                    Text("\((remote?.assets ?? []).filter { $0.mime == "application/pdf" && $0.state == "ready" }.count) PDF documents saved with this project. Online attachments remain part of the submitted brief. Reload the online version to preview photographs saved on another device.").font(.caption)
                    Button(cloudBusy ? "Saving…" : "Submit brief to LINART", systemImage: "paperplane") { Task { await saveOnline(submit: true) } }
                        .buttonStyle(PrimaryButtonStyle()).disabled(cloudBusy || importing || remote == nil)
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
        do { try draft.save(inquiryID: inquiryID); if !silent { notice = "Your studio was saved privately on this device." } }
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
            let format = UIGraphicsImageRendererFormat(); format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let normalized = renderer.image { _ in source.draw(in: CGRect(origin: .zero, size: size)) }
            guard let jpg = normalized.jpegData(compressionQuality: 0.78) else { continue }
            let name = UUID().uuidString + ".jpg"
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                try jpg.write(to: directory.appendingPathComponent(name), options: [.atomic, .completeFileProtection])
                draft.photos.append(StudioPhoto(filename: name, purpose: photoPurpose))
                added += 1
            } catch { notice = "A photo could not be saved on this device." }
        }
        notice = added > 0 ? "\(added) photo\(added == 1 ? "" : "s") added privately to your studio." : "No photos were added. Choose standard images under 25 MB and try again."
    }

    private func removePhoto(_ photo: StudioPhoto) {
        if remote?.assets.contains(where: { $0.id.lowercased() == photo.id.uuidString.lowercased() }) == true {
            cloudNotice="This photo is already saved online. Use Remove online photo below to remove it from the project."
            return
        }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(photo.filename))
        draft.photos.removeAll { $0.id == photo.id }
    }

    private func prepareBrief() {
        saveDraft(silent: true)
        do {
            let url = try StudioPDF.create(draft: draft, directory: directory)
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
    static func create(draft: StudioDraft, directory: URL) throws -> URL {
        let page = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: page)
        let pdf = renderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = 44
            let title = UIFont(name: "Georgia-Bold", size: 21) ?? UIFont.boldSystemFont(ofSize: 21)
            let normal = UIFont.systemFont(ofSize: 11)
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = .byWordWrapping
            paragraph.lineSpacing = 3
            "LINART · PROJECT STUDIO".draw(at: CGPoint(x: 42, y: y), withAttributes: [.font: title])
            y += 42
            for rawLine in draft.brief.components(separatedBy: "\n").flatMap({ line -> [String] in
                if line.isEmpty { return [""] }
                var remaining = line[...]; var chunks: [String] = []
                while !remaining.isEmpty { let chunk = remaining.prefix(250); chunks.append(String(chunk)); remaining = remaining.dropFirst(chunk.count) }
                return chunks
            }) {
                let text = rawLine.isEmpty ? " " : rawLine
                let attrs: [NSAttributedString.Key: Any] = [.font: normal, .paragraphStyle: paragraph]
                let bounding = (text as NSString).boundingRect(with: CGSize(width: 528, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attrs, context: nil)
                let height = max(16, ceil(bounding.height) + 4)
                if y + height > 748 { context.beginPage(); y = 45 }
                (text as NSString).draw(in: CGRect(x: 42, y: y, width: 528, height: height), withAttributes: attrs)
                y += height
            }
            for (index, photo) in draft.photos.enumerated() {
                guard let image = UIImage(contentsOfFile: directory.appendingPathComponent(photo.filename).path) else { continue }
                context.beginPage()
                let heading = "PHOTO \(index + 1) · \(photo.purpose)"
                (heading as NSString).draw(at: CGPoint(x: 42, y: 43), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 16)])
                let available = CGSize(width: 528, height: 570)
                let factor = min(available.width / image.size.width, available.height / image.size.height)
                let size = CGSize(width: image.size.width * factor, height: image.size.height * factor)
                image.draw(in: CGRect(x: (612 - size.width) / 2, y: 88, width: size.width, height: size.height))
                let caption = photo.note.isEmpty ? "No additional notes." : String(photo.note.prefix(500))
                (caption as NSString).draw(in: CGRect(x: 42, y: 682, width: 528, height: 68),
                                           withAttributes: [.font: normal])
            }
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LINART-Project-Brief-\(UUID().uuidString).pdf")
        try pdf.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }
}


extension StudioDraft {
    var answers: [String: String] {
        ["projectType":projectType,"goals":goals,"existingConditions":existingConditions,"style":style,"priorities":priorities,"investment":investment,"timeline":timeline,"constraints":constraints,"other":other]
    }
    mutating func apply(_ remote: RemoteStudio) {
        projectType=remote.answers["projectType"] ?? ""; goals=remote.answers["goals"] ?? ""
        existingConditions=remote.answers["existingConditions"] ?? ""; style=remote.answers["style"] ?? ""
        priorities=remote.answers["priorities"] ?? ""; investment=remote.answers["investment"] ?? ""
        timeline=remote.answers["timeline"] ?? ""; constraints=remote.answers["constraints"] ?? ""; other=remote.answers["other"] ?? ""
        references=remote.links.map { StudioReference(url:$0.url,note:$0.note) }
    }
}

struct StudioAccessView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var connection = StudioConnection()
    @State private var email = StudioVault.receipts.last?.email ?? ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var selected: String?
    @State private var showStudio = false
    @State private var cooldownUntil = Date.distantPast

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                Image("home-hero").resizable().scaledToFill().frame(height:220).clipped().clipShape(RoundedRectangle(cornerRadius:18)).accessibilityLabel("LINART architectural introduction")
                SectionHeading(eyebrow:"Your private project",title:"A little more of your vision.")
                Text("Your inquiry comes first. The Studio is an optional place to gather ideas, explore the possibilities and share a thoughtful brief.").foregroundStyle(.secondary)
                if connection.projects.isEmpty {
                    Text("Return securely with an email code. No password to create.").font(.headline)
                    TextField("Email used for your inquiry",text:$email).keyboardType(.emailAddress).textContentType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                    Button("Send verification code") { Task { await sendCode() } }.buttonStyle(PrimaryButtonStyle()).disabled(connection.busy)
                    if codeSent {
                        TextField("Email verification code",text:$code).keyboardType(.numberPad).textContentType(.oneTimeCode).textFieldStyle(.roundedBorder)
                        Button("Verify & open my projects") { Task { await verify() } }.buttonStyle(.borderedProminent).disabled(connection.busy || code.isEmpty)
                    }
                }
                if connection.projects.isEmpty && StudioVault.read("token") != nil {
                    Button("Retry project connection") { Task { await reconnect() } }.disabled(connection.busy)
                }
                if let notice=connection.notice { Text(notice).font(.footnote).foregroundStyle(Brand.bronze) }
                ForEach(connection.projects) { project in
                    Button {
                        do { try StudioVault.write("active",Data(project.id.utf8)); selected=project.id; showStudio=true }
                        catch { connection.notice=error.localizedDescription }
                    } label: {
                        VStack(alignment:.leading,spacing:8) {
                            Text(project.contact["service"] ?? "Your project").font(.system(.title3,design:.serif))
                            Text(project.contact["city"] ?? "").font(.subheadline)
                            Label("Continue Project Studio",systemImage:"arrow.up.right").font(.caption)
                        }.frame(maxWidth:.infinity,alignment:.leading).padding(20).background(Brand.paper,in:RoundedRectangle(cornerRadius:14))
                    }.buttonStyle(.plain)
                }
                if !connection.projects.isEmpty {
                    Button("Sign out") { Task { try? await StudioClient().request("logout"); try? StudioVault.write("token",nil); connection.projects=[]; codeSent=false; code="" } }
                }
                if let id=StudioVault.activeID {
                    Button("Continue my saved draft on this device") { selected=id; showStudio=true }
                    Text("Offline drafts stay on this device until you choose to save online.").font(.caption).foregroundStyle(.secondary)
                }
                Button("Start an initial project inquiry") { store.startInquiry() }.buttonStyle(.bordered)
                Text("If your invitation is over 30 days old or you changed devices before opening the Studio, contact LINART to reconnect it after verifying your identity.").font(.caption).foregroundStyle(.secondary)
                ContactActions()
            }.padding(24).frame(maxWidth:720).frame(maxWidth:.infinity)
        }.background(Brand.cream).navigationTitle("Project Studio").navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented:$showStudio) { if let selected { ProjectStudioView(inquiryID:selected).id(selected) } }
        .task { if StudioVault.read("token") != nil { await connection.refresh() } }
    }
    @MainActor private func sendCode() async {
        guard !connection.busy else { return }
        guard Date() >= cooldownUntil else { connection.notice="Please wait a minute before requesting another code."; return }
        connection.busy=true; defer { connection.busy=false }
        do { _ = try await StudioClient().request("send_code",fields:["email":email.trimmingCharacters(in:.whitespacesAndNewlines)],authenticated:false); codeSent=true; cooldownUntil=Date().addingTimeInterval(60); connection.notice="Check your email for a verification code." }
        catch { connection.notice=error.localizedDescription }
    }
    @MainActor private func verify() async {
        guard !connection.busy else { return }; connection.busy=true
        do {
            try await StudioClient().verify(email:email.trimmingCharacters(in:.whitespacesAndNewlines),code:code)
            await linkReceipts()
            code=""
        } catch { connection.notice=error.localizedDescription }
        connection.busy=false
    }
    @MainActor private func reconnect() async {
        guard !connection.busy else { return }; connection.busy=true
        await linkReceipts(); connection.busy=false
    }
    @MainActor private func linkReceipts() async {
        do {
            var pending=false
            for receipt in StudioVault.receipts where receipt.email.lowercased() == email.trimmingCharacters(in:.whitespacesAndNewlines).lowercased() {
                do { _ = try await StudioClient().request("claim",fields:["inquiry_id":receipt.id,"receipt":receipt.receipt]) }
                catch { pending=true }
            }
            connection.projects=try await StudioClient().projects()
            connection.notice=pending ? "An invitation is not ready yet or has expired. Your inquiry is still recorded. Retry the connection in a few minutes, or contact LINART." : (connection.projects.isEmpty ? "No linked project is available yet. Use the device that sent your inquiry, or contact LINART to reconnect it." : nil)
        } catch { connection.notice=error.localizedDescription }
    }

}

private extension ProjectStudioView {
    @MainActor func connect() async {
        do {
            remote=try await StudioClient().load(inquiryID)
            if draft.cloudRevision == nil && remote?.studio.revision == 0 { draft.cloudRevision=0 }
            if draft.projectType.isEmpty { draft.projectType=remote?.project.contact["service"] ?? "" }
            let config=try await StudioClient().request("config",authenticated:false)
            let settings = (try? JSONSerialization.jsonObject(with: config)) as? [String: Any]
            if let enabled = settings?["pdf_enabled"] as? Bool { pdfEnabled = enabled } else { pdfEnabled = false }
            cloudNotice="Connected. Local edits are kept on this device until you save online. Reload the online brief to bring in changes from another device."
        } catch { cloudNotice=error.localizedDescription }
    }
    @MainActor func loadOnline() async {
        guard !cloudBusy else { return }; cloudBusy=true; defer { cloudBusy=false }
        do {
            let envelope=try await StudioClient().load(inquiryID)
            var loaded=StudioDraft(); loaded.apply(envelope.studio); loaded.cloudRevision=envelope.studio.revision
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            for asset in envelope.assets where asset.mime.hasPrefix("image/") && asset.state == "ready" {
                let bytes=try await StudioClient().request("download",fields:["inquiry_id":inquiryID,"asset_id":asset.id])
                let filename=asset.id+".jpg"
                try bytes.write(to:directory.appendingPathComponent(filename),options:[.atomic,.completeFileProtection])
                if let id=UUID(uuidString:asset.id) { loaded.photos.append(StudioPhoto(id:id,filename:filename,purpose:asset.purpose,note:asset.note)) }
            }
            try loaded.save(inquiryID: inquiryID); draft=loaded; remote=envelope; cloudNotice="Your saved online brief is loaded on this device."
        } catch { cloudNotice=error.localizedDescription }
    }
    @MainActor func saveOnline(submit: Bool) async {
        guard !cloudBusy, let baseline=remote else { return }; cloudBusy=true; defer { cloudBusy=false }
        do {
            try draft.save(inquiryID: inquiryID)
            guard let revision=draft.cloudRevision else { throw StudioAPIError(message:"Reload the saved online brief before editing this project on a new device.") }
            let current=try await StudioClient().load(inquiryID)
            guard current.studio.revision == revision else { throw StudioAPIError(message:"The online brief changed. Your local draft is safe. Review or export it before reloading the online version.") }
            for photo in draft.photos {
                guard photo.note.count <= 500 else { throw StudioAPIError(message:"Keep each photo caption under 500 characters.") }
                if baseline.assets.contains(where: { $0.id.lowercased() == photo.id.uuidString.lowercased() && $0.state == "ready" }) {
                    _ = try await StudioClient().request("caption",fields:["inquiry_id":inquiryID,"asset_id":photo.id.uuidString.lowercased(),"note":photo.note])
                } else {
                    let bytes=try Data(contentsOf:directory.appendingPathComponent(photo.filename))
                    try await StudioClient().upload(id:inquiryID,assetID:photo.id.uuidString,bytes:bytes,mime:"image/jpeg",purpose:photo.purpose,note:photo.note)
                }
            }
            let result=try await StudioClient().save(draft,id:inquiryID,revision:revision,submit:submit)
            draft.cloudRevision=result.revision; try draft.save(inquiryID: inquiryID)
            remote?.studio=result
            // Refresh attachment metadata only after the acknowledged write.
            remote=try await StudioClient().load(inquiryID)
            cloudNotice=submit ? "Your project brief was submitted to LINART. You can return to make changes and submit an update." : "Your progress is saved online. LINART can review this optional draft."
        } catch { cloudNotice=error.localizedDescription }
    }
    @MainActor func importDocument(_ result: Result<URL,Error>) async {
        guard !cloudBusy else { return }; cloudBusy=true; defer { cloudBusy=false }
        do {
            let url=try result.get(); let scoped=url.startAccessingSecurityScopedResource(); defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            let size=try url.resourceValues(forKeys:[.fileSizeKey]).fileSize ?? 0
            guard size > 0, size <= 10_485_760 else { throw StudioAPIError(message:"Choose a PDF under 10 MB.") }
            let bytes=try Data(contentsOf:url)
            try await StudioClient().upload(id:inquiryID,assetID:UUID().uuidString,bytes:bytes,mime:"application/pdf",purpose:"Plans or drawings",note:String(url.lastPathComponent.prefix(500)))
            remote=try await StudioClient().load(inquiryID); cloudNotice="Your document is saved privately with this project."
        } catch { cloudNotice=error.localizedDescription }
    }
    @MainActor func deleteAsset(_ id: String) async {
        guard !cloudBusy else { return }; cloudBusy=true; defer { cloudBusy=false }
        do {
            _ = try await StudioClient().request("remove_asset",fields:["inquiry_id":inquiryID,"asset_id":id])
            if let photo=draft.photos.first(where: { $0.id.uuidString.lowercased() == id.lowercased() }) {
                try? FileManager.default.removeItem(at:directory.appendingPathComponent(photo.filename))
                draft.photos.removeAll { $0.id == photo.id }
            }
            remote=try await StudioClient().load(inquiryID); cloudNotice="The attachment was removed from your online project."
        }
        catch { cloudNotice=error.localizedDescription }
    }
    @MainActor func requestDeletion() async {
        guard !cloudBusy else { return }; cloudBusy=true; defer { cloudBusy=false }
        do { _ = try await StudioClient().request("request_deletion",fields:["inquiry_id":inquiryID]); remote=nil; cloudNotice="Deletion requested. Online access to this project is closed. Contact LINART for the request’s progress." }
        catch { cloudNotice=error.localizedDescription }
    }
}

private struct StudioRemotePhoto: View {
    let inquiryID: String
    let asset: RemoteAsset
    @State private var image: UIImage?
    @State private var errorMessage: String?
    var body: some View {
        VStack(alignment:.leading,spacing:8) {
            if let image { Image(uiImage:image).resizable().scaledToFit().frame(maxHeight:260).accessibilityLabel(asset.note.isEmpty ? asset.purpose : asset.note) }
            else if let errorMessage { Text(errorMessage).font(.caption) }
            else { ProgressView("Loading saved photo") }
            Text("\(asset.purpose) · \(asset.note)").font(.caption)
        }.task {
            do {
                let data=try await StudioClient().request("download",fields:["inquiry_id":inquiryID,"asset_id":asset.id])
                image=UIImage(data:data)
                if image == nil { errorMessage="This saved image cannot be previewed." }
            } catch { errorMessage="The online photo could not be loaded. Reconnect before submitting if you need to review it." }
        }
    }
}
