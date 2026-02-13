//
//  GlobalPlayerManager.swift
//  EchoNotes
//
//  Global audio player state that persists across views
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
import MediaPlayer
import CoreData

class GlobalPlayerManager: ObservableObject {
    static let shared = GlobalPlayerManager()

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentEpisode: RSSEpisode?
    @Published var currentPodcast: PodcastEntity?
    @Published var showMiniPlayer = false
    @Published var showFullPlayer = false
    @Published var playerError: String?
    @Published var isBuffering = false

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var lastHistoryUpdate: TimeInterval = 0
    private var pendingSeekTime: TimeInterval?
    private var pendingAutoPlay: Bool = false

    private init() {
        print("🎵 [Player] GlobalPlayerManager initializing")
        setupAudioSession()
        setupRemoteCommandCenter()
        print("✅ [Player] GlobalPlayerManager initialized")
    }

    private func setupAudioSession() {
        print("🔊 [Player] Setting up audio session")

        let audioSession = AVAudioSession.sharedInstance()

        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            print("✅ [Player] Audio session category set to .playback")

            try audioSession.setActive(true)
            print("✅ [Player] Audio session activated")

        } catch {
            print("❌ [Player] Audio session setup failed: \(error.localizedDescription)")
        }
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Skip forward command
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { [weak self] _ in
            self?.skipForward(30)
            return .success
        }

        // Skip backward command
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [30]
        commandCenter.skipBackwardCommand.addTarget { [weak self] _ in
            self?.skipBackward(30)
            return .success
        }

        // Disable continuous seek commands (we want discrete 30s skips instead)
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false

