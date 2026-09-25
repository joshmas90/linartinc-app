import SwiftUI
import UIKit

struct ProjectsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var savedOnly = false
    @State private var category = "All"
    private let categories = ["All", "Kitchens", "Bathrooms", "Additions", "Outdoor Living"]

    private func matchesCategory(_ project: PortfolioProject) -> Bool {
        switch category {
        case "Kitchens": return project.service == "Kitchen Remodeling"
        case "Bathrooms": return project.service == "Bathroom Remodeling"
        case "Additions": return project.service == "Home Addition"
        case "Outdoor Living": return ["Deck / Patio Construction", "Other Residential Work"].contains(project.service)
        default: return true
        }
    }

    private var filteredProjects: [PortfolioProject] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return (store.catalog?.projects ?? []).filter { project in
            matchesCategory(project) && (!savedOnly || store.favorites.contains(project.id)) &&
            (query.isEmpty || "\(project.title) \(project.category) \(project.scope)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "LINART portfolio", title: "Our Work")
                Text("Explore real projects. Find inspiration for what’s possible.")
                    .foregroundStyle(Brand.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { item in
                            Button { category = item } label: {
                                Text(item).font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 17).frame(minHeight: 44)
                                    .foregroundStyle(category == item ? .white : Brand.ink)
                                    .background(category == item ? Brand.ink : Brand.paper, in: Capsule())
                                    .overlay(Capsule().strokeBorder(category == item ? Brand.brass.opacity(0.5) : Brand.line))
                            }.buttonStyle(.plain)
                                .accessibilityAddTraits(category == item ? [.isSelected] : [])
                        }
                    }
                }
                Toggle("Show saved inspiration", isOn: $savedOnly).tint(Brand.bronze)
                if store.catalogUnavailable {
                    CatalogUnavailableView()
                } else if filteredProjects.isEmpty {
                    ContentUnavailableView("No projects found", systemImage: savedOnly ? "heart" : "magnifyingglass", description: Text(savedOnly ? "Save a project with the heart button to keep it here." : "Try searching for kitchens, bathrooms or outdoor living."))
                    Button("Show all projects") { search = ""; savedOnly = false; category = "All" }.buttonStyle(.bordered)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 22)], spacing: 24) {
                        ForEach(filteredProjects) { project in
                            NavigationLink { ProjectDetailView(project: project) } label: { ProjectCard(project: project) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 1100)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("Projects")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Find your inspiration")
    }
}

struct ProjectDetailView: View {
    let project: PortfolioProject
    @EnvironmentObject private var store: AppStore
    @State private var selectedPhoto: ProjectPhoto?
    @State private var photoIndex = 0
    @State private var sharing = false
    @EnvironmentObject private var studio: StudioStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                TabView(selection: $photoIndex) {
                    ForEach(Array(project.photos.enumerated()), id: \.element.id) { index, photo in
                        Button { selectedPhoto = photo } label: {
                            PortfolioImage(photo: photo, height: 310)
                        }.buttonStyle(.plain).tag(index)
                            .accessibilityHint("Opens full-screen photo gallery")
                    }
                }
                .frame(height: 310).tabViewStyle(.page(indexDisplayMode: .never))
                HStack(spacing: 6) {
                    ForEach(project.photos.indices, id: \.self) { index in
                        Capsule().fill(index == photoIndex ? Brand.bronze : Brand.line)
                            .frame(width: index == photoIndex ? 18 : 5, height: 5)
                    }
                    Text("\(photoIndex + 1) / \(project.photos.count)")
                        .font(.caption2).foregroundStyle(Brand.secondary).padding(.leading, 6)
                }.padding(.top, 14).accessibilityElement(children: .ignore)
                    .accessibilityLabel("Photo \(photoIndex + 1) of \(project.photos.count)")
                VStack(alignment: .leading, spacing: PremiumLayout.lg) {
                    VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                        SectionHeading(eyebrow: project.category, title: project.title)
                        Text(project.scope)
                            .foregroundStyle(Brand.secondary)
                            .lineSpacing(5)
                    }

                    projectFacts

                    if project.photos.indices.contains(photoIndex) {
                        VStack(alignment: .leading, spacing: 6) {
                            Eyebrow(title: "Current view")
                            Text(project.photos[photoIndex].caption)
                                .font(.subheadline)
                                .foregroundStyle(Brand.secondary)
                                .lineSpacing(3)
                        }
                    }

                    VStack(spacing: PremiumLayout.sm) {
                        Button { store.toggleFavorite(project.id) } label: {
                            Label(store.favorites.contains(project.id) ? "Saved to My Project" : "Save to My Project",
                                  systemImage: store.favorites.contains(project.id) ? "heart.fill" : "heart")
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Discuss a Similar Project") { store.startInquiry(service: project.service) }
                            .buttonStyle(SecondaryButtonStyle())

                        Button("Include in my project brief", systemImage: "text.badge.plus") { studio.include(project) }
                            .buttonStyle(TertiaryButtonStyle())
                            .frame(maxWidth: .infinity)
                            .disabled(!studio.isReady || studio.draft.ideas.contains(where: { $0.id == project.id }))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, PremiumLayout.tabBarClearance)
            }.frame(maxWidth: 820).frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("Project Gallery").navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { store.toggleFavorite(project.id) } label: {
                    Image(systemName: store.favorites.contains(project.id) ? "heart.fill" : "heart")
                }
                .accessibilityLabel(store.favorites.contains(project.id) ? "Remove saved project" : "Save project")
                Button("Share this project", systemImage: "square.and.arrow.up") { sharing = true }
            }
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            PhotoGalleryView(photos: project.photos, initialPhoto: photo.id)
        }
        .sheet(isPresented: $sharing) {
            StudioShareSheet(items: shareItems) { sharing = false }
        }
    }
    private var projectFacts: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.sm) {
            Rectangle().fill(Brand.line).frame(height: 1)
            Eyebrow(title: "Project details")
            HStack(alignment: .top, spacing: PremiumLayout.lg) {
                ProjectFact(symbol: "mappin.and.ellipse", label: "Location", value: project.location)
                ProjectFact(symbol: "square.stack.3d.up", label: "Gallery", value: project.stage)
            }
            Rectangle().fill(Brand.line).frame(height: 1)
        }
    }

    private var shareItems: [Any] {
        var items: [Any] = ["\(project.title)\nLINART Construction · \(project.location)\n\n\(project.scope)\n\n\(Company.website.absoluteString)"]
        if let photo = project.photos.first, let image = UIImage(named: photo.asset) { items.append(image) }
        return items
    }
}

private struct ProjectFact: View {
    let symbol: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: PremiumLayout.xs) {
            Image(systemName: symbol)
                .font(.subheadline)
                .foregroundStyle(Brand.bronze)
                .frame(width: 18)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .tracking(0.8)
                    .foregroundStyle(Brand.secondary)
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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
                        ZoomablePhoto(asset: photo.asset, caption: photo.caption)
                        Text(photo.caption).font(.body).multilineTextAlignment(.center).padding(.horizontal, 24)
                        Spacer(minLength: 35)
                    }.tag(photo.id)
                }
            }.tabViewStyle(.page(indexDisplayMode: .always))
        }
        .padding(.top, 12).foregroundStyle(.white).background(Brand.ink).tint(Brand.gold)
    }
}
