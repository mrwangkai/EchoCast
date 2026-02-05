//
//  iTunesSearchService.swift
//  EchoNotes
//
//  iTunes Search API service for podcast discovery
//

import Foundation

class iTunesSearchService {
    static let shared = iTunesSearchService()

    private var searchCache: [String: [iTunesPodcast]] = [:]

    struct iTunesPodcast: Identifiable, Codable {
        let collectionId: Int?
        let trackId: Int
        let collectionName: String?
        let trackName: String
        let artistName: String
        let artworkUrl600: String?
        let artworkUrl100: String?
        let feedUrl: String?
        let trackViewUrl: String?
        let collectionViewUrl: String?
        let primaryGenreName: String?
        let genreIds: [String]?
        let genres: [String]?

        var id: String {
            String(collectionId ?? trackId)
        }

        /// Display name - prefer collectionName over trackName
        var displayName: String {
            collectionName ?? trackName
        }
    }

    struct SearchResponse: Codable {
        let resultCount: Int
        let results: [iTunesPodcast]
    }

    private init() {}

    func search(query: String) async throws -> [iTunesPodcast] {
        print("🔍 [iTunesSearch] Searching for: \(query)")

        // Check cache first
        if let cached = searchCache[query.lowercased()] {
            print("✅ [iTunesSearch] Using cached results")
            return cached
        }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&media=podcast&limit=20") else {
            print("❌ [iTunesSearch] Invalid URL")
            throw URLError(.badURL)
        }

        print("📡 [iTunesSearch] Fetching from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [iTunesSearch] Response status: \(httpResponse.statusCode)")
            }

            let decoded = try JSONDecoder().decode(SearchResponse.self, from: data)

            // Cache results
            searchCache[query.lowercased()] = decoded.results

            print("✅ [iTunesSearch] Found \(decoded.resultCount) results")
            return decoded.results
        } catch {
            print("❌ [iTunesSearch] Search failed: \(error)")
            throw error
        }
    }

    /// Clear search cache
    func clearCache() {
        searchCache.removeAll()
        print("🗑️ [iTunesSearch] Cache cleared")
    }
}
