//
//  PodcastsRepository.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-06.
//
import Foundation

/// Defines repository operations for fetching and managing podcast lists.
protocol PodcastsRepositoryProtocol {
	/// Current aggregated list of podcasts.
	var items: [Podcast] { get }
	/// Indicates initial page load is in progress.
	var isLoadingInitial: Bool { get }
	/// Indicates incremental page load is in progress.
	var isLoadingMore: Bool { get }
	/// Indicates whether more pages can be fetched.
	var hasMore: Bool { get }
	/// Last error encountered during a load, if any.
	var lastError: NetworkError? { get }

	/// Loads the first page (page 1). Resets existing items on success.
	func loadInitial() async
	/// Loads the next page and appends to `items`.
	func loadMore() async
	/// Retries the initial load after an error.
	func retryInitial() async

	/// Returns whether a podcast is currently favorited.
	/// - Parameter id: Unique podcast identifier.
	func isFavorite(id: String) -> Bool
	/// Toggles favorite state for a podcast.
	/// - Parameter id: Unique podcast identifier.
	func toggleFavorite(id: String)
}

/// Repository that composes a podcast API client and favorites manager,
/// providing pagination (20 per page, duplicates allowed) and basic state.
final class PodcastsRepository: PodcastsRepositoryProtocol {

	// MARK: - Public (read-only) state
	private(set) var items: [Podcast] = []
	private(set) var isLoadingInitial: Bool = false
	private(set) var isLoadingMore: Bool = false
	private(set) var hasMore: Bool = true
	private(set) var lastError: NetworkError?

	// MARK: - Dependencies
	private let apiClient: PodcastAPIClientProtocol
	private let favorites: FavoritesManagerProtocol

	// MARK: - Pagination bookkeeping
	private var currentPage: Int = 0

	// Single-flight guard to prevent overlapping loadMore requests
	private var loadMoreTask: Task<Void, Never>?
	
	// Serial queue for atomic check-and-set operations
	private let loadMoreQueue = DispatchQueue(label: "com.podcasts.loadMore", qos: .userInitiated)

	// MARK: - Init
	/// Initializes the repository with its dependencies.
	/// - Parameters:
	///   - apiClient: Networking client to fetch podcasts per page.
	///   - favorites: Favorites persistence component.
	init(apiClient: PodcastAPIClientProtocol, favorites: FavoritesManagerProtocol) {
		self.apiClient = apiClient
		self.favorites = favorites
	}

	// MARK: - Loading
	/// Loads the first page (page 1). Resets items on success.
	func loadInitial() async {
		guard !isLoadingInitial else { return }
		isLoadingInitial = true
		lastError = nil

		defer { isLoadingInitial = false }

		do {
			let response = try await apiClient.fetchBestPodcasts(page: 1)
			items = response.podcasts
			currentPage = 1
			// The mock API repeats the same 20 items per page; still expose "more"
			// so UI can demonstrate pagination behavior.
			hasMore = !response.podcasts.isEmpty
		} catch {
			lastError = map(error)
		}
	}

	/// Loads the next page and appends to `items`.
	func loadMore() async {
		guard hasMore else { return }
		
		// Atomic single-flight guard using serial queue
		await withCheckedContinuation { continuation in
			loadMoreQueue.async { [weak self] in
				guard let self = self else {
					continuation.resume()
					return
				}
				
				// Check if already loading
				guard self.loadMoreTask == nil else {
					continuation.resume()
					return
				}
				
				// Claim the task slot
				self.loadMoreTask = Task { [weak self] in
					guard let self = self else { return }
					self.isLoadingMore = true
					self.lastError = nil
					defer {
						self.isLoadingMore = false
						self.loadMoreTask = nil
					}

					do {
						let nextPage = self.currentPage + 1
						let response = try await self.apiClient.fetchBestPodcasts(page: nextPage)
						self.items.append(contentsOf: response.podcasts) // duplicates allowed
						self.currentPage = nextPage
						self.hasMore = !response.podcasts.isEmpty
					} catch {
						self.lastError = self.map(error)
					}
				}
				
				continuation.resume()
			}
		}
		
		await loadMoreTask?.value
	}

	/// Retries the initial load after an error.
	func retryInitial() async {
		await loadInitial()
	}

	// MARK: - Favorites
	func isFavorite(id: String) -> Bool {
		favorites.isFavorite(podcastId: id)
	}

	func toggleFavorite(id: String) {
		favorites.toggleFavorite(podcastId: id)
	}

	// MARK: - Error mapping
	private func map(_ error: Error) -> NetworkError {
		if let e = error as? NetworkError { return e }
		return .unknown(error)
	}
}
