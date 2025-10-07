//
//  PodcastListView.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-06.
//
import SwiftUI

/// Main list view displaying paginated podcasts with loading states and error handling.
struct PodcastListView: View {
	@StateObject private var viewModel: PodcastsListViewModel
	private let repository: PodcastsRepositoryProtocol
	
	init(repository: PodcastsRepositoryProtocol) {
		self.repository = repository
		self._viewModel = StateObject(wrappedValue: PodcastsListViewModel(repository: repository))
	}
	
	var body: some View {
		NavigationView {
			Group {
				if viewModel.isLoadingInitial {
					loadingView
				} else if viewModel.isEmpty {
					emptyView
				} else {
					listView
				}
			}
			.navigationTitle("Podcasts")
			.refreshable {
				await viewModel.retryInitial()
			}
		}
		.task {
			await viewModel.onAppear()
		}
		.alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
			Button("Retry") {
				Task {
					await viewModel.retryInitial()
				}
			}
			Button("Cancel", role: .cancel) { }
		} message: {
			Text(viewModel.errorMessage ?? "")
		}
	}
	
	// MARK: - Subviews
	private var listView: some View {
		List {
			ForEach(Array(viewModel.items.enumerated()), id: \.offset) { _, podcast in
				NavigationLink(destination: PodcastDetailView(viewModel: PodcastDetailViewModel(podcast: podcast, repository: repository))) {
					PodcastRowView(podcast: podcast, isFavorite: viewModel.isFavorite(id: podcast.id))
				}
					.onAppear {
						Task { await viewModel.loadMoreIfNeeded(currentItem: podcast) }
					}
			}
			
			if viewModel.isLoadingMore {
				HStack {
					Spacer()
					ProgressView("Loading more...")
						.padding()
					Spacer()
				}
			}
		}
		.listStyle(PlainListStyle())
		.onAppear {
			viewModel.refreshFavoriteStates()
		}
	}
	
	private var loadingView: some View {
		VStack(spacing: 16) {
			ProgressView()
				.scaleEffect(1.2)
			Text("Loading podcasts...")
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
	
	private var emptyView: some View {
		VStack(spacing: 16) {
			Image(systemName: "waveform")
				.font(.system(size: 48))
				.foregroundColor(.secondary)
			Text("No podcasts available")
				.font(.headline)
			Text("Try refreshing to load podcasts")
				.foregroundColor(.secondary)
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

// MARK: - Preview
struct PodcastListView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			// Success state - shows loaded podcasts
			PodcastListView(repository: MockRepository.success)
				.previewDisplayName("Success")
			
			// Loading state - shows loading indicator
			PodcastListView(repository: MockRepository.loading)
				.previewDisplayName("Loading")
			
			// Empty state - shows empty message
			PodcastListView(repository: MockRepository.empty)
				.previewDisplayName("Empty")
		}
	}
}

// MARK: - Mock Repositories for Previews
private class MockRepository: PodcastsRepositoryProtocol {
	let items: [Podcast]
	let isLoadingInitial: Bool
	let isLoadingMore: Bool
	let hasMore: Bool
	let lastError: NetworkError?
	
	init(items: [Podcast] = [], isLoadingInitial: Bool = false, isLoadingMore: Bool = false, hasMore: Bool = true, lastError: NetworkError? = nil) {
		self.items = items
		self.isLoadingInitial = isLoadingInitial
		self.isLoadingMore = isLoadingMore
		self.hasMore = hasMore
		self.lastError = lastError
	}
	
	func loadInitial() async { }
	func loadMore() async { }
	func retryInitial() async { }
	func isFavorite(id: String) -> Bool {
		// Randomly show some as favorited for preview
		return id.contains("2") || id.contains("5") || id.contains("8")
	}
	func toggleFavorite(id: String) { }
	
	// Static factory methods for different preview states
	static var success: MockRepository {
		let podcasts = (0..<20).map { idx in
			Podcast(
				id: "preview-\(idx)",
				title: "Preview Podcast \(idx + 1)",
				publisher: "Preview Publisher \(idx + 1)",
				thumbnail: "https://via.placeholder.com/150",
				image: "https://via.placeholder.com/300",
				description: "This is a preview podcast description for podcast \(idx + 1)."
			)
		}
		return MockRepository(items: podcasts, isLoadingInitial: false, hasMore: true)
	}
	
	static var loading: MockRepository {
		MockRepository(items: [], isLoadingInitial: true, hasMore: true)
	}
	
	static var empty: MockRepository {
		MockRepository(items: [], isLoadingInitial: false, hasMore: false)
	}
}
