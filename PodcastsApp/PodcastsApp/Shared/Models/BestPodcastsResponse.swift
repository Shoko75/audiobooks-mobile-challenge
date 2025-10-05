//
//  BestPodcastsResponse.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

struct BestPodcastsResponse: Decodable, Equatable {
    let hasNext: Bool
    let podcasts: [Podcast]

    private enum CodingKeys: String, CodingKey {
        case hasNext = "has_next"
        case podcasts
    }
}