import SwiftUI
import UIKit

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var studio: StudioStore
    @State private var stepsExpanded = false
    @State private var inspirationExpanded = false
    @State private var checklistExpanded = false

    private var savedProjects: [PortfolioProject] {
        (store.catalog?.projects ?? []).filter { store.favorites.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PremiumLayout.lg) {
                VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                    SectionHeading(eyebrow: "A thoughtful beginning", title: "My Project")
                    Text("A private place to shape the conversation before the first meeting.")
                        .foregroundStyle(Brand.secondary)
                        .lineSpacing(3)
                }

                StudioStatusView()
                planningCard
                projectPath
                savedIdeas
                preparationChecklist

                VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                    Divider().overlay(Brand.line)
                    Eyebrow(title: "Start a conversation")
                    Text("Prefer to talk first?").font(.system(.title3, design: .serif)).foregroundStyle(Brand.ink)
                    Text("Send a short inquiry now and return to your private project brief whenever you are ready.")
                        .font(.subheadline).foregroundStyle(Brand.secondary).lineSpacing(3)
                    Button("Start a project inquiry") { store.startInquiry() }.buttonStyle(SecondaryButtonStyle())
                }

                NavigationLink { CloudStudioView() } label: {
                    MenuRow(title: "Sent briefs & account", subtitle: "Your submissions and sign-in settings", symbol: "person.crop.circle")
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, PremiumLayout.tabBarClearance)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .navigationTitle("My Project")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $store.studioRequested) { ProjectStudioView() }
    }

    private var planningCard: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.md) {
            VStack(alignment: .leading, spacing: PremiumLayout.xs) {
                Eyebrow(title: studio.draft.hasProjectContent ? "Current project" : "Private project plan")
                Text(studio.draft.hasProjectContent ? studio.draft.displayTitle : "Let's start with your space.")
                    .font(.system(.title, design: .serif))
                    .foregroundStyle(Brand.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(projectStatus)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.ink)
                Text("Details, photos, inspiration and timing come together here. Every question is optional.")
                    .foregroundStyle(Brand.secondary)
                    .lineSpacing(3)
            }

            VStack(alignment: .leading, spacing: PremiumLayout.xs) {
                HStack {
                    Text("STEP \(studio.currentSection.number) OF 5")
                    Spacer()
                    Text("\(completedPlanningSections) OF 4 SECTIONS SHAPED")
                }
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Brand.secondary)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Brand.line).frame(height: 3)
                        Capsule().fill(Brand.brass)
                            .frame(width: proxy.size.width * CGFloat(max(completedPlanningSections, studio.draft.hasProjectContent ? 1 : 0)) / 4, height: 3)
                    }
                }
                .frame(height: 3)
                .accessibilityHidden(true)

                Label(studio.currentSection.title, systemImage: studio.currentSection.symbol)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Brand.bronze)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { open(studio.currentSection) } label: {
                HStack {
                    Text(studio.currentSection == .details && !studio.draft.hasProjectContent ? "Start planning" : studio.currentSection == .review ? "Review project" : "Continue planning")
                    Spacer(minLength: 12)
                    Image(systemName: "arrow.right").accessibilityHidden(true)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!studio.isReady)
            .accessibilityIdentifier("openStudio")

            if studio.draft.hasProjectContent {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { stepsExpanded = true }
                } label: {
                    Text("View project overview")
                }
                .buttonStyle(TertiaryButtonStyle())
            }

            Divider().overlay(Brand.line)

            Text(studio.draft.contentSummary)
                .font(.subheadline)
                .foregroundStyle(Brand.secondary)
                .accessibilityIdentifier("studioContentSummary")
            HStack(alignment: .firstTextBaseline, spacing: PremiumLayout.xs) {
                Image(systemName: "lock").font(.caption2).foregroundStyle(Brand.bronze).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(studio.saveLabel).font(.caption).foregroundStyle(Brand.secondary)
                    Text("Private on this device until you choose to share.")
                        .font(.caption).foregroundStyle(Brand.secondary)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Brand.line))
        .shadow(color: .black.opacity(0.035), radius: 18, y: 8)
    }

    private var projectPath: some View {
        DisclosureGroup(isExpanded: $stepsExpanded) {
            VStack(spacing: 4) {
                ForEach(StudioSection.allCases) { section in
                    Button { open(section) } label: {
                        StudioStepRow(section: section, current: studio.currentSection, draft: studio.draft)
                    }
                    .buttonStyle(.plain)
                    .disabled(!studio.isReady)
                    .accessibilityIdentifier("openStep-\(section.id)")
                }
            }
            .padding(.top, PremiumLayout.sm)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your project path").font(.headline).foregroundStyle(Brand.ink)
                Text("\(completedPlanningSections) of 4 planning sections shaped · review is always available")
                    .font(.caption).foregroundStyle(Brand.secondary)
            }
        }
        .tint(Brand.bronze)
        .padding(PremiumLayout.md)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }

    private var savedIdeas: some View {
        DisclosureGroup(isExpanded: $inspirationExpanded) {
            VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                if savedProjects.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No inspiration saved yet").font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                        Text("Browse completed LINART projects when you're ready. Saved favorites can become part of your project brief.")
                            .font(.subheadline).foregroundStyle(Brand.secondary)
                    }
                }
                ForEach(savedProjects) { project in
                    NavigationLink { ProjectDetailView(project: project) } label: {
                        MenuRow(title: project.title, subtitle: "View this project", symbol: "heart")
                    }.buttonStyle(.plain)
                }
                Button("Browse LINART projects") { store.selectedTab = .projects }
                    .buttonStyle(SecondaryButtonStyle())
            }.padding(.top, PremiumLayout.sm)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Saved portfolio ideas").font(.headline).foregroundStyle(Brand.ink)
                Text(savedProjects.isEmpty ? "A quiet place for future inspiration" : "\(savedProjects.count) saved \(savedProjects.count == 1 ? "project" : "projects")")
                    .font(.caption).foregroundStyle(Brand.secondary)
            }
        }
        .tint(Brand.bronze)
        .padding(PremiumLayout.md)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }

    private var preparationChecklist: some View {
        DisclosureGroup(isExpanded: $checklistExpanded) {
            VStack(alignment: .leading, spacing: PremiumLayout.xs) {
                ForEach(AppStore.planningSteps, id: \.self) { step in
                    Button { store.toggleStep(step) } label: {
                        Label(step, systemImage: store.completedSteps.contains(step) ? "checkmark.circle.fill" : "circle")
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .multilineTextAlignment(.leading)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(store.completedSteps.contains(step) ? Brand.ink : Brand.secondary)
                    .accessibilityValue(store.completedSteps.contains(step) ? "Completed" : "Not completed")
                }
            }.padding(.top, PremiumLayout.sm)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Before we talk").font(.headline).foregroundStyle(Brand.ink)
                Text("A simple preparation checklist · completely optional")
                    .font(.caption).foregroundStyle(Brand.secondary)
            }
        }
        .tint(Brand.bronze)
        .padding(PremiumLayout.md)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }

    private var completedPlanningSections: Int {
        StudioSection.allCases.filter { $0 != .review && $0.hasContent(in: studio.draft) }.count
    }

    private var projectStatus: String {
        guard studio.draft.hasProjectContent else { return "Ready when you are." }
        if studio.currentSection == .review { return "Your project brief is ready to review." }
        if completedPlanningSections >= 3 { return "Your project is taking shape." }
        if StudioSection.details.hasContent(in: studio.draft) { return "Your project foundation is saved." }
        return "Your project has been started."
    }

    private func open(_ section: StudioSection) {
        studio.move(to: section)
        store.studioRequested = true
    }
}

