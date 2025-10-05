//
//  Podcast.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

struct Podcast: Decodable, Equatable {
	let id: String
	let title: String
	let publisher: String
	let thumbnail: String?

	// Convenience for views
    var thumbnailURL: URL? {
        thumbnail.flatMap { URL(string: $0) }
    }

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		id = try container.decode(String.self, forKey: .id)
		title = try container.decode(String.self, forKey: .title)
		publisher = try container.decode(String.self, forKey: .publisher)
		thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)

		guard !id.isEmpty, !title.isEmpty else {
			throw DecodingError.dataCorruptedError(
				forKey: .id,
				in: container,
				debugDescription: "Podcast id or title is empty."
			)
    	}
	}

	private enum CodingKeys: String, CodingKey {
		case id
		case title
		case publisher
		case thumbnail
	}
}
