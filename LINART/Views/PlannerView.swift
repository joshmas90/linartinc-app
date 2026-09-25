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
            VStack(alignment: .leading, spacing: 24) {
                SectionHeading(eyebrow: "A thoughtful beginning", title: "My Project")
                Text("Bring your plans together, one simple step at a time.")
                    .foregroundStyle(Brand.secondary)
                StudioStatusView()
                planningCard
                DisclosureGroup("View all 5 steps", isExpanded: $stepsExpanded) {
                    VStack(spacing: 10) {
                        ForEach(StudioSection.allCases) { section in
                            Button { open(section) } label: {
                                StudioStepRow(section: section, current: studio.currentSection, draft: studio.draft)
                            }.buttonStyle(.plain).disabled(!studio.isReady)
                                .accessibilityIdentifier("openStep-\(section.id)")
                        }
                    }.padding(.top, 14)
                }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))

                DisclosureGroup("Saved portfolio ideas (\(savedProjects.count))", isExpanded: $inspirationExpanded) {
                    VStack(alignment: .leading, spacing: 14) {
                        if savedProjects.isEmpty {
                            Text("Save projects you love from the portfolio. You can also choose them in the inspiration step.")
                                .foregroundStyle(Brand.secondary)
                        }
                        ForEach(savedProjects) { project in
                            NavigationLink { ProjectDetailView(project: project) } label: {
                                MenuRow(title: project.title, subtitle: "View this project", symbol: "heart")
                            }.buttonStyle(.plain)
                        }
                        Button("Browse LINART projects") { store.selectedTab = .projects }
                            .buttonStyle(SecondaryButtonStyle())
                    }.padding(.top, 16)
                }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))

                DisclosureGroup("Before we talk", isExpanded: $checklistExpanded) {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(AppStore.planningSteps, id: \.self) { step in
                            Button { store.toggleStep(step) } label: {
                                Label(step, systemImage: store.completedSteps.contains(step) ? "checkmark.square.fill" : "square")
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                            }.buttonStyle(.plain)
                                .accessibilityValue(store.completedSteps.contains(step) ? "Completed" : "Not completed")
                        }
                    }.padding(.top, 16)
                }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Prefer to talk first?").font(.headline)
                    Text("Send a short inquiry to start the conversation. You can work on your plan whenever you are ready.")
                        .font(.subheadline).foregroundStyle(Brand.secondary)
                    Button("Start a project inquiry") { store.startInquiry() }.buttonStyle(SecondaryButtonStyle())
                }
                NavigationLink { CloudStudioView() } label: {
                    MenuRow(title: "Sent briefs & account", subtitle: "Your submissions and sign-in settings", symbol: "person.crop.circle")
                }.buttonStyle(.plain)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("My Project").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $store.studioRequested) { ProjectStudioView() }
    }

    private var planningCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(title: studio.draft.hasProjectContent ? "Continue your plan" : "Your private project plan")
            Text(studio.draft.hasProjectContent ? studio.draft.displayTitle : "Let's start with your space.")
                .font(.system(.title, design: .serif)).foregroundStyle(Brand.ink)
            Text("Details, photos, inspiration and timing — then a final review. Every question is optional.")
                .foregroundStyle(Brand.secondary)
            Label("Step \(studio.currentSection.number) of 5 · \(studio.currentSection.title)", systemImage: studio.currentSection.symbol)
                .font(.subheadline.weight(.medium)).foregroundStyle(Brand.bronze)
                .fixedSize(horizontal: false, vertical: true)
            Button { open(studio.currentSection) } label: {
                Label(studio.currentSection == .details && !studio.draft.hasProjectContent ? "Start planning" : "Continue planning", systemImage: "arrow.right")
            }.buttonStyle(PrimaryButtonStyle()).disabled(!studio.isReady).accessibilityIdentifier("openStudio")
            Text(studio.saveLabel).font(.caption).foregroundStyle(Brand.secondary)
            Text("Your draft stays on this device until you choose to share it.")
                .font(.caption).foregroundStyle(Brand.secondary)
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Brand.line))
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

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(section.number)").font(.headline)
                .frame(width: 36, height: 36)
                .foregroundStyle(section == current ? Brand.paper : Brand.bronze)
                .background(section == current ? Brand.bronze : Brand.gold.opacity(0.25), in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(section.title).font(.subheadline.weight(.semibold)).foregroundStyle(Brand.ink)
                Text(section == current ? "Continue here" : section == .review ? "Check your brief and choose how to send" : section.hasContent(in: draft) ? "Details added · edit anytime" : "Optional · add now or skip")
                    .font(.caption).foregroundStyle(Brand.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(Brand.bronze).accessibilityHidden(true)
        }.frame(maxWidth: .infinity, minHeight: 48, alignment: .leading).padding(.vertical, 8)
            .contentShape(Rectangle()).accessibilityElement(children: .combine)
            .accessibilityLabel("Step \(section.number). \(section.title)")
            .accessibilityValue(section == current ? "Current step" : section.hasContent(in: draft) ? "Details added" : "Optional")
    }
}

struct StudioStepHeader: View {
    let section: StudioSection
    @AccessibilityFocusState private var headerFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(title: "Step \(section.number) of \(StudioSection.allCases.count)")
            ProgressView(value: Double(section.number), total: Double(StudioSection.allCases.count))
                .tint(Brand.bronze).accessibilityHidden(true)
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
        }.id(studio.currentSection)
            .background(Brand.cream)
            .navigationTitle("Project planner").navigationBarTitleDisplayMode(.inline)
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
                    .font(.subheadline).frame(minHeight: 44)
                    .accessibilityIdentifier("studioSkip")
                    .disabled(!studio.isReady || closing)
            }
        }.padding(.horizontal, 24).padding(.vertical, 12)
            .frame(maxWidth: 760).frame(maxWidth: .infinity)
            .background(Brand.paper)
            .overlay(alignment: .top) { Divider() }
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
            NavigationLink { CloudStudioView() } label: {
                Text("Send to LINART").fixedSize(horizontal: false, vertical: true)
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
