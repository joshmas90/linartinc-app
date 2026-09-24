import SwiftUI

struct ServicesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeading(eyebrow: "Build · Renovate · Improve", title: "Our Services")
                Text("From concept to completion, thoughtful craftsmanship for every part of your home.")
                    .foregroundStyle(Brand.secondary).lineSpacing(4)
                if let catalog = store.catalog {
                    ForEach(catalog.services) { service in
                        NavigationLink { ServiceDetailView(service: service) } label: {
                            HStack(spacing: 14) {
                                Image(service.photo.asset).resizable().scaledToFill()
                                    .frame(width: 72, height: 78).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 7)).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(service.title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                                    Text(service.summary).font(.caption).foregroundStyle(Brand.secondary)
                                }.fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(Brand.bronze)
                            }.padding(12)
                                .background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
                        }.buttonStyle(.plain)
                    }
                } else { CatalogUnavailableView() }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Services").navigationBarTitleDisplayMode(.inline)
    }
}

struct ServiceDetailView: View {
    let service: Service
    @EnvironmentObject private var store: AppStore

    private var relatedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { $0.service == service.inquiryType }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                PortfolioImage(photo: service.photo, height: 290)
                VStack(alignment: .leading, spacing: 22) {
                    SectionHeading(eyebrow: "Residential expertise", title: service.title)
                    Text(service.introduction).foregroundStyle(Brand.secondary).lineSpacing(5)
                    ForEach(service.details, id: \.self) { detail in
                        Label {
                            Text(detail).foregroundStyle(Brand.ink)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.brass)
                        }.fixedSize(horizontal: false, vertical: true)
                    }
                    Button("Request a Quote") { store.startInquiry(service: service.inquiryType) }
                        .buttonStyle(PrimaryButtonStyle())
                    if !relatedProjects.isEmpty {
                        NavigationLink {
                            RelatedProjectsView(title: service.title, projects: relatedProjects)
                        } label: { Text("View Related Projects") }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    Divider().padding(.vertical, 6)
                    Text("Considered from the start").font(.system(.title2, design: .serif))
                    ForEach(service.priorities, id: \.self) { priority in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(priority[0]).font(.headline)
                            Text(priority[1]).foregroundStyle(Brand.secondary).lineSpacing(4)
                        }
                    }
                    Text(service.planning).font(.subheadline).lineSpacing(4).padding(20)
                        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
                }.padding(24)
            }.frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Service Details").navigationBarTitleDisplayMode(.inline)
            .toolbar(.visible, for: .navigationBar)
    }
}

struct RelatedProjectsView: View {
    let title: String
    let projects: [PortfolioProject]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeading(eyebrow: "Related projects", title: title)
                ForEach(projects) { project in
                    NavigationLink { ProjectDetailView(project: project) } label: {
                        ProjectCard(project: project)
                    }.buttonStyle(.plain)
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Related Projects").navigationBarTitleDisplayMode(.inline)
    }
}
