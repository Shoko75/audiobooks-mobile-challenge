//
//  PodcastDetailViewModelTests.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-07.
//

import XCTest
@testable import PodcastsApp

/// Tests for `PodcastDetailViewModel`, ensuring it exposes view-ready
/// properties, handles favorite state, and provides robust fallbacks.
final class PodcastDetailViewModelTests: XCTestCase {

    // MARK: - Mocks
    /// Minimal repository mock that supports favorite state for isolation.
    private final class MockRepository: PodcastsRepositoryProtocol {
        var items: [Podcast] = []
        var isLoadingInitial: Bool = false
        var isLoadingMore: Bool = false
        var hasMore: Bool = false
        var lastError: NetworkError?

        private var favoriteIds: Set<String> = []

        func loadInitial() async { }
        func loadMore() async { }
        func retryInitial() async { }

        func isFavorite(id: String) -> Bool { favoriteIds.contains(id) }
        func toggleFavorite(id: String) {
            if favoriteIds.contains(id) {
                favoriteIds.remove(id)
            } else {
                favoriteIds.insert(id)
            }
        }
    }

    // MARK: - Helpers
    /// Convenience factory for a `Podcast` used by tests.
    private func makePodcast(
        id: String = "id-1",
        title: String = "Title",
        publisher: String = "Publisher",
        thumbnail: String? = "https://example.com/thumb.jpg",
        image: String? = "https://example.com/large.jpg",
        description: String? = "Some description"
    ) -> Podcast {
        Podcast(id: id, title: title, publisher: publisher, thumbnail: thumbnail, image: image, description: description)
    }

    // MARK: - Tests
    @MainActor
    func test_init_setsFieldsFromPodcast() async {
        let repo = MockRepository()
        let podcast = makePodcast()
        let sut = PodcastDetailViewModel(podcast: podcast, repository: repo)

        XCTAssertEqual(sut.title, podcast.title)
        XCTAssertEqual(sut.publisher, podcast.publisher)
        XCTAssertEqual(sut.descriptionText, "Some description")
        XCTAssertEqual(sut.imageURL, podcast.imageURL)
        XCTAssertFalse(sut.isFavorite)
    }

    @MainActor
    func test_toggleFavorite_togglesStateAndPersists() async {
        let repo = MockRepository()
        let podcast = makePodcast(id: "abc")
        let sut = PodcastDetailViewModel(podcast: podcast, repository: repo)

        XCTAssertFalse(sut.isFavorite)
        sut.toggleFavorite()
        XCTAssertTrue(sut.isFavorite)
        sut.toggleFavorite()
        XCTAssertFalse(sut.isFavorite)
    }

    @MainActor
    func test_description_emptyShowsFallback() async {
        let repo = MockRepository()
        let podcastNil = makePodcast(description: nil)
        let sutNil = PodcastDetailViewModel(podcast: podcastNil, repository: repo)
        XCTAssertEqual(sutNil.descriptionText, "No description available.")

        let podcastEmpty = makePodcast(description: "   \n\t  ")
        let sutEmpty = PodcastDetailViewModel(podcast: podcastEmpty, repository: repo)
        XCTAssertEqual(sutEmpty.descriptionText, "No description available.")
    }

    @MainActor
    func test_imageURL_prefersLargeOverThumbnail() async {
        let repo = MockRepository()
        let podcast = makePodcast(
            thumbnail: "https://example.com/thumb.jpg",
            image: "https://example.com/large.jpg"
        )
        let sut = PodcastDetailViewModel(podcast: podcast, repository: repo)

        XCTAssertEqual(sut.imageURL, podcast.imageURL)
    }

    // MARK: - HTML Stripping Tests
    @MainActor
    func test_description_stripsHTMLAndDecodesEntities() async {
        let repo = MockRepository()
        let htmlDescription = "<p>This is a <strong>bold</strong> description with &amp; entities &quot;quoted&quot;.</p>"
        let podcast = makePodcast(description: htmlDescription)
        let sut = PodcastDetailViewModel(podcast: podcast, repository: repo)

        XCTAssertEqual(sut.descriptionText, "This is a bold description with & entities \"quoted\".")
    }

    @MainActor
    func test_description_handlesEmptyHTML() async {
        let repo = MockRepository()
        let emptyHTML = "<p></p><br><div>&nbsp;</div>"
        let podcast = makePodcast(description: emptyHTML)
        let sut = PodcastDetailViewModel(podcast: podcast, repository: repo)

        XCTAssertEqual(sut.descriptionText, "No description available.")
    }
}


