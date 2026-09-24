import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @ScaledMetric(relativeTo: .largeTitle) private var heroType: CGFloat = 46

    var body: some View {
        GeometryReader { viewport in
            ScrollView {
                VStack(spacing: 0) {
                    hero(minHeight: viewport.size.height)
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Label("Family-owned", systemImage: "person.2")
                            Spacer()
                            Text("Since 2004")
                        }.font(.subheadline).foregroundStyle(Brand.bronze)
                        SectionHeading(eyebrow: "Selected work", title: "The details make the difference.")
                        if let catalog = store.catalog {
                            ForEach(Array(catalog.projects.prefix(3))) { project in
                                NavigationLink { ProjectDetailView(project: project) } label: {
                                    ProjectCard(project: project)
                                }.buttonStyle(.plain)
                            }
                            Button("Explore all projects") { store.selectedTab = 1 }
                                .buttonStyle(SecondaryButtonStyle())
                            SectionHeading(eyebrow: "Made for your home", title: "One home. One standard.")
                                .padding(.top, 12)
                            Text("From a thoughtful renovation to a new beginning, discover what we can create together.")
                                .foregroundStyle(Brand.secondary).lineSpacing(4)
                            Button("Discover our services") { store.selectedTab = 4 }
                                .buttonStyle(PrimaryButtonStyle())
                        } else {
                            CatalogUnavailableView()
                        }
                        ContactActions()
                    }.padding(24).padding(.vertical, 12).frame(maxWidth: 760)
                }.frame(maxWidth: .infinity)
            }
            .background(Brand.cream)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func hero(minHeight: CGFloat) -> some View {
        // Only the photograph fills/crops. All words and actions participate in native layout.
        VStack(alignment: .leading, spacing: 24) {
            BrandWordmark(light: true)
                .frame(maxWidth: .infinity).padding(.top, 16)
            Spacer(minLength: 100)
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow(title: "A higher standard. A better home.", light: true)
                Text("Exceptional Spaces for Real Life")
                    .font(.system(size: heroType, weight: .regular, design: .serif))
                    .tracking(-0.8).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text("Custom construction and renovations across New Jersey.")
                    .font(.body).foregroundStyle(.white.opacity(0.92)).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                Button { store.selectedTab = 1 } label: {
                    HStack { Text("View Our Work"); Spacer(); Image(systemName: "arrow.right") }
                }.buttonStyle(PrimaryButtonStyle(light: true)).padding(.top, 4)
            }
            .frame(maxWidth: 560, alignment: .leading)
        }
        .padding(.horizontal, 28).padding(.bottom, 32)
        .frame(maxWidth: .infinity, minHeight: max(540, minHeight), alignment: .leading)
        .background {
            GeometryReader { bounds in
                Image("kitchen-remodeling")
                    .resizable().scaledToFill()
                    .frame(width: bounds.size.width, height: bounds.size.height)
                    .clipped().accessibilityHidden(true)
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.78), location: 0),
                    .init(color: .black.opacity(0.10), location: 0.30),
                    .init(color: .black.opacity(0.50), location: 0.53),
                    .init(color: .black.opacity(0.94), location: 1)
                ], startPoint: .top, endPoint: .bottom)
            }
        }
    }
}
