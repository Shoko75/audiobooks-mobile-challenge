//
//  PodcastRowView.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-06.
//

import SwiftUI

/// Individual row view for displaying a podcast in the list.
struct PodcastRowView: View {
	let podcast: Podcast
	let isFavorite: Bool
	
	var body: some View {
		HStack(spacing: 12) {
			// Thumbnail
			AsyncImage(url: podcast.thumbnailURL) { image in
				image
					.resizable()
					.aspectRatio(contentMode: .fill)
			} placeholder: {
				RoundedRectangle(cornerRadius: 8)
					.fill(Color.gray.opacity(0.3))
					.overlay(
						Image(systemName: "waveform")
							.foregroundColor(.gray)
					)
			}
			.frame(width: 60, height: 60)
			.clipShape(RoundedRectangle(cornerRadius: 8))
			
			// Content
			VStack(alignment: .leading, spacing: 4) {
				// Title
				Text(podcast.title)
					.font(.headline)
					.lineLimit(1)
					.foregroundColor(.primary)
				
				// Publisher
				Text(podcast.publisher)
					.font(.subheadline)
					.foregroundColor(.secondary)
					.lineLimit(1)
				
				// Favorite indicator
				if isFavorite {
					HStack(spacing: 4) {
						Image(systemName: "heart.fill")
							.foregroundColor(.red)
							.font(.caption)
						Text("Favourited")
							.font(.caption)
							.foregroundColor(.red)
					}
					.padding(.top, 2)
				}
			}
			
			Spacer()
			
			// Chevron
			Image(systemName: "chevron.right")
				.font(.caption)
				.foregroundColor(.secondary)
		}
		.padding(.vertical, 8)
		.contentShape(Rectangle()) // Makes entire row tappable
	}
}

// MARK: - Preview
struct PodcastRowView_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			// Normal podcast
			PodcastRowView(
				podcast: Podcast(
					id: "1",
					title: "Swift Over Coffee",
					publisher: "Paul Hudson",
					thumbnail: "https://via.placeholder.com/150",
					image: nil,
					description: "A podcast about Swift programming"
				),
				isFavorite: false
			)
			.previewDisplayName("Normal")
			
			// Favorited podcast
			PodcastRowView(
				podcast: Podcast(
					id: "2",
					title: "Very Long Podcast Title That Might Wrap to Multiple Lines",
					publisher: "Very Long Publisher Name That Might Be Truncated",
					thumbnail: nil,
					image: nil,
					description: nil
				),
				isFavorite: true
			)
			.previewDisplayName("Favorited")
			
			// No thumbnail
			PodcastRowView(
				podcast: Podcast(
					id: "3",
					title: "No Thumbnail Podcast",
					publisher: "Publisher",
					thumbnail: nil,
					image: nil,
					description: nil
				),
				isFavorite: false
			)
			.previewDisplayName("No Thumbnail")
		}
		.previewLayout(.sizeThatFits)
		.padding()
	}
}
