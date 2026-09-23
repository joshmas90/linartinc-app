import XCTest
@testable import LINART

final class InquiryURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let status: Int
        let payload: String
        switch path {
        case "/success": status = 200; payload = #"{"ok":true}"#
        case "/invalid": status = 422; payload = #"{"ok":false,"error":"Invalid email","fields":{"email":"Please check your email."}}"#
        case "/rate-limit": status = 429; payload = #"{"ok":false,"error":"Please wait before sending again."}"#
        case "/false-success": status = 200; payload = #"{"ok":false}"#
        case "/server-error": status = 500; payload = #"{"ok":true}"#
        case "/offline":
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        default: status = 200; payload = "<html>Unexpected response</html>"
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(payload.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

final class InquiryClientTests: XCTestCase {
    private func client(path: String) -> InquiryClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [InquiryURLProtocol.self]
        return InquiryClient(session: URLSession(configuration: configuration), endpoint: URL(string: "https://example.invalid/\(path)")!)
    }

    private var inquiry: Inquiry {
        Inquiry(name: "Test Homeowner", email: "test@example.com", phone: "6095550100", city: "08000")
    }

    func testSuccessRequiresHTTPAndPayloadSuccess() async throws {
        try await client(path: "success").send(inquiry)
        for path in ["false-success", "server-error", "rate-limit", "malformed", "offline"] {
            do {
                try await client(path: path).send(inquiry)
                XCTFail("Expected failure for \(path)")
            } catch { XCTAssertTrue(error is InquiryError) }
        }
    }

    func testServerFieldErrorsArePreserved() async {
        do {
            try await client(path: "invalid").send(inquiry)
            XCTFail("Expected validation failure")
        } catch InquiryError.rejected(let message, let fields) {
            XCTAssertEqual(message, "Invalid email")
            XCTAssertEqual(fields["email"], "Please check your email.")
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    func testInvalidInquiryIsRejectedBeforeNetwork() async {
        do {
            try await client(path: "success").send(Inquiry())
            XCTFail("Expected local validation failure")
        } catch InquiryError.rejected(_, let fields) {
            XCTAssertEqual(fields.count, 4)
        } catch { XCTFail("Unexpected error: \(error)") }
    }
}
