//
//  iTunesSearchService.swift
//  EchoNotes
//
//  iTunes Search API service for podcast discovery
//

import Foundation

class iTunesSearchService {
    static let shared = iTunesSearchService()

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

        // These fields can be either strings or arrays from iTunes API
        // Using private storage with custom decoding
        private let genreIdsRaw: GenreIdsRaw?
        private let genresRaw: GenresRaw?

        // Computed properties to always return arrays
        var genreIds: [String]? {
            genreIdsRaw?.arrayValue
        }

        var genres: [String]? {
            genresRaw?.arrayValue
        }

        var id: String {
            String(collectionId ?? trackId)
        }

        /// Display name - prefer collectionName over trackName
        var displayName: String {
            collectionName ?? trackName
        }

        // Custom init to handle decoding errors gracefully
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Decode standard fields
            self.collectionId = try container.decodeIfPresent(Int.self, forKey: .collectionId)
            self.trackId = try container.decode(Int.self, forKey: .trackId)
            self.collectionName = try container.decodeIfPresent(String.self, forKey: .collectionName)
            self.trackName = try container.decode(String.self, forKey: .trackName)
            self.artistName = try container.decode(String.self, forKey: .artistName)
            self.artworkUrl600 = try container.decodeIfPresent(String.self, forKey: .artworkUrl600)
            self.artworkUrl100 = try container.decodeIfPresent(String.self, forKey: .artworkUrl100)
            self.feedUrl = try container.decodeIfPresent(String.self, forKey: .feedUrl)
            self.trackViewUrl = try container.decodeIfPresent(String.self, forKey: .trackViewUrl)
            self.collectionViewUrl = try container.decodeIfPresent(String.self, forKey: .collectionViewUrl)
            self.primaryGenreName = try container.decodeIfPresent(String.self, forKey: .primaryGenreName)

            // Decode mixed-type fields
            self.genreIdsRaw = try container.decodeIfPresent(GenreIdsRaw.self, forKey: .genreIds)
            self.genresRaw = try container.decodeIfPresent(GenresRaw.self, forKey: .genres)
        }

        // CodingKeys for custom init
        enum CodingKeys: String, CodingKey {
            case collectionId, trackId, collectionName, trackName, artistName
            case artworkUrl600, artworkUrl100, feedUrl, trackViewUrl, collectionViewUrl
            case primaryGenreName, genreIds, genres
        }

        // Standard encode
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(collectionId, forKey: .collectionId)
            try container.encode(trackId, forKey: .trackId)
            try container.encodeIfPresent(collectionName, forKey: .collectionName)
            try container.encode(trackName, forKey: .trackName)
            try container.encode(artistName, forKey: .artistName)
            try container.encodeIfPresent(artworkUrl600, forKey: .artworkUrl600)
            try container.encodeIfPresent(artworkUrl100, forKey: .artworkUrl100)
            try container.encodeIfPresent(feedUrl, forKey: .feedUrl)
            try container.encodeIfPresent(trackViewUrl, forKey: .trackViewUrl)
            try container.encodeIfPresent(collectionViewUrl, forKey: .collectionViewUrl)
            try container.encodeIfPresent(primaryGenreName, forKey: .primaryGenreName)
            try container.encodeIfPresent(genreIdsRaw, forKey: .genreIds)
            try container.encodeIfPresent(genresRaw, forKey: .genres)
        }

        // Helper enums for handling mixed types from iTunes API
        enum GenreIdsRaw: Codable {
            case string(String)
            case array([String])

            var arrayValue: [String]? {
                switch self {
                case .string(let s): return [s]
                case .array(let a): return a
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    self = .string(stringValue)
                } else if let arrayValue = try? container.decode([String].self) {
                    self = .array(arrayValue)
                } else {
                    self = .array([])
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let s): try container.encode(s)
                case .array(let a): try container.encode(a)
                }
            }
        }

        enum GenresRaw: Codable {
            case string(String)
            case array([String])

            var arrayValue: [String]? {
                switch self {
                case .string(let s): return [s]
                case .array(let a): return a
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let stringValue = try? container.decode(String.self) {
                    self = .string(stringValue)
                } else if let arrayValue = try? container.decode([String].self) {
                    self = .array(arrayValue)
                } else {
                    self = .array([])
                }
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                switch self {
                case .string(let s): try container.encode(s)
                case .array(let a): try container.encode(a)
                }
            }
        }
    }

    struct SearchResponse: Codable {
        let resultCount: Int
        let results: [iTunesPodcast]
    }

    private init() {}

    func search(query: String) async throws -> [iTunesPodcast] {
        print("🔍 [iTunesSearch] Searching for: \(query)")

        // Check DataCacheManager first
        let cacheKey = "search_\(query.lowercased())"
        if let cached: [iTunesPodcast] = await DataCacheManager.shared.get(key: cacheKey, as: [iTunesPodcast].self) {
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

            // Cache results using DataCacheManager (30 minutes for search)
            await DataCacheManager.shared.set(key: cacheKey, value: decoded.results, duration: .medium)

            print("✅ [iTunesSearch] Found \(decoded.resultCount) results")
            return decoded.results
        } catch {
            print("❌ [iTunesSearch] Search failed: \(error)")
            throw error
        }
    }

    /// Clear search cache
    func clearCache() {
        Task {
            await DataCacheManager.shared.clearAll()
        }
        print("🗑️ [iTunesSearch] Cache cleared")
    }
}
