//
//  FavoritesManagerTests.swift
//  PodcastsAppTests
//
//  Created by Shoko Hashimoto on 2025-10-06.
//

import XCTest
@testable import PodcastsApp

final class FavoritesManagerTests: XCTestCase {

	private var suiteName: String!
	private var defaults: UserDefaults!
	private var sut: FavoritesManager!

	override func setUp() {
		super.setUp()
		suiteName = "FavoritesTests-\(UUID().uuidString)"
		defaults = UserDefaults(suiteName: suiteName)!
		defaults.removePersistentDomain(forName: suiteName)
		sut = FavoritesManager(userDefaults: defaults)
	}

	override func tearDown() {
		defaults.removePersistentDomain(forName: suiteName)
		sut = nil
		defaults = nil
		suiteName = nil
		super.tearDown()
	}

	// MARK: - Add
	func test_addFavorite_addsID() {
		sut.addFavorite(podcastId: "id1")
		XCTAssertTrue(sut.isFavorite(podcastId: "id1"))
	}

	func test_addFavorite_idempotentWhenAddedTwice_thenSingleRemoveUnfavorites() {
		sut.addFavorite(podcastId: "id1")
		sut.addFavorite(podcastId: "id1") // duplicate add should be idempotent
		XCTAssertTrue(sut.isFavorite(podcastId: "id1"))
		sut.removeFavorite(podcastId: "id1")
		XCTAssertFalse(sut.isFavorite(podcastId: "id1"))
	}

	// MARK: - Remove
	func test_removeFavorite_nonexistentIsNoop() {
		sut.removeFavorite(podcastId: "unknown")
		XCTAssertFalse(sut.isFavorite(podcastId: "unknown"))
	}

	// MARK: - Toggle
	func test_toggleFavorite_addsWhenAbsent() {
		XCTAssertFalse(sut.isFavorite(podcastId: "id1"))
		sut.toggleFavorite(podcastId: "id1")
		XCTAssertTrue(sut.isFavorite(podcastId: "id1"))
	}

	func test_toggleFavorite_removesWhenPresent() {
		sut.addFavorite(podcastId: "id1")
		XCTAssertTrue(sut.isFavorite(podcastId: "id1"))
		sut.toggleFavorite(podcastId: "id1")
		XCTAssertFalse(sut.isFavorite(podcastId: "id1"))
	}

	// MARK: - Query
	func test_isFavorite_reflectsState() {
		sut.addFavorite(podcastId: "a")
		XCTAssertTrue(sut.isFavorite(podcastId: "a"))
		XCTAssertFalse(sut.isFavorite(podcastId: "b"))
	}

	// MARK: - Persistence
	func test_persistsAcrossInstances_sameSuite() {
		sut.addFavorite(podcastId: "id1")
		let sut2 = FavoritesManager(userDefaults: defaults)
		XCTAssertTrue(sut2.isFavorite(podcastId: "id1"))
	}

	// MARK: - Corrupted Data
	func test_corruptedData_returnsEmptyAndRecovers() {
		// Simulate corrupted value under the key (mixed types)
		defaults.set(["invalid", 123, Date()], forKey: "favorites.podcastIds")

		// Should read as empty (no crash)
		XCTAssertFalse(sut.isFavorite(podcastId: "x"))

		// After recovery via add, store should work normally
		sut.addFavorite(podcastId: "x")
		XCTAssertTrue(sut.isFavorite(podcastId: "x"))
	}
}