        print("✅ Remote command center configured")
    }

    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        if let episode = currentEpisode {
            nowPlayingInfo[MPMediaItemPropertyTitle] = episode.title
        }

        if let podcast = currentPodcast {
            nowPlayingInfo[MPMediaItemPropertyArtist] = podcast.title ?? "Unknown Podcast"
        }

        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func loadEpisode(_ episode: RSSEpisode, podcast: PodcastEntity) {
        pendingSeekTime = nil
        pendingAutoPlay = false

        // Check if this is the same episode that's already loaded
        if let currentEp = currentEpisode,
           currentEp.id == episode.id,
           currentPodcast?.id == podcast.id {
            print("✅ Episode already loaded, resuming playback")
            showMiniPlayer = true
            return
        }

        currentEpisode = episode
        currentPodcast = podcast
        playerError = nil
        isBuffering = true

        Task { @MainActor in
            DevStatusManager.shared.playerStatus = .loading
            DevStatusManager.shared.addMessage("Loading episode: \(episode.title)")
        }

        // Check if episode is downloaded locally
        let episodeID = episode.id
        let downloadManager = EpisodeDownloadManager.shared

        let audioURL: URL?

        if let localURL = downloadManager.getLocalFileURL(for: episodeID),
           downloadManager.isDownloaded(episodeID),
           FileManager.default.fileExists(atPath: localURL.path) {
            // Use local file
            audioURL = localURL
            print("✅ Playing from local file: \(localURL.lastPathComponent)")
            Task { @MainActor in
                DevStatusManager.shared.addMessage("Playing from local file")
            }
        } else {
            // Stream from URL
            guard let audioURLString = episode.audioURL?.trimmingCharacters(in: .whitespaces),
                  !audioURLString.isEmpty else {
                print("❌ Error: Empty audio URL for episode: \(episode.title)")
                Task { @MainActor in
                    DevStatusManager.shared.playerStatus = .error("Empty URL")
                    DevStatusManager.shared.addMessage("Error: Empty audio URL")
                }
                DispatchQueue.main.async {
                    self.playerError = "No audio URL available for this episode"
                    self.isBuffering = false
                }
                return
            }

            guard let remoteURL = URL(string: audioURLString) else {
                print("❌ Error: Invalid audio URL: \(audioURLString)")
                Task { @MainActor in
                    DevStatusManager.shared.playerStatus = .error("Invalid URL")
                    DevStatusManager.shared.addMessage("Error: Invalid audio URL")
                }
                DispatchQueue.main.async {
                    self.playerError = "Invalid audio URL"
                    self.isBuffering = false
                }
                return
            }

            audioURL = remoteURL
            print("🌐 Streaming from: \(audioURLString)")
            print("✅ [Player] Valid audio URL: \(remoteURL.absoluteString)")
            print("🔍 [Player] URL scheme: \(remoteURL.scheme ?? "none")")
            print("🔍 [Player] URL is file: \(remoteURL.isFileURL)")
            print("🔍 [Player] URL host: \(remoteURL.host ?? "none")")
            Task { @MainActor in
                DevStatusManager.shared.addMessage("Streaming from URL")
                DevStatusManager.shared.networkStatus = .loading
            }
        }

        guard let url = audioURL else {
            DispatchQueue.main.async {
                self.playerError = "Unable to load audio"
                self.isBuffering = false
            }
            return
        }

        // Remove previous observers
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        statusObserver?.invalidate()
        statusObserver = nil

        // Create player
        let playerItem = AVPlayerItem(url: url)
        print("🔍 [Player] Created AVPlayerItem")
        print("🔍 [Player] Item status immediately: \(playerItem.status.rawValue)")
        print("🔍 [Player] Item status string: \(statusString(playerItem.status))")

        player = AVPlayer(playerItem: playerItem)
        print("🔍 [Player] Created AVPlayer")
        print("🔍 [Player] Player rate: \(player?.rate ?? -1)")

        // Observe player item status for errors
        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            guard let self = self else { return }

            let statusName = self.statusString(item.status)
            print("🔍 [Player] Status changed to: \(item.status.rawValue) (\(statusName))")

            DispatchQueue.main.async {
                switch item.status {
                case .unknown:
                    print("⏳ [Player] Status: unknown - waiting for player item to load...")
                    self.isBuffering = true
                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .loading
                        DevStatusManager.shared.addMessage("Player status unknown")
                    }

                case .readyToPlay:
                    print("✅ [Player] Status: readyToPlay - player is ready!")

                    let durationSeconds = CMTimeGetSeconds(item.duration)
                    print("🔍 [Player] Duration value: \(durationSeconds)")

                    if durationSeconds.isFinite && durationSeconds > 0 {
                        Task { @MainActor in
                            self.duration = durationSeconds
                            print("✅ [Player] Duration set: \(Int(durationSeconds))s (\(self.formatTime(durationSeconds)))")
                        }
                    } else {
                        print("⚠️ [Player] Duration not available or invalid: \(durationSeconds)")
                    }

                    self.playerError = nil
                    self.isBuffering = false

                    // Resume from saved position if available
                    if let episode = self.currentEpisode {
                        let episodeID = episode.id
                        if let savedPosition = PlaybackHistoryManager.shared.getPlaybackPosition(for: episodeID),
                           savedPosition > 0 {
                            print("⏭️ Resuming from saved position: \(savedPosition)s")
                            self.seek(to: savedPosition)
                        }
                    }

                    // Handle pending seek time from loadEpisodeAndPlay
                    if let pending = self.pendingSeekTime {
                        self.seek(to: pending)
                        self.pendingSeekTime = nil
                    }

                    // Auto-play when ready (for loadEpisodeAndPlay)
                    if self.pendingAutoPlay {
                        self.play()
                        self.pendingAutoPlay = false
                    }

                    // Add to playback history immediately when loaded so it shows in Continue Listening
                    self.savePlaybackHistory()

                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .success
                        DevStatusManager.shared.networkStatus = .success
                        DevStatusManager.shared.addMessage("Player ready to play")
                    }

                case .failed:
                    print("❌ [Player] Status: FAILED - player item failed to load")

                    if let error = item.error {
                        print("❌ [Player] Error: \(error.localizedDescription)")
                        print("❌ [Player] Error code: \((error as NSError).code)")
                        print("❌ [Player] Error domain: \((error as NSError).domain)")

                        // Log user info for more details
                        let userInfo = (error as NSError).userInfo
                        for (key, value) in userInfo {
                            print("❌ [Player] Error info - \(key): \(value)")
                        }
                    } else {
                        print("❌ [Player] No error object available")
                    }

                    let errorMessage = item.error?.localizedDescription ?? "Unknown playback error"
                    self.playerError = "Playback failed: \(errorMessage)"
                    self.isBuffering = false

                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .error(errorMessage)
                        DevStatusManager.shared.networkStatus = .error("Failed")
                        DevStatusManager.shared.addMessage("Player failed: \(errorMessage)")
                    }

                @unknown default:
                    print("⚠️ [Player] Unknown status: \(item.status.rawValue)")
                }
            }
        }

        // Setup time observer (CRITICAL for time updates)
        // ⏱️ [Player] Setting up time observer - updates every 0.5 seconds
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }

            let currentSeconds = time.seconds

            // ALWAYS print first to see if callback fires
            print("⏱️ [Player] Observer fired: \(Int(currentSeconds))s (stored: \(Int(self.currentTime))s, diff: \(abs(self.currentTime - currentSeconds)))")

            // Only update if changed significantly (avoid excessive UI updates)
            if abs(self.currentTime - currentSeconds) > 0.1 {
                self.currentTime = currentSeconds
                print("✅ [Player] Updated currentTime: \(Int(currentSeconds))s / \(Int(self.duration))s")
            } else {
                // Log why we're not updating
                // print("⏸️ [Player] Skipped update - diff too small: \(abs(self.currentTime - currentSeconds))")
            }

            // Update Now Playing info
            self.updateNowPlayingInfo()

            // Update playback history every 10 seconds
            if self.currentTime - self.lastHistoryUpdate >= 10.0 {
                self.savePlaybackHistory()
                self.lastHistoryUpdate = self.currentTime
            }
        }

        print("✅ [Player] Time observer setup complete")

        // Setup duration observer
        // ⏱️ [Player] Loading duration from asset
        if let asset = player?.currentItem?.asset {
            Task {
                do {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = duration.seconds
                        print("✅ [Player] Duration set: \(Int(duration.seconds))s (\(formatTime(duration.seconds)))")
                        self.updateNowPlayingInfo()
                    }
                } catch {
                    print("⚠️ [Player] Error loading duration: \(error)")
                }
            }
        }

        // Don't show mini player here - let the player view control this
    }

    func loadEpisodeAndPlay(_ episode: RSSEpisode, podcast: PodcastEntity, seekTo time: TimeInterval = 0) {
        pendingSeekTime = time > 0 ? time : nil
        pendingAutoPlay = true
        loadEpisode(episode, podcast: podcast)
        // play() will be called after readyToPlay fires
    }

    func togglePlayPause() {
        print("🎮 [Player] Toggle play/pause called, current state: isPlaying=\(isPlaying)")
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        print("▶️ [Player] Play called")

        guard let player = player else {
            print("❌ [Player] Cannot play - no player exists")
            return
        }

        guard let item = player.currentItem else {
            print("❌ [Player] Cannot play - no current item")
            return
        }

        let statusName = statusString(item.status)
        print("🔍 [Player] Current item status: \(item.status.rawValue) (\(statusName))")

        if item.status != .readyToPlay {
            print("⚠️ [Player] Item not ready to play! Status: \(statusName)")

            if let error = item.error {
                print("❌ [Player] Item has error: \(error.localizedDescription)")
            } else {
                print("⚠️ [Player] Item is still loading, will play when ready")
            }
        }

        print("🔍 [Player] Player rate before play(): \(player.rate)")
        print("🔍 [Player] Current time before play(): \(currentTime)")

        player.play()
        isPlaying = true

        print("✅ [Player] play() executed, isPlaying set to true")
        print("🔍 [Player] Player rate immediately after play(): \(player.rate)")

        // Auto-download episode if not already downloaded
        if let episode = currentEpisode, let podcast = currentPodcast {
            let downloadManager = EpisodeDownloadManager.shared
            if !downloadManager.isDownloaded(episode.id) && !downloadManager.isDownloading(episode.id) {
                print("📥 [Player] Auto-downloading episode: \(episode.title)")
                downloadManager.downloadEpisode(episode, podcastTitle: podcast.title ?? "Unknown Podcast", podcastFeedURL: podcast.feedURL)
            }
        }

        // Add to playback history immediately so it shows in Continue Listening
        savePlaybackHistory()

        // Check rate after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, let player = self.player else { return }
            print("🔍 [Player] Player rate 0.5s after play(): \(player.rate)")

            if player.rate == 0.0 {
                print("⚠️ [Player] WARNING: Player rate is still 0.0 after 0.5s")
                print("⚠️ [Player] This means audio is NOT playing")

                if let item = player.currentItem {
                    print("🔍 [Player] Item status: \(self.statusString(item.status))")
                    if let error = item.error {
                        print("❌ [Player] Item error: \(error.localizedDescription)")
                    }
                }
            } else {
                print("✅ [Player] Player is playing! Rate: \(player.rate)")
            }
        }

        updateNowPlayingInfo()
    }

    func pause() {
        print("⏸️ [Player] Pause called")
        player?.pause()
        isPlaying = false
        print("✅ [Player] isPlaying: false")
        updateNowPlayingInfo()
    }

    func stop() {
        // Save final position before stopping
        savePlaybackHistory()

        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        showMiniPlayer = false
        currentEpisode = nil
        currentPodcast = nil
    }

    func closeMiniPlayer() {
        // Save position but keep episode loaded
        if currentEpisode != nil && currentPodcast != nil {
            savePlaybackHistory()
        }
        player?.pause()
        isPlaying = false
        showMiniPlayer = false
    }

    func seek(to time: TimeInterval) {
        print("⏩ [Player] Seek to: \(formatTime(time))")
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] completed in
            if completed {
                print("✅ [Player] Seek completed")
                self?.currentTime = time
            } else {
                print("⚠️ [Player] Seek interrupted")
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func statusString(_ status: AVPlayerItem.Status) -> String {
        switch status {
        case .unknown:
            return "unknown"
        case .readyToPlay:
            return "readyToPlay"
        case .failed:
            return "FAILED"
        @unknown default:
            return "unknown_default"
        }
    }

    // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
    // /// Load an episode by ID and optionally seek to a timestamp
    // /// Used for deep linking
    // func loadEpisodeByID(_ episodeID: String, seekTo timestamp: TimeInterval? = nil, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
    //     Task { @MainActor in
    //         // Try to find the episode in playback history
    //         if let historyEntry = PlaybackHistoryManager.shared.getPlaybackHistory(for: episodeID),
    //            let podcast = fetchPodcast(byID: historyEntry.podcastID, context: context) {
    //
    //             // Create RSSEpisode from history
    //             let episode = RSSEpisode(
    //                 title: historyEntry.episodeTitle,
    //                 description: nil,
    //                 pubDate: nil,
    //                 duration: formatDuration(historyEntry.duration),
    //                 audioURL: historyEntry.audioURL,
    //                 imageURL: nil
    //             )
    //
    //             // Load the episode
    //             self.loadEpisode(episode, podcast: podcast)
    //
    //             // Seek to timestamp if provided
    //             if let timestamp = timestamp {
    //                 // Wait a bit for the player to be ready
    //                 DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
    //                     self.seek(to: timestamp)
    //                 }
    //             }
    //
    //             self.showMiniPlayer = true
    //             completion(true)
    //             return
    //         }
    //
    //         // Episode not found in history
    //         print("❌ Episode \(episodeID) not found in playback history")
    //         completion(false)
    //     }
    // }
    //
    // private func fetchPodcast(byID podcastID: String, context: NSManagedObjectContext) -> PodcastEntity? {
    //     let request = PodcastEntity.fetchRequest()
    //     request.predicate = NSPredicate(format: "id == %@", podcastID)
    //     request.fetchLimit = 1
    //
    //     do {
    //         let results = try context.fetch(request)
    //         return results.first
    //     } catch {
    //         print("❌ Error fetching podcast: \(error)")
    //         return nil
    //     }
    // }
    //
    // private func formatDuration(_ seconds: TimeInterval) -> String {
    //     let hours = Int(seconds) / 3600
    //     let minutes = Int(seconds) / 60 % 60
    //     let secs = Int(seconds) % 60
    //
    //     if hours > 0 {
    //         return String(format: "%d:%02d:%02d", hours, minutes, secs)
    //     } else {
    //         return String(format: "%d:%02d", minutes, secs)
    //     }
    // }

    func skipForward(_ seconds: TimeInterval) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }

    func skipBackward(_ seconds: TimeInterval) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }

    private func savePlaybackHistory() {
        guard let episode = currentEpisode,
              let podcast = currentPodcast else { return }

        // Use feedURL as fallback ID if podcast.id is nil
        // This ensures consistent identification across app sessions
        let podcastID: String
        if let id = podcast.id {
            podcastID = id
        } else if let feedURL = podcast.feedURL {
            // Generate deterministic ID from feed URL
            podcastID = "feed_\(abs(feedURL.hashValue))"
            print("⚠️ Podcast ID is nil, using feed URL hash: \(podcastID)")
        } else {
            // Last resort: use podcast title hash
            let title = podcast.title ?? "Unknown"
            podcastID = "title_\(abs(title.hashValue))"
            print("⚠️ Podcast ID and feedURL are nil, using title hash: \(podcastID)")
        }

        Task { @MainActor in
            PlaybackHistoryManager.shared.updatePlayback(
                episodeID: episode.id,
                episodeTitle: episode.title,
                podcastTitle: podcast.title ?? "Unknown Podcast",
                podcastID: podcastID,
                audioURL: episode.audioURL ?? "",
                currentTime: self.currentTime,
                duration: self.duration
            )
        }
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}

