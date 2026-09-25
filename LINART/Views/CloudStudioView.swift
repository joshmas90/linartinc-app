import SwiftUI

struct CloudStudioView: View {
    @EnvironmentObject private var cloud: CloudStudioStore
    @EnvironmentObject private var studio: StudioStore
    @State private var email = ""
    @State private var consent = false
    @State private var deleting: CloudReceipt?
    var body: some View {
        Form {
            Section {
                Text("Send your Studio securely").font(.system(.title2, design: .serif))
                Text("Choose to send your answers, saved references and \(studio.draft.photos.count) selected photos to LINART. Local planning and PDF sharing remain available without signing in.").foregroundStyle(Brand.secondary)
            }
            if let address = cloud.email {
                Section("Signed in") { Text(address); Button("Sign out on this device") { cloud.signOut() } }
                Section("Your submission") {
                    Text(studio.draft.displayTitle).font(.headline)
                    Text("\(studio.draft.photos.count) photos · \(studio.draft.references.count) links · \(studio.draft.ideas.count) portfolio ideas")
                    Toggle("I agree to send this brief and the selected photos to LINART.", isOn: $consent)
                    Button("Send to LINART", systemImage: "paperplane") { cloud.send(draft: studio.draft, persistence: studio.persistence) }
                        .disabled(!consent || !studio.isReady || studio.isImporting || studio.draft.isEmpty)
                    Text("A receipt confirms secure storage, not an appointment, estimate or response time. Retrying an unchanged brief uses the same submission reference.").font(.caption).foregroundStyle(Brand.secondary)
                }
                if let receipt = cloud.lastReceipt {
                    Section("Submission receipt") {
                        Label("Received securely", systemImage: "checkmark.seal")
                        Text(receipt.id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                        if let date = receipt.submitted_at { Text(date).font(.caption) }
                    }
                }
                Section("Your app submissions") {
                    Button("Refresh submissions", systemImage: "arrow.clockwise") { cloud.refresh() }
                    ForEach(cloud.receipts) { receipt in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(receipt.submitted_at == nil ? "Unfinished upload" : "Submitted Studio").font(.headline)
                            Text(receipt.id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                            Button("Delete this app submission", role: .destructive) { deleting = receipt }
                        }
                    }
                    Text("You can remove submitted or unfinished app uploads here. Website inquiries are separate.").font(.caption).foregroundStyle(Brand.secondary)
                }
            } else {
                Section("Verify your email") {
                    TextField("Email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                    Button("Email me a sign-in link", systemImage: "envelope") { cloud.signIn(email: email) }
                    Text("Open the link on this device to return to LINART. Your sign-in is stored securely in the device Keychain; no password is needed.").font(.caption).foregroundStyle(Brand.secondary)
                }
            }
            if cloud.busy { Section { ProgressView("Working securely…") } }
            if let notice = cloud.notice { Section { Label(notice, systemImage: "info.circle").font(.subheadline).textSelection(.enabled) } }
            Section { NavigationLink("Privacy & your information") { PrivacyView() } }
        }.disabled(cloud.busy).scrollContentBackground(.hidden).background(Brand.cream)
            .navigationTitle("Send to LINART").navigationBarTitleDisplayMode(.inline)
            .onAppear { if email.isEmpty { email = studio.draft.inquiryEmail } }
            .confirmationDialog("Delete this app submission and its uploaded photos?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete submission", role: .destructive) { if let receipt = deleting { cloud.remove(receipt) }; deleting = nil }
            } message: { Text("This removes the cloud copy. It leaves your local Studio and website inquiries unchanged. Copies already downloaded by a recipient cannot be recalled.") }
    }
}
