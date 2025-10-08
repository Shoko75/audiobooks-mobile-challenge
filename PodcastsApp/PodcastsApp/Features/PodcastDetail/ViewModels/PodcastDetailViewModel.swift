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
    /// empty or missing. Strips HTML tags and decodes entities.
    var descriptionText: String {
        let trimmed = podcast.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return "No description available." }
        
        let stripped = stripHTML(trimmed)
        return stripped.isEmpty ? "No description available." : stripped
    }
    
    /// Strips HTML tags and decodes HTML entities from the input string.
    private func stripHTML(_ html: String) -> String {
        // Remove HTML tags using regex
        let htmlTagPattern = "<[^>]+>"
        let htmlTagRegex = try! NSRegularExpression(pattern: htmlTagPattern, options: [])
        let range = NSRange(location: 0, length: html.utf16.count)
        let withoutTags = htmlTagRegex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "")
        
        // Decode HTML entities
        let htmlEntities = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'",
            "&nbsp;": " ",
            "&#39;": "'",
            "&#160;": " ",  // Non-breaking space
            "&nbsp": " "    // Sometimes without semicolon
        ]
        
        var result = withoutTags
        for (entity, replacement) in htmlEntities {
            result = result.replacingOccurrences(of: entity, with: replacement)
        }
        
        // Clean up extra whitespace
        let cleaned = result.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the result contains only whitespace characters
        let hasOnlyWhitespace = cleaned.allSatisfy { $0.isWhitespace || $0.isNewline }
        
        return (cleaned.isEmpty || hasOnlyWhitespace) ? "" : cleaned
    }

    /// Toggles favorite state for the current podcast and updates `isFavorite`.
    func toggleFavorite() {
        repository.toggleFavorite(id: podcast.id)
        isFavorite = repository.isFavorite(id: podcast.id)
    }
}


