import SwiftUI
import UIKit

struct StudioReviewView: View {
    @EnvironmentObject private var studio: StudioStore
    @EnvironmentObject private var store: AppStore
    let onEdit: (StudioSection) -> Void
    let onSaveAndClose: () -> Void
    @State private var format: StudioExportMode = .projectBook
    @State private var showPDF = false
    @State private var showOptional = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: PremiumLayout.lg) {
                StudioStepHeader(section: .review)
                StudioStatusView()

                if !studio.draft.hasProjectContent {
                    blankBrief
                } else {
                    briefMasthead
                    if StudioSection.details.hasContent(in: studio.draft) { projectPreview }
                    if StudioSection.photos.hasContent(in: studio.draft) { photoPreview }
                    if StudioSection.links.hasContent(in: studio.draft) { inspirationPreview }
                    if StudioSection.timing.hasContent(in: studio.draft) { timingPreview }
                    optionalDetails
                    readyToShare
                    pdfOptions
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(Brand.cream)
        .sheet(isPresented: Binding(get: { studio.shareURL != nil }, set: { value in
            if !value, let url = studio.shareURL { studio.finishSharing(url) }
        })) {
            if let url = studio.shareURL { StudioShareSheet(items: [url]) { studio.finishSharing(url) } }
        }
    }

    private var blankBrief: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.md) {
            Eyebrow(title: "Your project brief")
            Text("A blank page is a perfectly good beginning.")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Brand.ink)
            Text("Add a few words, a photo or an idea before sharing. Everything else can stay open for the first conversation.")
                .foregroundStyle(Brand.secondary)
                .lineSpacing(3)
            Button("Add project details") { onEdit(.details) }
                .buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }

    private var briefMasthead: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.sm) {
            Eyebrow(title: "Project brief")
            Text(studio.draft.displayTitle)
                .font(.system(.largeTitle, design: .serif))
                .foregroundStyle(Brand.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(reviewStatus)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.ink)

            Text(studio.draft.contentSummary)
                .font(.subheadline)
                .foregroundStyle(Brand.secondary)
                .lineSpacing(3)

            HStack(spacing: PremiumLayout.xs) {
                Image(systemName: "lock").font(.caption2).foregroundStyle(Brand.bronze).accessibilityHidden(true)
                Text("Prepared by you · private until you choose to share")
                    .font(.caption)
                    .foregroundStyle(Brand.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var reviewStatus: String {
        let count = studio.draft.unansweredSections.count
        if count == 0 { return "Your brief is fully shaped and ready to verify." }
        return count == 1 ? "Ready to review · 1 optional section remains." : "Ready to review · \(count) optional sections remain."
    }

    @ViewBuilder private var optionalDetails: some View {
        if !studio.draft.unansweredSections.isEmpty {
            VStack(alignment: .leading, spacing: showOptional ? PremiumLayout.md : PremiumLayout.xs) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) { showOptional.toggle() }
                } label: {
                    HStack(alignment: .center, spacing: PremiumLayout.sm) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Want to add anything else?")
                                .font(.headline)
                                .foregroundStyle(Brand.ink)
                            Text("\(studio.draft.unansweredSections.count) optional \(studio.draft.unansweredSections.count == 1 ? "section remains" : "sections remain")")
                                .font(.caption)
                                .foregroundStyle(Brand.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: showOptional ? "chevron.up" : "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.bronze)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
                .accessibilityIdentifier("studioOptionalDetails")
                .accessibilityLabel("Optional details to add")
                .accessibilityValue(showOptional ? "Expanded" : "Collapsed")
                .accessibilityHint(showOptional ? "Hides optional project sections." : "Shows optional project sections.")

                if showOptional {
                    VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                        Text("Your brief can be shared exactly as it is. Add any of these only if they would help the first conversation.")
                            .font(.subheadline)
                            .foregroundStyle(Brand.secondary)
                            .lineSpacing(3)

                        ForEach(studio.draft.unansweredSections) { section in
                            Button { onEdit(section) } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "plus.circle").foregroundStyle(Brand.bronze)
                                    Text("Add \(section.title.lowercased())")
                                    Spacer(minLength: 8)
                                    Image(systemName: "arrow.right").font(.caption).foregroundStyle(Brand.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .multilineTextAlignment(.leading)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Brand.ink)
                            .disabled(!studio.isReady)
                            .accessibilityIdentifier("studioEdit-\(section.id)")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(PremiumLayout.md)
            .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
        }
    }

    private var projectPreview: some View {
        previewSection(.details) {
            let d = studio.draft
            let topics = [("Project type", d.projectType), ("What you would like to create", d.goals),
                          ("Your space today", d.existingConditions), ("Style & materials", d.style),
                          ("What matters most", d.priorities), ("Things to consider", d.constraints),
                          ("Anything else", d.other), ("Inquiry email", d.inquiryEmail)]
                .filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if topics.isEmpty { optionalNote("No project details added yet.") }
            ForEach(topics, id: \.0) { title, value in
                answer(title, value)
            }
        }
    }

    private var photoPreview: some View {
        previewSection(.photos) {
            if studio.draft.photos.isEmpty { optionalNote("No photos added. You can add these later.") }
            ForEach(studio.draft.photos) { photo in
                VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                    StudioThumbnail(photo: photo, expanded: true)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(photo.purpose).font(.subheadline.weight(.medium)).foregroundStyle(Brand.ink)
                        if !photo.note.isEmpty {
                            Text(photo.note).font(.subheadline).foregroundStyle(Brand.secondary).lineSpacing(3)
                        }
                    }
                }
            }
        }
    }

    private var inspirationPreview: some View {
        previewSection(.links) {
            if studio.draft.ideas.isEmpty && studio.draft.references.isEmpty {
                optionalNote("No inspiration added. This is optional.")
            }
            ForEach(studio.draft.ideas) { idea in
                VStack(alignment: .leading, spacing: PremiumLayout.xs) {
                    if let project = store.catalog?.projects.first(where: { $0.id == idea.id }),
                       let photo = project.photos.first {
                        PortfolioImage(photo: photo, height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    Text(idea.title).font(.subheadline.weight(.medium)).foregroundStyle(Brand.ink)
                    if !idea.note.isEmpty { Text(idea.note).foregroundStyle(Brand.secondary).lineSpacing(3) }
                }
            }
            ForEach(studio.draft.references) { reference in
                VStack(alignment: .leading, spacing: 5) {
                    Text(reference.url).font(.subheadline).textSelection(.enabled)
                    if !reference.note.isEmpty { Text(reference.note).foregroundStyle(Brand.secondary).lineSpacing(3) }
                }
            }
        }
    }

    private var timingPreview: some View {
        previewSection(.timing) {
            if !StudioSection.timing.hasContent(in: studio.draft) {
                optionalNote("Budget and timing are open for discussion.")
            }
            if !studio.draft.investment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                answer("Budget considerations", studio.draft.investment)
            }
            if !studio.draft.timeline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                answer("Ideal timing", studio.draft.timeline)
            }
        }
    }

    private func previewSection<Content: View>(_ section: StudioSection, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: PremiumLayout.md) {
            Rectangle().fill(Brand.line).frame(height: 1)
            HStack(alignment: .firstTextBaseline, spacing: PremiumLayout.sm) {
                VStack(alignment: .leading, spacing: 3) {
                    Eyebrow(title: "Brief section")
                    Text(section.title)
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(Brand.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 0)
                Button("Edit") { onEdit(section) }
                    .buttonStyle(TertiaryButtonStyle())
                    .accessibilityLabel("Edit \(section.title)")
                    .accessibilityIdentifier("studioEdit-\(section.id)")
                    .disabled(!studio.isReady)
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func answer(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Brand.bronze)
            Text(value)
                .foregroundStyle(Brand.ink)
                .lineSpacing(4)
                .textSelection(.enabled)
        }
    }

    private func optionalNote(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(Brand.secondary)
    }

    private var readyToShare: some View {
        VStack(alignment: .leading, spacing: PremiumLayout.sm) {
            Rectangle().fill(Brand.brass.opacity(0.65)).frame(width: 44, height: 2)
            Eyebrow(title: "Next step")
            Text("Ready to share your plan?")
                .font(.system(.title2, design: .serif))
                .foregroundStyle(Brand.ink)
            Text("Verify your email, review the final confirmation, and then send your brief and selected photos directly to LINART.")
                .foregroundStyle(Brand.secondary)
                .lineSpacing(3)
            Text("Nothing is sent until you confirm.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Brand.secondary)
            Button("Save for later", action: onSaveAndClose)
                .buttonStyle(TertiaryButtonStyle())
                .disabled(!studio.isReady)
                .accessibilityIdentifier("studioSaveForLater")
        }
        .padding(.vertical, PremiumLayout.xs)
    }

    private var pdfOptions: some View {
        DisclosureGroup(isExpanded: $showPDF) {
            VStack(alignment: .leading, spacing: PremiumLayout.sm) {
                Picker("Export format", selection: $format) {
                    Text("Project book").tag(StudioExportMode.projectBook)
                    Text("Summary").tag(StudioExportMode.summary)
                }
                .pickerStyle(.menu)

                Text(format == .projectBook ? "Your complete answers and all \(studio.draft.photos.count) photos, with notes." : "A short overview of your goals, priorities, budget and timing.")
                    .font(.footnote)
                    .foregroundStyle(Brand.secondary)

                if let message = studio.exportError {
                    Label(message, systemImage: "exclamationmark.circle").foregroundStyle(.red)
                }

                Button { studio.export(mode: format) } label: {
                    HStack {
                        if studio.isExporting { ProgressView() }
                        Text(studio.isExporting ? "Preparing your PDF…" : "Export & share PDF")
                        Spacer(minLength: 8)
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!studio.isReady || studio.isImporting || studio.isExporting || !studio.draft.hasProjectContent)

                Text("Save a copy or choose your email app and send it to \(Company.email). Opening the share sheet does not send it automatically.")
                    .font(.footnote)
                    .foregroundStyle(Brand.secondary)

                if let date = studio.lastExportedAt {
                    Text("Last prepared \(date.formatted(date: .abbreviated, time: .shortened)).")
                        .font(.caption)
                        .foregroundStyle(Brand.secondary)
                }
            }
            .padding(.top, PremiumLayout.sm)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Prefer a PDF copy?").font(.headline).foregroundStyle(Brand.ink)
                Text("Prepare a project book or concise summary")
                    .font(.caption)
                    .foregroundStyle(Brand.secondary)
            }
        }
        .tint(Brand.bronze)
        .padding(PremiumLayout.md)
        .background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Brand.line))
    }
}

struct StudioShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onFinish: () -> Void = { }
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, _, _, _ in Task { @MainActor in onFinish() } }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) { }
}
