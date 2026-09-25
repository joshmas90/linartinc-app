import SwiftUI

struct CloudStudioView: View {
    @EnvironmentObject private var cloud: CloudStudioStore
    @EnvironmentObject private var studio: StudioStore
    @State private var email = ""
    @State private var deleting: CloudReceipt?
    @State private var deleteAccount = false
    var body: some View {
        Form {
            Section {
                Text("Sent briefs & account").font(.system(.title2, design: .serif))
                Text("Find your submitted project briefs and manage your account. Continue planning from My Project.").foregroundStyle(Brand.secondary)
            }
            if let address = cloud.email {
                Section("Signed in") { Text(address); Button("Sign out on this device") { cloud.signOut() } }
                Section("Your app submissions") {
                    Button("Refresh submissions", systemImage: "arrow.clockwise") { cloud.refresh() }
                    ForEach(cloud.receipts) { receipt in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(receipt.submitted_at == nil ? "Unfinished upload" : "Submitted project brief").font(.headline)
                            if let date = receipt.submittedDate { Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(Brand.secondary) }
                            Text(receipt.id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                            Button("Delete this app submission", role: .destructive) { deleting = receipt }
                        }
                    }
                    Text("You can remove submitted or unfinished app uploads here. Website inquiries are separate.").font(.caption).foregroundStyle(Brand.secondary)
                }
                Section("Account deletion") {
                    if let request = cloud.deletionRequest {
                        Label("Deletion requested", systemImage: "checkmark.circle")
                        Text("Reference: \(request.id.uuidString)").font(.caption.monospaced()).textSelection(.enabled)
                    }
                    Button(cloud.deletionRequest == nil ? "Delete my app account" : "Retry upload removal", role: .destructive) { deleteAccount = true }
                    Text("Your app uploads are removed immediately. LINART completes account deletion within 7 days and confirms by email. Existing website records are reviewed separately; your local project draft stays on this device.").font(.caption).foregroundStyle(Brand.secondary)
                }
            } else {
                Section("Verify your email") { ProjectEmailSignInView(email: $email) }
            }
            if cloud.busy { Section { ProgressView("Working securely…") } }
            if let notice = cloud.notice { Section { Label(notice, systemImage: "info.circle").font(.subheadline).textSelection(.enabled) } }
            Section { NavigationLink("Privacy & your information") { PrivacyView() } }
        }.disabled(cloud.busy).scrollContentBackground(.hidden).background(Brand.cream)
            .navigationTitle("Sent briefs & account").navigationBarTitleDisplayMode(.inline)
            .onAppear { if email.isEmpty { email = studio.draft.inquiryEmail } }
            .task { if cloud.email != nil { cloud.refresh() } }
            .alert("Request account deletion?", isPresented: $deleteAccount) {
                Button("Delete uploads & request deletion", role: .destructive) { cloud.requestAccountDeletion() }
                Button("Cancel", role: .cancel) { }
            } message: { Text("All app uploads will be permanently removed. LINART will finish deleting your account within 7 days. You will not be able to send new briefs while this request is pending.") }
            .confirmationDialog("Delete this app submission and its uploaded photos?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
                Button("Delete submission", role: .destructive) { if let receipt = deleting { cloud.remove(receipt) }; deleting = nil }
            } message: { Text("This removes the cloud copy. It leaves your local project draft and website inquiries unchanged. Copies already downloaded by a recipient cannot be recalled.") }
    }
}


