import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var studio: StudioStore
    @State private var checklistExpanded = false
    private var savedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { store.favorites.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "A thoughtful beginning", title: "My Project")
                StudioStatusView()
                NavigationLink { ProjectStudioView() } label: {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("YOUR PRIVATE STUDIO", systemImage: "square.and.pencil")
                            .font(.caption.weight(.semibold)).tracking(1.4).foregroundStyle(Brand.bronze)
                        Text(studio.draft.displayTitle).font(.system(.title, design: .serif))
                        Text(studio.draft.goals.isEmpty ? "Make room for your ideas. Bring photos, priorities and plans together in one place." : studio.draft.goals)
                            .foregroundStyle(Brand.secondary).lineLimit(3)
                        Text("\(studio.draft.photos.count) photos · \(studio.draft.ideas.count) saved ideas").font(.caption)
                        HStack { Text(studio.draft.isEmpty ? "Begin your project" : "Continue planning"); Spacer(); Image(systemName: "arrow.right") }
                            .font(.headline).foregroundStyle(Brand.bronze).frame(minHeight: 44)
                    }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))
                        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Brand.line))
                }.buttonStyle(.plain).disabled(!studio.isReady).accessibilityIdentifier("openStudio")
                Text(studio.saveLabel).font(.caption).foregroundStyle(Brand.secondary)
                NavigationLink { CloudStudioView() } label: {
                    Label("Send to LINART & account", systemImage: "paperplane").frame(maxWidth: .infinity, minHeight: 44)
                }.buttonStyle(SecondaryButtonStyle())
                SectionHeading(eyebrow: "Collected with care", title: "Saved inspiration")
                if savedProjects.isEmpty {
                    Text("Save a project from the portfolio to keep the details you love close at hand.").foregroundStyle(Brand.secondary)
                    Button("Explore projects") { store.selectedTab = .projects }.buttonStyle(SecondaryButtonStyle())
                }
                ForEach(savedProjects) { project in
                    VStack(alignment: .leading, spacing: 12) {
                        NavigationLink { ProjectDetailView(project: project) } label: { ProjectCard(project: project) }.buttonStyle(.plain)
                        Button(studio.draft.ideas.contains(where: { $0.id == project.id }) ? "Included in your brief" : "Include in my brief", systemImage: "text.badge.plus") { studio.include(project) }
                            .disabled(!studio.isReady || studio.draft.ideas.contains(where: { $0.id == project.id })).frame(minHeight: 44)
                    }
                }
                DisclosureGroup("Before we talk", isExpanded: $checklistExpanded) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(AppStore.planningSteps, id: \.self) { step in
                            Button { store.toggleStep(step) } label: {
                                Label(step, systemImage: store.completedSteps.contains(step) ? "checkmark.square.fill" : "square")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).multilineTextAlignment(.leading)
                            }.buttonStyle(.plain).accessibilityValue(store.completedSteps.contains(step) ? "Completed" : "Not completed")
                        }
                    }.padding(.top, 16)
                }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
                Button("Start a project inquiry") { store.startInquiry() }.buttonStyle(SecondaryButtonStyle())
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("My Project").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $store.studioRequested) { ProjectStudioView() }
    }
}

struct StudioStatusView: View {
    @EnvironmentObject private var studio: StudioStore
    var body: some View {
        switch studio.state {
        case .loading, .clearing: ProgressView(studio.state == .loading ? "Opening your Studio…" : "Removing local files…")
        case .unavailable(let message):
            VStack(alignment: .leading, spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle")
                Button("Try opening again") { Task { await studio.load() } }
                Button("Recover previous saved copy") { Task { await studio.recover() } }
            }.padding().background(Brand.gold.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        case .ready:
            if let notice = studio.notice { Label(notice, systemImage: "info.circle").font(.footnote).foregroundStyle(Brand.secondary) }
        }
    }
}

enum StudioSection: String, CaseIterable, Identifiable {
    case photos = "Photos & inspiration", details = "The spaces you imagine", timing = "Investment & timing", links = "Links & saved ideas", review = "Review & share"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .photos: "photo.on.rectangle"; case .details: "text.alignleft"; case .timing: "calendar"; case .links: "link"; case .review: "doc.text.magnifyingglass" }
    }
    var subtitle: String {
        switch self {
        case .photos: "Your space, inspiration and drawings"
        case .details: "Goals, priorities and considered details"
        case .timing: "Your expectations, at your pace"
        case .links: "Keep the details that speak to you"
        case .review: "Create a project book or a concise summary"
        }
    }
}

struct ProjectStudioView: View {
    @EnvironmentObject private var studio: StudioStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(eyebrow: "A considered beginning", title: studio.draft.displayTitle)
                Text("A place to gather what matters. Every question is optional; your progress stays on this device until you choose to share it.").foregroundStyle(Brand.secondary).lineSpacing(4)
                StudioStatusView()
                ForEach(StudioSection.allCases) { section in
                    NavigationLink {
                        if section == .review { StudioReviewView() } else { StudioEditorView(section: section) }
                    } label: { MenuRow(title: section.rawValue, subtitle: section.subtitle, symbol: section.symbol) }
                        .buttonStyle(.plain).disabled(!studio.isReady).accessibilityIdentifier("studio-\(section.id)")
                }
                Text(studio.saveLabel).font(.caption).foregroundStyle(Brand.secondary)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("Project Studio").navigationBarTitleDisplayMode(.inline)
    }
}
