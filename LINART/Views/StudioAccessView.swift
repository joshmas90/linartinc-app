import SwiftUI

struct StudioAccessView: View {
    @EnvironmentObject private var store: AppStore
    @State private var email = ""
    @State private var code = ""
    @State private var codeSent = false
    @State private var busy = false
    @State private var notice: String?
    @State private var projects: [StudioProject] = []
    @State private var authenticated = false
    @State private var confirmDeletion = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image("linart-residence-hero").resizable().scaledToFill().frame(height: 210).clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 18)).accessibilityHidden(true)
                SectionHeading(eyebrow: "Your private Project Studio", title: "A home begins with your vision.")
                Text("Your inquiry comes first. After it is received, this optional space lets you gather ideas and share details at your own pace.").foregroundStyle(.secondary)
                if authenticated {
                    if projects.isEmpty {
                        Text("No accepted inquiries are available for this verified email yet. A new inquiry may take a few minutes to appear. You can close this screen and return later.")
                    }
                    ForEach(projects) { project in
                        NavigationLink {
                            ProjectStudioView(project: project)
                        } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(project.contact.service).font(.system(.title2, design: .serif))
                                Text(project.contact.city).font(.subheadline)
                                Text(project.submitted_at == nil ? "Develop your ideas" : "Review or update your brief").font(.caption)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
                                .background(Brand.paper, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain)
                    }
                    Button("Verify email again") { authenticated = false; codeSent = false; code = "" }
                    Button("Refresh my projects") { perform { projects = try await StudioClient().projects() } }.buttonStyle(.bordered)
                    Button("Delete my Studio account and cloud projects", role: .destructive) { confirmDeletion = true }
                    Button("Sign out of Studio") { perform { await StudioClient().logout(); authenticated = false; projects = [] } }
                } else {
                    Text("Return securely with a code sent to the email address used for your inquiry. No password is needed.")
                    TextField("Inquiry email address", text: $email).textContentType(.emailAddress).keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().textFieldStyle(.roundedBorder)
                    Button(codeSent ? "Send a new code" : "Email me an access code") {
                        perform { try await StudioClient().sendCode(email: email.trimmingCharacters(in: .whitespacesAndNewlines)); codeSent = true; notice = "Check your email for your access code." }
                    }.buttonStyle(PrimaryButtonStyle()).disabled(email.isEmpty)
                    if codeSent {
                        TextField("One-time code", text: $code).textContentType(.oneTimeCode).keyboardType(.numberPad).textFieldStyle(.roundedBorder)
                        Button("Open my Studio") {
                            perform {
                                try await StudioClient().verify(email: email.trimmingCharacters(in: .whitespacesAndNewlines), code: code.trimmingCharacters(in: .whitespacesAndNewlines))
                                projects = try await StudioClient().projects(); authenticated = true; code = ""
                            }
                        }.buttonStyle(PrimaryButtonStyle()).disabled(code.count < 6)
                    }
                    Button("Start an initial inquiry") { store.startInquiry() }.buttonStyle(.bordered)
                }
                if busy { ProgressView("Connecting securely…") }
                if let notice { Text(notice).font(.footnote).foregroundStyle(Brand.bronze).accessibilityAddTraits(.updatesFrequently) }
                Text("Questions, photos and budget expectations are optional. Closing the Studio never changes the inquiry you already sent.").font(.caption).foregroundStyle(.secondary)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(Brand.cream).navigationTitle("Project Studio").navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively).disabled(busy)
        .confirmationDialog("Delete your Studio account and all cloud projects?", isPresented: $confirmDeletion, titleVisibility: .visible) {
            Button("Delete account and Studio data", role: .destructive) {
                perform {
                    try await StudioClient().deleteAccount()
                    authenticated = false; projects = []; store.clearRememberedInquiry(); email = ""
                    notice = "Your Studio account and cloud projects were deleted. Previously emailed inquiries and business records may remain; contact LINART for help with those records."
                }
            }
        } message: { Text("This removes your account, cloud drafts, submissions, uploaded files and local Studio drafts. Previously emailed inquiries are separate business records. This cannot be undone.") }
        .task {
            email = store.lastInquiryEmail
            if StudioCredential.token != nil {
                let cached = StudioClient.cachedProjects()
                if !cached.isEmpty { projects = cached; authenticated = true }
                perform { projects = try await StudioClient().projects(); authenticated = true }
            }
        }
    }
    private func perform(_ action: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }; busy = true; notice = nil
        Task { @MainActor in
            defer { busy = false }
            do { try await action() } catch { notice = error.localizedDescription }
        }
    }
}
