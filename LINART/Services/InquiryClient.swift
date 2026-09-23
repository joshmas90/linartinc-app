import Foundation

struct InquiryResponse: Decodable {
    let ok: Bool
    let error: String?
    let fields: [String: String]?
    let inquiry_id: String?
    let receipt: String?
    let studio_available: Bool?
}

enum InquiryError: LocalizedError {
    case rejected(String, [String: String])
    case unconfirmed

    var errorDescription: String? {
        switch self {
        case let .rejected(message, _): return message
        case .unconfirmed:
            return "Delivery could not be confirmed. Your details are still here. Contact LINART before sending again to avoid a duplicate inquiry."
        }
    }
}

struct InquiryClient {
    let session: URLSession
    let endpoint: URL

    init(session: URLSession? = nil, endpoint: URL = Company.inquiryEndpoint) {
        if let session {
            self.session = session
        } else {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.timeoutIntervalForRequest = 20
            configuration.timeoutIntervalForResource = 30
            configuration.httpCookieAcceptPolicy = .never
            configuration.httpShouldSetCookies = false
            self.session = URLSession(configuration: configuration)
        }
        self.endpoint = endpoint
    }

    @discardableResult
    func send(_ inquiry: Inquiry) async throws -> InquiryResponse {
        let errors = inquiry.validationErrors
        guard errors.isEmpty else {
            throw InquiryError.rejected("Please review the highlighted fields.", errors)
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = try JSONEncoder().encode(inquiry.normalized)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw InquiryError.unconfirmed
        }
        guard let httpResponse = response as? HTTPURLResponse,
              let result = try? JSONDecoder().decode(InquiryResponse.self, from: data) else {
            throw InquiryError.unconfirmed
        }
        if httpResponse.statusCode >= 500 || httpResponse.statusCode == 409 { throw InquiryError.unconfirmed }
        guard (200..<300).contains(httpResponse.statusCode), result.ok else {
            throw InquiryError.rejected(
                result.error ?? "Delivery could not be confirmed. Call or email LINART for help.",
                result.fields ?? [:]
            )
        }
        return result
    }
}
