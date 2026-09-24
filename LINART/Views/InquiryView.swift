import SwiftUI

struct InquiryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var errors: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var isSending = false
    @State private var sent = false
    @State private var consent = false
    @State private var confirmClear = false
    @State private var emailUnavailable = false
    @State private var sendTask: Task<Void, Never>?

    var body: some View {
        Group {
            if sent { successContent } else { inquiryForm }
        }
        .navigationTitle(sent ? "Inquiry Received" : "Project Inquiry")
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
                Text("Tell us about your project.").font(.system(.title, design: .serif))
                Text("Name, email, phone and project location are required. Timing and additional details are optional.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Section("Your details") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Full name *").font(.caption.weight(.medium)).foregroundStyle(Brand.secondary)
                    TextField("Full name", text: $store.inquiry.name).textContentType(.name)
                    fieldError("name")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Email address *").font(.caption.weight(.medium)).foregroundStyle(Brand.secondary)
                    TextField("Email address", text: $store.inquiry.email)
                        .keyboardType(.emailAddress).textContentType(.emailAddress)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                    fieldError("email")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Phone number *").font(.caption.weight(.medium)).foregroundStyle(Brand.secondary)
                    TextField("Phone number", text: $store.inquiry.phone)
                        .keyboardType(.phonePad).textContentType(.telephoneNumber)
                    fieldError("phone")
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Project city or ZIP *").font(.caption.weight(.medium)).foregroundStyle(Brand.secondary)
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
                Text("We’ll use these details to respond to your project inquiry. Nothing is sent until you choose Submit Inquiry.")
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
                        Text(isSending ? "Sending…" : "Submit Inquiry")
                        if !isSending { Image(systemName: "arrow.up.right") }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isSending || !consent)
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
            VStack(spacing: 28) {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .medium)).foregroundStyle(.white)
                        .frame(width: 88, height: 88)
                        .background(LinearGradient(colors: [Brand.brass, Brand.bronze], startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
                        .accessibilityHidden(true)
                    Text("Thank You!").font(.system(.largeTitle, design: .serif))
                    Text("Your inquiry has been received. We’ll follow up using the contact details you provided.")
                        .foregroundStyle(Brand.secondary).multilineTextAlignment(.center).lineSpacing(4)
                }.padding(.top, 30)
                VStack(alignment: .leading, spacing: 16) {
                    Label("Have more to share?", systemImage: "square.and.pencil")
                        .font(.headline).foregroundStyle(Brand.bronze)
                    Text("Collect photos, inspiration and ideas in your private Project Studio. Add as much or as little as you like, whenever you’re ready.")
                        .foregroundStyle(Brand.secondary).lineSpacing(4)
                    Text("Your initial inquiry is complete. The Studio is an optional next step.")
                        .font(.caption).foregroundStyle(Brand.secondary)
                }.padding(22).background(Brand.paper, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.line))
                VStack(spacing: 12) {
                    Button("Continue to Project Studio") {
                        store.selectedTab = 2
                        store.studioRequested = true
                        dismiss()
                    }.buttonStyle(PrimaryButtonStyle())
                    Button("Back to Home") {
                        store.selectedTab = 0
                        dismiss()
                    }.buttonStyle(SecondaryButtonStyle())
                }
                Text("An inquiry does not book an appointment or confirm a quote.")
                    .font(.caption).foregroundStyle(Brand.secondary).multilineTextAlignment(.center)
            }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
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
                try await InquiryClient().send(snapshot)
                guard !Task.isCancelled else { return }
                sent = true
                store.inquiry = Inquiry()
            } catch let error as InquiryError {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                if case let .rejected(_, fields) = error { errors = fields }
            } catch {
                errorMessage = InquiryError.unconfirmed.localizedDescription
            }
        }
    }
}