// Kept separate from account management so the final action has one purpose.
struct ProjectSendView: View {
    @EnvironmentObject private var cloud: CloudStudioStore
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var consent = false
    @State private var confirmation: SentProjectConfirmation?
    @State private var opened = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let confirmation {
                    receiptView(confirmation)
                } else {
                    SectionHeading(eyebrow: "One final check", title: "Share your project brief")
                    Text(studio.draft.displayTitle).font(.system(.title2, design: .serif))
                    Text(studio.draft.contentSummary).font(.subheadline).foregroundStyle(Brand.secondary)
                    Text("Your answers, selected photos and inspiration will be sent together. Your draft stays on this device.")
                        .foregroundStyle(Brand.secondary)
                    if !studio.draft.hasProjectContent {
                        Label("Add a few details before sending your brief.", systemImage: "square.and.pencil")
                        Button("Return to review") { dismiss() }.buttonStyle(SecondaryButtonStyle())
                    } else if let address = cloud.email {
                        confirmationForm(address: address)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Verify your email").font(.headline)
                            ProjectEmailSignInView(email: $email)
                        }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
                    }
                    if cloud.busy {
                        ProgressView("Please wait…").accessibilityIdentifier("projectSendProgress")
                    }
                    if let notice = cloud.notice {
                        Label(notice, systemImage: "info.circle").font(.subheadline).textSelection(.enabled)
                            .accessibilityIdentifier("projectSendNotice")
                    }
                    Text("You will receive a submission reference after the upload succeeds. Sending a brief does not book an appointment or confirm an estimate.")
                        .font(.footnote).foregroundStyle(Brand.secondary)
                    NavigationLink("Privacy & your information") { PrivacyView() }.frame(minHeight: 44)
                }
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
            .navigationTitle(confirmation == nil ? "Verify & send" : "Brief received")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(cloud.busy)
            .disabled(cloud.busy)
            .onAppear {
                if email.isEmpty { email = studio.draft.inquiryEmail }
                if !opened {
                    opened = true
                    if !cloud.busy { cloud.notice = nil }
                }
            }
            .onChange(of: cloud.email) { _, _ in consent = false; confirmation = nil }
            .onChange(of: studio.draft) { _, _ in consent = false }
    }

    private var canSend: Bool {
        consent && studio.isReady && !studio.isImporting && studio.draft.hasProjectContent &&
        cloud.email != nil && cloud.deletionRequest == nil && !cloud.busy
    }

    private func confirmationForm(address: String) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Email verified", systemImage: "checkmark.seal").font(.headline).foregroundStyle(Brand.bronze)
            Text(address).textSelection(.enabled)
            Button("Use a different email") { consent = false; cloud.signOut() }.frame(minHeight: 44)
            if cloud.deletionRequest != nil {
                Text("Sending is unavailable while your account-deletion request is pending. You can keep planning or save a PDF from review.")
                    .foregroundStyle(Brand.secondary)
            } else {
                Toggle("I agree to send this brief and the selected photos to LINART.", isOn: $consent)
                    .tint(Brand.bronze).accessibilityIdentifier("projectSendConsent")
                Button(action: send) {
                    Label("Send my brief", systemImage: "paperplane")
                }.buttonStyle(PrimaryButtonStyle())
                    .disabled(!canSend).opacity(canSend ? 1 : 0.5)
                    .accessibilityIdentifier("projectSendConfirm")
                Text("You can return to review to make changes before sending.").font(.footnote).foregroundStyle(Brand.secondary)
            }
        }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
    }

    private func send() {
        guard canSend else { return }
        let draft = studio.draft
        cloud.send(draft: draft, persistence: studio.persistence) { receipt in
            // This receipt belongs to this tap and snapshot, never an older submission.
            confirmation = SentProjectConfirmation(receipt: receipt, title: draft.displayTitle, summary: draft.contentSummary)
            consent = false
        }
    }

    private func receiptView(_ result: SentProjectConfirmation) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Label("Your brief has been received", systemImage: "checkmark.seal.fill")
                .font(.system(.title2, design: .serif)).foregroundStyle(Brand.bronze)
                .accessibilityAddTraits(.isHeader).accessibilityIdentifier("projectSendSuccess")
            Text(result.title).font(.title3.weight(.semibold))
            Text(result.summary).foregroundStyle(Brand.secondary)
            Text("Your project brief is stored securely with LINART. You can find its receipt in My Project → Sent briefs & account.")
            VStack(alignment: .leading, spacing: 8) {
                Text("Submission reference").font(.caption.weight(.semibold)).foregroundStyle(Brand.secondary)
                Text(result.receipt.id.uuidString).font(.caption.monospaced()).textSelection(.enabled)
                if let date = result.receipt.submittedDate { Text(date.formatted(date: .abbreviated, time: .shortened)).font(.caption) }
            }
            Text("Your local draft remains available to edit. Later edits are not sent automatically. An appointment or estimate is arranged separately.")
                .font(.subheadline).foregroundStyle(Brand.secondary)
            Button("Return to my brief") { dismiss() }.buttonStyle(PrimaryButtonStyle())
        }.padding(24).background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct SentProjectConfirmation {
    let receipt: CloudReceipt
    let title: String
    let summary: String
}

struct ProjectEmailSignInView: View {
    @EnvironmentObject private var cloud: CloudStudioStore
    @Binding var email: String
    var body: some View {
        TextField("Email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
            .textInputAutocapitalization(.never).autocorrectionDisabled()
            .textFieldStyle(.roundedBorder)
            .accessibilityLabel("Email address")
            .accessibilityIdentifier("projectSignInEmail")
        Button("Email me a sign-in link", systemImage: "envelope") { cloud.signIn(email: email) }
            .frame(minHeight: 44).disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cloud.busy)
        Text("Open the link on this device to return to My Project. No password is needed and signing in does not send your project.")
            .font(.footnote).foregroundStyle(Brand.secondary)
    }
}
