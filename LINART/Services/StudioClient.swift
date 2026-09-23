import Foundation
import Security

struct StudioAPIError: LocalizedError {
    var message: String
    var errorDescription: String? { message }
}
struct StudioContact: Codable {
    var name: String
    var email: String
    var phone: String
    var city: String
    var service: String
    var contact: String
}
struct StudioProject: Codable, Identifiable {
    var id: String
    var contact: StudioContact
    var status: String
    var version: Int
    var submitted_at: String?
}
struct StudioAsset: Decodable, Identifiable {
    var id: String
    var filename: String
    var purpose: String
    var note: String
    var mime: String
    var bytes: Int
}
struct StudioDetail: Decodable {
    var project: StudioRemoteProject
    var assets: [StudioAsset]
}
struct StudioRemoteProject: Decodable {
    var id: String
    var version: Int
    var draft: StudioAnswers
    var submitted_at: String?
}
struct StudioAnswers: Codable {
    var projectType: String?
    var goals: String?
    var existingConditions: String?
    var style: String?
    var priorities: String?
    var investment: String?
    var timeline: String?
    var constraints: String?
    var other: String?
    var references: [StudioReference]?

    init(_ draft: StudioDraft) {
        projectType = draft.projectType; goals = draft.goals; existingConditions = draft.existingConditions
        style = draft.style; priorities = draft.priorities; investment = draft.investment
        timeline = draft.timeline; constraints = draft.constraints; other = draft.other; references = draft.references
    }
    func apply(to draft: inout StudioDraft) {
        draft.projectType = projectType ?? ""; draft.goals = goals ?? ""; draft.existingConditions = existingConditions ?? ""
        draft.style = style ?? ""; draft.priorities = priorities ?? ""; draft.investment = investment ?? ""
        draft.timeline = timeline ?? ""; draft.constraints = constraints ?? ""; draft.other = other ?? ""; draft.references = references ?? []
    }
}

