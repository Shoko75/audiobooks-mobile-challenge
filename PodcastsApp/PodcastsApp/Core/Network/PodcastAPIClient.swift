//
//  PodcastAPIClient.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

/// Protocol defining podcast API operations
protocol PodcastAPIClientProtocol {
    /// Fetches the best podcasts for a given page
    /// - Parameter page: Page number (1-based)
    /// - Returns: BestPodcastsResponse containing podcasts and pagination info
    /// - Throws: NetworkError for network issues, not URLError
    func fetchBestPodcasts(page: Int) async throws -> BestPodcastsResponse
}

/// URLSession-based implementation of PodcastAPIClientProtocol
final class PodcastAPIClient: PodcastAPIClientProtocol {
	private let session: URLSession
	private let baseURL: URL
	
	private static let defaultBaseURL: URL = {
		guard let url = URL(string: "https://listen-api-test.listennotes.com/api/v2") else {
			fatalError("Invalid default base URL")
		}
		return url
	}()
	/// Initializes the API client
	/// - Parameters:
	///   - session: URLSession to use for requests (defaults to .shared)
	///   - baseURL: Base URL for the API (defaults to Listen Notes test API)
	init(session: URLSession = .shared, baseURL: URL = defaultBaseURL) {
		self.session = session
		self.baseURL = baseURL
	}
	
	// MARK: - Generic Request Builder
	private func makeRequest(endpoint: String, queryItems: [URLQueryItem] = []) throws -> URLRequest {
		guard let url = URL(string: endpoint, relativeTo: baseURL) else {
			throw NetworkError.badURL
		}
		
		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		components?.queryItems = queryItems
		
		guard let finalURL = components?.url else {
			throw NetworkError.badURL
		}
		
		return URLRequest(url: finalURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
	}
	
	// MARK: - Generic Response Handler
	private func handleResponse<T: Decodable>(_ type: T.Type, data: Data, response: URLResponse) throws -> T {
		guard let http = response as? HTTPURLResponse else {
			throw NetworkError.invalidData
		}
		
		guard 200..<300 ~= http.statusCode else {
			throw NetworkError.serverError(http.statusCode)
		}
		
		do {
			let decoder = JSONDecoder()
			return try decoder.decode(type, from: data)
		} catch {
			throw NetworkError.invalidData
		}
	}
	
	// MARK: - Error Mapping
	private func mapError(_ error: Error) -> NetworkError {
		switch error {
		case let error as NetworkError:
			return error
		case let error as URLError:
			switch error.code {
			case .notConnectedToInternet: return .noInternet
			case .timedOut: return .timeout
			default: return .unknown(error)
			}
		default:
			return .unknown(error)
		}
	}
	
	// MARK: - Public API Methods
	func fetchBestPodcasts(page: Int) async throws -> BestPodcastsResponse {
		do {
			let request = try makeRequest(endpoint: "best_podcasts", queryItems: [URLQueryItem(name: "page", value: String(page))])
			let (data, response) = try await session.data(for: request)
			return try handleResponse(BestPodcastsResponse.self, data: data, response: response)
		} catch {
			throw mapError(error)
		}
	}
}
