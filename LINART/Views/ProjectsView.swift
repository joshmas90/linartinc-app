import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var savedOnly = false

    private var filteredProjects: [PortfolioProject] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return (store.catalog?.projects ?? []).filter { project in
            (!savedOnly || store.favorites.contains(project.id)) &&
            (query.isEmpty || "\(project.title) \(project.category) \(project.scope)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "LINART portfolio", title: "Work worth a closer look.")
                Toggle("Show saved inspiration", isOn: $savedOnly).tint(Brand.bronze)
                if store.catalogUnavailable {
                    CatalogUnavailableView()
                } else if filteredProjects.isEmpty {
                    ContentUnavailableView("No projects found", systemImage: savedOnly ? "heart" : "magnifyingglass", description: Text(savedOnly ? "Save a project with the heart button to keep it here." : "Try searching for kitchens, bathrooms or outdoor living."))
                    Button("Show all projects") { search = ""; savedOnly = false }.buttonStyle(.bordered)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 290), spacing: 22)], spacing: 24) {
                        ForEach(filteredProjects) { project in
                            NavigationLink { ProjectDetailView(project: project) } label: { ProjectCard(project: project) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }.padding(24).frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Find your inspiration")
    }
}

struct ProjectDetailView: View {
    let project: PortfolioProject
    @EnvironmentObject private var store: AppStore
    @State private var selectedPhoto: ProjectPhoto?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: project.category, title: project.title)
                Label(project.location, systemImage: "mappin.and.ellipse").foregroundStyle(.secondary)
                Text(project.scope).lineSpacing(5)
                Eyebrow(title: project.stage)
                ForEach(project.photos) { photo in
                    Button { selectedPhoto = photo } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            PortfolioImage(photo: photo, height: 300).clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(photo.caption).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain).accessibilityHint("Opens full-screen photo gallery")
                }
                Button { store.startInquiry(service: project.service) } label: {
                    Label("Plan something like this", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
            }.padding(24).frame(maxWidth: 820).frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("Project details").navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { store.toggleFavorite(project.id) } label: {
                    Image(systemName: store.favorites.contains(project.id) ? "heart.fill" : "heart")
                }
                .accessibilityLabel(store.favorites.contains(project.id) ? "Remove saved project" : "Save project")
                ShareLink(item: Company.projects, subject: Text(project.title), message: Text("\(project.title) — LINART Construction"))
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoGalleryView(photos: project.photos, initialPhoto: photo.id)
        }
    }
}

struct PhotoGalleryView: View {
    let photos: [ProjectPhoto]
    @State private var selection: String
    @Environment(\.dismiss) private var dismiss

    init(photos: [ProjectPhoto], initialPhoto: String) {
        self.photos = photos
        _selection = State(initialValue: initialPhoto)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\((photos.firstIndex { $0.id == selection } ?? 0) + 1) of \(photos.count)").font(.subheadline)
                Spacer()
                Button("Done") { dismiss() }.font(.headline).padding(10)
            }.padding(.horizontal, 20)
            TabView(selection: $selection) {
                ForEach(photos) { photo in
                    VStack(spacing: 18) {
                        Image(photo.asset).resizable().scaledToFit().accessibilityLabel(photo.caption)
                        Text(photo.caption).font(.body).multilineTextAlignment(.center).padding(.horizontal, 24)
                        Spacer(minLength: 35)
                    }.tag(photo.id)
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
        }
        .padding(.top, 12).foregroundStyle(.white).background(Brand.ink).tint(Brand.gold)
    }
}