struct StudioStatusView: View {
    @EnvironmentObject private var studio: StudioStore
    var body: some View {
        switch studio.state {
        case .loading, .clearing:
            ProgressView(studio.state == .loading ? "Opening your project…" : "Removing local files…")
        case .unavailable(let message):
            VStack(alignment: .leading, spacing: 12) {
                Label(message, systemImage: "exclamationmark.triangle")
                Button("Try opening again") { Task { await studio.load() } }
                Button("Recover previous saved copy") { Task { await studio.recover() } }
            }.padding().background(Brand.gold.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        case .ready:
            if let notice = studio.notice {
                Label(notice, systemImage: "info.circle").font(.footnote).foregroundStyle(Brand.secondary)
            }
        }
    }
}

struct StudioStepRow: View {
    let section: StudioSection
    let current: StudioSection
    let draft: StudioDraft

    private var hasContent: Bool { section.hasContent(in: draft) }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(section == current ? Brand.ink : hasContent ? Brand.gold.opacity(0.34) : Brand.cream)
                    .overlay(Circle().strokeBorder(section == current ? Brand.brass.opacity(0.7) : Brand.line))
                if hasContent && section != current {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Brand.bronze)
                } else {
                    Text("\(section.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(section == current ? Brand.paper : Brand.secondary)
                }
            }
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.subheadline.weight(section == current ? .semibold : .medium))
                    .foregroundStyle(Brand.ink)
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(Brand.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(section == current ? Brand.bronze : Brand.secondary.opacity(0.55))
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, section == current ? 12 : 0)
        .padding(.vertical, 7)
        .background(section == current ? Brand.gold.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 10))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(section.number). \(section.title)")
        .accessibilityValue(section == current ? "Current step" : hasContent ? "Details added" : "Optional")
    }

    private var statusText: String {
        if section == current { return section == .review ? "Your brief is ready here" : "Continue here" }
        if section == .review { return draft.hasProjectContent ? "Review your brief when you're ready" : "Your final review" }
        guard hasContent else { return "Optional · add now or later" }
        switch section {
        case .details: return "Project foundation saved"
        case .photos: return "Selected photos saved"
        case .links: return "Inspiration saved"
        case .timing: return "Planning horizon noted"
        case .review: return "Review your brief"
        }
    }
}

