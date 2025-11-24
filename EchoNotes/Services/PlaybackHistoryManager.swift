//
//  PlaybackHistoryManager.swift
//  EchoNotes
//
//  Manages playback history and recently played episodes
//

import Foundation

struct PlaybackHistoryItem: Codable, Identifiable {
    let id: String // Episode ID
    let episodeTitle: String
    let podcastTitle: String
    let podcastID: String
    let audioURL: String
    var currentTime: TimeInterval
    var duration: TimeInterval
    var lastPlayed: Date
    var isFinished: Bool

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}

@MainActor
class PlaybackHistoryManager: ObservableObject {
    static let shared = PlaybackHistoryManager()

    @Published var recentlyPlayed: [PlaybackHistoryItem] = []

    private let userDefaultsKey = "playbackHistory"
    private let maxHistory = 50 // Keep last 50 items

    private init() {
        loadHistory()
    }

    // MARK: - Update History

    func updatePlayback(
        episodeID: String,
        episodeTitle: String,
        podcastTitle: String,
        podcastID: String,
        audioURL: String,
        currentTime: TimeInterval,
        duration: TimeInterval
    ) {
        let isFinished = duration > 0 && currentTime >= duration * 0.95 // 95% completion counts as finished

        let item = PlaybackHistoryItem(
            id: episodeID,
            episodeTitle: episodeTitle,
            podcastTitle: podcastTitle,
            podcastID: podcastID,
            audioURL: audioURL,
            currentTime: currentTime,
            duration: duration,
            lastPlayed: Date(),
            isFinished: isFinished
        )

        // Remove existing entry for this episode
        recentlyPlayed.removeAll { $0.id == episodeID }

        // Add to front if not finished
        if !isFinished {
            recentlyPlayed.insert(item, at: 0)
        }

        // Keep only max items
        if recentlyPlayed.count > maxHistory {
            recentlyPlayed = Array(recentlyPlayed.prefix(maxHistory))
        }

        saveHistory()
    }

    func removeFromHistory(episodeID: String) {
        recentlyPlayed.removeAll { $0.id == episodeID }
        saveHistory()
    }

    func getPlaybackPosition(for episodeID: String) -> TimeInterval? {
        return recentlyPlayed.first { $0.id == episodeID }?.currentTime
    }

    func getPlaybackHistory(for episodeID: String) -> PlaybackHistoryItem? {
        return recentlyPlayed.first { $0.id == episodeID }
    }

    // MARK: - Recently Played (Not Finished)

    func getRecentlyPlayed(limit: Int = 3) -> [PlaybackHistoryItem] {
        return Array(recentlyPlayed
            .filter { !$0.isFinished }
            .prefix(limit))
    }

    // MARK: - Persistence

    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(recentlyPlayed) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([PlaybackHistoryItem].self, from: data) {
            recentlyPlayed = decoded
        }
    }
}
