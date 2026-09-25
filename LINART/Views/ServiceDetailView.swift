import SwiftUI

struct ServicesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PremiumLayout.md) {
                SectionHeading(eyebrow: "Build · Renovate · Improve", title: "Our Services")
                Text("From concept to completion, thoughtful craftsmanship for every part of your home.")
                    .foregroundStyle(Brand.secondary).lineSpacing(4)
                if let catalog = store.catalog {
                    ForEach(catalog.services) { service in
                        NavigationLink { ServiceDetailView(service: service) } label: {
                            HStack(spacing: PremiumLayout.sm) {
                                Image(service.photo.asset).resizable().scaledToFill()
                                    .frame(width: 78, height: 86).clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 9)).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(service.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Brand.ink)
                                    Text(service.summary)
                                        .font(.caption)
                                        .foregroundStyle(Brand.secondary)
                                        .lineSpacing(2)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.bronze)
                            }
                            .padding(14)
                            .background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
                            .shadow(color: .black.opacity(0.025), radius: 8, y: 4)
                        }.buttonStyle(.plain)
                    }
                } else { CatalogUnavailableView() }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
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
                VStack(alignment: .leading, spacing: PremiumLayout.lg) {
                    VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                        SectionHeading(eyebrow: "Residential expertise", title: service.title)
                        Text(service.introduction)
                            .foregroundStyle(Brand.secondary)
                            .lineSpacing(5)
                    }

                    VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                        Eyebrow(title: "What we coordinate")
                        ForEach(service.details, id: \.self) { detail in
                            Label {
                                Text(detail).foregroundStyle(Brand.ink)
                            } icon: {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Brand.bronze)
                                    .frame(width: 24, height: 24)
                                    .background(Brand.gold.opacity(0.22), in: Circle())
                            }
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    VStack(spacing: PremiumLayout.sm) {
                        Button("Request a Quote") { store.startInquiry(service: service.inquiryType) }
                            .buttonStyle(PrimaryButtonStyle())
                        if !relatedProjects.isEmpty {
                            NavigationLink {
                                RelatedProjectsView(title: service.title, projects: relatedProjects)
                            } label: { Text("View Related Projects") }
                                .buttonStyle(SecondaryButtonStyle())
                        }
                    }

                    VStack(alignment: .leading, spacing: PremiumLayout.md) {
                        Rectangle().fill(Brand.line).frame(height: 1)
                        Eyebrow(title: "Planning perspective")
                        Text("Considered from the start")
                            .font(.system(.title2, design: .serif))
                            .foregroundStyle(Brand.ink)
                        ForEach(service.priorities, id: \.self) { priority in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(priority[0]).font(.headline).foregroundStyle(Brand.ink)
                                Text(priority[1]).foregroundStyle(Brand.secondary).lineSpacing(4)
                            }
                        }
                        HStack(alignment: .top, spacing: PremiumLayout.sm) {
                            Rectangle().fill(Brand.brass).frame(width: 2)
                            Text(service.planning)
                                .font(.subheadline)
                                .foregroundStyle(Brand.ink)
                                .lineSpacing(4)
                                .padding(.leading, 2)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, PremiumLayout.tabBarClearance)
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
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle("Related Projects").navigationBarTitleDisplayMode(.inline)
    }
}