struct StudioStepHeader: View {
    @EnvironmentObject private var studio: StudioStore
    let section: StudioSection
    @AccessibilityFocusState private var headerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(title: "Step \(section.number) of \(StudioSection.allCases.count)")
            HStack(spacing: 8) {
                ForEach(StudioSection.allCases) { step in
                    Capsule()
                        .fill(step == section ? Brand.ink : step.hasContent(in: studio.draft) ? Brand.brass.opacity(0.58) : Brand.line)
                        .frame(height: step == section ? 5 : 3)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: section)
            .accessibilityHidden(true)
            Text(studio.draft.contentSummary).font(.caption).foregroundStyle(Brand.secondary)
            Text(section.title).font(.system(.title, design: .serif)).foregroundStyle(Brand.ink)
                .accessibilityAddTraits(.isHeader)
            Text(section.subtitle).foregroundStyle(Brand.secondary)
            if section != .review {
                Text("Optional · skip anything you are unsure about.").font(.caption).foregroundStyle(Brand.secondary)
            }
        }.fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            .accessibilityFocused($headerFocused)
            .accessibilityIdentifier("studioStepHeader")
            .task(id: section) {
                do { try await Task.sleep(for: .milliseconds(200)) } catch { return }
                headerFocused = true
            }
    }
}

struct ProjectStudioView: View {
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showSteps = false
    @State private var confirmClear = false
    @State private var editingFromReview = false
    @State private var keyboardVisible = false
    @State private var closing = false