// Only the short-lived access token is stored. Refresh tokens are deliberately discarded.
// Reverification renews access and works on a new device without a password or deep link.
enum StudioCredential {
    private static let service = "com.linartinc.studio"
    static var token: String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service,
                                   kSecAttrAccount as String: "access", kSecReturnData as String: true]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    static func save(_ token: String?) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: "access"]
        SecItemDelete(query as CFDictionary)
        guard let token else { return }
        var item = query
        item[kSecValueData as String] = Data(token.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw StudioAPIError(message: "Could not securely save your session. Please try again.") }
    }
}
struct StudioClient {
    private let endpoint = URL(string: "https://linartinc.com/studio/api.php")!
    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 35; config.timeoutIntervalForResource = 60
        config.httpShouldSetCookies = false; config.httpCookieAcceptPolicy = .never
        config.urlCache = nil
        return URLSession(configuration: config)
    }()
    private func request(action: String, id: String? = nil, body: Data? = nil, contentType: String = "application/json", extra: [URLQueryItem] = []) async throws -> Data {
        var url = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        url.queryItems = [URLQueryItem(name: "action", value: action)] + (id.map { [URLQueryItem(name: "id", value: $0)] } ?? []) + extra
        var request = URLRequest(url: url.url!); request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = body == nil ? "GET" : "POST"; request.httpBody = body
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = StudioCredential.token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        let data: Data; let response: URLResponse
        do { (data, response) = try await session.data(for: request) }
        catch { throw StudioAPIError(message: "The connection was interrupted. Your local draft is safe. Reload the saved project before sending again; the server may have received it.") }
        guard let http = response as? HTTPURLResponse else { throw StudioAPIError(message: "The server response could not be confirmed.") }
        if http.statusCode == 401 { try? StudioCredential.save(nil) }
        struct Envelope: Decodable { var ok: Bool; var error: String? }
        guard let result = try? JSONDecoder().decode(Envelope.self, from: data), result.ok, (200..<300).contains(http.statusCode) else {
            let result = try? JSONDecoder().decode(Envelope.self, from: data)
            throw StudioAPIError(message: result?.error ?? "Studio is unavailable. Your original inquiry is unaffected.")
        }
        return data
    }
    func sendCode(email: String) async throws {
        _ = try await request(action: "otp", body: JSONEncoder().encode(["email": email]))
    }
    func verify(email: String, code: String) async throws {
        let data = try await request(action: "verify", body: JSONEncoder().encode(["email": email, "code": code]))
        struct Result: Decodable { var access_token: String }
        try StudioCredential.save(JSONDecoder().decode(Result.self, from: data).access_token)
    }
    func projects() async throws -> [StudioProject] {
        struct Result: Decodable { var projects: [StudioProject] }
        let projects = try JSONDecoder().decode(Result.self, from: await request(action: "list")).projects
        try FileManager.default.createDirectory(at: StudioDraft.directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(projects).write(to: StudioDraft.directory.appendingPathComponent("projects.json"), options: [.atomic, .completeFileProtectionUnlessOpen])
        return projects
    }
    static func cachedProjects() -> [StudioProject] {
        guard let data = try? Data(contentsOf: StudioDraft.directory.appendingPathComponent("projects.json")) else { return [] }
        return (try? JSONDecoder().decode([StudioProject].self, from: data)) ?? []
    }
    func detail(id: String) async throws -> StudioDetail {
        try JSONDecoder().decode(StudioDetail.self, from: await request(action: "detail", id: id))
    }
    func save(id: String, draft: StudioDraft, submit: Bool) async throws -> StudioRemoteProject {
        struct Body: Encodable { var draft: StudioAnswers; var version: Int; var submit: Bool }
        struct Result: Decodable { var project: StudioRemoteProject }
        let body = Body(draft: StudioAnswers(draft), version: draft.remoteVersion ?? 0, submit: submit)
        return try JSONDecoder().decode(Result.self, from: await request(action: "save", id: id, body: JSONEncoder().encode(body))).project
    }
    func upload(id: String, assetID: UUID, filename: String, purpose: String, note: String, bytes: Data, mime: String) async throws {
        let boundary = UUID().uuidString
        var body = Data()
        func append(_ text: String) { body.append(Data(text.utf8)) }
        for (key, value) in [("asset_id", assetID.uuidString.lowercased()), ("purpose", purpose), ("note", note)] {
            append("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n")
        }
        // Send a generated filename, never a user-controlled multipart header.
        let safeName = assetID.uuidString.lowercased() + (mime == "application/pdf" ? ".pdf" : ".jpg")
        append("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(safeName)\"\r\nContent-Type: \(mime)\r\n\r\n")
        body.append(bytes); append("\r\n--\(boundary)--\r\n")
        _ = try await request(action: "upload", id: id, body: body, contentType: "multipart/form-data; boundary=\(boundary)")
    }
    func updateNote(id: String, assetID: UUID, note: String) async throws {
        _ = try await request(action: "asset-note", id: id, body: JSONEncoder().encode(["asset_id": assetID.uuidString.lowercased(), "note": note]))
    }
    func remove(id: String, assetID: UUID) async throws {
        _ = try await request(action: "remove-asset", id: id, body: JSONEncoder().encode(["asset_id": assetID.uuidString.lowercased()]))
    }
    func download(id: String, assetID: String) async throws -> Data {
        struct Result: Decodable { var url: URL }
        let data = try await request(action: "asset", id: id, extra: [URLQueryItem(name: "asset", value: assetID)])
        let url = try JSONDecoder().decode(Result.self, from: data).url
        guard url.scheme == "https", url.host?.hasSuffix(".supabase.co") == true else { throw StudioAPIError(message: "Invalid private download address.") }
        let (bytes, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200, bytes.count <= 10 * 1024 * 1024 else { throw StudioAPIError(message: "This private file could not be downloaded.") }
        return bytes
    }
    func deleteAccount() async throws {
        _ = try await request(action: "delete-account", body: JSONEncoder().encode(["confirmation": "DELETE"]))
        try StudioCredential.save(nil)
        try StudioDraft.clear()
    }
    func logout() async {
        _ = try? await request(action: "logout", body: Data("{}".utf8))
        try? StudioCredential.save(nil)
    }
}
