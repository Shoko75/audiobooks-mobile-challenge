//
//  PodcastsListViewModel.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-06.
//
import Foundation

/// ViewModel that exposes a paginated list of podcasts and UI-ready state.
/// - Fetches 20 items per page via `PodcastsRepositoryProtocol`.
/// - Triggers incremental loading when the user scrolls near the end.
/// - Surfaces loading, empty, and error states suitable for SwiftUI rendering.
@MainActor
final class PodcastsListViewModel: ObservableObject {
	// Inputs
	private let repository: PodcastsRepositoryProtocol
	private let nearEndThreshold: Int

	// Outputs
	/// Aggregated list of podcasts for display.
	@Published private(set) var items: [Podcast] = []
	/// True while the first page is loading.
	@Published private(set) var isLoadingInitial: Bool = false
	/// True while a subsequent page is loading.
	@Published private(set) var isLoadingMore: Bool = false
	/// Localized description of the most recent error (if any).
	@Published private(set) var errorMessage: String?
	/// True when there are no items to show (not loading and no error).
	@Published private(set) var isEmpty: Bool = false
	/// True when more items can be loaded from the API.
	@Published private(set) var hasMore: Bool = true

	/// Creates a new ViewModel.
	/// - Parameters:
	///   - repository: Repository providing pagination and favorites.
	///   - nearEndThreshold: Number of items from the end at which to trigger load-more.
	init(repository: PodcastsRepositoryProtocol, nearEndThreshold: Int = 5) {
		self.repository = repository
		self.nearEndThreshold = nearEndThreshold
	}

	/// Loads the first page and mirrors repository state to published properties.
	func onAppear() async {
		isLoadingInitial = true
		errorMessage = nil
		await repository.loadInitial()
		mirrorRepositoryState()
	}

	/// Triggers loading of the next page when the current item is near the end.
	/// - Parameter currentItem: The row’s podcast being displayed.
	func loadMoreIfNeeded(currentItem: Podcast) async {
		guard let idx = items.firstIndex(where: { $0.id == currentItem.id }) else { return }
		guard hasMore, !isLoadingMore else { return }
		let triggerIndex = max(items.count - nearEndThreshold, 0)
		guard idx >= triggerIndex else { return }

		await repository.loadMore()
		mirrorRepositoryState()
	}

	/// Retries the initial load after an error.
	func retryInitial() async {
		errorMessage = nil
		await repository.retryInitial()
		mirrorRepositoryState()
	}

	/// Toggles the favorite state for a given podcast.
	/// - Parameter id: Unique podcast identifier.
	func toggleFavorite(id: String) {
		repository.toggleFavorite(id: id)
	}

	/// Checks whether a given podcast is favorited.
	/// - Parameter id: Unique podcast identifier.
	/// - Returns: `true` if favorited; otherwise `false`.
	func isFavorite(id: String) -> Bool {
		repository.isFavorite(id: id)
	}

	/// Refreshes the view state to reflect any changes in favorites.
	func refreshFavoriteStates() {
		// Force UI update by triggering objectWillChange
		objectWillChange.send()
	}

	/// Mirrors repository state into published UI properties.
	private func mirrorRepositoryState() {
		items = repository.items
		isLoadingInitial = repository.isLoadingInitial
		isLoadingMore = repository.isLoadingMore
		hasMore = repository.hasMore
		isEmpty = (!repository.isLoadingInitial && repository.items.isEmpty && repository.lastError == nil)
		errorMessage = repository.lastError?.localizedDescription
	}
}
