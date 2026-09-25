import Foundation
import Combine

@MainActor final class CloudStudioStore: ObservableObject {
    @Published private(set) var email: String?
    @Published private(set) var busy = false
    @Published private(set) var signInLinkEmail: String?
    @Published private(set) var receipts: [CloudReceipt] = []
    @Published var notice: String?
    @Published var authenticationMessage: String?
    @Published var lastReceipt: CloudReceipt?
    @Published private(set) var deletionRequest: CloudDeletionRequest?
    private let client = CloudStudioClient()
    private var task: Task<Void, Never>?
    private var generation = 0
    func load() async {
        let token = generation
        do { let address = try await client.signedInEmail(); if token == generation { email = address } }
        catch { if token == generation { notice = error.localizedDescription } }
    }
    func signIn(email: String) {
        run {
            try await self.client.sendSignInLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            try Task.checkCancellation()
            self.signInLinkEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            self.notice = "Check your email and open the sign-in link on this device. Nothing has been uploaded yet."
        }
    }
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "com.linartinc.linart" else { return }
        run {
            do { try await self.client.finishSignIn(url: url) }
            catch { if !Task.isCancelled { self.authenticationMessage = error.localizedDescription }; throw error }
            try Task.checkCancellation()
            self.email = try await self.client.signedInEmail()
            self.signInLinkEmail = nil
            self.notice = "Signed in. Review your brief and choose Verify & send when ready."
            self.authenticationMessage = nil
            try await self.loadRemoteState()
        }
    }
    func send(draft: StudioDraft, persistence: StudioPersistence, onSuccess: @escaping @MainActor (CloudReceipt) -> Void = { _ in }) {
        guard draft.hasProjectContent, deletionRequest == nil else { return }
        run {
            let receipt = try await self.client.submit(draft: draft, persistence: persistence)
            try Task.checkCancellation()
            self.lastReceipt = receipt
            self.receipts.removeAll { $0.id == receipt.id }
            self.receipts.insert(receipt, at: 0)
            self.notice = "Your project brief was received securely. Find the receipt in Sent briefs & account."
            onSuccess(receipt)
            // History refresh belongs to the account screen. A later refresh failure
            // must not turn a confirmed submission into an apparent send failure.
        }
    }
    func refresh() { run { try await self.loadRemoteState() } }
    private func loadRemoteState() async throws {
        let rows = try await client.receipts()
        let deletion = try await client.deletionStatus()
        try Task.checkCancellation()
        receipts = rows; deletionRequest = deletion
    }
    func requestAccountDeletion() {
        run {
            let request = try await self.client.requestAccountDeletion()
            try Task.checkCancellation()
            self.deletionRequest = request
            self.receipts = []; self.lastReceipt = nil
            self.notice = "Your app uploads were removed. LINART will complete your account-deletion request within 7 days and confirm by email. Your local project draft remains on this device."
        }
    }
    func remove(_ receipt: CloudReceipt) {
        run {
            try await self.client.remove(receipt)
            try Task.checkCancellation()
            self.receipts.removeAll { $0.id == receipt.id }
            if self.lastReceipt?.id == receipt.id { self.lastReceipt = nil }
            self.notice = "This app submission and its uploaded photos were removed. Copies already downloaded by a recipient are unaffected."
        }
    }
    func signOut() {
        Task {
            do { try await clearLocal() }
            catch { notice = error.localizedDescription }
        }
    }
    func clearLocal() async throws {
        generation += 1
        task?.cancel(); task = nil; busy = false
        email = nil; receipts = []; lastReceipt = nil; deletionRequest = nil; signInLinkEmail = nil
        let confirmed = try await client.signOut()
        notice = confirmed ? "Signed out on this device. Cloud submissions remain available when you sign in again." : "Signed out on this device. Server sign-out could not be confirmed while offline; the session expires automatically."
    }
    private func run(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !busy else { return }
        busy = true; notice = nil
        let token = generation
        task = Task {
            defer { if token == generation { busy = false } }
            do { try await operation() }
            catch { if !Task.isCancelled { notice = error.localizedDescription } }
        }
    }
}
