import Foundation

struct InquiryResponse: Decodable {
    let ok: Bool
    let error: String?
    let fields: [String: String]?
}

enum InquiryError: LocalizedError {
    case rejected(String, [String: String])
    case unconfirmed
    case offline
    case rateLimited(Date)

    var errorDescription: String? {
        switch self {
        case let .rejected(message, _): return message
        case .offline: return "You appear to be offline. Your details are still here. Reconnect, then try again."
        case .rateLimited(let date): return "Please wait until \(date.formatted(date: .omitted, time: .shortened)) before sending again."
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

    func send(_ inquiry: Inquiry) async throws {
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
        } catch let error as URLError where error.code == .notConnectedToInternet || error.code == .cannotFindHost {
            throw InquiryError.offline
        } catch is CancellationError { throw CancellationError()
        } catch {
            throw InquiryError.unconfirmed
        }
        if let response = response as? HTTPURLResponse, response.statusCode == 429 {
            let value = response.value(forHTTPHeaderField: "Retry-After") ?? "60"
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            let date = TimeInterval(value).map { Date().addingTimeInterval(max(1, $0)) } ?? formatter.date(from: value) ?? Date().addingTimeInterval(60)
            throw InquiryError.rateLimited(date)
        }
        guard let httpResponse = response as? HTTPURLResponse,
              let result = try? JSONDecoder().decode(InquiryResponse.self, from: data) else {
            throw InquiryError.unconfirmed
        }
        guard (200..<300).contains(httpResponse.statusCode), result.ok else {
            throw InquiryError.rejected(
                result.error ?? "Delivery could not be confirmed. Call or email LINART for help.",
                result.fields ?? [:]
            )
        }
    }
}
