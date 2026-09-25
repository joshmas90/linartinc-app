import Foundation
import Combine

@MainActor final class CloudStudioStore: ObservableObject {
    @Published private(set) var email: String?
    @Published private(set) var busy = false
    @Published private(set) var receipts: [CloudReceipt] = []
    @Published var notice: String?
    @Published var lastReceipt: CloudReceipt?
    private let client = CloudStudioClient()
    private var task: Task<Void, Never>?
    private var generation = 0
    func load() async {
        do { email = try await client.signedInEmail() }
        catch { notice = error.localizedDescription }
    }
    func signIn(email: String) {
        run {
            try await self.client.sendSignInLink(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
            self.notice = "Check your email and open the sign-in link on this device. Nothing has been uploaded yet."
        }
    }
    func handle(_ url: URL) {
        guard url.scheme?.lowercased() == "com.linartinc.linart" else { return }
        run {
            try await self.client.finishSignIn(url: url)
            self.email = try await self.client.signedInEmail()
            self.notice = "Signed in. Review your brief and choose Send to LINART when ready."
            self.receipts = try await self.client.receipts()
        }
    }
    func send(draft: StudioDraft, persistence: StudioPersistence) {
        run {
            let receipt = try await self.client.submit(draft: draft, persistence: persistence)
            try Task.checkCancellation()
            self.lastReceipt = receipt
            self.notice = "Your brief and selected photos were stored securely with LINART. Keep the receipt below for reference."
            self.receipts = try await self.client.receipts()
        }
    }
    func refresh() { run { self.receipts = try await self.client.receipts() } }
    func remove(_ receipt: CloudReceipt) {
        run {
            try await self.client.remove(receipt)
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
        email = nil; receipts = []; lastReceipt = nil
        try await client.signOut()
        notice = "Signed out on this device. Cloud submissions remain available when you sign in again."
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
