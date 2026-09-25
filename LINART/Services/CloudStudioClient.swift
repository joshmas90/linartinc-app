import Foundation
import CryptoKit
import Security

enum CloudStudioError: LocalizedError {
    case message(String), signedOut, keychain(OSStatus)
    var errorDescription: String? {
        switch self {
        case .message(let text): text
        case .signedOut: "Sign in with your email before sending your Studio."
        case .keychain: "Your sign-in could not be saved securely on this device. Please try again."
        }
    }
}

enum CloudKeychain {
    static func read(_ account: String) throws -> Data? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.linartinc.LINART.studio", kSecAttrAccount as String: account, kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw CloudStudioError.keychain(status) }
        return item as? Data
    }
    static func write(_ data: Data?, account: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "com.linartinc.LINART.studio", kSecAttrAccount as String: account]
        guard let data else {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw CloudStudioError.keychain(status) }; return
        }
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecItemNotFound {
            var item = query; item[kSecValueData as String] = data; item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let added = SecItemAdd(item as CFDictionary, nil); guard added == errSecSuccess else { throw CloudStudioError.keychain(added) }
        } else if status != errSecSuccess { throw CloudStudioError.keychain(status) }
    }
}

struct CloudReceipt: Codable, Identifiable, Sendable {
    let id: UUID
    let submitted_at: String?
    var status: String?
    var created_at: String?
    var submittedDate: Date? {
        guard let submitted_at else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: submitted_at) { return date }
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: submitted_at)
    }
}
struct CloudDeletionRequest: Codable, Sendable {
    let id: UUID
    let requested_at: String
    var uploads_removed_at: String?
    var completed_at: String?
}
private struct CloudSession: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let email: String
    let userID: String
}
private struct CloudTokenResponse: Decodable {
    let access_token: String
    let refresh_token: String
    let expires_in: TimeInterval
    let user: User
    struct User: Decodable { let id: String; let email: String }
    var session: CloudSession { CloudSession(accessToken: access_token, refreshToken: refresh_token, expiresAt: Date().addingTimeInterval(expires_in), email: user.email, userID: user.id) }
}
private struct CloudPending: Codable { let id: UUID; let fingerprint: String; let userID: String }
private struct CloudPhoto: Codable {
    let id: UUID; let purpose: String; let note: String; let sha256: String; let bytes: Int
}
private struct CloudPayload: Codable { let draft: StudioDraft; let photos: [CloudPhoto] }

