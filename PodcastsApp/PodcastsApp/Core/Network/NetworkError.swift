//
//  NetworkError.swift
//  PodcastsApp
//
//  Created by Shoko Hashimoto on 2025-10-05.
//

import Foundation

enum NetworkError: Error, LocalizedError, Equatable {
    case noInternet
    case timeout
    case serverError(Int)
    case invalidData
    case badURL
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .noInternet:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error: \(code)"
        case .invalidData:
            return "Invalid data received"
        case .badURL:
            return "Invalid URL"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }

    // MARK: - Equatable
    static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
        switch (lhs, rhs) {
        case (.noInternet, .noInternet):
            return true
        case (.timeout, .timeout):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        case (.invalidData, .invalidData):
            return true
        case (.badURL, .badURL):
            return true
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
