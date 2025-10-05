//
//  BestPodcastsResponse.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

struct BestPodcastsResponse: Decodable {
    let hasNext: Bool
    let podcasts: [Podcast]
}