actor CloudStudioClient {
    static let base = URL(string: "https://sembxmcpuildyloqjhfj.supabase.co")!
    static let publishableKey = "sb_publishable_7N4BlC4sEFXRaeoRX0AAQg_DOaXh_o3"
    static let callback = "com.linartinc.LINART://auth/callback"
    private let network: URLSession
    private var session: CloudSession?
    private var loaded = false
    private var generation = 0
    private var refreshTask: Task<CloudSession, Error>?
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30; config.timeoutIntervalForResource = 90
        config.httpShouldSetCookies = false
        network = URLSession(configuration: config)
    }
    private func load() throws {
        guard !loaded else { return }
        if let bytes = try CloudKeychain.read("session") { session = try JSONDecoder().decode(CloudSession.self, from: bytes) }
        loaded = true
    }
    func signedInEmail() throws -> String? { try load(); return session?.email }
    func sendSignInLink(email: String) async throws {
        guard email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil, email.count <= 180 else { throw CloudStudioError.message("Enter a valid email address.") }
        var random = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, random.count, &random) == errSecSuccess else { throw CloudStudioError.message("Secure sign-in could not be prepared.") }
        let verifier = Data(random).base64URLEncoded
        let challenge = Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncoded
        try CloudKeychain.write(Data(verifier.utf8), account: "verifier")
        var components = URLComponents(url: Self.base.appendingPathComponent("auth/v1/otp"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "redirect_to", value: Self.callback)]
        _ = try await request(url: components.url!, method: "POST", body: JSONSerialization.data(withJSONObject: ["email": email, "create_user": true, "code_challenge": challenge, "code_challenge_method": "s256"]))
    }
    func finishSignIn(url: URL) async throws {
        guard url.scheme?.lowercased() == "com.linartinc.linart", url.host == "auth", url.path == "/callback",
              let code = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "code" })?.value,
              let bytes = try CloudKeychain.read("verifier"), let verifier = String(data: bytes, encoding: .utf8) else { throw CloudStudioError.message("This sign-in link is invalid or expired. Request a new link from this device.") }
        let token = generation
        let data = try await request(url: Self.base.appendingPathComponent("auth/v1/token").appending(queryItems: [URLQueryItem(name: "grant_type", value: "pkce")]), method: "POST", body: JSONSerialization.data(withJSONObject: ["auth_code": code, "code_verifier": verifier]))
        guard token == generation else { throw CancellationError() }
        let response = try JSONDecoder().decode(CloudTokenResponse.self, from: data)
        try save(response.session); try CloudKeychain.write(nil, account: "verifier")
    }
    private func save(_ value: CloudSession) throws {
        try CloudKeychain.write(JSONEncoder().encode(value), account: "session"); session = value; loaded = true
    }
    private func validSession() async throws -> CloudSession {
        try load()
        guard let session else { throw CloudStudioError.signedOut }
        if session.expiresAt.timeIntervalSinceNow > 60 { return session }
        let token = generation
        if let refreshTask {
            let refreshed = try await refreshTask.value
            guard token == generation else { throw CancellationError() }
            return refreshed
        }
        let task = Task { () async throws -> CloudSession in
            let data = try await self.request(url: Self.base.appendingPathComponent("auth/v1/token").appending(queryItems: [URLQueryItem(name: "grant_type", value: "refresh_token")]), method: "POST", body: JSONSerialization.data(withJSONObject: ["refresh_token": session.refreshToken]))
            return try JSONDecoder().decode(CloudTokenResponse.self, from: data).session
        }
        refreshTask = task; defer { refreshTask = nil }
        let refreshed = try await task.value
        guard token == generation else { throw CancellationError() }
        try save(refreshed); return refreshed
    }
    func signOut() async throws -> Bool {
        generation += 1; refreshTask?.cancel(); refreshTask = nil
        let old = session
        session = nil; loaded = true
        for name in ["session", "verifier", "pending"] { try CloudKeychain.write(nil, account: name) }
        if let old {
            do { _ = try await request(url: Self.base.appendingPathComponent("auth/v1/logout").appending(queryItems: [URLQueryItem(name: "scope", value: "local")]), method: "POST", bearer: old.accessToken) }
            catch { return false }
        }
        return true
    }
    func submit(draft: StudioDraft, persistence: StudioPersistence) async throws -> CloudReceipt {
        let auth = try await validSession(), token = generation
        var photos: [CloudPhoto] = [], files: [UUID: Data] = [:]
        for photo in draft.photos {
            try Task.checkCancellation()
            let bytes = try Data(contentsOf: persistence.photoURL(photo.filename))
            guard bytes.count <= 5_000_000 else { throw CloudStudioError.message("A photo is too large to send. Remove it and import it again.") }
            files[photo.id] = bytes
            photos.append(CloudPhoto(id: photo.id, purpose: photo.purpose, note: photo.note, sha256: Self.hash(bytes), bytes: bytes.count))
        }
        var snapshot = draft; snapshot.photos = []
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(CloudPayload(draft: snapshot, photos: photos))
        let fingerprint = Self.hash(data)
        var pending = CloudPending(id: UUID(), fingerprint: fingerprint, userID: auth.userID)
        if let bytes = try CloudKeychain.read("pending"), let prior = try? JSONDecoder().decode(CloudPending.self, from: bytes), prior.fingerprint == fingerprint, prior.userID == auth.userID { pending = prior }
        try CloudKeychain.write(encoder.encode(pending), account: "pending")
        let begun = try await call(action: "begin", method: "POST", id: pending.id, body: data, session: auth)
        let current = try JSONDecoder().decode(CloudReceipt.self, from: begun)
        if current.status == "submitted" { return current }
        for photo in photos {
            try Task.checkCancellation(); guard generation == token else { throw CancellationError() }
            _ = try await call(action: "photo", method: "PUT", id: pending.id, photo: photo.id, body: files[photo.id], contentType: "image/jpeg", session: auth)
        }
        try Task.checkCancellation(); guard generation == token else { throw CancellationError() }
        let response = try await call(action: "submit", method: "POST", id: pending.id, session: auth)
        return try JSONDecoder().decode(CloudReceipt.self, from: response)
    }
    func receipts() async throws -> [CloudReceipt] {
        struct List: Decodable { let receipts: [CloudReceipt] }
        let auth = try await validSession()
        return try JSONDecoder().decode(List.self, from: await call(action: "receipts", method: "GET", session: auth)).receipts
    }
    func remove(_ receipt: CloudReceipt) async throws {
        let auth = try await validSession()
        _ = try await call(action: "delete", method: "DELETE", id: receipt.id, session: auth)
        if let bytes = try CloudKeychain.read("pending"),
           let pending = try? JSONDecoder().decode(CloudPending.self, from: bytes), pending.id == receipt.id {
            try CloudKeychain.write(nil, account: "pending")
        }
    }
    func requestAccountDeletion() async throws -> CloudDeletionRequest {
        let auth = try await validSession()
        let data = try await call(action: "account", method: "DELETE", session: auth)
        try CloudKeychain.write(nil, account: "pending")
        return try JSONDecoder().decode(CloudDeletionRequest.self, from: data)
    }
    func deletionStatus() async throws -> CloudDeletionRequest? {
        struct Status: Decodable { let request: CloudDeletionRequest? }
        let auth = try await validSession()
        return try JSONDecoder().decode(Status.self, from: await call(action: "deletion-status", method: "GET", session: auth)).request
    }
    private func call(action: String, method: String, id: UUID? = nil, photo: UUID? = nil, body: Data? = nil, contentType: String = "application/json", session: CloudSession) async throws -> Data {
        var query = [URLQueryItem(name: "action", value: action)]
        if let id { query.append(URLQueryItem(name: "id", value: id.uuidString.lowercased())) }
        if let photo { query.append(URLQueryItem(name: "photo", value: photo.uuidString)) }
        return try await request(url: Self.base.appendingPathComponent("functions/v1/linart-ios-api").appending(queryItems: query), method: method, body: body, bearer: session.accessToken, contentType: contentType)
    }
    private func request(url: URL, method: String, body: Data? = nil, bearer: String? = nil, contentType: String = "application/json") async throws -> Data {
        var request = URLRequest(url: url); request.httpMethod = method; request.httpBody = body
        request.setValue(Self.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        if let bearer { request.setValue("Bearer " + bearer, forHTTPHeaderField: "Authorization") }
        let (data, response) = try await network.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw CloudStudioError.message("No response was received. Your local Studio is safe.") }
        if http.statusCode == 401 { throw CloudStudioError.signedOut }
        guard (200..<300).contains(http.statusCode) else {
            let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let message = object?["error_description"] as? String ?? object?["msg"] as? String ?? object?["error"] as? String
            throw CloudStudioError.message(message ?? "The request could not be completed. Your local Studio is safe; retry when connected.")
        }
        return data
    }
    private static func hash(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }
}
private extension Data {
    var base64URLEncoded: String { base64EncodedString().replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "") }
}
