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

    /// Load podcasts for all main genres on app launch using parallel loading
    func loadAllGenres() async {
        print("📡 [BrowseViewModel] Loading all genres in parallel...")

        let genresToLoad = PodcastGenre.mainGenres.filter { $0 != .all }

        // Mark all as loading initially for skeleton placeholders
        for genre in genresToLoad {
            isLoadingGenres.insert(genre)
        }

        // Load all genres in parallel using TaskGroup
        await withTaskGroup(of: (PodcastGenre, [iTunesSearchService.iTunesPodcast]).self) { group in
            for genre in genresToLoad {
                group.addTask {
                    do {
                        let podcasts = try await self.apiService.getTopPodcasts(genreId: genre.rawValue, limit: 10)
                        return (genre, podcasts)
                    } catch {
                        print("❌ [BrowseViewModel] Failed to load \(genre.displayName): \(error)")
                        return (genre, [])
                    }
                }
            }

            // Collect results as they complete
            for await (genre, podcasts) in group {
                genreResults[genre] = podcasts
                isLoadingGenres.remove(genre)
                print("✅ [BrowseViewModel] Loaded \(podcasts.count) podcasts for \(genre.displayName)")
            }
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

    // MARK: - Load More for Genre (for "View All")

    /// Load more podcasts for a specific genre (used by "View all" sheet)
    func loadMoreForGenre(_ genre: PodcastGenre, limit: Int) async {
        print("📡 [ViewModel] loadMoreForGenre called")
        print("📡 [ViewModel] Genre: \(genre.displayName)")
        print("📡 [ViewModel] Limit: \(limit)")

        do {
            print("📡 [ViewModel] Fetching from API...")
            let podcasts = try await apiService.getTopPodcasts(
                genreId: genre.rawValue,
                limit: limit
            )

            print("📡 [ViewModel] Fetched \(podcasts.count) podcasts from API")

            // Update on main thread to ensure UI updates
            genreResults[genre] = podcasts
            print("✅ [ViewModel] genreResults updated - now have \(podcasts.count) podcasts")
        } catch {
            print("❌ [ViewModel] Failed to load more podcasts: \(error)")
            print("❌ [ViewModel] Error details: \(error.localizedDescription)")
        }
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

    /// Get all cached podcasts for a genre (for View All)
    func getAllPodcasts(for genre: PodcastGenre) -> [iTunesSearchService.iTunesPodcast] {
        return genreResults[genre] ?? []
    }

    /// Check if genre is currently loading
    func isLoadingGenre(_ genre: PodcastGenre) -> Bool {
        return isLoadingGenres.contains(genre)
    }
}
