//
//  PodcastsAppApp.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import SwiftUI

@main
struct PodcastsApp: App {
	var body: some Scene {
		WindowGroup {
			PodcastListView(repository: makeRepository())
		}
	}
	
	private func makeRepository() -> PodcastsRepositoryProtocol {
		let apiClient = PodcastAPIClient()
		let favorites = FavoritesManager()
		return PodcastsRepository(apiClient: apiClient, favorites: favorites)
	}
}
