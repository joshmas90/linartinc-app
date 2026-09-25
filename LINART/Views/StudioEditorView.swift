import SwiftUI
import PhotosUI

struct StudioEditorView: View {
    let section: StudioSection
    @EnvironmentObject private var studio: StudioStore
    @State private var selections: [PhotosPickerItem] = []
    @State private var purpose = "My space"
    @State private var filter = "All"
    @State private var newURL = ""
    @State private var newNote = ""
    @State private var confirmClear = false
    private let purposes = ["My space", "Inspiration", "Plans & drawings"]
    var body: some View {
        Form {
            Section { StudioStatusView(); Text(studio.saveLabel).font(.caption).foregroundStyle(Brand.secondary) }
            if section == .photos { photos }
            if section == .details {
                Section("A little context · optional") {
                    StudioField(title: "Your inquiry email", text: $studio.draft.inquiryEmail, email: true)
                    Picker("Project type", selection: $studio.draft.projectType) {
                        Text("Not decided").tag("")
                        ForEach(Inquiry.serviceOptions, id: \.self) { Text($0).tag($0) }
                    }
                    StudioField(title: "What would you like to create?", text: $studio.draft.goals)
                    StudioField(title: "What does the space look like today?", text: $studio.draft.existingConditions)
                }
                Section("Considered details · optional") {
                    StudioField(title: "Style, finishes or materials you like", text: $studio.draft.style)
                    StudioField(title: "What matters most to you?", text: $studio.draft.priorities)
                    StudioField(title: "Existing plans, constraints or site access", text: $studio.draft.constraints)
                    StudioField(title: "Anything else we should know?", text: $studio.draft.other)
                }
            }
            if section == .timing {
                Section("Looking ahead · optional") {
                    StudioField(title: "Investment range or budget considerations", text: $studio.draft.investment)
                    StudioField(title: "Ideal project timing", text: $studio.draft.timeline)
                }
            }
            if section == .links { references }
            Section {
                NavigationLink { StudioReviewView() } label: { Label("Review & share", systemImage: "doc.text.magnifyingglass") }
                Button("Save now", systemImage: "square.and.arrow.down") { Task { await studio.flush() } }
                Button("Clear my private Studio", role: .destructive) { confirmClear = true }
            }
        }.disabled(!studio.isReady)
            .scrollContentBackground(.hidden).background(Brand.cream).scrollDismissesKeyboard(.interactively)
            .navigationTitle(section.rawValue).navigationBarTitleDisplayMode(.inline)
            .onChange(of: selections) { _, items in
                guard !items.isEmpty else { return }
                studio.importPhotos(items, purpose: purpose); selections = []
            }
            .onDisappear { Task { await studio.flush() } }
            .confirmationDialog("Remove your saved Studio?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Remove all photos and answers", role: .destructive) { Task { do { try await studio.clear() } catch { /* Store displays the failure. */ } } }
            } message: { Text("Deletes this device’s Studio and prepared exports. Anything already shared remains with its recipient.") }
    }

    private var photos: some View {
        let pickerTitle = studio.isImporting ? "Adding photos…" : "Add photos"
        return Section {
            Picker("Photos you are adding", selection: $purpose) { ForEach(purposes, id: \.self) { Text($0).tag($0) } }.disabled(studio.isImporting)
            PhotosPicker(selection: $selections, maxSelectionCount: max(1, 8 - studio.draft.photos.count), matching: .images) {
                Label(pickerTitle, systemImage: "photo.badge.plus")
            }.disabled(studio.isImporting || studio.draft.photos.count >= 8)
            Text("Up to 8 photos, at 1,600 pixels or smaller. Imported copies stay in your Studio. Your originals are unchanged.").font(.caption).foregroundStyle(Brand.secondary)
            Picker("Show photos", selection: $filter) {
                Text("All").tag("All")
                ForEach(purposes, id: \.self) { Text($0).tag($0) }
            }
            ForEach($studio.draft.photos) { $photo in
                if filter == "All" || photo.purpose == filter {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            StudioThumbnail(photo: photo)
                            Picker("Purpose", selection: $photo.purpose) { ForEach(purposes, id: \.self) { Text($0).tag($0) } }
                            Button(role: .destructive) { Task { await studio.removePhoto(photo) } } label: {
                                Image(systemName: "trash").frame(minWidth: 44, minHeight: 44)
                            }.buttonStyle(.borderless).accessibilityLabel("Remove \(photo.purpose) photo")
                        }
                        StudioField(title: "What should LINART notice?", text: $photo.note)
                    }.padding(.vertical, 8)
                }
            }
        } header: { Text("Your photo library") }
    }

    private var references: some View {
        Group {
            Section("Inspiration links · optional") {
                TextField("Full web address", text: $newURL).keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                StudioField(title: "What appeals to you?", text: $newNote)
                Button("Add link", systemImage: "link.badge.plus") { addLink() }.disabled(studio.draft.references.count >= 10 || newURL.isEmpty)
                ForEach(studio.draft.references) { reference in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(reference.url).font(.footnote).textSelection(.enabled)
                        if !reference.note.isEmpty { Text(reference.note) }
                        Button("Remove link", role: .destructive) { studio.draft.references.removeAll { $0.id == reference.id } }
                    }
                }
            }
            Section("From the LINART portfolio") {
                if studio.draft.ideas.isEmpty { Text("Include a saved project from My Project, then add what you like about it here.").foregroundStyle(Brand.secondary) }
                ForEach($studio.draft.ideas) { $idea in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(idea.title).font(.headline)
                        StudioField(title: "The details you love", text: $idea.note)
                        Button("Remove from brief", role: .destructive) { studio.draft.ideas.removeAll { $0.id == idea.id } }
                    }
                }
            }
        }
    }
    private func addLink() {
        let raw = newURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URLComponents(string: raw), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
              let host = url.host, host.contains("."), url.user == nil, url.password == nil, raw.count <= 1000 else {
            studio.notice = "Enter a complete http or https web address without sign-in details."; return
        }
        studio.draft.references.append(StudioReference(url: raw, note: String(newNote.prefix(2000))))
        newURL = ""; newNote = ""; studio.notice = nil
    }
}

struct StudioField: View {
    let title: String
    @Binding var text: String
    var email = false
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.medium))
            TextField("Optional", text: $text, axis: .vertical).lineLimit(2...6).accessibilityLabel(title)
                .keyboardType(email ? .emailAddress : .default).textInputAutocapitalization(email ? .never : .sentences).autocorrectionDisabled(email)
        }.padding(.vertical, 4)
    }
}

struct StudioThumbnail: View {
    let photo: StudioPhoto
    @EnvironmentObject private var studio: StudioStore
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill() }
            else { Image(systemName: "photo").frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.line) }
        }.frame(width: 80, height: 80).clipShape(RoundedRectangle(cornerRadius: 10)).accessibilityLabel(photo.purpose)
            .task(id: photo.filename) {
                let persistence = studio.persistence, name = photo.filename, thumbnail = photo.thumbnailFilename
                let bytes = await Task.detached(priority: .utility) { () -> Data? in
                    guard let full = try? persistence.photoURL(name), let small = try? persistence.photoURL(thumbnail) else { return nil }
                    if let data = try? Data(contentsOf: small) { return data }
                    guard let original = try? Data(contentsOf: full) else { return nil }
                    return try? StudioImageProcessor.normalize(original).thumbnail
                }.value
                guard !Task.isCancelled else { return }
                image = bytes.flatMap(UIImage.init(data:))
            }
    }
}
