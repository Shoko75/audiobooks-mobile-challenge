//
//  PodcastTests.swift
//  PodcastsAppTests
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import XCTest
@testable import PodcastsApp

final class PodcastTests: XCTestCase {

    // MARK: - Helpers
    private func data(_ json: String) -> Data { json.data(using: .utf8)! }

    // MARK: - Happy Path
    // Valid decoding
    func testPodcast_decodesWithRequiredFields() throws {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson",
              "thumbnail": "https://example.com/thumb.jpg"
            }
          ]
        }
        """)

        let res = try? JSONDecoder().decode(BestPodcastsResponse.self, from: json)
        let pod = res?.podcasts.first

        XCTAssertNotNil(res)
        XCTAssertEqual(res?.hasNext, true)
        XCTAssertNotNil(pod)
        XCTAssertEqual(pod?.id, "abc123")
        XCTAssertEqual(pod?.title, "Swift Over Coffee")
        XCTAssertEqual(pod?.publisher, "Paul Hudson")
        XCTAssertEqual(pod?.thumbnail, "https://example.com/thumb.jpg")
    }

    // MARK: - Errors
    // Missing fields (required keys)
    func testPodcast_decodingFails_whenMissingId() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson",
              "thumbnail": "https://example.com/thumb.jpg"
            }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json)) { err in
            guard case let DecodingError.keyNotFound(key, _) = err else {
                return XCTFail("Expected keyNotFound, got \(err)")
            }
            XCTAssertEqual(key.stringValue, "id")
        }
    }

    func testPodcast_decodingFails_whenMissingTitle() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "publisher": "Paul Hudson",
              "thumbnail": "https://example.com/thumb.jpg"
            }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json)) { err in
            guard case let DecodingError.keyNotFound(key, _) = err else {
                return XCTFail("Expected keyNotFound, got \(err)")
            }
            XCTAssertEqual(key.stringValue, "title")
        }
    }

    // Empty or invalid values (business validation)
    func testPodcast_decodingFails_whenIdIsEmpty() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "",
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson"
            }
          ]
        }
        """)

        // Expect your custom validation to throw (e.g., DecodingError.dataCorrupted)
        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

    func testPodcast_decodingFails_whenTitleIsEmpty() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "title": "",
              "publisher": "Paul Hudson"
            }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

    // Unknown fields (should be ignored)
    func testPodcast_decodes_whenUnknownFieldsPresent() throws {
        let json = data("""
        {
          "has_next": false,
          "podcasts": [
            {
              "id": "abc123",
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson",
              "randomFlag": true,
              "anotherUnknown": "value"
            }
          ],
          "top_level_unknown": 42
        }
        """)

        let res = try? JSONDecoder().decode(BestPodcastsResponse.self, from: json)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.hasNext, false)
        XCTAssertEqual(res?.podcasts.first?.id, "abc123")
    }

    // Type mismatches(id is number)
    func testPodcast_decodingFails_whenIdIsNumberNotString() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": 123,
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson"
            }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

    // Thumbnail URL optionality
    func testPodcast_decodes_whenThumbnailIsMissing() throws {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson"
            }
          ]
        }
        """)

        let res = try? JSONDecoder().decode(BestPodcastsResponse.self, from: json)
        XCTAssertNotNil(res)
        XCTAssertNil(res?.podcasts.first?.thumbnail)
    }

    func testPodcast_decodingFails_whenPublisherMissing_ifRequired() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "title": "Swift Over Coffee"
            }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json)) { err in
            guard case let DecodingError.keyNotFound(key, _) = err else {
                return XCTFail("Expected keyNotFound, got \(err)")
            }
            XCTAssertEqual(key.stringValue, "publisher")
        }
    }
}
