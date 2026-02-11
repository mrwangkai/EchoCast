//
//  DataCacheManager.swift
//  EchoNotes
//
//  Production-ready data caching for:
//  - Podcast metadata (iTunes API responses)
//  - RSS feed episodes
//  - Genre/category results
//  - Search results
//
//  Uses custom disk-based caching because:
//  - iTunes API doesn't reliably send HTTP cache headers (URLCache won't work)
//  - Need flexible expiration logic (5 min, 30 min, 2 hours, 24 hours)
//  - Caching parsed Codable models, not just raw HTTP responses
//  - Need full control over cache invalidation
//

import SwiftUI
import Foundation

// MARK: - Cache Entry

struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let expirationSeconds: TimeInterval

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationSeconds
    }
}

// MARK: - Data Cache Manager

@MainActor
class DataCacheManager: ObservableObject {
    static let shared = DataCacheManager()

    // MARK: - Cache Durations
    enum CacheDuration {
        case short      // 5 minutes - for rapidly changing data
        case medium     // 30 minutes - for search results, genre browsing
        case long       // 2 hours - for podcast metadata, genre results
        case persistent // 24 hours - for RSS feeds

        var seconds: TimeInterval {
            switch self {
            case .short: return 300         // 5 min
            case .medium: return 1800       // 30 min
            case .long: return 7200         // 2 hours
            case .persistent: return 86400  // 24 hours
            }
        }
    }

    // MARK: - Disk Cache Storage
    private let diskCacheDirectory: URL = {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = paths[0].appendingPathComponent("DataCache")
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        // Configure JSON encoder/decoder
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601

        print("💾 [DataCache] Initialized - Cache dir: \(diskCacheDirectory.path)")

        // Clean expired entries on init
        cleanExpiredEntries()
    }

    // MARK: - Public API

    /// Get cached data if available and not expired
    func get<T: Codable>(
        key: String,
        as type: T.Type
    ) -> T? {
        let cacheKey = sanitizeKey(key)
        let fileURL = cacheURL(for: cacheKey)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let entry = try? decoder.decode(CacheEntry<T>.self, from: data) else {
            print("❌ [DataCache] Miss: \(cacheKey)")
            return nil
        }

        if entry.isExpired {
            print("⏰ [DataCache] Expired: \(cacheKey)")
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }

        print("✅ [DataCache] Hit: \(cacheKey)")
        return entry.data
    }

    /// Save data to cache with expiration
    func set<T: Codable>(
        key: String,
        value: T,
        duration: CacheDuration = .medium
    ) {
        let cacheKey = sanitizeKey(key)
        let entry = CacheEntry(
            data: value,
            timestamp: Date(),
            expirationSeconds: duration.seconds
        )

        guard let data = try? encoder.encode(entry) else {
            print("❌ [DataCache] Failed to encode: \(cacheKey)")
            return
        }

        let fileURL = cacheURL(for: cacheKey)

        do {
            try data.write(to: fileURL, options: .atomic)
            print("💾 [DataCache] Saved: \(cacheKey) (expires in \(Int(duration.seconds))s)")
        } catch {
            print("❌ [DataCache] Save failed: \(error)")
        }
    }

    /// Remove specific cache entry
    func remove(key: String) {
        let cacheKey = sanitizeKey(key)
        let fileURL = cacheURL(for: cacheKey)
        try? FileManager.default.removeItem(at: fileURL)
        print("🗑️ [DataCache] Removed: \(cacheKey)")
    }

    /// Clear all cached data
    func clearAll() {
        try? FileManager.default.removeItem(at: diskCacheDirectory)
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        print("🗑️ [DataCache] All cache cleared")
    }

    /// Clean expired entries only
    func cleanExpiredEntries() {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: diskCacheDirectory,
            includingPropertiesForKeys: nil
        ) else { return }

        var expiredCount = 0

        for fileURL in files {
            guard let data = try? Data(contentsOf: fileURL),
                  let jsonDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let timestampString = jsonDict["timestamp"] as? String,
                  let expirationSeconds = jsonDict["expirationSeconds"] as? TimeInterval else {
                continue
            }

            // Parse ISO8601 timestamp
            let formatter = ISO8601DateFormatter()
            guard let timestamp = formatter.date(from: timestampString) else { continue }

            // Check if expired
            if Date().timeIntervalSince(timestamp) > expirationSeconds {
                try? FileManager.default.removeItem(at: fileURL)
                expiredCount += 1
            }
        }

        if expiredCount > 0 {
            print("🧹 [DataCache] Cleaned \(expiredCount) expired entries")
        }
    }

    // MARK: - Private Helpers

    private func sanitizeKey(_ key: String) -> String {
        // Create safe filename from cache key
        key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
    }

    private func cacheURL(for key: String) -> URL {
        diskCacheDirectory.appendingPathComponent("\(key).json")
    }
}

// MARK: - Convenience Extensions for Common Types

extension DataCacheManager {

    /// Cache podcast search/browse results
    func cachePodcasts(
        _ podcasts: [iTunesPodcast],
        forKey key: String,
        duration: CacheDuration = .medium
    ) {
        set(key: "podcasts_\(key)", value: podcasts, duration: duration)
    }

    func getCachedPodcasts(forKey key: String) -> [iTunesPodcast]? {
        get(key: "podcasts_\(key)", as: [iTunesPodcast].self)
    }

    /// Cache RSS episodes
    func cacheEpisodes(
        _ episodes: [RSSEpisode],
        forPodcastFeed feedURL: String,
        duration: CacheDuration = .persistent
    ) {
        set(key: "episodes_\(feedURL)", value: episodes, duration: duration)
    }

    func getCachedEpisodes(forPodcastFeed feedURL: String) -> [RSSEpisode]? {
        get(key: "episodes_\(feedURL)", as: [RSSEpisode].self)
    }

    /// Cache genre results
    func cacheGenreResults(
        _ podcasts: [iTunesPodcast],
        forGenre genreId: Int,
        duration: CacheDuration = .long
    ) {
        set(key: "genre_\(genreId)", value: podcasts, duration: duration)
    }

    func getCachedGenreResults(forGenre genreId: Int) -> [iTunesPodcast]? {
        get(key: "genre_\(genreId)", as: [iTunesPodcast].self)
    }

    /// Cache search results
    func cacheSearchResults(
        _ podcasts: [iTunesPodcast],
        forQuery query: String,
        duration: CacheDuration = .medium
    ) {
        set(key: "search_\(query)", value: podcasts, duration: duration)
    }

    func getCachedSearchResults(forQuery query: String) -> [iTunesPodcast]? {
        get(key: "search_\(query)", as: [iTunesPodcast].self)
    }
}

// MARK: - Cache-or-Fetch Helper

extension DataCacheManager {

    /// Generic cache-or-fetch pattern
    func fetchOrCache<T: Codable>(
        key: String,
        duration: CacheDuration = .medium,
        fetch: () async throws -> T
    ) async throws -> T {
        // Check cache first
        if let cached = get(key: key, as: T.self) {
            print("✅ [DataCache] Using cached data for: \(key)")
            return cached
        }

        // Fetch fresh data
        print("📡 [DataCache] Fetching fresh data for: \(key)")
        let data = try await fetch()

        // Cache the result
        set(key: key, value: data, duration: duration)

        return data
    }
}
