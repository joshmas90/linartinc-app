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
            VStack(alignment: .leading, spacing: 22) {
                StudioStepHeader(section: .review)
                StudioStatusView()
                if !studio.draft.hasProjectContent {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your plan is still a blank page.").font(.headline)
                        Text("Add a few words, a photo or an idea before sharing. You can leave the rest for later.")
                            .foregroundStyle(Brand.secondary)
                        Button("Add project details") { onEdit(.details) }.buttonStyle(SecondaryButtonStyle())
                    }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
                }
                if studio.draft.hasProjectContent {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(title: "Your project brief")
                        Text(studio.draft.displayTitle).font(.system(.title, design: .serif))
                        Text("Prepared by you · private until you share").font(.caption).foregroundStyle(Brand.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                if StudioSection.details.hasContent(in: studio.draft) { projectPreview }
                if StudioSection.photos.hasContent(in: studio.draft) { photoPreview }
                if StudioSection.links.hasContent(in: studio.draft) { inspirationPreview }
                if StudioSection.timing.hasContent(in: studio.draft) { timingPreview }
                optionalDetails
                VStack(alignment: .leading, spacing: 14) {
                    Text("Ready to share your plan?").font(.system(.title2, design: .serif))
                    Text("Send your brief and selected photos directly to LINART. You will verify your email and confirm before anything is sent.")
                        .foregroundStyle(Brand.secondary)
                    Text("Choose Verify & send below, or save your draft for later.")
                        .font(.footnote).foregroundStyle(Brand.secondary)
                    Button("Save for later", action: onSaveAndClose).buttonStyle(SecondaryButtonStyle())
                        .disabled(!studio.isReady).accessibilityIdentifier("studioSaveForLater")
                }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
                pdfOptions
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .sheet(isPresented: Binding(get: { studio.shareURL != nil }, set: { value in
                if !value, let url = studio.shareURL { studio.finishSharing(url) }
            })) {
                if let url = studio.shareURL { StudioShareSheet(items: [url]) { studio.finishSharing(url) } }
            }
    }

    @ViewBuilder private var optionalDetails: some View {
        if !studio.draft.unansweredSections.isEmpty {
            DisclosureGroup("Optional details to add (\(studio.draft.unansweredSections.count))", isExpanded: $showOptional) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("You can share what you have and discuss the rest later.").font(.subheadline).foregroundStyle(Brand.secondary)
                    ForEach(studio.draft.unansweredSections) { section in
                        Button { onEdit(section) } label: {
                            Label("Add \(section.title.lowercased())", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }.buttonStyle(.plain).disabled(!studio.isReady)
                            .accessibilityIdentifier("studioEdit-\(section.id)")
                    }
                }.padding(.top, 14)
            }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("studioOptionalDetails")
        }
    }

    private var projectPreview: some View {
        previewCard(.details) {
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
        previewCard(.photos) {
            if studio.draft.photos.isEmpty { optionalNote("No photos added. You can add these later.") }
            ForEach(studio.draft.photos) { photo in
                HStack(alignment: .top, spacing: 14) {
                    StudioThumbnail(photo: photo)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(photo.purpose).font(.subheadline.weight(.medium))
                        if !photo.note.isEmpty { Text(photo.note).font(.subheadline).foregroundStyle(Brand.secondary) }
                    }
                }
            }
        }
    }

    private var inspirationPreview: some View {
        previewCard(.links) {
            if studio.draft.ideas.isEmpty && studio.draft.references.isEmpty {
                optionalNote("No inspiration added. This is optional.")
            }
            ForEach(studio.draft.ideas) { idea in
                VStack(alignment: .leading, spacing: 5) {
                    if let project = store.catalog?.projects.first(where: { $0.id == idea.id }),
                       let photo = project.photos.first {
                        PortfolioImage(photo: photo, height: 180)
                    }
                    Text(idea.title).font(.subheadline.weight(.medium))
                    if !idea.note.isEmpty { Text(idea.note).foregroundStyle(Brand.secondary) }
                }
            }
            ForEach(studio.draft.references) { reference in
                VStack(alignment: .leading, spacing: 5) {
                    Text(reference.url).font(.subheadline).textSelection(.enabled)
                    if !reference.note.isEmpty { Text(reference.note).foregroundStyle(Brand.secondary) }
                }
            }
        }
    }

    private var timingPreview: some View {
        previewCard(.timing) {
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

    private func previewCard<Content: View>(_ section: StudioSection, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Text(section.title).font(.headline).accessibilityAddTraits(.isHeader)
                Spacer(minLength: 0)
                Button("Edit") { onEdit(section) }.frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Edit \(section.title)")
                    .accessibilityIdentifier("studioEdit-\(section.id)")
                    .disabled(!studio.isReady)
            }
            content()
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Brand.line))
    }

    private func answer(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(Brand.bronze)
            Text(value).lineSpacing(4).textSelection(.enabled)
        }
    }

    private func optionalNote(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(Brand.secondary)
    }

    private var pdfOptions: some View {
        DisclosureGroup("Prefer to save or share a PDF?", isExpanded: $showPDF) {
            VStack(alignment: .leading, spacing: 14) {
                Picker("Export format", selection: $format) {
                    Text("Project book").tag(StudioExportMode.projectBook)
                    Text("Summary").tag(StudioExportMode.summary)
                }.pickerStyle(.menu)
                Text(format == .projectBook ? "Your complete answers and all \(studio.draft.photos.count) photos, with notes." : "A short overview of your goals, priorities, budget and timing.")
                    .font(.footnote).foregroundStyle(Brand.secondary)
                if let message = studio.exportError {
                    Label(message, systemImage: "exclamationmark.circle").foregroundStyle(.red)
                }
                Button { studio.export(mode: format) } label: {
                    HStack {
                        if studio.isExporting { ProgressView() }
                        Text(studio.isExporting ? "Preparing your PDF…" : "Export & share PDF")
                        Image(systemName: "square.and.arrow.up")
                    }
                }.buttonStyle(SecondaryButtonStyle())
                    .disabled(!studio.isReady || studio.isImporting || studio.isExporting || !studio.draft.hasProjectContent)
                Text("Save a copy or choose your email app and send it to \(Company.email). Opening the share sheet does not send it automatically.")
                    .font(.footnote).foregroundStyle(Brand.secondary)
                if let date = studio.lastExportedAt {
                    Text("Last prepared \(date.formatted(date: .abbreviated, time: .shortened)).")
                        .font(.caption).foregroundStyle(Brand.secondary)
                }
            }.padding(.top, 14)
        }.padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 14))
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
