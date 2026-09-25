import SwiftUI
import UIKit

struct InquiryView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var studio: StudioStore
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var errors: [String: String] = [:]
    @State private var errorMessage: String?
    @State private var isSending = false
    @State private var sent = false
    @State private var consent = false
    @State private var confirmClear = false
    @State private var retryAfter: Date?
    @State private var sendTask: Task<Void, Never>?
    @FocusState private var focus: String?
    private let titles = ["Your details", "Your project", "Review & send"]
    private let orderedFields = ["name", "email", "phone", "city", "service", "timing", "contact", "message"]
    var body: some View {
        Group { if sent { success } else { form } }
            .navigationTitle(sent ? "Inquiry received" : "Project inquiry").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(sent ? "Done" : "Close") { dismiss() }.disabled(isSending) }
                if !sent { ToolbarItem(placement: .topBarTrailing) { Button("Clear", role: .destructive) { confirmClear = true }.disabled(isSending) } }
            }
            .interactiveDismissDisabled(isSending)
            .confirmationDialog("Clear this inquiry?", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("Clear inquiry", role: .destructive) {
                    Task {
                        do { try await store.clearSavedInquiry(); errors = [:]; errorMessage = nil; consent = false; step = 0 }
                        catch { errorMessage = "The saved inquiry could not be removed. Try again." }
                    }
                }
            }
            .onDisappear { sendTask?.cancel(); Task { await store.flushInquiryDraft() } }
    }
    private var form: some View {
        ScrollViewReader { proxy in
            Form {
                Section {
                    Text(titles[step]).font(.system(.title, design: .serif)).accessibilityAddTraits(.isHeader)
                    Text("Step \(step + 1) of 3").font(.caption).foregroundStyle(Brand.secondary)
                    ProgressView(value: Double(step + 1), total: 3).accessibilityLabel("Inquiry progress")
                }.id("top")
                if step == 0 {
                    Section("How can we reach you?") {
                        field("Full name", key: "name", text: $store.inquiry.name, type: .name)
                        field("Email address", key: "email", text: $store.inquiry.email, type: .emailAddress, keyboard: .emailAddress)
                        field("Phone number", key: "phone", text: $store.inquiry.phone, type: .telephoneNumber, keyboard: .phonePad)
                        field("Project city or ZIP", key: "city", text: $store.inquiry.city, type: .addressCity)
                    }
                    Section {
                        Toggle("Save this inquiry on my device", isOn: $store.rememberInquiry).disabled(store.inquiryDraftNotice != nil)
                        Text("Optional. Saves contact details in protected app files so you can return later. Clear removes the saved copy.").font(.caption).foregroundStyle(Brand.secondary)
                        if let notice = store.inquiryDraftNotice { Label(notice, systemImage: "exclamationmark.circle").font(.footnote) }
                    }
                }
                if step == 1 {
                    Section("The project") {
                        Picker("Project type", selection: $store.inquiry.service) { ForEach(Inquiry.serviceOptions, id: \.self) { Text($0).tag($0) } }.id("service")
                        fieldError("service")
                        Picker("Timing", selection: $store.inquiry.timing) {
                            Text("Not sure yet").tag("")
                            ForEach(Inquiry.timingOptions, id: \.self) { Text($0).tag($0) }
                        }.id("timing")
                        fieldError("timing")
                        Picker("Contact me by", selection: $store.inquiry.contact) { ForEach(Inquiry.contactOptions, id: \.self) { Text($0).tag($0) } }.id("contact")
                        fieldError("contact")
                        VStack(alignment: .leading, spacing: 7) {
                            Text("What would you like to create? · optional").font(.subheadline)
                            TextField("Your ideas", text: $store.inquiry.message, axis: .vertical).lineLimit(4...9).focused($focus, equals: "message").accessibilityLabel("Project description, optional")
                            Text("\(store.inquiry.message.count) / 1,000 characters").font(.caption).foregroundStyle(Brand.secondary)
                            fieldError("message")
                        }.id("message")
                    }
                }
                if step == 2 {
                    Section("Check your details") {
                        Text(store.inquiry.normalized.brief).font(.subheadline).textSelection(.enabled)
                        Button("Edit contact details") { step = 0 }
                        Button("Edit project details") { step = 1 }
                    }
                    Section {
                        Toggle("I agree to send these details to LINART so the team can respond to my inquiry.", isOn: $consent)
                        NavigationLink("How your information is used") { PrivacyView() }
                    }
                }
                if let errorMessage { Section { Label(errorMessage, systemImage: "exclamationmark.circle").foregroundStyle(.red) }.id("error") }
                Section {
                    if step < 2 { Button("Continue") { advance() }.buttonStyle(PrimaryButtonStyle()) }
                    else {
                        TimelineView(.periodic(from: .now, by: 1)) { context in
                            Button { submit() } label: {
                                HStack { if isSending { ProgressView().tint(.white) }; Text(isSending ? "Sending…" : "Submit inquiry"); Image(systemName: "arrow.up.right") }
                            }.buttonStyle(PrimaryButtonStyle()).disabled(isSending || !consent || (retryAfter.map { $0 > context.date } ?? false))
                        }
                    }
                    if step > 0 { Button("Back") { step -= 1 }.frame(minHeight: 44) }
                    ShareLink(item: store.inquiry.normalized.brief) { Label("Share inquiry another way", systemImage: "square.and.arrow.up") }
                }
            }.disabled(isSending).scrollContentBackground(.hidden).background(Brand.cream).scrollDismissesKeyboard(.interactively)
                .onChange(of: step) { _, _ in proxy.scrollTo("top", anchor: .top) }
                .onChange(of: focus) { _, field in if let field { withAnimation { proxy.scrollTo(field, anchor: .center) } } }
                .onChange(of: errorMessage) { _, message in
                    if let message { UIAccessibility.post(notification: .announcement, argument: message); if focus == nil { proxy.scrollTo("error", anchor: .center) } }
                }
        }
    }
    private func field(_ title: String, key: String, text: Binding<String>, type: UITextContentType, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title + " *").font(.caption.weight(.medium)).foregroundStyle(Brand.secondary)
            TextField(title, text: text).textContentType(type).keyboardType(keyboard)
                .textInputAutocapitalization(key == "email" ? .never : .words).autocorrectionDisabled(key == "email")
                .focused($focus, equals: key).accessibilityLabel(title + ", required")
            fieldError(key)
        }.id(key)
    }
    @ViewBuilder private func fieldError(_ key: String) -> some View { if let error = errors[key] { Text(error).font(.caption).foregroundStyle(.red) } }
    private func revealErrors() {
        guard let first = orderedFields.first(where: { errors[$0] != nil }) else { return }
        step = ["name", "email", "phone", "city"].contains(first) ? 0 : 1
        Task { @MainActor in await Task.yield(); focus = first }
        errorMessage = errors[first]
    }
    private func advance() {
        errors = store.inquiry.validationErrors.filter { step == 0 ? ["name", "email", "phone", "city"].contains($0.key) : !["name", "email", "phone", "city"].contains($0.key) }
        guard errors.isEmpty else { revealErrors(); return }
        focus = nil; errorMessage = nil; step += 1
    }
    private func submit() {
        guard !isSending, consent, retryAfter.map({ $0 <= Date() }) ?? true else { return }
        errors = store.inquiry.validationErrors
        guard errors.isEmpty else { revealErrors(); return }
        let snapshot = store.inquiry.normalized
        isSending = true; errorMessage = nil
        sendTask = Task { @MainActor in
            defer { isSending = false }
            do {
                try await InquiryClient().send(snapshot)
                guard !Task.isCancelled else { return }
                sent = true
                if studio.isReady {
                    if studio.draft.inquiryEmail.isEmpty { studio.draft.inquiryEmail = snapshot.email }
                    if studio.draft.projectType.isEmpty { studio.draft.projectType = snapshot.service }
                    if studio.draft.goals.isEmpty { studio.draft.goals = snapshot.message }
                    if studio.draft.timeline.isEmpty { studio.draft.timeline = snapshot.timing }
                    await studio.flush()
                }
                do { try await store.clearSavedInquiry() }
                catch { store.inquiryDraftNotice = "Your inquiry was sent, but its saved local copy could not be removed. Clear local data in Settings to retry."; store.inquiry = Inquiry() }
            } catch is CancellationError {
                // Keep the entered draft; cancellation is not a delivery result.
            } catch let error as InquiryError {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                switch error {
                case .rejected(_, let fields): errors = fields; revealErrors(); Diagnostics.shared.record(.inquiryRejected)
                case .rateLimited(let date): retryAfter = date
                case .offline: Diagnostics.shared.record(.inquiryOffline)
                case .unconfirmed: Diagnostics.shared.record(.inquiryUnconfirmed)
                }
            } catch { if !Task.isCancelled { errorMessage = InquiryError.unconfirmed.localizedDescription } }
        }
    }
    private var success: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: "checkmark.circle").font(.largeTitle).foregroundStyle(Brand.bronze)
                SectionHeading(eyebrow: "Thank you", title: "A thoughtful beginning.")
                Text("Your inquiry was received. The LINART team will use your preferred contact method to respond.").lineSpacing(5)
                if let notice = store.inquiryDraftNotice { Text(notice).font(.footnote) }
                Text("Keep gathering photos and ideas in your private Studio. Your existing notes stay intact.").foregroundStyle(Brand.secondary)
                Button("Continue to Project Studio") { store.selectedTab = .studio; store.studioRequested = true; dismiss() }.buttonStyle(PrimaryButtonStyle())
                Button("Back to Home") { store.selectedTab = .home; dismiss() }.buttonStyle(SecondaryButtonStyle())
                Text("An inquiry does not book an appointment or confirm a quote.").font(.caption).foregroundStyle(Brand.secondary)
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(Brand.cream)
    }
}
