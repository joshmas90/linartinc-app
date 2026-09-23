import SwiftUI

struct InquiryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var errors: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var isSending = false
    @State private var deliveryUncertain = false
    @State private var sent = false
    @State private var accessNotice: String?
    @State private var consent = false
    @State private var confirmClear = false
    @State private var emailUnavailable = false
    @State private var sendTask: Task<Void, Never>?

    var body: some View {
        Group {
            if sent { successContent } else { inquiryForm }
        }
        .navigationTitle(sent ? "Thank you" : "Your project")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(sent ? "Done" : "Close") { dismiss() }.disabled(isSending)
            }
            if !sent {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) { confirmClear = true }.disabled(isSending)
                }
            }
        }
        .interactiveDismissDisabled(isSending)
        .confirmationDialog("Clear this inquiry?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear inquiry", role: .destructive) {
                store.inquiry = Inquiry()
                errors = [:]
                errorMessage = nil
                consent = false
            }
        } message: { Text("This removes the details you have entered from this app.") }
        .alert("Email app unavailable", isPresented: $emailUnavailable) {
            Button("OK", role: .cancel) { }
        } message: { Text("Use Share project brief to send your details, or email \(Company.email).") }
        .onDisappear { sendTask?.cancel() }
    }

    private var inquiryForm: some View {
        Form {
            Section {
                Text("Tell us what you have in mind.").font(.system(.title2, design: .serif))
                Text("Name, email, phone and project location are required. Timing and additional details are optional.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section("Your details") {
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Full name", text: $store.inquiry.name).textContentType(.name)
                    fieldError("name")
                }
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Email address", text: $store.inquiry.email)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    fieldError("email")
                }
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Phone number", text: $store.inquiry.phone)
                        .keyboardType(.phonePad).textContentType(.telephoneNumber)
                    fieldError("phone")
                }
                VStack(alignment: .leading, spacing: 5) {
                    TextField("Project city or ZIP", text: $store.inquiry.city).textContentType(.addressCity)
                    fieldError("city")
                }
            }
            Section("The project") {
                Picker("Project type", selection: $store.inquiry.service) {
                    ForEach(Inquiry.serviceOptions, id: \.self) { Text($0).tag($0) }
                }
                fieldError("service")
                Picker("Timing", selection: $store.inquiry.timing) {
                    Text("Not sure yet").tag("")
                    ForEach(Inquiry.timingOptions, id: \.self) { Text($0).tag($0) }
                }
                fieldError("timing")
                Picker("Contact me by", selection: $store.inquiry.contact) {
                    Text("No preference").tag("")
                    ForEach(Inquiry.contactOptions, id: \.self) { Text($0).tag($0) }
                }
                fieldError("contact")
                TextField("What would you like to create? (Optional)", text: $store.inquiry.message, axis: .vertical)
                    .lineLimit(4...9)
                Text("\(store.inquiry.message.count) / 1,000 characters").font(.caption).foregroundStyle(.secondary)
                fieldError("message")
            }
            Section {
                Toggle("I agree to send these details to LINART so the team can respond to my inquiry.", isOn: $consent)
                    .font(.subheadline)
                NavigationLink("How your information is used") { PrivacyView() }
            } footer: {
                Text("Submitting sends the form to LINART’s existing website service. No information is sent before you tap Send inquiry.")
            }
            if let errorMessage {
                Section("Please review") {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red).accessibilityAddTraits(.isStaticText)
                }
            }
            Section {
                Button(action: submit) {
                    HStack {
                        if isSending { ProgressView().tint(.white) }
                        Text(isSending ? "Sending…" : "Send inquiry")
                        if !isSending { Image(systemName: "arrow.up.right") }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSending || !consent || deliveryUncertain)
                .opacity(consent ? 1 : 0.5)
                if !consent { Text("Please agree above before sending.").font(.caption).foregroundStyle(.secondary) }
            }
            Section("Prefer another way?") {
                Button("Email project brief", systemImage: "envelope") {
                    guard let url = store.inquiry.normalized.emailURL else { emailUnavailable = true; return }
                    openURL(url) { if !$0 { emailUnavailable = true } }
                }
                ShareLink(item: store.inquiry.normalized.brief) {
                    Label("Share project brief", systemImage: "square.and.arrow.up")
                }
                ContactActions()
            }
        }
        .disabled(isSending)
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden).background(Brand.cream)
    }

    private var successContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 54)).foregroundStyle(Brand.bronze)
                SectionHeading(eyebrow: "Inquiry received", title: "Let’s make something lasting.")
                Text("LINART’s website service confirmed your inquiry. The team can follow up using the contact details you provided.")
                    .lineSpacing(5)
                Text("Sending an inquiry does not book an appointment or confirm a quote.").font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Would you like to share more of your vision?").font(.system(.title2, design: .serif))
                    Text("The inquiry above is complete. Our private Project Studio is an optional next step where you can gather photographs, inspiration links and your ideas. You can return later or skip it entirely.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("Explore the optional Project Studio") {
                        store.selectedTab = 2
                        dismiss()
                    }.buttonStyle(PrimaryButtonStyle())
                }
                .padding(20).background(Brand.paper, in: RoundedRectangle(cornerRadius: 18))
                if let accessNotice { Text(accessNotice).font(.footnote) }
                Button("Return to Studio later") { dismiss() }.buttonStyle(.bordered)
                Button("Finish without adding details") { dismiss() }.buttonStyle(.bordered)
                ContactActions()
            }.padding(28).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(Brand.cream)
    }

    @ViewBuilder
    private func fieldError(_ field: String) -> some View {
        if let message = errors[field] {
            Text(message).font(.caption).foregroundStyle(.red)
        }
    }

    private func submit() {
        guard !isSending, consent else { return }
        errors = store.inquiry.validationErrors
        guard errors.isEmpty else {
            errorMessage = "Please review the highlighted fields."
            return
        }
        let snapshot = store.inquiry.normalized
        isSending = true
        errorMessage = nil
        sendTask = Task { @MainActor in
            defer { isSending = false }
            do {
                let response = try await InquiryClient().send(snapshot)
                if let id=response.inquiry_id, let receipt=response.receipt {
                    do { try StudioVault.accept(StudioReceipt(id:id,receipt:receipt,email:snapshot.email,service:snapshot.service)) }
                    catch { accessNotice="Your inquiry was received, but private Studio access could not be saved. Contact LINART for help returning to it." }
                }
                guard !Task.isCancelled else { return }
                sent = true
                store.inquiry = Inquiry()
            } catch let error as InquiryError {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                if case let .rejected(_, fields) = error { errors = fields }
                if case .unconfirmed = error { deliveryUncertain = true }
            } catch {
                errorMessage = InquiryError.unconfirmed.localizedDescription
            }
        }
    }
}
