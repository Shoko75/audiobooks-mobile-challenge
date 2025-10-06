//
//  PodcastsRepositoryTests.swift
//  PodcastsAppTests
//
//  Created by Shoko Hashimoto on 2025-10-06.
//

import XCTest
@testable import PodcastsApp

final class PodcastsRepositoryTests: XCTestCase {

	// MARK: - Mocks
	private final class MockAPIClient: PodcastAPIClientProtocol {
		struct PageResult {
			var result: Result<BestPodcastsResponse, NetworkError>
		}

		// Configure per-page behavior
		var pages: [Int: PageResult] = [:]

		func fetchBestPodcasts(page: Int) async throws -> BestPodcastsResponse {
			if let configured = pages[page] {
				switch configured.result {
				case .success(let response): return response
				case .failure(let err): throw err
				}
			}
			// Default: 20 items
			return BestPodcastsResponse(hasNext: true, podcasts: Self.makePodcasts(count: 20, page: page))
		}

		static func makePodcasts(count: Int, page: Int) -> [Podcast] {
			(0..<count).map { idx in
				// Allow duplicates across pages by repeating ids if desired:
				let id = "p\(page)-\(idx)" // Different per page; change to "\(idx)" to simulate dupes
				return Podcast(id: id,
							   title: "Title \(id)",
							   publisher: "Publisher \(id)",
							   thumbnail: nil,
							   image: nil,
							   description: nil)
			}
		}
	}

	private final class MockFavorites: FavoritesManagerProtocol {
		private var set: Set<String> = []
		func addFavorite(podcastId: String) { set.insert(podcastId) }
		func removeFavorite(podcastId: String) { set.remove(podcastId) }
		func toggleFavorite(podcastId: String) {
			if set.contains(podcastId) {
				set.remove(podcastId)
			} else {
				set.insert(podcastId)
			}
		}
		func isFavorite(podcastId: String) -> Bool { set.contains(podcastId) }
	}

	// MARK: - Helpers
	private func makeSUT() -> (PodcastsRepository, MockAPIClient, MockFavorites) {
		let api = MockAPIClient()
		let fav = MockFavorites()
		let sut = PodcastsRepository(apiClient: api, favorites: fav)
		return (sut, api, fav)
	}

	// MARK: - Tests
	func test_loadInitial_success_fetchesPage1_andSets20Items() async {
		let (sut, api, _) = makeSUT()
		// Default mock returns 20 items
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 1))))
		XCTAssertEqual(sut.items.count, 0)
		XCTAssertFalse(sut.isLoadingInitial)

		await sut.loadInitial()

		XCTAssertFalse(sut.isLoadingInitial)
		XCTAssertNil(sut.lastError)
		XCTAssertEqual(sut.items.count, 20)
		XCTAssertTrue(sut.hasMore) // since response had items
	}

	func test_loadMore_success_fetchesNextPage_andAppends20() async {
		let (sut, api, _) = makeSUT()
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 1))))
		api.pages[2] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 2))))

		await sut.loadInitial()
		XCTAssertEqual(sut.items.count, 20)

		await sut.loadMore()
		XCTAssertNil(sut.lastError)
		XCTAssertEqual(sut.items.count, 40) // append another 20
		XCTAssertTrue(sut.hasMore)
	}

	func test_loadMore_whileAlreadyLoading_isNoop() async {
		let (sut, api, _) = makeSUT()
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 1))))
		api.pages[2] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 2))))

		await sut.loadInitial()
		XCTAssertEqual(sut.items.count, 20)

		// Simulate overlap: kick off loadMore twice; only the first should run
		await withTaskGroup(of: Void.self) { group in
			group.addTask { await sut.loadMore() }
			group.addTask { await sut.loadMore() }
		}

		// Only one page should have been added
		XCTAssertEqual(sut.items.count, 40)
		XCTAssertNil(sut.lastError)
	}
	
	func test_loadMore_failure_preservesItems_andSetsError() async {
		let (sut, api, _) = makeSUT()
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 1))))
		api.pages[2] = .init(result: .failure(.serverError(500)))

		await sut.loadInitial()
		XCTAssertEqual(sut.items.count, 20)

		await sut.loadMore()

		// Items preserved, error set
		XCTAssertEqual(sut.items.count, 20)
		XCTAssertNotNil(sut.lastError)
		// Still can try to load more again later
	}

	func test_loadInitial_empty_setsEmptyState() async {
		let (sut, api, _) = makeSUT()
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: false,
																   podcasts: []))) // simulate empty page 1

		await sut.loadInitial()

		XCTAssertEqual(sut.items.count, 0)
		XCTAssertFalse(sut.isLoadingInitial)
		XCTAssertNil(sut.lastError)
		XCTAssertFalse(sut.hasMore)
	}

	func test_retryInitial_afterFailure_attemptsAgain() async {
		let (sut, api, _) = makeSUT()
		api.pages[1] = .init(result: .failure(.noInternet))

		await sut.loadInitial()
		XCTAssertNotNil(sut.lastError)
		XCTAssertEqual(sut.items.count, 0)

		// Fix and retry
		api.pages[1] = .init(result: .success(BestPodcastsResponse(hasNext: true,
																   podcasts: MockAPIClient.makePodcasts(count: 20, page: 1))))
		await sut.retryInitial()

		XCTAssertNil(sut.lastError)
		XCTAssertEqual(sut.items.count, 20)
		XCTAssertTrue(sut.hasMore)
	}

	func test_favorites_passthrough_isFavoriteAndToggle() async {
		let (sut, _, _) = makeSUT()
		XCTAssertFalse(sut.isFavorite(id: "id1"))
		sut.toggleFavorite(id: "id1")
		XCTAssertTrue(sut.isFavorite(id: "id1"))
		sut.toggleFavorite(id: "id1")
		XCTAssertFalse(sut.isFavorite(id: "id1"))
	}
}
