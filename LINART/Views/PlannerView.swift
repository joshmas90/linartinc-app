import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore

    private var savedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { store.favorites.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "Your next chapter", title: "Make room for what’s next.")
                Text("Keep the ideas you love and prepare for a conversation about your home.")
                    .foregroundStyle(.secondary).lineSpacing(4)
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
                Text("Your checklist and saved projects stay on this device. Inquiry drafts stay in memory until you close the app or clear them.")
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
