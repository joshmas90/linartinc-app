import SwiftUI
import PhotosUI

struct StudioEditorView: View {
    let section: StudioSection
    @EnvironmentObject private var studio: StudioStore
    @State private var selections: [PhotosPickerItem] = []
    @State private var purpose = "My space"
    @State private var filter = "All"
    @State private var moreDetails = false
    @State private var showLinkEditor = false
    @State private var showIdeas = false
    private let purposes = ["My space", "Inspiration", "Plans & drawings"]

    var body: some View {
        Form {
            Section {
                StudioStepHeader(section: section)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
            Section { StudioStatusView() }
            Group {
                if section == .details { details }
                if section == .photos { photos }
                if section == .links { references }
                if section == .timing {
                    Section("Looking ahead · optional") {
                        StudioField(title: "Investment range or budget considerations", text: $studio.draft.investment,
                                    placeholder: "A range is helpful, or say you are still exploring.")
                        StudioField(title: "Ideal project timing", text: $studio.draft.timeline,
                                    placeholder: "For example, this fall or flexible.")
                    }
                }
            }.disabled(!studio.isReady)
        }.scrollContentBackground(.hidden).background(Brand.cream).scrollDismissesKeyboard(.interactively)
            .onChange(of: selections) { _, items in
                guard !items.isEmpty else { return }
                studio.importPhotos(items, purpose: purpose); selections = []
            }
            .sheet(isPresented: $showLinkEditor) { StudioLinkEditor() }
            .sheet(isPresented: $showIdeas) { StudioIdeasPicker() }
            .onAppear {
                let draft = studio.draft
                moreDetails = [draft.style, draft.priorities, draft.constraints, draft.other, draft.inquiryEmail]
                    .contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
    }

    private var details: some View {
        Group {
            Section("Start with the basics · optional") {
                Picker("Project type", selection: $studio.draft.projectType) {
                    Text("Not decided yet").tag("")
                    ForEach(Inquiry.serviceOptions, id: \.self) { Text($0).tag($0) }
                }.accessibilityIdentifier("studioProjectType")
                StudioField(title: "What would you like to create?", text: $studio.draft.goals,
                            placeholder: studio.draft.guidance.goal)
                StudioField(title: "What does the space look like today?", text: $studio.draft.existingConditions,
                            placeholder: studio.draft.guidance.currentSpace)
            }
            Section {
                DisclosureGroup("More project details", isExpanded: $moreDetails) {
                    StudioField(title: "Style, finishes or materials you like", text: $studio.draft.style,
                                placeholder: studio.draft.guidance.style)
                    StudioField(title: "What matters most to you?", text: $studio.draft.priorities,
                                placeholder: studio.draft.guidance.priorities)
                    StudioField(title: "Existing plans, constraints or site access", text: $studio.draft.constraints)
                    StudioField(title: "Anything else we should know?", text: $studio.draft.other)
                    StudioField(title: "Your inquiry email", text: $studio.draft.inquiryEmail, email: true,
                                placeholder: "If you have already contacted LINART")
                }
            } footer: {
                Text("You do not need all the answers today. Continue when you are ready.")
            }
        }
    }

    private var photos: some View {
        let importing = studio.isImporting
        return Group {
            Section {
                Text(studio.draft.guidance.photos).foregroundStyle(Brand.secondary)
                    .accessibilityIdentifier("studioPhotoGuidance")
                Picker("Type of photo", selection: $purpose) {
                    ForEach(purposes, id: \.self) { Text($0).tag($0) }
                }.disabled(studio.isImporting)
                PhotosPicker(selection: $selections, maxSelectionCount: max(1, 8 - studio.draft.photos.count), matching: .images) {
                    Label(importing ? "Adding photos…" : "Choose photos", systemImage: "photo.badge.plus")
                        .frame(minHeight: 44)
                }.disabled(studio.isImporting || studio.draft.photos.count >= 8)
                    .accessibilityIdentifier("studioAddPhotos")
                Text("\(studio.draft.photos.count) of 8 photos added. Only the photos you choose are copied into your plan.")
                    .font(.caption).foregroundStyle(Brand.secondary)
                if studio.isImporting { ProgressView("Adding your selected photos…") }
                if studio.draft.photos.isEmpty && !studio.isImporting {
                    StudioEmptyState(
                        symbol: "photo.on.rectangle.angled",
                        title: "No photos yet",
                        message: "A wide view is a useful start, but you can continue without photos and return whenever you're ready."
                    )
                }
            } header: { Text("Add photos · optional") }

            if !studio.draft.photos.isEmpty {
                Section("Your selected photos") {
                    Picker("Show photos", selection: $filter) {
                        Text("All").tag("All")
                        ForEach(purposes, id: \.self) { Text($0).tag($0) }
                    }
                    if filter != "All" && !studio.draft.photos.contains(where: { $0.purpose == filter }) {
                        Text("No photos in this category. Choose All to see your other photos.")
                            .font(.footnote).foregroundStyle(Brand.secondary)
                    }
                    ForEach($studio.draft.photos) { $photo in
                        if filter == "All" || photo.purpose == filter {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    StudioThumbnail(photo: photo)
                                    Spacer()
                                    Button(role: .destructive) { Task { await studio.removePhoto(photo) } } label: {
                                        Image(systemName: "trash").frame(minWidth: 44, minHeight: 44)
                                    }.buttonStyle(.borderless).accessibilityLabel("Remove \(photo.purpose) photo")
                                }
                                Picker("Photo type", selection: $photo.purpose) {
                                    ForEach(purposes, id: \.self) { Text($0).tag($0) }
                                }
                                StudioField(title: "What should LINART notice?", text: $photo.note,
                                            placeholder: "For example, the wall we would like to open up.")
                            }.padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }

    private var references: some View {
        Group {
            Section {
                if studio.draft.references.isEmpty {
                    StudioEmptyState(
                        symbol: "link",
                        title: "No web inspiration saved yet",
                        message: "Add a room, finish or product link only when it helps explain what you like."
                    )
                }
                ForEach(studio.draft.references) { reference in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reference.url).font(.footnote).textSelection(.enabled)
                        if !reference.note.isEmpty { Text(reference.note) }
                        Button("Remove link", role: .destructive) { studio.draft.references.removeAll { $0.id == reference.id } }
                            .buttonStyle(.borderless).frame(minHeight: 44)
                    }
                }
                Button("Add a web link", systemImage: "link.badge.plus") { showLinkEditor = true }
                    .disabled(studio.draft.references.count >= 10).frame(minHeight: 44)
                    .accessibilityIdentifier("studioAddLink")
            } header: { Text("Web inspiration · optional") } footer: {
                Text("\(studio.draft.references.count) of 10 links added.")
            }

            Section("Ideas from LINART projects · optional") {
                if studio.draft.ideas.isEmpty {
                    StudioEmptyState(
                        symbol: "square.grid.2x2",
                        title: "No LINART inspiration selected yet",
                        message: "Browse completed projects and save only the details that speak to your project."
                    )
                }
                ForEach($studio.draft.ideas) { $idea in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(idea.title).font(.headline)
                        StudioField(title: "The details you love", text: $idea.note,
                                    placeholder: "For example, the cabinetry or the open layout.")
                        Button("Remove from brief", role: .destructive) { studio.draft.ideas.removeAll { $0.id == idea.id } }
                            .buttonStyle(.borderless).frame(minHeight: 44)
                    }
                }
                Button("Choose from LINART projects", systemImage: "square.grid.2x2") { showIdeas = true }
                    .frame(minHeight: 44).accessibilityIdentifier("studioChooseIdeas")
            }
        }
    }
}

struct StudioLinkEditor: View {
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var note = ""
    @State private var error: String?
    @FocusState private var addressFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Web address") {
                    TextField("https://…", text: $url)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityLabel("Full web address").focused($addressFocused)
                    if let error { Label(error, systemImage: "exclamationmark.circle").font(.footnote).foregroundStyle(.red) }
                }
                Section { StudioField(title: "What appeals to you?", text: $note) }
            }.navigationTitle("Add inspiration").navigationBarTitleDisplayMode(.inline)
                .scrollDismissesKeyboard(.interactively)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add link") { addLink() }
                            .disabled(url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !studio.isReady || studio.draft.references.count >= 10)
                    }
                }
        }.tint(Brand.bronze)
            // An unfinished link cannot disappear because of an accidental sheet swipe.
            .interactiveDismissDisabled(!url.isEmpty || !note.isEmpty)
    }

    private func addLink() {
        let raw = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: raw), ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
              let host = components.host, host.contains("."), components.user == nil, components.password == nil, raw.count <= 1000 else {
            error = "Enter a full web address beginning with https:// or http://."
            addressFocused = true
            return
        }
        guard studio.isReady, studio.draft.references.count < 10 else { return }
        studio.draft.references.append(StudioReference(url: raw, note: String(note.prefix(2000))))
        Task { await studio.flush() }
        dismiss()
    }
}

