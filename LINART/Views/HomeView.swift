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
                            Button("Explore all projects") { store.selectedTab = .projects }
                                .buttonStyle(SecondaryButtonStyle())
                            SectionHeading(eyebrow: "Made for your home", title: "One home. One standard.")
                                .padding(.top, 12)
                            Text("From a thoughtful renovation to a new beginning, discover what we can create together.")
                                .foregroundStyle(Brand.secondary).lineSpacing(4)
                            Button("Discover our services") { store.selectedTab = .services }
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
        VStack(alignment: .leading, spacing: 0) {
            BrandWordmark().frame(maxWidth: .infinity).padding(.vertical, 28)
            GeometryReader { bounds in
                Image("bath-main").resizable().scaledToFill()
                    .frame(width: bounds.size.width, height: bounds.size.height).clipped()
                    .accessibilityLabel("A LINART bathroom with a freestanding tub, black fixtures and geometric tile")
            }.frame(height: min(360, max(220, minHeight * 0.38)))
            VStack(alignment: .leading, spacing: 18) {
                Eyebrow(title: "Crafted around you")
                Text("Exceptional spaces.\nReal life.")
                    .font(.system(.largeTitle, design: .serif)).tracking(-0.6)
                    .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                Text("Custom construction and considered renovations across New Jersey.")
                    .foregroundStyle(Brand.secondary).lineSpacing(4)
                Button { store.selectedTab = .projects } label: {
                    HStack { Text("Explore our work"); Spacer(); Image(systemName: "arrow.right") }
                }.buttonStyle(PrimaryButtonStyle())
                Button("Plan your project") { store.selectedTab = .studio }.buttonStyle(SecondaryButtonStyle())
            }.padding(28).frame(maxWidth: 760, alignment: .leading).frame(maxWidth: .infinity)
        }.background(Brand.cream)
    }
}
