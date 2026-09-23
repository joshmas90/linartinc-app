import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                BrandHeader()
                PortfolioImage(photo: ProjectPhoto(asset: "home-hero", caption: "LINART website's architectural bathroom hero"), height: 300)
                VStack(alignment: .leading, spacing: 18) {
                    Eyebrow(title: "Residential construction, elevated.", light: true)
                    Text("Considered spaces.\nLasting craftsmanship.")
                        .font(.system(.largeTitle, design: .serif)).foregroundStyle(.white)
                    Text("Custom homes, renovations and outdoor living, built with care throughout New Jersey.")
                        .foregroundStyle(.white.opacity(0.85)).lineSpacing(4)
                    Button { store.startInquiry() } label: {
                        Label("Discuss your project", systemImage: "arrow.up.right")
                    }.buttonStyle(PrimaryButtonStyle(light: true))
                }
                .padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Brand.ink)

                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Label("Family-owned", systemImage: "person.2")
                        Spacer()
                        Text("Since 2004")
                    }.font(.subheadline).foregroundStyle(Brand.bronze)
                    SectionHeading(eyebrow: "Selected work", title: "The details make the difference.")
                    if let catalog = store.catalog {
                        ForEach(Array(catalog.projects.prefix(3))) { project in
                            NavigationLink { ProjectDetailView(project: project) } label: { ProjectCard(project: project) }
                                .buttonStyle(.plain)
                        }
                        Button("View all projects") { store.selectedTab = 1 }
                            .buttonStyle(PrimaryButtonStyle())
                        SectionHeading(eyebrow: "What we do", title: "One home. One standard.").padding(.top, 12)
                        ForEach(catalog.services) { service in
                            NavigationLink { ServiceDetailView(service: service) } label: {
                                HStack(alignment: .top, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(service.title).font(.headline).foregroundStyle(Brand.ink)
                                        Text(service.summary).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "arrow.up.right").foregroundStyle(Brand.bronze)
                                }.padding(.vertical, 12)
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    } else {
                        CatalogUnavailableView()
                    }
                    ContactActions()
                }.padding(24).frame(maxWidth: 760)
            }
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .toolbar(.hidden, for: .navigationBar)
    }
}
