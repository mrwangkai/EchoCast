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

    /// Fetch top podcasts for a specific genre
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

        // Build URL for iTunes API top podcasts by genre
        // Using the RSS feed generator endpoint which supports genre filtering
        let url_string = "https://itunes.apple.com/us/rss/toppodcasts/limit=\(limit)/genre=\(genreId)/json"

        guard let url = URL(string: url_string) else {
            print("❌ [PodcastAPI] Invalid URL: \(url_string)")
            throw URLError(.badURL)
        }

        print("📡 [PodcastAPI] Fetching from: \(url)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Log response info
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 [PodcastAPI] Response status: \(httpResponse.statusCode)")
            }

            let genreResponse = try JSONDecoder().decode(GenreResponse.self, from: data)
            let podcasts = genreResponse.results

            // Cache results
            genreCache[cacheKey] = podcasts
            cacheTimestamps[cacheKey] = Date()

            print("✅ [PodcastAPI] Fetched \(podcasts.count) podcasts for genre \(genreId)")
            return podcasts
        } catch {
            print("❌ [PodcastAPI] Failed to fetch genre podcasts: \(error)")
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
