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
    func testPodcast_decodesWithRequiredFields() throws {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            {
              "id": "abc123",
              "title": "Swift Over Coffee",
              "publisher": "Paul Hudson",
              "thumbnail": "https://example.com/thumb.jpg",
              "image": "https://example.com/image.jpg",
              "description": "A podcast about Swift programming"
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
        XCTAssertEqual(pod?.image, "https://example.com/image.jpg")
        XCTAssertEqual(pod?.description, "A podcast about Swift programming")
    }

    func testBestPodcastsResponse_decodesWithPodcastsArray_hasNextAndCount() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            { "id": "1", "title": "A", "publisher": "P" },
            { "id": "2", "title": "B", "publisher": "Q" }
          ]
        }
        """)

        let res = try? JSONDecoder().decode(BestPodcastsResponse.self, from: json)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.hasNext, true)
        XCTAssertEqual(res?.podcasts.count, 2)
    }

    // MARK: - Optional Fields
    func testPodcast_decodes_whenOptionalFieldsMissing() throws {
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
        let pod = res?.podcasts.first

        XCTAssertNotNil(pod)
        XCTAssertNil(pod?.thumbnail)
        XCTAssertNil(pod?.image)
        XCTAssertNil(pod?.description)
    }

    func testPodcast_decodes_whenOnlyThumbnailPresent() throws {
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

        XCTAssertNotNil(pod)
        XCTAssertEqual(pod?.thumbnail, "https://example.com/thumb.jpg")
        XCTAssertNil(pod?.image)
        XCTAssertNil(pod?.description)
    }

    // MARK: - URL Convenience Properties
    func testPodcast_thumbnailURL_returnsValidURL() {
        let podcast = Podcast(
            id: "test",
            title: "Test",
            publisher: "Test",
            thumbnail: "https://example.com/thumb.jpg",
            image: nil,
            description: nil
        )
        
        XCTAssertEqual(podcast.thumbnailURL?.absoluteString, "https://example.com/thumb.jpg")
    }

    func testPodcast_imageURL_returnsValidURL() {
        let podcast = Podcast(
            id: "test",
            title: "Test",
            publisher: "Test",
            thumbnail: nil,
            image: "https://example.com/image.jpg",
            description: nil
        )
        
        XCTAssertEqual(podcast.imageURL?.absoluteString, "https://example.com/image.jpg")
    }
    
    // MARK: - Errors
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

    func testPodcast_decodingFails_whenIdIsWhitespaceOnly() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            { "id": "   \t\n", "title": "Swift Over Coffee", "publisher": "Paul Hudson" }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

    func testPodcast_decodingFails_whenTitleIsWhitespaceOnly() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": [
            { "id": "abc123", "title": "   \t\n", "publisher": "Paul Hudson" }
          ]
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

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

    func testBestPodcastsResponse_failsOnInvalidTopLevelShape_whenPodcastsIsObject() {
        let json = data("""
        {
          "has_next": true,
          "podcasts": { "id": "abc123", "title": "T", "publisher": "P" }
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }

    func testBestPodcastsResponse_failsOnInvalidTopLevelShape_whenPodcastsMissing() {
        let json = data("""
        {
          "has_next": true
        }
        """)

        XCTAssertThrowsError(try JSONDecoder().decode(BestPodcastsResponse.self, from: json))
    }
}
