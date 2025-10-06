//
//  PodcastAPIClientTests.swift
//  PodcastsAppTests
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import XCTest
@testable import PodcastsApp

// MARK: - URLProtocol Stub
final class URLProtocolStub: URLProtocol {
    struct Stub { let data: Data?; let response: HTTPURLResponse?; let error: Error? }
    static var requestHandler: ((URLRequest) -> Stub)?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = URLProtocolStub.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            client?.urlProtocolDidFinishLoading(self)
            return
        }
        let stub = handler(request)
        if let response = stub.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub.data {
            client?.urlProtocol(self, didLoad: data)
        }
        if let error = stub.error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: - Tests
final class PodcastAPIClientTests: XCTestCase {
    private var session: URLSession!
    private let baseURL = URL(string: "https://listen-api-test.listennotes.com/api/v2")!

    override func setUp() {
        super.setUp()
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        session = URLSession(configuration: config)
    }

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        session = nil
        super.tearDown()
    }

    // MARK: - Helper Methods
    private func expectNetworkError<T>(_ expression: @escaping () async throws -> T, expectedError: NetworkError, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await expression()
            XCTFail("Expected \(expectedError)", file: file, line: line)
        } catch let error as NetworkError {
            XCTAssertEqual(error, expectedError, file: file, line: line)
        } catch {
            XCTFail("Expected NetworkError, got \(error)", file: file, line: line)
        }
    }

    // MARK: - Success Cases
    func test_fetchBestPodcasts_success_decodesResponse() async throws {
        let body = """
        { "has_next": true, "podcasts": [
          { "id": "1", "title": "A", "publisher": "P" }
        ] }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .init(data: body, response: response, error: nil)
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        let result = try await sut.fetchBestPodcasts(page: 1)
        XCTAssertEqual(result.hasNext, true)
        XCTAssertEqual(result.podcasts.count, 1)
        XCTAssertEqual(result.podcasts.first?.id, "1")
    }

    func test_fetchBestPodcasts_success_withPagination() async throws {
        let body = """
        { "has_next": false, "podcasts": [
          { "id": "1", "title": "A", "publisher": "P" },
          { "id": "2", "title": "B", "publisher": "Q" }
        ] }
        """.data(using: .utf8)!

        URLProtocolStub.requestHandler = { request in
            // Verify page parameter is included
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            XCTAssertTrue(components?.queryItems?.contains(where: { $0.name == "page" && $0.value == "2" }) == true)
            
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .init(data: body, response: response, error: nil)
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        let result = try await sut.fetchBestPodcasts(page: 2)
        XCTAssertEqual(result.hasNext, false)
        XCTAssertEqual(result.podcasts.count, 2)
    }

    // MARK: - Error Cases
    func test_fetchBestPodcasts_serverError_throwsNetworkError() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return .init(data: Data(), response: response, error: nil)
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        await expectNetworkError({ try await sut.fetchBestPodcasts(page: 1) }, expectedError: .serverError(500))
    }

    func test_fetchBestPodcasts_invalidJSON_throwsNetworkError() async {
        URLProtocolStub.requestHandler = { request in
            let data = Data("invalid json".utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .init(data: data, response: response, error: nil)
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        await expectNetworkError({ try await sut.fetchBestPodcasts(page: 1) }, expectedError: .invalidData)
    }

    func test_fetchBestPodcasts_noInternet_throwsNetworkError() async {
        URLProtocolStub.requestHandler = { request in
            return .init(data: nil, response: nil, error: URLError(.notConnectedToInternet))
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        await expectNetworkError({ try await sut.fetchBestPodcasts(page: 1) }, expectedError: .noInternet)
    }

    func test_fetchBestPodcasts_timeout_throwsNetworkError() async {
        URLProtocolStub.requestHandler = { request in
            return .init(data: nil, response: nil, error: URLError(.timedOut))
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        await expectNetworkError({ try await sut.fetchBestPodcasts(page: 1) }, expectedError: .timeout)
    }

    // MARK: - URL Building Tests
    func test_fetchBestPodcasts_buildsCorrectURL() async {
        URLProtocolStub.requestHandler = { request in
            let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
            XCTAssertEqual(components?.path, "best_podcasts")
            XCTAssertTrue(components?.queryItems?.contains(where: { $0.name == "page" && $0.value == "3" }) == true)
            
            let body = Data("{\"has_next\": false, \"podcasts\": []}".utf8)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return .init(data: body, response: response, error: nil)
        }

        let sut = PodcastAPIClient(session: session, baseURL: baseURL)
        _ = try? await sut.fetchBestPodcasts(page: 3)
    }
}
