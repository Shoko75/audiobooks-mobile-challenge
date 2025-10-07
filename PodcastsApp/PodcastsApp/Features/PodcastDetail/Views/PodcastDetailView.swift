//
//  PodcastDetailView.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-07.
//

import SwiftUI

struct PodcastDetailView: View {
	@StateObject var viewModel: PodcastDetailViewModel
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		ScrollView {
			VStack(alignment: .center, spacing: 16) {
				// Title
				Text(viewModel.title)
					.font(.title2.bold())
					.fixedSize(horizontal: false, vertical: true)

				// Publisher
				Text(viewModel.publisher)
					.font(.subheadline)
					.foregroundColor(.secondary)

				// Square image (fixed)
				AsyncImage(url: viewModel.imageURL) { phase in
					switch phase {
					case .empty:
						ZStack {
							Rectangle()
								.fill(Color.gray.opacity(0.2))
							ProgressView()
						}
						.frame(width: 240, height: 240)
						.clipShape(RoundedRectangle(cornerRadius: 12))
						.accessibilityHidden(true)
					case .success(let image):
						image
							.resizable()
							.scaledToFill()
							.frame(width: 240, height: 240)
							.clipped()
							.clipShape(RoundedRectangle(cornerRadius: 12))
							.accessibilityLabel("Podcast artwork")
					case .failure:
						ZStack {
							Rectangle()
								.fill(Color.gray.opacity(0.2))
							Image(systemName: "photo")
								.imageScale(.large)
								.foregroundColor(.secondary)
						}
						.frame(width: 240, height: 240)
						.clipShape(RoundedRectangle(cornerRadius: 12))
						.accessibilityLabel("No artwork available")
					@unknown default:
						EmptyView()
					}
				}
				.frame(maxWidth: .infinity, alignment: .center)

				// Favourite button
				Button(action: { viewModel.toggleFavorite() }) {
					Text(viewModel.isFavorite ? "Favourited" : "Favourite")
						.font(.subheadline.weight(.medium))
						.foregroundColor(viewModel.isFavorite ? .white : .primary)
						.padding(.horizontal, 16)
						.padding(.vertical, 8)
						.background(
							RoundedRectangle(cornerRadius: 8)
								.fill(viewModel.isFavorite ? Color.red : Color.gray.opacity(0.2))
						)
				}
				.accessibilityIdentifier("favoriteButton")

				// Description
				Text(viewModel.descriptionText)
					.font(.body)
					.foregroundColor(.primary)
					.fixedSize(horizontal: false, vertical: true)

			}
			.padding()
		}
		.navigationBarTitleDisplayMode(.inline)
		.navigationBarBackButtonHidden(true)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: { dismiss() }) {
					HStack(spacing: 4) {
						Image(systemName: "chevron.left")
						Text("Back")
					}
				}
				.accessibilityLabel("Back")
			}
		}
	}
}

// MARK: - Preview Support Types
private final class PreviewRepo: PodcastsRepositoryProtocol {
	var items: [Podcast] = []
	var isLoadingInitial: Bool = false
	var isLoadingMore: Bool = false
	var hasMore: Bool = false
	var lastError: NetworkError?
	private var fav: Set<String> = []
	func loadInitial() async { }
	func loadMore() async { }
	func retryInitial() async { }
	func isFavorite(id: String) -> Bool { fav.contains(id) }
	func toggleFavorite(id: String) {
		if fav.contains(id) {
			fav.remove(id)
		} else {
			fav.insert(id)
		}
	}
}

// MARK: - Preview
struct PodcastDetailView_Previews: PreviewProvider {
	static var previews: some View {
		let podcast = Podcast(
			id: "id-1",
			title: "Sample Podcast",
			publisher: "Sample Publisher",
			thumbnail: "https://example.com/thumb.jpg",
			image: "https://example.com/large.jpg",
			description: "This is a sample description for the podcast detail view."
		)
		let repo = PreviewRepo()
		let vm = PodcastDetailViewModel(podcast: podcast, repository: repo)
		NavigationView { PodcastDetailView(viewModel: vm) }
	}
}
