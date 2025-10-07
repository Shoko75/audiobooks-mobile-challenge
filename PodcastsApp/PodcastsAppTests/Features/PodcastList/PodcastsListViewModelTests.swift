//
//  PodcastsListViewModelTests.swift
//  PodcastsAppTests
//
//  Created by Shoko Hashimoto on 2025-10-06.
//

import XCTest
@testable import PodcastsApp

/// Unit tests for `PodcastsListViewModel`.
/// Verifies first-load, load-more triggers, error/empty states, and retry behavior.
final class PodcastsListViewModelTests: XCTestCase {

	// MARK: - Mocks
	/// In-memory repository double allowing per-call success/failure control.
	private final class MockRepository: PodcastsRepositoryProtocol {
		// State mirrored to ViewModel
		var items: [Podcast] = []
		var isLoadingInitial = false
		var isLoadingMore = false
		var hasMore = true
		var lastError: NetworkError?

		// Controls for next calls
		var nextInitialResult: Result<[Podcast], NetworkError> = .success([])
		var nextMoreResult: Result<[Podcast], NetworkError> = .success([])

		func loadInitial() async {
			isLoadingInitial = true
			lastError = nil
			defer { isLoadingInitial = false }
			switch nextInitialResult {
			case .success(let page):
				items = page
				hasMore = !page.isEmpty
			case .failure(let err):
				lastError = err
			}
		}

		func loadMore() async {
			guard hasMore, !isLoadingMore else { return }
			isLoadingMore = true
			lastError = nil
			defer { isLoadingMore = false }
			switch nextMoreResult {
			case .success(let page):
				items.append(contentsOf: page)
				hasMore = !page.isEmpty
			case .failure(let err):
				lastError = err
			}
		}

		func retryInitial() async { await loadInitial() }

		func isFavorite(id: String) -> Bool { false }
		func toggleFavorite(id: String) { }
	}

	// MARK: - Helpers
	/// Builds a page of synthetic podcasts for testing.
	private func makePodcasts(count: Int, page: Int = 1) -> [Podcast] {
		(0..<count).map { idx in
			let id = "p\(page)-\(idx)"
			return Podcast(id: id, title: "T \(id)", publisher: "P \(id)", thumbnail: nil, image: nil, description: nil)
		}
	}

	// MARK: - Tests
	@MainActor
	func test_onAppear_loadsFirstPage_setsItemsAndStopsLoading() async {
		let repo = MockRepository()
		repo.nextInitialResult = .success(makePodcasts(count: 20, page: 1))
		let vm = PodcastsListViewModel(repository: repo)

		await vm.onAppear()

		XCTAssertEqual(vm.items.count, 20)
		XCTAssertFalse(vm.isLoadingInitial)
		XCTAssertNil(vm.errorMessage)
		XCTAssertFalse(vm.isEmpty)
		XCTAssertTrue(vm.hasMore)
	}

	@MainActor
	func test_nearEndThreshold_triggersLoadMore_andAppends() async {
		let repo = MockRepository()
		repo.nextInitialResult = .success(makePodcasts(count: 20, page: 1))
		let vm = PodcastsListViewModel(repository: repo, nearEndThreshold: 5)

		await vm.onAppear()
		XCTAssertEqual(vm.items.count, 20)

		repo.nextMoreResult = .success(makePodcasts(count: 20, page: 2))
		let triggerItem = vm.items[vm.items.count - 1] // last row triggers
		await vm.loadMoreIfNeeded(currentItem: triggerItem)

		XCTAssertEqual(vm.items.count, 40)
		XCTAssertNil(vm.errorMessage)
	}

	@MainActor
	func test_initialError_showsError_andRetryLoads() async {
		let repo = MockRepository()
		repo.nextInitialResult = .failure(.noInternet)
		let vm = PodcastsListViewModel(repository: repo)

		await vm.onAppear()
		XCTAssertNotNil(vm.errorMessage)
		XCTAssertTrue(vm.items.isEmpty)

		repo.nextInitialResult = .success(makePodcasts(count: 20, page: 1))
		await vm.retryInitial()

		XCTAssertNil(vm.errorMessage)
		XCTAssertEqual(vm.items.count, 20)
		XCTAssertFalse(vm.isEmpty)
	}

	@MainActor
	func test_loadMoreError_preservesItems_andExposesError() async {
		let repo = MockRepository()
		repo.nextInitialResult = .success(makePodcasts(count: 20, page: 1))
		let vm = PodcastsListViewModel(repository: repo)

		await vm.onAppear()
		XCTAssertEqual(vm.items.count, 20)

		repo.nextMoreResult = .failure(.serverError(500))
		let triggerItem = vm.items[vm.items.count - 1]
		await vm.loadMoreIfNeeded(currentItem: triggerItem)

		XCTAssertEqual(vm.items.count, 20)
		XCTAssertNotNil(vm.errorMessage)
	}

	@MainActor
	func test_emptyInitial_setsEmptyState() async {
		let repo = MockRepository()
		repo.nextInitialResult = .success([])
		let vm = PodcastsListViewModel(repository: repo)

		await vm.onAppear()

		XCTAssertTrue(vm.items.isEmpty)
		XCTAssertTrue(vm.isEmpty)
		XCTAssertNil(vm.errorMessage)
		XCTAssertFalse(vm.isLoadingInitial)
		XCTAssertFalse(vm.hasMore)
	}
}
