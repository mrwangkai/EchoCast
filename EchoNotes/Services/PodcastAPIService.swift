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

    struct GenreResponse: Codable {
        let resultCount: Int
        let results: [iTunesSearchService.iTunesPodcast]
    }

    /// Fetch top podcasts for a specific genre using Search API
    func getTopPodcasts(genreId: String, limit: Int = 10) async throws -> [iTunesSearchService.iTunesPodcast] {
        print("📡 [PodcastAPI] Fetching top \(limit) podcasts for genre ID: \(genreId)")

        // Check cache first
        let cacheKey = "\(genreId)-\(limit)"
        if let cached = genreCache[cacheKey],
           let timestamp = cacheTimestamps[cacheKey],
           Date().timeIntervalSince(timestamp) < cacheValidityInterval {
            print("✅ [PodcastAPI] Using cached data for genre \(genreId)")
            return cached
        }

        // FIXED: Use Search API instead of RSS feed generator
        // RSS feed endpoint returns different JSON structure that doesn't match our model
        var components = URLComponents(string: "https://itunes.apple.com/search")
        components?.queryItems = [
            URLQueryItem(name: "media", value: "podcast"),
            URLQueryItem(name: "entity", value: "podcast"),
            URLQueryItem(name: "genreId", value: genreId),
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

            // Log first podcast for debugging
            if let first = podcasts.first {
                print("📋 [PodcastAPI] First podcast: \(first.displayName)")
                print("📋 [PodcastAPI] Artwork URL: \(first.artworkUrl600 ?? "nil")")
            }

            // Cache results
            genreCache[cacheKey] = podcasts
            cacheTimestamps[cacheKey] = Date()

            print("✅ [PodcastAPI] Successfully decoded \(podcasts.count) podcasts for genre \(genreId)")
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
