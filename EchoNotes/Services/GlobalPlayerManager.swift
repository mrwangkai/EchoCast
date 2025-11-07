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

    private init() {
        setupAudioSession()
        setupRemoteCommandCenter()
    }

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [])
            try audioSession.setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to set up audio session: \(error)")
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
        currentEpisode = episode
        currentPodcast = podcast
        playerError = nil
        isBuffering = true

        Task { @MainActor in
            DevStatusManager.shared.playerStatus = .loading
            DevStatusManager.shared.addMessage("Loading episode: \(episode.title)")
        }

        // Check if episode is downloaded locally
        let episodeID = episode.id.uuidString
        let downloadManager = EpisodeDownloadManager.shared

        let audioURL: URL?

        if let localURL = downloadManager.getLocalFileURL(for: episodeID),
           downloadManager.isDownloaded(episodeID) {
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
        player = AVPlayer(playerItem: playerItem)

        // Observe player item status for errors
        statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    print("✅ Player ready to play")
                    self?.playerError = nil
                    self?.isBuffering = false
                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .success
                        DevStatusManager.shared.networkStatus = .success
                        DevStatusManager.shared.addMessage("Player ready to play")
                    }
                case .failed:
                    let errorMessage = item.error?.localizedDescription ?? "Unknown playback error"
                    print("❌ Player failed: \(errorMessage)")
                    self?.playerError = "Playback failed: \(errorMessage)"
                    self?.isBuffering = false
                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .error(errorMessage)
                        DevStatusManager.shared.networkStatus = .error("Failed")
                        DevStatusManager.shared.addMessage("Player failed: \(errorMessage)")
                    }
                case .unknown:
                    print("⏳ Player status unknown")
                    self?.isBuffering = true
                    Task { @MainActor in
                        DevStatusManager.shared.playerStatus = .loading
                        DevStatusManager.shared.addMessage("Player status unknown")
                    }
                @unknown default:
                    break
                }
            }
        }

        // Observe current time
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds

            // Update Now Playing info
            self.updateNowPlayingInfo()

            // Update playback history every 10 seconds
            if self.currentTime - self.lastHistoryUpdate >= 10.0 {
                self.savePlaybackHistory()
                self.lastHistoryUpdate = self.currentTime
            }
        }

        // Get duration
        if let asset = player?.currentItem?.asset {
            Task {
                do {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = duration.seconds
                        self.updateNowPlayingInfo()
                    }
                } catch {
                    print("⚠️ Error loading duration: \(error)")
                }
            }
        }

        // Don't show mini player here - let the player view control this
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        showMiniPlayer = false
        currentEpisode = nil
        currentPodcast = nil
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
    }

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

        Task { @MainActor in
            PlaybackHistoryManager.shared.updatePlayback(
                episodeID: episode.id.uuidString,
                episodeTitle: episode.title,
                podcastTitle: podcast.title ?? "Unknown Podcast",
                podcastID: podcast.id ?? UUID().uuidString,
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

class EpisodeDownloadManager: NSObject, ObservableObject {
    static let shared = EpisodeDownloadManager()

    @Published var downloadProgress: [String: Double] = [:] // episodeID -> progress
    @Published var downloadedEpisodes: Set<String> = [] // episodeIDs

    private var activeDownloads: [String: URLSessionDownloadTask] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "com.echonotes.downloads")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private override init() {
        super.init()
        loadDownloadedEpisodes()
    }

    // MARK: - Download Management

    func downloadEpisode(_ episode: RSSEpisode) {
        guard let audioURLString = episode.audioURL,
              let url = URL(string: audioURLString) else {
            print("Invalid audio URL for episode: \(episode.title)")
            Task { @MainActor in
                DevStatusManager.shared.downloadStatus = .error("Invalid URL")
                DevStatusManager.shared.addMessage("Download failed: Invalid URL")
            }
            return
        }

        let episodeID = episode.id.uuidString

        // Check if already downloaded
        if downloadedEpisodes.contains(episodeID) {
            print("Episode already downloaded: \(episode.title)")
            return
        }

        // Check if already downloading
        if activeDownloads[episodeID] != nil {
            print("Episode already downloading: \(episode.title)")
            return
        }

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

        DispatchQueue.main.async {
            self.downloadProgress.removeValue(forKey: episodeID)
        }
    }

    func deleteDownload(_ episodeID: String) {
        guard let fileURL = getLocalFileURL(for: episodeID) else { return }

        try? FileManager.default.removeItem(at: fileURL)

        DispatchQueue.main.async {
            self.downloadedEpisodes.remove(episodeID)
            self.saveDownloadedEpisodes()
        }
    }

    // MARK: - File Management

    func getLocalFileURL(for episodeID: String) -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)

        // Create directory if needed
        if !FileManager.default.fileExists(atPath: downloadsPath.path) {
            try? FileManager.default.createDirectory(at: downloadsPath, withIntermediateDirectories: true)
        }

        return downloadsPath.appendingPathComponent("\(episodeID).mp3")
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
}

// MARK: - URLSessionDownloadDelegate

extension EpisodeDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let episodeID = downloadTask.taskDescription,
              let destinationURL = getLocalFileURL(for: episodeID) else {
            return
        }

        // Move file to permanent location
        do {
            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            try FileManager.default.moveItem(at: location, to: destinationURL)

            DispatchQueue.main.async {
                self.downloadedEpisodes.insert(episodeID)
                self.activeDownloads.removeValue(forKey: episodeID)
                self.downloadProgress.removeValue(forKey: episodeID)
                self.saveDownloadedEpisodes()

                print("Download completed for episode: \(episodeID)")
                Task { @MainActor in
                    DevStatusManager.shared.downloadStatus = .success
                    DevStatusManager.shared.addMessage("Download completed")
                }
            }
        } catch {
            print("Error moving downloaded file: \(error)")
            Task { @MainActor in
                DevStatusManager.shared.downloadStatus = .error("Move failed")
                DevStatusManager.shared.addMessage("Error: \(error.localizedDescription)")
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
