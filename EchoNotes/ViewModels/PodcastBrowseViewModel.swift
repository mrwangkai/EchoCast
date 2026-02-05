//
//  PodcastBrowseViewModel.swift
//  EchoNotes
//
//  View model for podcast browsing with genre support
//

import Foundation
import SwiftUI

@MainActor
class PodcastBrowseViewModel: ObservableObject {
    @Published var genreResults: [PodcastGenre: [iTunesSearchService.iTunesPodcast]] = [:]
    @Published var isLoadingGenres: Set<PodcastGenre> = []
    @Published var searchResults: [iTunesSearchService.iTunesPodcast] = []
    @Published var isSearching: Bool = false
    @Published var selectedGenre: PodcastGenre? = nil

    private let apiService = PodcastAPIService.shared

    // MARK: - Load All Genres

    /// Load podcasts for all main genres on app launch
    func loadAllGenres() async {
        print("📡 [BrowseViewModel] Loading all genres...")

        let genresToLoad = PodcastGenre.mainGenres.filter { $0 != .all }

        for genre in genresToLoad {
            await loadPodcasts(for: genre)
        }

        print("✅ [BrowseViewModel] All genres loaded")
    }

    // MARK: - Load Single Genre

    /// Load podcasts for a specific genre
    func loadPodcasts(for genre: PodcastGenre) async {
        // Skip if already loading or loaded
        if isLoadingGenres.contains(genre) || genreResults[genre] != nil {
            print("⏭️ [BrowseViewModel] Skipping \(genre.displayName) - already loaded/loading")
            return
        }

        isLoadingGenres.insert(genre)
        print("📡 [BrowseViewModel] Loading \(genre.displayName)...")

        do {
            let podcasts = try await apiService.getTopPodcasts(genreId: genre.rawValue, limit: 10)
            genreResults[genre] = podcasts
            print("✅ [BrowseViewModel] Loaded \(podcasts.count) podcasts for \(genre.displayName)")
        } catch {
            print("❌ [BrowseViewModel] Failed to load \(genre.displayName): \(error)")
        }

        isLoadingGenres.remove(genre)
    }

    // MARK: - Search

    /// Search for podcasts by query
    func search(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        print("🔍 [BrowseViewModel] Searching: \(query)")

        do {
            searchResults = try await apiService.search(query: query, limit: 20)
            print("✅ [BrowseViewModel] Found \(searchResults.count) results")
        } catch {
            print("❌ [BrowseViewModel] Search failed: \(error)")
        }

        isSearching = false
    }

    // MARK: - Get Podcasts for Genre

    /// Get cached podcasts for a genre, or load if not available
    func getPodcasts(for genre: PodcastGenre) -> [iTunesSearchService.iTunesPodcast] {
        if let podcasts = genreResults[genre] {
            return Array(podcasts.prefix(10))
        }
        return []
    }

    /// Check if genre is currently loading
    func isLoadingGenre(_ genre: PodcastGenre) -> Bool {
        return isLoadingGenres.contains(genre)
    }
}
