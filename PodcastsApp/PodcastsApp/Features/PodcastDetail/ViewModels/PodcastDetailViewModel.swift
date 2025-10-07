//
//  PodcastDetailViewModel.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-07.
//
import Foundation

/// View model that exposes view-ready fields for a single `Podcast` and
/// manages favorite state via the repository. No network requests are made
/// from this view model; it derives all content from the provided `Podcast`.
@MainActor
final class PodcastDetailViewModel: ObservableObject {
    /// Repository dependency used to query and mutate favorite state.
    private let repository: PodcastsRepositoryProtocol
    /// Immutable source podcast used to derive display properties.
    private let podcast: Podcast

    /// Whether the current podcast is marked as a favorite.
    @Published private(set) var isFavorite: Bool

    /// Creates a new view model for displaying podcast details.
    /// - Parameters:
    ///   - podcast: The source podcast to display.
    ///   - repository: Repository used for favorite state.
    init(podcast: Podcast, repository: PodcastsRepositoryProtocol) {
        self.podcast = podcast
        self.repository = repository
        self.isFavorite = repository.isFavorite(id: podcast.id)
    }

    /// Display title trimmed for presentation.
    var title: String {
        podcast.title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Display publisher trimmed for presentation.
    var publisher: String {
        podcast.publisher.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Preferred image URL for detail, choosing the large image when available
    /// and falling back to the thumbnail.
    var imageURL: URL? {
        // Prefer large image for detail; fallback to thumbnail
        if let large = podcast.imageURL { return large }
        return podcast.thumbnailURL
    }

    /// Human-friendly description, or a fallback string when the source is
    /// empty or missing.
    var descriptionText: String {
        let trimmed = podcast.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "No description available." : trimmed
    }

    /// Toggles favorite state for the current podcast and updates `isFavorite`.
    func toggleFavorite() {
        repository.toggleFavorite(id: podcast.id)
        isFavorite = repository.isFavorite(id: podcast.id)
    }
}


