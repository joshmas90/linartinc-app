import Foundation
import Security
import Combine

struct StudioReceipt: Codable, Identifiable {
    var id: String
    var receipt: String
    var email: String
    var service: String
}
struct StudioProject: Decodable, Identifiable {
    var id: String
    var contact: [String: String]
    var status: String
}
struct RemoteLink: Decodable { var url: String; var note: String }
struct RemoteStudio: Decodable {
    var answers: [String: String]
    var links: [RemoteLink]
    var revision: Int
    var submitted_at: String?
    var submitted_revision: Int?
}
struct RemoteAsset: Decodable, Identifiable {
    var id: String
    var filename: String
    var mime: String
    var purpose: String
    var note: String
    var state: String
}
struct StudioEnvelope: Decodable {
    var project: StudioProject
    var studio: RemoteStudio
    var assets: [RemoteAsset]
}
struct StudioAPIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
// Tokens and receipts never enter UserDefaults, URLs, analytics or logs.
enum StudioVault {
    static func read(_ key: String) -> Data? {
        var result: CFTypeRef?
        let query: [String: Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:"com.linartinc.studio", kSecAttrAccount as String:key, kSecReturnData as String:true]
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
    static func write(_ key: String, _ value: Data?) throws {
        let query: [String: Any] = [kSecClass as String:kSecClassGenericPassword, kSecAttrService as String:"com.linartinc.studio", kSecAttrAccount as String:key]
        if value == nil { SecItemDelete(query as CFDictionary); return }
        let attributes: [String: Any] = [kSecValueData as String:value!, kSecAttrAccessible as String:kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var item=query; attributes.forEach { item[$0.key]=$0.value }
            guard SecItemAdd(item as CFDictionary,nil) == errSecSuccess else { throw StudioAPIError(message:"Secure access could not be saved on this device.") }
        } else if status != errSecSuccess { throw StudioAPIError(message:"Secure access could not be updated.") }
    }
    static var receipts: [StudioReceipt] { (try? JSONDecoder().decode([StudioReceipt].self, from: read("receipts") ?? Data())) ?? [] }
    static func accept(_ receipt: StudioReceipt) throws {
        var saved=receipts.filter { $0.id != receipt.id }; saved.append(receipt)
        try write("receipts", JSONEncoder().encode(saved))
        try write("active",Data(receipt.id.lowercased().utf8))
    }
    static var activeID: String? {
        guard let data=read("active"), let value=String(data:data,encoding:.utf8), UUID(uuidString:value) != nil else { return nil }
        return value.lowercased()
    }
    static func clear() { ["receipts","token","active"].forEach { try? write($0,nil) } }
}
struct StudioClient {
    private let endpoint = URL(string:"https://linartinc.com/studio.php")!
    private let session: URLSession = {
        let config=URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest=35; config.timeoutIntervalForResource=60
        config.httpShouldSetCookies=false; config.httpCookieAcceptPolicy = .never
        return URLSession(configuration:config)
    }()
    func request(_ action: String, fields: [String:Any] = [:], authenticated: Bool = true) async throws -> Data {
        var body=fields; body["action"]=action
        var request=URLRequest(url:endpoint); request.httpMethod="POST"
        request.setValue("application/json",forHTTPHeaderField:"Content-Type")
        request.httpBody=try JSONSerialization.data(withJSONObject:body)
        if authenticated { try authorize(&request) }
        return try await perform(request)
    }
    private func authorize(_ request: inout URLRequest) throws {
        guard let data=StudioVault.read("token"), let token=String(data:data,encoding:.utf8), !token.isEmpty else { throw StudioAPIError(message:"Verify your email to continue. Your local draft is safe.") }
        request.setValue("Bearer \(token)",forHTTPHeaderField:"Authorization")
    }
    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data; let response: URLResponse
        do { (data,response)=try await session.data(for:request) }
        catch { throw StudioAPIError(message:"This action could not be confirmed. Your local draft is safe. Reload the online project before retrying a save or submission.") }
        guard let http=response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if (response as? HTTPURLResponse)?.statusCode == 401 { try? StudioVault.write("token",nil) }
            let message=(try? JSONSerialization.jsonObject(with:data)) as? [String:Any]
            throw StudioAPIError(message:message?["error"] as? String ?? "Online Studio is unavailable. Your inquiry is unaffected.")
        }
        return data
    }
    func verify(email: String, code: String) async throws {
        let data=try await request("verify_code",fields:["email":email,"code":code],authenticated:false)
        guard let json=try JSONSerialization.jsonObject(with:data) as? [String:Any], let token=json["access_token"] as? String else { throw StudioAPIError(message:"Verification could not be confirmed.") }
        try StudioVault.write("token",Data(token.utf8))
    }
    func projects() async throws -> [StudioProject] {
        struct Response: Decodable { var projects: [StudioProject] }
        return try JSONDecoder().decode(Response.self,from:await request("list")).projects
    }
    func load(_ id: String) async throws -> StudioEnvelope { try JSONDecoder().decode(StudioEnvelope.self,from:await request("get",fields:["inquiry_id":id])) }
    func save(_ draft: StudioDraft, id: String, revision: Int, submit: Bool) async throws -> RemoteStudio {
        struct Response: Decodable { var studio: RemoteStudio }
        let links=draft.references.map { ["url":$0.url,"note":$0.note] }
        return try JSONDecoder().decode(Response.self,from:await request(submit ? "submit":"save",fields:["inquiry_id":id,"revision":revision,"answers":draft.answers,"links":links])).studio
    }
    func upload(id: String, assetID: String, bytes: Data, mime: String, purpose: String, note: String) async throws {
        let boundary="LINART-\(UUID().uuidString)"
        var request=URLRequest(url:endpoint); request.httpMethod="POST"; try authorize(&request)
        request.setValue("multipart/form-data; boundary=\(boundary)",forHTTPHeaderField:"Content-Type")
        var body=Data()
        for (key,value) in ["action":"upload","inquiry_id":id,"asset_id":assetID.lowercased(),"purpose":purpose,"note":note] {
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"\r\n\r\n\(value)\r\n".utf8))
        }
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"file\"; filename=\"attachment\"\r\nContent-Type: \(mime)\r\n\r\n".utf8)); body.append(bytes); body.append(Data("\r\n--\(boundary)--\r\n".utf8)); request.httpBody=body
        _ = try await perform(request)
    }
}

@MainActor
final class StudioConnection: ObservableObject {
    @Published var projects: [StudioProject] = []
    @Published var notice: String?
    @Published var busy=false
    func refresh() async {
        busy=true; defer { busy=false }
        do { projects=try await StudioClient().projects(); notice=nil }
        catch { notice=error.localizedDescription }
    }
}
