//
//  FavoritesManager.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-06.
//

import Foundation

/// Protocol defining favorites persistence operations.
protocol FavoritesManagerProtocol {
	/// Adds a podcast to favorites (idempotent).
	/// - Parameter podcastId: Unique podcast identifier.
	func addFavorite(podcastId: String)

	/// Removes a podcast from favorites (no-op if not present).
	/// - Parameter podcastId: Unique podcast identifier.
	func removeFavorite(podcastId: String)

	/// Toggles the favorite state of a podcast.
	/// - Parameter podcastId: Unique podcast identifier.
	func toggleFavorite(podcastId: String)

	/// Returns whether a podcast is currently favorited.
	/// - Parameter podcastId: Unique podcast identifier.
	/// - Returns: `true` if favorited; otherwise `false`.
	func isFavorite(podcastId: String) -> Bool
}

/// UserDefaults-based implementation of `FavoritesManagerProtocol`.
/// - Note: Values are stored under the key "favorites.podcastIds" as `[String]`.
///         Reads are resilient to corruption; invalid payloads are treated as empty.
final class FavoritesManager: FavoritesManagerProtocol {
	private let userDefaults: UserDefaults
	private let favoritesKey = "favorites.podcastIds"

	/// Initializes the favorites manager.
	/// - Parameter userDefaults: Backing store for persistence (defaults to `.standard`).
	init(userDefaults: UserDefaults = .standard) {
		self.userDefaults = userDefaults
	}

	/// Adds a podcast id to favorites (idempotent).
	/// - Parameter podcastId: Unique podcast identifier.
	func addFavorite(podcastId: String) {
		var set = loadSet()
		set.insert(podcastId)
		persist(set)
	}

	/// Removes a podcast id from favorites (no-op if not present).
	/// - Parameter podcastId: Unique podcast identifier.
	func removeFavorite(podcastId: String) {
		var set = loadSet()
		set.remove(podcastId)
		persist(set)
	}

	/// Toggles favorite state for the given podcast id.
	/// - Parameter podcastId: Unique podcast identifier.
	func toggleFavorite(podcastId: String) {
		var set = loadSet()
		if set.contains(podcastId) {
			set.remove(podcastId)
		} else {
			set.insert(podcastId)
		}
		persist(set)
	}

	/// Checks whether a podcast id is favorited.
	/// - Parameter podcastId: Unique podcast identifier.
	/// - Returns: `true` if favorited; otherwise `false`.
	func isFavorite(podcastId: String) -> Bool {
		loadSet().contains(podcastId)
	}

	// MARK: - Storage

	/// Loads the favorites set from `UserDefaults`.
	/// - Returns: A `Set<String>` of favorited ids. Returns empty on missing/corrupted data.
	private func loadSet() -> Set<String> {
		guard let array = userDefaults.array(forKey: favoritesKey) as? [String] else {
			return []
		}
		return Set(array)
	}

	/// Persists the favorites set to `UserDefaults`.
	/// - Parameter set: Set of favorited ids to store.
	private func persist(_ set: Set<String>) {
		userDefaults.set(Array(set), forKey: favoritesKey)
	}
}
