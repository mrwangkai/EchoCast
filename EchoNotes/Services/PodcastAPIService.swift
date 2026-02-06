//
//  PodcastAPIService.swift
//  EchoNotes
//
//  iTunes API service for fetching podcasts by genre
//

import Foundation

class PodcastAPIService {
    static let shared = PodcastAPIService()

    private var genreCache: [String: [iTunesSearchService.iTunesPodcast]] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheValidityInterval: TimeInterval = 3600  // 1 hour

    private init() {}

    /// Map genre ID to genre name for search
    private func getGenreName(from genreId: String) -> String {
        switch genreId {
        case "1303": return "comedy"
        case "1489": return "news"
        case "1488": return "true crime"
        case "1545": return "sports"
        case "1321": return "business"
        case "1304": return "education"
        case "1318": return "technology"
        case "26": return "arts"
        case "1510": return "health"
        case "1507": return "tv film"
        case "1310": return "music"
        case "1270": return "society"
        case "1323": return "science fiction"
        default: return "podcast"
        }
    }

    struct GenreResponse: Codable {
        let resultCount: Int
        let results: [iTunesSearchService.iTunesPodcast]
    }

    /// Fetch top podcasts for a specific genre using Search API with genre name
    func getTopPodcasts(genreId: String, limit: Int = 10) async throws -> [iTunesSearchService.iTunesPodcast] {
        // Map genre ID to genre name for search
        let genreName = getGenreName(from: genreId)
        print("📡 [PodcastAPI] Fetching top \(limit) podcasts for genre: \(genreName) (ID: \(genreId))")

        // Check cache first
        let cacheKey = "\(genreId)-\(limit)"
        if let cached = genreCache[cacheKey],
           let timestamp = cacheTimestamps[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheValidityInterval {
            print("✅ [PodcastAPI] Using cached data for genre \(genreName)")
            return cached
        }

        // FIXED: Use "term" parameter with genre name instead of "genreId"
        // iTunes Search API doesn't filter by genreId, but searching by genre name works
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "term", value: genreName),
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "explicit", value: "Yes")
        ]

        guard let url = components?.url else {
            print("❌ [PodcastAPI] Failed to construct URL")
            throw URLError(.badURL)
        }

        print("📡 [PodcastAPI] Fetching from: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        // Log response info
        if let httpResponse = response as? HTTPURLResponse {
            print("📡 [PodcastAPI] Response status: \(httpResponse.statusCode)")
        }

        do {
            let searchResponse = try JSONDecoder().decode(GenreResponse.self, from: data)
            let podcasts = searchResponse.results

            // Log results for debugging
            print("📊 [PodcastAPI] Result count: \(searchResponse.resultCount)")

            // Log first podcast for debugging
            if let first = podcasts.first {
                print("📋 [PodcastAPI] First podcast: \(first.displayName)")
                print("📋 [PodcastAPI] Artwork URL: \(first.artworkUrl600 ?? "nil")")
            }

            // Cache results
            genreCache[cacheKey] = podcasts
            cacheTimestamps[cacheKey] = Date()

            print("✅ [PodcastAPI] Successfully decoded \(podcasts.count) podcasts for genre \(genreName)")
            return podcasts
        } catch {
            print("❌ [PodcastAPI] Failed to fetch genre podcasts: \(error)")

            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 [PodcastAPI] Raw JSON (first 500 chars):")
                print(String(jsonString.prefix(500)))
            }

            throw error
        }
    }

    /// Search podcasts by query (delegates to iTunesSearchService)
    func search(query: String, limit: Int = 20) async throws -> [iTunesSearchService.iTunesPodcast] {
        return try await iTunesSearchService.shared.search(query: query)
    }

    /// Clear all caches
    func clearCache() {
        genreCache.removeAll()
        cacheTimestamps.removeAll()
        print("🗑️ [PodcastAPI] Cache cleared")
    }
}