// MARK: - Episode Download Manager

// MARK: - Episode Download Metadata

struct DownloadedEpisodeMetadata: Codable {
    let episodeID: String
    let episodeTitle: String
    let podcastTitle: String
    let podcastFeedURL: String?
    let downloadDate: Date
}

class EpisodeDownloadManager: NSObject, ObservableObject {
    static let shared = EpisodeDownloadManager()

    @Published var downloadProgress: [String: Double] = [:] // episodeID -> progress
    @Published var downloadedEpisodes: Set<String> = [] // episodeIDs
    @Published var episodeMetadata: [String: DownloadedEpisodeMetadata] = [:] // episodeID -> metadata

    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    private var pendingMetadata: [String: DownloadedEpisodeMetadata] = [:] // Store metadata until download completes

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.echonotes.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        loadDownloadedEpisodes()
        loadEpisodeMetadata()
    }

    // MARK: - Download Management

    func downloadEpisode(_ episode: RSSEpisode, podcastTitle: String = "Unknown Podcast", podcastFeedURL: String? = nil) {
        guard let audioURLString = episode.audioURL,
              let url = URL(string: audioURLString) else {
            print("Invalid audio URL for episode: \(episode.title)")
            Task { @MainActor in
                DevStatusManager.shared.downloadStatus = .error("Invalid URL")
                DevStatusManager.shared.addMessage("Download failed: Invalid URL")
            }
            return
        }

        let episodeID = episode.id

        print("📥 Download requested for: \(episode.title)")
        print("   Episode ID: \(episodeID)")
        print("   Already downloaded: \(downloadedEpisodes.contains(episodeID))")
        print("   Currently downloading: \(activeDownloads[episodeID] != nil)")

        // Check if already downloaded
        if downloadedEpisodes.contains(episodeID) {
            print("⚠️ Episode already downloaded, skipping: \(episode.title)")
            return
        }

        // Check if already downloading
        if activeDownloads[episodeID] != nil {
            print("⚠️ Episode already downloading, skipping: \(episode.title)")
            return
        }

        // Store metadata for when download completes
        let metadata = DownloadedEpisodeMetadata(
            episodeID: episodeID,
            episodeTitle: episode.title,
            podcastTitle: podcastTitle,
            podcastFeedURL: podcastFeedURL,
            downloadDate: Date()
        )
        pendingMetadata[episodeID] = metadata

        // Start download
        let task = session.downloadTask(with: url)
        task.taskDescription = episodeID
        activeDownloads[episodeID] = task

        DispatchQueue.main.async {
            self.downloadProgress[episodeID] = 0.0
        }

        task.resume()
        print("Started downloading episode: \(episode.title)")
        Task { @MainActor in
            DevStatusManager.shared.downloadStatus = .loading
            DevStatusManager.shared.addMessage("Downloading: \(episode.title)")
        }
    }

    func cancelDownload(_ episodeID: String) {
        activeDownloads[episodeID]?.cancel()
        activeDownloads.removeValue(forKey: episodeID)
        pendingMetadata.removeValue(forKey: episodeID)

        DispatchQueue.main.async {
            self.downloadProgress.removeValue(forKey: episodeID)
        }
    }

    func deleteDownload(_ episodeID: String) {
        guard let fileURL = getLocalFileURL(for: episodeID) else { return }

        try? FileManager.default.removeItem(at: fileURL)

        DispatchQueue.main.async {
            self.downloadedEpisodes.remove(episodeID)
            self.episodeMetadata.removeValue(forKey: episodeID)
            self.saveDownloadedEpisodes()
            self.saveEpisodeMetadata()
        }
    }

    // MARK: - File Management

    /// Sanitizes episode ID (which is often a full URL) into a safe filename
    private func sanitizeFilename(from episodeID: String) -> String {
        // Create a hash for long URLs to ensure consistent, valid filenames
        let hash = abs(episodeID.hashValue)

        // Also create a readable prefix from the URL
        var sanitized = episodeID
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
            .replacingOccurrences(of: "=", with: "_")
            .replacingOccurrences(of: "%", with: "_")
            .replacingOccurrences(of: "#", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        // Limit prefix length and add hash for uniqueness
        if sanitized.count > 50 {
            sanitized = String(sanitized.prefix(50))
        }

        return "\(sanitized)_\(hash)"
    }

    func getLocalFileURL(for episodeID: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Could not get documents path")
            return nil
        }

        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: downloadsPath.path) {
            do {
                try FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
                print("✅ Created Downloads directory: \(downloadsPath.path)")
            } catch {
                print("❌ Failed to create Downloads directory: \(error)")
                return nil
            }
        }

        let safeFilename = sanitizeFilename(from: episodeID)
        let fileURL = downloadsPath.appendingPathComponent("\(safeFilename).mp3")

        print("📁 File path for episode:")
        print("   Original ID: \(episodeID.prefix(100))...")
        print("   Safe filename: \(safeFilename).mp3")
        print("   Full path: \(fileURL.path)")

        return fileURL
    }

    func isDownloaded(_ episodeID: String) -> Bool {
        return downloadedEpisodes.contains(episodeID)
    }

    func isDownloading(_ episodeID: String) -> Bool {
        return activeDownloads[episodeID] != nil
    }

    // MARK: - Persistence

    private func saveDownloadedEpisodes() {
        let array = Array(downloadedEpisodes)
        UserDefaults.standard.set(array, forKey: "downloadedEpisodes")
    }

    private func loadDownloadedEpisodes() {
        if let array = UserDefaults.standard.array(forKey: "downloadedEpisodes") as? [String] {
            downloadedEpisodes = Set(array)
        }
    }

    private func saveEpisodeMetadata() {
        let encoder = JSONEncoder()
        let metadataArray = Array(episodeMetadata.values)
        if let encoded = try? encoder.encode(metadataArray) {
            UserDefaults.standard.set(encoded, forKey: "episodeMetadata")
        }
    }

    private func loadEpisodeMetadata() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "episodeMetadata"),
           let metadataArray = try? decoder.decode([DownloadedEpisodeMetadata].self, from: data) {
            episodeMetadata = Dictionary(uniqueKeysWithValues: metadataArray.map { ($0.episodeID, $0) })
        }
    }

    func getMetadata(for episodeID: String) -> DownloadedEpisodeMetadata? {
        return episodeMetadata[episodeID]
    }
}

