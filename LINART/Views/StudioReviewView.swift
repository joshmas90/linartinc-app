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
                Text(studio.draft.brief).font(.subheadline).lineSpacing(4).textSelection(.enabled)
                    .padding(22).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
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
                if let date = studio.lastExportedAt { Text("Last prepared \(date.formatted(date: .abbreviated, time: .shortened)).").font(.caption).foregroundStyle(Brand.secondary) }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream).navigationTitle("Review & share").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: Binding(get: { studio.shareURL != nil }, set: { value in if !value, let url = studio.shareURL { studio.finishSharing(url) } })) {
                if let url = studio.shareURL { StudioShareSheet(items: [url]) { studio.finishSharing(url) } }
            }
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