    var body: some View {
        Group {
            if studio.currentSection == .review {
                StudioReviewView(onEdit: { section in
                    editingFromReview = true
                    navigate(to: section)
                }, onSaveAndClose: saveAndClose)
            } else {
                StudioEditorView(section: studio.currentSection)
            }
        }
        .id(studio.currentSection)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
        .animation(.easeInOut(duration: 0.22), value: studio.currentSection)
            .background(Brand.cream)
            .navigationTitle("My Project").navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !keyboardVisible { navigationFooter }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Steps", systemImage: "list.number") { showSteps = true }
                        .accessibilityIdentifier("studioSteps").disabled(!studio.isReady)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Save & close", systemImage: "square.and.arrow.down") { saveAndClose() }
                        Button("Save now", systemImage: "arrow.clockwise") { Task { await studio.flush() } }
                        Divider()
                        Button("Clear this project", role: .destructive) { confirmClear = true }
                    } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("Project options").disabled(!studio.isReady || closing)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { dismissKeyboard() }
                }
            }
            .sheet(isPresented: $showSteps) {
                NavigationStack {
                    List {
                        Section {
                            Text("Go to any step. Your answers stay in the same draft.")
                                .foregroundStyle(Brand.secondary)
                        }
                        ForEach(StudioSection.allCases) { section in
                            Button {
                                editingFromReview = false
                                navigate(to: section)
                                showSteps = false
                            } label: {
                                StudioStepRow(section: section, current: studio.currentSection, draft: studio.draft)
                            }.buttonStyle(.plain).accessibilityIdentifier("studio-\(section.id)")
                        }
                    }.navigationTitle("Your project steps").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showSteps = false } } }
                }.tint(Brand.bronze)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
            .onDisappear { Task { await studio.flush() } }
            .confirmationDialog("Clear this project from your device?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Remove all photos and answers", role: .destructive) {
                    Task {
                        do { try await studio.clear(); editingFromReview = false }
                        catch { /* The store shows the failure and preserves the navigation state. */ }
                    }
                }
            } message: { Text("This removes your local photos, notes and prepared PDFs. Anything already shared stays with its recipient.") }
    }

    private var navigationFooter: some View {
        VStack(spacing: 10) {
            if studio.hasUnsavedChanges && !studio.isSaving {
                Button("Changes not saved · try Save now") { Task { await studio.flush() } }
                    .font(.caption).frame(minHeight: 44)
            } else {
                Text(studio.isImporting ? "Adding your photos…" : studio.saveLabel)
                    .font(.caption).foregroundStyle(Brand.secondary)
            }
            if typeSize.isAccessibilitySize {
                VStack(spacing: 8) { forwardButton; backButton }
            } else {
                HStack(spacing: 12) { backButton; forwardButton }
            }
            if studio.currentSection != .review && !editingFromReview && !studio.currentSection.hasContent(in: studio.draft) {
                Button("Skip for now") { advance() }
                    .buttonStyle(TertiaryButtonStyle())
                    .accessibilityIdentifier("studioSkip")
                    .disabled(!studio.isReady || closing)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Rectangle().fill(Brand.line).frame(height: 1) }
    }

    @ViewBuilder private var backButton: some View {
        if !editingFromReview {
            Button {
                if let previous = studio.currentSection.previous { navigate(to: previous) }
                else { saveAndClose() }
            } label: {
                Label(studio.currentSection.previous == nil ? "Close" : "Back", systemImage: "chevron.left")
            }.buttonStyle(SecondaryButtonStyle()).accessibilityIdentifier("studioBack")
                .disabled(!studio.isReady || closing)
        }
    }

    @ViewBuilder private var forwardButton: some View {
        if studio.currentSection == .review {
            NavigationLink { ProjectSendView() } label: {
                Text("Verify & send").fixedSize(horizontal: false, vertical: true)
            }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("studioSend")
                .accessibilityHint("Verify your email and confirm before sending")
                .disabled(!studio.isReady || studio.isImporting || !studio.draft.hasProjectContent || closing)
        } else {
            Button { advance() } label: {
                Text(closing ? "Saving…" : editingFromReview ? "Return to review" : studio.currentSection.next == .review ? "Review project" : "Continue")
                    .fixedSize(horizontal: false, vertical: true)
            }.buttonStyle(PrimaryButtonStyle()).accessibilityIdentifier("studioContinue")
                .accessibilityHint(editingFromReview ? "Return to your updated brief" : studio.currentSection.next.map { "Next: \($0.title)" } ?? "Review your project")
                .disabled(!studio.isReady || closing)
        }
    }

    private func advance() {
        if editingFromReview {
            editingFromReview = false
            navigate(to: .review)
        } else if let next = studio.currentSection.next {
            navigate(to: next)
        } else {
            saveAndClose()
        }
    }

    private func navigate(to section: StudioSection) {
        dismissKeyboard()
        studio.move(to: section)
        Task { await studio.flush() }
    }

    private func saveAndClose() {
        guard !closing else { return }
        dismissKeyboard()
        closing = true
        Task {
            await studio.flush()
            closing = false
            // Keep a failed save visible instead of claiming it was saved on exit.
            if !studio.hasUnsavedChanges { dismiss() }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