struct StudioIdeasPicker: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss

    private var projects: [PortfolioProject] {
        let projects = store.catalog?.projects ?? []
        return projects.filter { store.favorites.contains($0.id) } + projects.filter { !store.favorites.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    Text("Explore the details, then add the projects that speak to you. Your saved favorites appear first.")
                        .foregroundStyle(Brand.secondary)
                    ForEach(projects) { project in
                        VStack(alignment: .leading, spacing: 16) {
                            if let photo = project.photos.first { PortfolioImage(photo: photo, height: 210) }
                            VStack(alignment: .leading, spacing: 12) {
                                Text(project.title).font(.system(.title3, design: .serif)).foregroundStyle(Brand.ink)
                                if store.favorites.contains(project.id) {
                                    Label("Saved favorite", systemImage: "heart.fill").font(.caption).foregroundStyle(Brand.bronze)
                                }
                                Text(project.scope).font(.subheadline).foregroundStyle(Brand.secondary).lineLimit(3)
                                NavigationLink { StudioInspirationDetail(project: project) } label: {
                                    Label("View project", systemImage: "photo.on.rectangle")
                                }.buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("studioPreview-\(project.id)")
                                StudioIncludeIdeaButton(project: project)
                            }.padding([.horizontal, .bottom], 20)
                        }
                        .accessibilityElement(children: .contain)
                        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    if projects.isEmpty {
                        Text("The portfolio could not be loaded. Your plan is still available; you can add ideas later.")
                            .foregroundStyle(Brand.secondary)
                    }
                }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(Brand.cream).navigationTitle("Choose inspiration").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }.tint(Brand.bronze)
    }
}