// MARK: - URLSessionDownloadDelegate

extension EpisodeDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("\n📥 Download finished!")
        print("   Temp location: \(location.path)")

        guard let episodeID = downloadTask.taskDescription else {
            print("❌ No episode ID in task description")
            return
        }

        print("   Episode ID: \(episodeID.prefix(100))...")

        guard let destinationURL = getLocalFileURL(for: episodeID) else {
            print("❌ Could not get destination URL for episode")
            return
        }

        // Move file to permanent location
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("   Removing existing file at destination")
                try FileManager.default.removeItem(at: destinationURL)
            }

            print("   Moving file from temp to permanent location...")
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("   ✅ File moved successfully!")

            // Verify file exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                let attributes = try? FileManager.default.attributesOfItem(atPath: destinationURL.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                print("   ✅ File verified! Size: \(fileSize) bytes")
            } else {
                print("   ⚠️ File does not exist after move!")
            }

            DispatchQueue.main.async {
                // Explicitly trigger objectWillChange before modifying
                self.objectWillChange.send()

                self.downloadedEpisodes.insert(episodeID)
                self.activeDownloads.removeValue(forKey: episodeID)
                self.downloadProgress.removeValue(forKey: episodeID)

                // Save metadata if available
                if let metadata = self.pendingMetadata[episodeID] {
                    self.episodeMetadata[episodeID] = metadata
                    self.pendingMetadata.removeValue(forKey: episodeID)
                    self.saveEpisodeMetadata()
                    print("   ✅ Metadata saved")
                }

                self.saveDownloadedEpisodes()

                print("✅ Download completed for episode: \(episodeID.prefix(100))...")
                print("   Downloaded episodes count: \(self.downloadedEpisodes.count)")
                print("   Is downloaded: \(self.downloadedEpisodes.contains(episodeID))")

                Task { @MainActor in
                    DevStatusManager.shared.downloadStatus = .success
                    DevStatusManager.shared.addMessage("Download completed")
                }
            }
        } catch {
            print("❌ Error moving downloaded file: \(error)")
            print("   From: \(location.path)")
            print("   To: \(destinationURL.path)")
            print("   Error details: \(error.localizedDescription)")

            Task { @MainActor in
                DevStatusManager.shared.downloadStatus = .error("Move failed")
                DevStatusManager.shared.addMessage("❌ Error: \(error.localizedDescription)")
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let episodeID = downloadTask.taskDescription else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            self.downloadProgress[episodeID] = progress
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let episodeID = task.taskDescription else { return }

        if let error = error {
            print("Download failed for episode \(episodeID): \(error)")

            DispatchQueue.main.async {
                self.activeDownloads.removeValue(forKey: episodeID)
                self.downloadProgress.removeValue(forKey: episodeID)
            }
        }
    }
}
