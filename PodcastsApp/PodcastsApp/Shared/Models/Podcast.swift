//
//  Podcast.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

struct Podcast: Decodable {
	let id: String
	let title: String
	let publisher: String
	let thumbnail: String?
}
