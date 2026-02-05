//
//  PodcastDetailView.swift
//  EchoNotes
//
//  Podcast detail view with episode list and player
//

import SwiftUI
import AVFoundation

struct PodcastDetailView: View {
    let podcast: PodcastEntity
    @State private var episodes: [RSSEpisode] = []
    @State private var isLoadingEpisodes = false
    @State private var errorMessage: String?
    @State private var showPlayerSheet = false
    @State private var selectedEpisode: RSSEpisode?
    @State private var showDeleteConfirmation = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Podcast Header
            PodcastHeaderView(podcast: podcast)
                .padding()

            Divider()

            // Episodes List
            if isLoadingEpisodes {
                ProgressView("Loading episodes...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Failed to load episodes")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        loadEpisodes()
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if episodes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No episodes found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    if let feedURL = podcast.feedURL {
                        Text("Feed: \(feedURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(episodes) { episode in
                        Button(action: {
                            // Reset state first, then set in async to ensure proper timing
                            selectedEpisode = nil
                            showPlayerSheet = false

                            DispatchQueue.main.async {
                                selectedEpisode = episode
                                DispatchQueue.main.async {
                                    showPlayerSheet = true
                                }
                            }
                        }) {
                            EpisodeRowView(
                                episode: episode,
                                podcastTitle: podcast.title ?? "Unknown Podcast",
                                podcastFeedURL: podcast.feedURL
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteEpisode(episode)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(podcast.title ?? "Podcast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Podcast", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                }
            }
        }
        .alert("Delete Podcast", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deletePodcast()
            }
        } message: {
            Text("Are you sure you want to delete this podcast and all its downloaded episodes? This action cannot be undone.")
        }
        .onAppear {
            loadEpisodes()
        }
        .sheet(isPresented: $showPlayerSheet) {
            if let episode = selectedEpisode {
                PlayerSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    dismiss: { showPlayerSheet = false },
                    autoPlay: true,
                    seekToTime: nil
                )
            } else {
                // Fallback if episode is missing
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading episode...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    print("⚠️ Episode sheet opened but selectedEpisode is nil")

                    // Auto-dismiss after 5 seconds if still nil (DO NOT force re-render)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if selectedEpisode == nil {
                            print("❌ Timeout: Episode data still nil after 5s - closing sheet")
                            showPlayerSheet = false
                        }
                    }
                }
            }
        }
    }

    private func loadEpisodes() {
        guard let feedURL = podcast.feedURL else {
            errorMessage = "No feed URL available for this podcast"
            return
        }

        isLoadingEpisodes = true
        errorMessage = nil
        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                await MainActor.run {
                    episodes = rssPodcast.episodes
                    isLoadingEpisodes = false
                    print("✅ Loaded \(rssPodcast.episodes.count) episodes from \(rssPodcast.title)")
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoadingEpisodes = false
                    print("❌ Error loading episodes: \(error)")
                }
            }
        }
    }

    private func deleteEpisode(_ episode: RSSEpisode) {
        episodes.removeAll { $0.id == episode.id }
    }

    private func deletePodcast() {
        // Delete all downloaded episodes for this podcast
        let podcastFeedURL = podcast.feedURL
        let downloadedEpisodes = Array(downloadManager.downloadedEpisodes)

        for episodeID in downloadedEpisodes {
            if let metadata = downloadManager.getMetadata(for: episodeID),
               metadata.podcastFeedURL == podcastFeedURL {
                downloadManager.deleteDownload(episodeID)
            }
        }

        // Delete the podcast from Core Data
        viewContext.delete(podcast)

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting podcast: \(error)")
        }
    }
}

// MARK: - Podcast Header

struct PodcastHeaderView: View {
    let podcast: PodcastEntity

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            AsyncImage(url: URL(string: podcast.artworkURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.8)
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 100, height: 100)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if let title = podcast.title {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(2)
                }
                if let author = podcast.author {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                if let description = podcast.podcastDescription {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Episode Row

struct EpisodeRowView: View {
    let episode: RSSEpisode
    var podcastTitle: String = "Unknown Podcast"
    var podcastFeedURL: String? = nil
    var onPlay: () -> Void = {}
    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared
    @FetchRequest private var episodeNotes: FetchedResults<NoteEntity>

    init(episode: RSSEpisode, podcastTitle: String = "Unknown Podcast", podcastFeedURL: String? = nil, onPlay: @escaping () -> Void = {}) {
        self.episode = episode
        self.podcastTitle = podcastTitle
        self.podcastFeedURL = podcastFeedURL
        self.onPlay = onPlay

        // Fetch notes for this episode
        _episodeNotes = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
            predicate: NSPredicate(format: "episodeTitle == %@", episode.title)
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(episode.title)
                .font(.headline)
                .lineLimit(2)

            if let description = episode.description {
                Text(description.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            // Note count indicator
            if !episodeNotes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("\(episodeNotes.count) note\(episodeNotes.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 2)
            }

            HStack {
                if let pubDate = episode.pubDate {
                    Text(pubDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                if let duration = episode.duration {
                    Text("•")
                        .foregroundColor(.gray)
                    Text(duration)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Download status indicator
                let episodeID = episode.id

                if let progress = downloadManager.downloadProgress[episodeID] {
                    // Downloading - fixed width to prevent jitter
                    if progress >= 0.99 {
                        // Show "Downloaded" when at 100%
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Downloaded")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 4) {
                            ProgressView(value: progress)
                                .frame(width: 40)
                            Text("\(Int(progress * 100))%")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                } else if downloadManager.isDownloaded(episodeID) {
                    // Downloaded
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                        .frame(width: 24)
                } else {
                    // Not downloaded
                    Button(action: {
                        downloadManager.downloadEpisode(episode, podcastTitle: podcastTitle, podcastFeedURL: podcastFeedURL)
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 24)
                }
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            let episodeID = episode.id

            if downloadManager.isDownloading(episodeID) {
                Button(role: .destructive, action: {
                    downloadManager.cancelDownload(episodeID)
                }) {
                    Label("Cancel Download", systemImage: "xmark.circle")
                }
            } else if downloadManager.isDownloaded(episodeID) {
                Button(role: .destructive, action: {
                    downloadManager.deleteDownload(episodeID)
                }) {
                    Label("Delete Download", systemImage: "trash")
                }
            } else {
                Button(action: {
                    downloadManager.downloadEpisode(episode, podcastTitle: podcastTitle, podcastFeedURL: podcastFeedURL)
                }) {
                    Label("Download Episode", systemImage: "arrow.down.circle")
                }
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let podcast = PodcastEntity(context: context)
    podcast.id = "preview"
    podcast.title = "Sample Podcast"
    podcast.author = "Sample Author"
    podcast.podcastDescription = "A great podcast about technology and life"
    podcast.feedURL = "http://multiverseradio.ca/feed/feed.xml"

    return PodcastDetailView(podcast: podcast)
}
