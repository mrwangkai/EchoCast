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
    @State private var selectedEpisode: RSSEpisode?

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
            } else if episodes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No episodes found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(episodes) { episode in
                        EpisodeRowView(episode: episode, onPlay: {
                            print("👆 Play tapped for episode: \(episode.title)")
                            selectedEpisode = episode
                            print("   Selected episode set: \(selectedEpisode?.title ?? "nil")")
                        })
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
        .onAppear {
            loadEpisodes()
        }
        .sheet(item: $selectedEpisode) { episode in
            PlayerSheetWrapper(
                episode: episode,
                podcast: podcast,
                dismiss: {
                    print("❌ Dismissing player sheet")
                    selectedEpisode = nil
                }
            )
            .onAppear {
                print("🎬 Opening player sheet for episode: \(episode.title)")
                print("📱 Podcast: \(podcast.title ?? "Unknown")")
                print("🔊 Audio URL: \(episode.audioURL ?? "No URL")")
            }
        }
    }

    private func loadEpisodes() {
        guard let feedURL = podcast.feedURL else { return }

        isLoadingEpisodes = true
        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                await MainActor.run {
                    episodes = rssPodcast.episodes
                    isLoadingEpisodes = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading episodes: \(error)")
                    isLoadingEpisodes = false
                }
            }
        }
    }

    private func deleteEpisode(_ episode: RSSEpisode) {
        episodes.removeAll { $0.id == episode.id }
    }
}

// MARK: - Podcast Header

struct PodcastHeaderView: View {
    let podcast: PodcastEntity

    var body: some View {
        HStack(spacing: 16) {
            // Artwork
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                )

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
    var onPlay: () -> Void = {}
    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared
    @FetchRequest private var episodeNotes: FetchedResults<NoteEntity>

    init(episode: RSSEpisode, onPlay: @escaping () -> Void = {}) {
        self.episode = episode
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
                let episodeID = episode.id.uuidString

                if let progress = downloadManager.downloadProgress[episodeID] {
                    // Downloading - fixed width to prevent jitter
                    HStack(spacing: 4) {
                        ProgressView(value: progress)
                            .frame(width: 40)
                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .frame(width: 35, alignment: .trailing)
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
                        downloadManager.downloadEpisode(episode)
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.gray)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(width: 24)
                }

                // Play button
                Button(action: {
                    print("▶️ Play button tapped for: \(episode.title)")
                    onPlay()
                }) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .contextMenu {
            let episodeID = episode.id.uuidString

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
                    downloadManager.downloadEpisode(episode)
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
