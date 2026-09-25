import SwiftUI
import UIKit

struct StudioReviewView: View {
    @EnvironmentObject private var studio: StudioStore
    @State private var format: StudioExportMode = .projectBook
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeading(eyebrow: "In your own words", title: "Your project, considered.")
                StudioStatusView()
                briefPreview
                Picker("Export format", selection: $format) {
                    Text("Project book").tag(StudioExportMode.projectBook)
                    Text("Summary").tag(StudioExportMode.summary)
                }.pickerStyle(.segmented)
                Text(format == .projectBook ? "Your complete answers and all \(studio.draft.photos.count) photos, with notes and page numbers." : "A concise overview of your goals, priorities, investment and timing. Photos and detailed notes stay in the project book.")
                    .font(.footnote).foregroundStyle(Brand.secondary)
                if let message = studio.exportError { Label(message, systemImage: "exclamationmark.circle").foregroundStyle(.red) }
                Button { studio.export(mode: format) } label: {
                    HStack { if studio.isExporting { ProgressView().tint(.white) }; Text(studio.isExporting ? "Preparing your PDF…" : "Export & share PDF"); Image(systemName: "square.and.arrow.up") }
                }.buttonStyle(PrimaryButtonStyle()).disabled(!studio.isReady || studio.isImporting || studio.isExporting)
                Text("Choose your email app, address the message to \(Company.email), and send the PDF. Sharing opens another app; delivery is not confirmed here.").font(.footnote).foregroundStyle(Brand.secondary)
                Divider()
                NavigationLink { CloudStudioView() } label: { Label("Send directly to LINART", systemImage: "paperplane").frame(maxWidth: .infinity, minHeight: 44) }.buttonStyle(SecondaryButtonStyle())
                if let date = studio.lastExportedAt { Text("Last prepared \(date.formatted(date: .abbreviated, time: .shortened)).").font(.caption).foregroundStyle(Brand.secondary) }
            }.padding(24).padding(.bottom, 20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("Review & share").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(get: { studio.shareURL != nil }, set: { value in if !value, let url = studio.shareURL { studio.finishSharing(url) } })) {
                if let url = studio.shareURL { StudioShareSheet(items: [url]) { studio.finishSharing(url) } }
            }
    }
    private var briefPreview: some View {
        VStack(alignment: .leading, spacing: 22) {
            if studio.draft.isEmpty {
                Label("Your story starts here", systemImage: "square.and.pencil").font(.headline)
                Text("Add a few thoughts or photos in your Studio. Only the details you choose will appear in this preview.").foregroundStyle(Brand.secondary)
            }
            ForEach(answeredTopics, id: \.title) { topic in
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.title).font(.caption.weight(.semibold)).foregroundStyle(Brand.bronze)
                    Text(topic.value).font(.body).lineSpacing(4).textSelection(.enabled)
                }
            }
            if !studio.draft.photos.isEmpty {
                Divider()
                Text("Your selected photos").font(.headline)
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
            if !studio.draft.ideas.isEmpty {
                Divider(); Text("Details you love").font(.headline)
                ForEach(studio.draft.ideas) { idea in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(idea.title).font(.subheadline.weight(.medium))
                        if !idea.note.isEmpty { Text(idea.note).foregroundStyle(Brand.secondary) }
                    }
                }
            }
            if !studio.draft.references.isEmpty {
                Divider(); Text("Inspiration links").font(.headline)
                ForEach(studio.draft.references) { reference in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(reference.url).font(.subheadline).textSelection(.enabled)
                        if !reference.note.isEmpty { Text(reference.note).foregroundStyle(Brand.secondary) }
                    }
                }
            }
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
    }
    private var answeredTopics: [(title: String, value: String)] {
        let d = studio.draft
        return [("Project",d.projectType),("Contact email",d.inquiryEmail),
                ("The spaces you imagine",d.goals),("Your home today",d.existingConditions),
                ("Style & materials",d.style),("What matters most",d.priorities),
                ("Investment",d.investment),("Timing",d.timeline),
                ("Things to consider",d.constraints),("Anything else",d.other)]
            .filter { !$0.1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
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