struct StudioIncludeIdeaButton: View {
    let project: PortfolioProject
    @EnvironmentObject private var studio: StudioStore
    private var included: Bool { studio.draft.ideas.contains { $0.id == project.id } }
    var body: some View {
        Button { studio.include(project) } label: {
            Label(included ? "Added to your brief" : "Add to my brief", systemImage: included ? "checkmark.circle.fill" : "plus.circle")
                .fixedSize(horizontal: false, vertical: true)
        }.buttonStyle(PrimaryButtonStyle()).disabled(included || !studio.isReady)
            .accessibilityIdentifier("studioIdea-\(project.id)")
    }
}

// A focused preview stays inside the planner and never opens an inquiry or changes tabs.
struct StudioInspirationDetail: View {
    let project: PortfolioProject
    @State private var selectedPhoto: ProjectPhoto?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: project.category, title: project.title)
                Text(project.scope).foregroundStyle(Brand.secondary)
                Label(project.location, systemImage: "mappin.and.ellipse").font(.subheadline)
                ForEach(project.photos) { photo in
                    VStack(alignment: .leading, spacing: 10) {
                        Button { selectedPhoto = photo } label: { PortfolioImage(photo: photo, height: 240) }
                            .buttonStyle(.plain).accessibilityLabel("View photo: \(photo.caption)")
                        Text(photo.caption).font(.subheadline).foregroundStyle(Brand.secondary)
                    }
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("Project inspiration").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                StudioIncludeIdeaButton(project: project).padding(20).frame(maxWidth: 760)
                    .frame(maxWidth: .infinity).background(Brand.paper)
            }
            .fullScreenCover(item: $selectedPhoto) { photo in
                PhotoGalleryView(photos: project.photos, initialPhoto: photo.id)
            }
    }
}

struct StudioField: View {
    let title: String
    @Binding var text: String
    var email = false
    var placeholder = "Optional"
    var body: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.xs) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Brand.ink)
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...6)
                .lineSpacing(3)
                .accessibilityLabel(title)
                .keyboardType(email ? .emailAddress : .default)
                .textInputAutocapitalization(email ? .never : .sentences)
                .autocorrectionDisabled(email)
        }
        .padding(.vertical, 5)
    }
}
struct StudioEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: PremiumLayout.sm) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Brand.bronze)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Brand.secondary)
                    .lineSpacing(3)
            }
        }
        .padding(.vertical, PremiumLayout.xs)
        .accessibilityElement(children: .combine)
    }
}

struct StudioThumbnail: View {
    let photo: StudioPhoto
    var expanded = false
    @EnvironmentObject private var studio: StudioStore
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image {
                if expanded { Image(uiImage: image).resizable().scaledToFit() }
                else { Image(uiImage: image).resizable().scaledToFill() }
            }
            else { Image(systemName: "photo").frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.line) }
        }.frame(width: expanded ? nil : 80, height: expanded ? 200 : 80)
            .frame(maxWidth: expanded ? .infinity : 80)
            .background(Brand.cream).clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityLabel(photo.purpose)
            .task(id: photo.filename) {
                let persistence = studio.persistence, name = photo.filename, thumbnail = photo.thumbnailFilename
                let useFullImage = expanded
                let bytes = await Task.detached(priority: .utility) { () -> Data? in
                    guard let full = try? persistence.photoURL(name), let small = try? persistence.photoURL(thumbnail) else { return nil }
                    if useFullImage { return try? Data(contentsOf: full) }
                    if let data = try? Data(contentsOf: small) { return data }
                    guard let original = try? Data(contentsOf: full) else { return nil }
                    return try? StudioImageProcessor.normalize(original).thumbnail
                }.value
                guard !Task.isCancelled else { return }
                image = bytes.flatMap(UIImage.init(data:))
            }
    }
}
