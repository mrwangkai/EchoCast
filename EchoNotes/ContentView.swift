//
//  ContentView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

// MARK: - UTType Extension

extension UTType {
    static var opml: UTType {
        UTType(importedAs: "org.opml.opml")
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var player = GlobalPlayerManager.shared
    @StateObject private var devStatus = DevStatusManager.shared
    @State private var showSiriNoteCaptureSheet = false
    @State private var siriNoteTimestamp = ""
    @State private var showFullPlayer = false  // NEW: Manage full player sheet at root level
    @Environment(\.managedObjectContext) private var viewContext
    // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
    // @EnvironmentObject private var deepLinkManager: DeepLinkManager
    // @State private var showDeepLinkAlert = false
    // @State private var deepLinkErrorMessage = ""

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                PodcastsListView()
                    .tabItem {
                        Label("Podcasts", systemImage: "mic.fill")
                    }
                    .tag(1)

                NotesListView(selectedTab: $selectedTab)
                    .tabItem {
                        Label("Notes", systemImage: "note.text")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.blue)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                // Always render MiniPlayerView, control visibility via opacity
                MiniPlayerView(showFullPlayer: $showFullPlayer)
                    .opacity(player.showMiniPlayer ? 1 : 0)
                    .frame(height: player.showMiniPlayer ? nil : 0)
                    .clipped()
            }
        }
        // FULL PLAYER SHEET - Attached to root ZStack (always exists)
        .sheet(isPresented: $showFullPlayer, onDismiss: {
            print("🔴 [ContentView] Sheet onDismiss called")
        }) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                PlayerSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    dismiss: {
                        print("🔴 [ContentView] Dismiss closure called")
                        showFullPlayer = false
                    },
                    autoPlay: false
                )
                .id(episode.id)  // Stable ID to prevent recreation
                .onAppear {
                    print("👁️ [ContentView Sheet] PlayerSheetWrapper appeared")
                }
                .onDisappear {
                    print("👁️ [ContentView Sheet] PlayerSheetWrapper disappeared")
                }
            } else {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .onAppear {
                    print("⚠️ [ContentView Sheet] Fallback view - episode/podcast is nil")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        if player.currentEpisode == nil || player.currentPodcast == nil {
                            showFullPlayer = false
                        }
                    }
                }
            }
        }
        .onAppear {
            checkForSiriIntent()
        }
        .onChange(of: showSiriNoteCaptureSheet) { _, newValue in
            if !newValue {
                // Clear flags when sheet is dismissed
                UserDefaults.standard.removeObject(forKey: "shouldShowNoteCaptureFromSiri")
                UserDefaults.standard.removeObject(forKey: "siriNoteTimestamp")
            }
        }
        // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
        // .onChange(of: deepLinkManager.pendingDeepLink) { _, newValue in
        //     if let deepLink = newValue {
        //         handleDeepLink(deepLink)
        //     }
        // }
        .sheet(isPresented: $showSiriNoteCaptureSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                QuickNoteCaptureView(
                    podcast: podcast,
                    episode: episode,
                    timestamp: siriNoteTimestamp
                )
            }
        }
        // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
        // .alert("Deep Link Error", isPresented: $showDeepLinkAlert) {
        //     Button("OK", role: .cancel) { }
        // } message: {
        //     Text(deepLinkErrorMessage)
        // }
    }

    // TODO: Uncomment when DeepLinkManager.swift is added to Xcode project
    // private func handleDeepLink(_ deepLink: DeepLinkDestination) {
    //     switch deepLink {
    //     case .episode(let episodeID, let timestamp):
    //         print("🔗 Handling deep link for episode: \(episodeID), timestamp: \(timestamp?.description ?? "none")")
    //
    //         player.loadEpisodeByID(episodeID, seekTo: timestamp, context: viewContext) { success in
    //             if success {
    //                 print("✅ Deep link handled successfully")
    //             } else {
    //                 deepLinkErrorMessage = "Episode not found. Make sure you've played this episode before."
    //                 showDeepLinkAlert = true
    //             }
    //
    //             // Clear the deep link
    //             deepLinkManager.clearPendingDeepLink()
    //         }
    //     }
    // }

    private func checkForSiriIntent() {
        if UserDefaults.standard.bool(forKey: "shouldShowNoteCaptureFromSiri") {
            siriNoteTimestamp = UserDefaults.standard.string(forKey: "siriNoteTimestamp") ?? ""
            showSiriNoteCaptureSheet = true
        }
    }
}

// MARK: - Empty States

struct EmptyPodcastsHomeView: View {
    let onAddPodcast: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "mic.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Button("Add Your First Podcast") {
                onAddPodcast()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptyNotesHomeView: View {
    var onFindPodcast: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Podcast Card
            HStack(spacing: 20) {
                // Left side: Text and button
                VStack(alignment: .leading, spacing: 16) {
                    Text("Discover podcasts and\nlisten to great content")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onFindPodcast) {
                        Text("Find Podcast")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right side: Podcast icon
                Image("mic")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
            }
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(16)

            // Notes Card
            HStack(spacing: 20) {
                // Left side: Notes icon
                Image("notes")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)

                // Right side: Text
                VStack(alignment: .leading, spacing: 12) {
                    Text("Capture insights while\nlistening to episodes")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Take timestamped notes with tags")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(24)
            .background(Color(.systemGray6))
            .cornerRadius(16)
        }
        .padding(.horizontal)
    }
}

// MARK: - Podcasts List View

struct PodcastsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var podcasts: FetchedResults<PodcastEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default)
    private var allNotes: FetchedResults<NoteEntity>

    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared
    @State private var showAddPodcastSheet = false
    @State private var showSearchSheet = false
    @State private var showEpisodePlayer = false
    @State private var showAllEpisodesSheet = false
    @State private var showOPMLImport = false
    @State private var selectedEpisode: RSSEpisode?
    @State private var selectedPodcast: PodcastEntity?
    @State private var isLoadingEpisode = false
    @State private var podcastToDelete: PodcastEntity?
    @State private var showDeletePodcastConfirmation = false
    @State private var selectedExplorePodcast: RecommendedPodcast?
    @State private var showExplorePodcastDetail = false

    // Recommended podcasts for zero state
    private let recommendedPodcasts = [
        RecommendedPodcast(
            title: "The Tim Ferriss Show",
            description: "Interviews with world-class performers",
            rssURL: "https://rss.art19.com/tim-ferriss-show",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/64/32/e3/6432e32a-1938-3f85-80a1-05e0d9f1f0be/mza_15545433498878218867.jpg/600x600bb.jpg"
        ),
        RecommendedPodcast(
            title: "Huberman Lab",
            description: "Science-based tools for everyday life",
            rssURL: "https://feeds.megaphone.fm/hubermanlab",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/8e/8b/97/8e8b9782-462e-c1b7-c7b4-49e70e2663f8/mza_2111121872644406144.jpg/600x600bb.jpg"
        ),
        RecommendedPodcast(
            title: "Lex Fridman Podcast",
            description: "Conversations about AI, science, and technology",
            rssURL: "https://lexfridman.com/feed/podcast/",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts125/v4/e7/ee/dd/e7eeddf2-a75f-e623-9cfc-3b1eae2ee6e3/mza_16428964146354887078.jpg/600x600bb.jpg"
        ),
        RecommendedPodcast(
            title: "How I Built This",
            description: "Stories behind the world's best known companies",
            rssURL: "https://feeds.npr.org/510313/podcast.xml",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/32/41/7a/32417aef-3e18-b73c-7a53-16e21c918701/mza_7821527367969406485.jpg/600x600bb.jpg"
        ),
        RecommendedPodcast(
            title: "The Daily",
            description: "The biggest stories of our time",
            rssURL: "https://feeds.simplecast.com/54nAGcIl",
            imageURL: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts126/v4/c4/6e/6c/c46e6cf0-3f3c-19ee-7021-8e7a8c59b535/mza_8467155565149422907.jpg/600x600bb.jpg"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    Button(action: {
                        showSearchSheet = true
                    }) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            Text("Search for podcasts...")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Explore Section (Grid of Top Podcasts) - only show when no podcasts
                    if podcasts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Explore")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                ForEach(recommendedPodcasts.prefix(12)) { podcast in
                                    ExplorePodcastCard(podcast: podcast, onTap: {
                                        selectedExplorePodcast = podcast
                                        showExplorePodcastDetail = true
                                    })
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Episodes Section (Carousel)
                    if !getIndividualEpisodes().isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Episodes")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: {
                                    showAllEpisodesSheet = true
                                }) {
                                    Text("view all")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 16) {
                                    ForEach(getIndividualEpisodes().prefix(5)) { item in
                                        EpisodeCardView(item: item, onTap: {
                                            playIndividualEpisode(item)
                                        })
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // My Podcasts Section (Horizontal Listing)
                    if !podcasts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("My Podcasts")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Spacer()
                                Button(action: {
                                    showOPMLImport = true
                                }) {
                                    Text("Import OPML")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(Array(podcasts)) { podcast in
                                    NavigationLink(destination: PodcastDetailView(podcast: podcast)) {
                                        HStack(spacing: 12) {
                                            // Thumbnail
                                            CachedAsyncImage(url: podcast.artworkURL) { image in
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 60, height: 60)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue.opacity(0.2))
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        Image(systemName: "music.note")
                                                            .foregroundColor(.blue)
                                                    )
                                            }

                                            // Info
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(podcast.title ?? "Unknown")
                                                    .font(.headline)
                                                    .lineLimit(2)
                                                    .foregroundColor(.primary)

                                                if let author = podcast.author {
                                                    Text(author)
                                                        .font(.subheadline)
                                                        .foregroundColor(.gray)
                                                        .lineLimit(1)
                                                }
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            podcastToDelete = podcast
                                            showDeletePodcastConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Empty state
                    if podcasts.isEmpty && getIndividualEpisodes().isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Tap the search bar above to discover podcasts")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.vertical, 60)
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationTitle("Podcasts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showSearchSheet) {
                PodcastSearchView(recommendedPodcasts: recommendedPodcasts)
            }
            .sheet(isPresented: $showEpisodePlayer) {
                if let episode = selectedEpisode, let podcast = selectedPodcast {
                    PlayerSheetWrapper(
                        episode: episode,
                        podcast: podcast,
                        dismiss: {
                            showEpisodePlayer = false
                            selectedEpisode = nil
                            selectedPodcast = nil
                        },
                        autoPlay: true
                    )
                }
            }
            .sheet(isPresented: $showAllEpisodesSheet) {
                AllEpisodesSheet(
                    episodes: getIndividualEpisodes(),
                    onTap: { item in
                        showAllEpisodesSheet = false
                        playIndividualEpisode(item)
                    }
                )
            }
            .sheet(isPresented: $showOPMLImport) {
                OPMLImportView()
            }
            .sheet(isPresented: $showExplorePodcastDetail) {
                if let podcast = selectedExplorePodcast {
                    ExplorePodcastDetailView(podcast: podcast, viewContext: viewContext)
                }
            }
            .overlay {
                if isLoadingEpisode {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                VStack(spacing: 4) {
                                    Text("Loading episode...")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Finding the perfect timestamp for your next 'aha!' moment")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                        }
                }
            }
            .alert("Delete Podcast", isPresented: $showDeletePodcastConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let podcast = podcastToDelete {
                        deletePodcast(podcast)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this podcast and all its downloaded episodes? This action cannot be undone.")
            }
        }
    }

    private func deletePodcast(at offsets: IndexSet) {
        offsets.forEach { index in
            let podcast = podcasts[index]
            viewContext.delete(podcast)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting podcast: \(error)")
        }
    }

    private func deletePodcast(_ podcast: PodcastEntity) {
        viewContext.delete(podcast)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting podcast: \(error)")
        }
    }

    private func addRecommendedPodcast(_ recommended: RecommendedPodcast) {
        // Check if podcast already exists
        let existingPodcast = podcasts.first { $0.feedURL == recommended.rssURL }
        if existingPodcast != nil {
            print("⚠️ Podcast already exists, skipping: \(recommended.title)")
            return
        }

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: recommended.rssURL)
                await MainActor.run {
                    // Double-check after async operation
                    let stillExists = podcasts.first { $0.feedURL == recommended.rssURL }
                    if stillExists != nil {
                        print("⚠️ Podcast was added during fetch, skipping: \(recommended.title)")
                        return
                    }

                    let newPodcast = PodcastEntity(context: viewContext)
                    newPodcast.id = rssPodcast.id.uuidString
                    newPodcast.title = rssPodcast.title
                    newPodcast.author = rssPodcast.author
                    newPodcast.podcastDescription = rssPodcast.description
                    newPodcast.artworkURL = rssPodcast.imageURL
                    newPodcast.feedURL = rssPodcast.feedURL

                    do{
                        try viewContext.save()
                    } catch {
                        print("Error saving recommended podcast: \(error)")
                    }
                }
            } catch {
                print("Error loading recommended podcast: \(error)")
            }
        }
    }

    private func getIndividualEpisodes() -> [IndividualEpisodeItem] {
        var episodes: [IndividualEpisodeItem] = []
        var seenEpisodes = Set<String>()

        // Build lookup dictionaries once - O(n) instead of O(n²)
        let podcastsByTitle: [String: PodcastEntity] = Dictionary(uniqueKeysWithValues:
            podcasts.compactMap { podcast -> (String, PodcastEntity)? in
                guard let title = podcast.title, !title.isEmpty else { return nil }
                return (title, podcast)
            }
        )

        let noteCountsByEpisode = Dictionary(grouping: allNotes) { $0.episodeTitle ?? "" }
            .mapValues { $0.count }

        // Safe dictionary creation to avoid duplicate keys crash
        var playbackItemsByEpisode: [String: PlaybackHistoryItem] = [:]
        for item in PlaybackHistoryManager.shared.recentlyPlayed {
            if !item.episodeTitle.isEmpty {
                playbackItemsByEpisode[item.episodeTitle] = item
            }
        }

        // Get episodes with notes - now O(n)
        for note in allNotes {
            guard let episodeTitle = note.episodeTitle,
                  let podcastTitle = note.showTitle,
                  !seenEpisodes.contains(episodeTitle) else { continue }

            seenEpisodes.insert(episodeTitle)

            // Lookup instead of search - O(1)
            let podcast = podcastsByTitle[podcastTitle]
            let noteCount = noteCountsByEpisode[episodeTitle] ?? 0

            // Check if also downloaded - O(1) lookup
            let isDownloaded = playbackItemsByEpisode[episodeTitle].map {
                downloadManager.isDownloaded($0.id)
            } ?? false

            episodes.append(IndividualEpisodeItem(
                episodeTitle: episodeTitle,
                podcastTitle: podcastTitle,
                episodeImageURL: nil,
                podcastImageURL: podcast?.artworkURL,
                noteCount: noteCount,
                isDownloaded: isDownloaded
            ))
        }

        // Get downloaded episodes from playback history - now O(n)
        for item in PlaybackHistoryManager.shared.recentlyPlayed {
            guard downloadManager.isDownloaded(item.id),
                  !seenEpisodes.contains(item.episodeTitle) else { continue }

            seenEpisodes.insert(item.episodeTitle)

            // O(1) lookups
            let podcast = podcastsByTitle[item.podcastTitle]
            let noteCount = noteCountsByEpisode[item.episodeTitle] ?? 0

            episodes.append(IndividualEpisodeItem(
                episodeTitle: item.episodeTitle,
                podcastTitle: item.podcastTitle,
                episodeImageURL: nil,
                podcastImageURL: podcast?.artworkURL,
                noteCount: noteCount,
                isDownloaded: true
            ))
        }

        return episodes
    }

    private func playIndividualEpisode(_ item: IndividualEpisodeItem) {
        // Find the podcast
        guard let podcast = podcasts.first(where: { $0.title == item.podcastTitle }),
              let feedURL = podcast.feedURL else {
            return
        }

        isLoadingEpisode = true

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                guard let episode = rssPodcast.episodes.first(where: { $0.title == item.episodeTitle }) else {
                    await MainActor.run {
                        isLoadingEpisode = false
                    }
                    return
                }

                await MainActor.run {
                    selectedEpisode = episode
                    selectedPodcast = podcast
                    isLoadingEpisode = false
                    showEpisodePlayer = true
                }
            } catch {
                await MainActor.run {
                    isLoadingEpisode = false
                }
            }
        }
    }
}

// MARK: - Individual Episode Item

struct IndividualEpisodeItem: Identifiable {
    let id = UUID()
    let episodeTitle: String
    let podcastTitle: String
    let episodeImageURL: String?
    let podcastImageURL: String?
    let noteCount: Int
    let isDownloaded: Bool

    var imageURL: String? {
        episodeImageURL ?? podcastImageURL
    }
}

// MARK: - Episode Card (Vertical for Carousel)

struct EpisodeCardView: View {
    let item: IndividualEpisodeItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                CachedAsyncImage(url: item.imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 40))
                                .foregroundColor(.orange)
                        )
                }

                // Episode info
                VStack(alignment: .leading, spacing: 4) {
                    // Episode name
                    Text(item.episodeTitle)
                        .font(.headline)
                        .foregroundColor(item.isDownloaded ? .primary : .primary.opacity(0.45))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Series name
                    Text(item.podcastTitle)
                        .font(.caption)
                        .foregroundColor(item.isDownloaded ? .gray : .gray.opacity(0.45))
                        .lineLimit(1)

                    // Note count
                    if item.noteCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                            Text("\(item.noteCount) note\(item.noteCount == 1 ? "" : "s")")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }

                    // Downloaded indicator
                    if item.isDownloaded {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption2)
                            Text("Downloaded")
                                .font(.caption2)
                        }
                        .foregroundColor(.green)
                    }
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Individual Episode Row (Horizontal for List)

struct IndividualEpisodeRow: View {
    let item: IndividualEpisodeItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
        HStack(spacing: 12) {
            CachedAsyncImage(url: item.imageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } placeholder: {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "music.note")
                            .foregroundColor(.orange)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.episodeTitle)
                    .font(.headline)
                    .foregroundColor(item.isDownloaded ? .primary : .primary.opacity(0.45))
                    .lineLimit(2)
                Text(item.podcastTitle)
                    .font(.subheadline)
                    .foregroundColor(item.isDownloaded ? .gray : .gray.opacity(0.45))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if item.noteCount > 0 {
                        Label("\(item.noteCount) \(item.noteCount == 1 ? "note" : "notes")", systemImage: "note.text")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    if item.isDownloaded {
                        Label("Downloaded", systemImage: "arrow.down.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - All Episodes Sheet

struct AllEpisodesSheet: View {
    let episodes: [IndividualEpisodeItem]
    let onTap: (IndividualEpisodeItem) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(episodes) { item in
                        IndividualEpisodeRow(item: item, onTap: {
                            onTap(item)
                        })
                        .padding(.horizontal)
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("All Episodes")
            .navigationBarTitleDisplayMode(.large)
            .safeAreaInset(edge: .bottom) {
                VStack {
                    Divider()
                    Text("\(episodes.count) episode\(episodes.count == 1 ? "" : "s") downloaded")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Recommended Podcast Model

struct RecommendedPodcast: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let rssURL: String
    let imageURL: String?
}

// MARK: - Recommended Podcast Row

struct RecommendedPodcastRow: View {
    let podcast: RecommendedPodcast
    let onAdd: () -> Void
    @State private var isAdding = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnailView

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(podcast.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            addButton
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var thumbnailView: some View {
        CachedAsyncImage(
            url: podcast.imageURL,
            content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            },
            placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                    )
            }
        )
        .frame(width: 60, height: 60)
    }

    private var addButton: some View {
        Button(action: {
            isAdding = true
            onAdd()
        }) {
            Group {
                if isAdding {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .frame(width: 32, height: 32)
        }
        .disabled(isAdding)
    }
}

// MARK: - Explore Podcast Card

struct ExplorePodcastCard: View {
    let podcast: RecommendedPodcast
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Podcast artwork
                CachedAsyncImage(
                    url: podcast.imageURL,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    },
                    placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.blue)
                            )
                    }
                )

                // Podcast title
                Text(podcast.title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Explore Podcast Detail View

struct ExplorePodcastDetailView: View {
    let podcast: RecommendedPodcast
    let viewContext: NSManagedObjectContext
    @State private var rssPodcast: RSSPodcast?
    @State private var isLoading = true
    @State private var isSubscribed = false
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)]
    ) private var podcasts: FetchedResults<PodcastEntity>

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading podcast...")
                } else if let rssPodcast = rssPodcast {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header with artwork and info
                            HStack(spacing: 16) {
                                CachedAsyncImage(url: podcast.imageURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text(rssPodcast.title)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    if let author = rssPodcast.author {
                                        Text(author)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()

                            // Description
                            if !rssPodcast.description.isEmpty {
                                Text(rssPodcast.description)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                            }

                            // Subscribe button
                            if !isSubscribed {
                                Button(action: subscribe) {
                                    Text("Subscribe")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Podcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkIfSubscribed()
            loadPodcast()
        }
    }

    private func checkIfSubscribed() {
        isSubscribed = podcasts.contains { $0.feedURL == podcast.rssURL }
    }

    private func loadPodcast() {
        Task {
            do {
                let podcast = try await PodcastRSSService.shared.fetchPodcast(from: self.podcast.rssURL)
                await MainActor.run {
                    rssPodcast = podcast
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func subscribe() {
        guard let rssPodcast = rssPodcast else { return }

        let newPodcast = PodcastEntity(context: viewContext)
        newPodcast.id = rssPodcast.id.uuidString
        newPodcast.title = rssPodcast.title
        newPodcast.author = rssPodcast.author
        newPodcast.podcastDescription = rssPodcast.description
        newPodcast.artworkURL = rssPodcast.imageURL
        newPodcast.feedURL = rssPodcast.feedURL

        do {
            try viewContext.save()
            isSubscribed = true
        } catch {
            print("Error saving podcast: \(error)")
        }
    }
}

// MARK: - Notes List View

struct NotesListView: View {
    @Binding var selectedTab: Int
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<NoteEntity>

    @State private var selectedSegment = 0
    @State private var searchText = ""
    @State private var showShareSheet = false
    @State private var shareNote: NoteEntity?
    @State private var selectedTag: String?
    @State private var showTagNotesSheet = false
    @State private var noteToDelete: NoteEntity?
    @State private var showDeleteConfirmation = false
    @State private var selectedNote: NoteEntity?

    var filteredNotes: [NoteEntity] {
        if searchText.isEmpty {
            return Array(notes)
        } else {
            return notes.filter { note in
                let noteTextMatch = note.noteText?.localizedCaseInsensitiveContains(searchText) ?? false
                let tagsMatch = note.tagsArray.contains { $0.localizedCaseInsensitiveContains(searchText) }
                return noteTextMatch || tagsMatch
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                segmentedControl
                notesContent
            }
            .padding(.bottom, 100)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showShareSheet) {
                if let note = shareNote {
                    ShareSheet(activityItems: buildShareItems(from: note))
                }
            }
            .sheet(isPresented: $showTagNotesSheet) {
                if let tag = selectedTag {
                    TagNotesSheet(tag: tag, notes: getNotesForTag(tag))
                }
            }
            .sheet(item: $selectedNote) { note in
                NavigationStack {
                    NoteDetailSheetView(note: note)
                }
            }
            .alert("Delete Note", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
        }
    }

    @ViewBuilder
    private var notesContent: some View {
        if notes.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "note.text")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("Listen to a podcast and take notes today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Button(action: {
                    selectedTab = 1 // Switch to Podcasts tab
                }) {
                    Text("Find a podcast")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if selectedSegment == 2 && getAllTags().isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "tag")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                Text("No tags yet")
                    .font(.title3)
                    .foregroundColor(.gray)
                Text("You have not added tags to any notes yet. Once you add them, you can find them here.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            notesList
        }
    }

    @ViewBuilder
    private var notesList: some View {
        List {
            if selectedSegment == 0 {
                byDateSection
            } else if selectedSegment == 1 {
                byEpisodeSection
            } else {
                byTagsSection
            }
        }
        .listStyle(.plain)
    }

    @ViewBuilder
    private var byDateSection: some View {
        ForEach(groupedByDate(filteredNotes), id: \.key) { date, notesForDate in
            Section(header: Text(date)) {
                ForEach(notesForDate) { note in
                    Button(action: {
                        selectedNote = note
                    }) {
                        NoteCardView(note: note)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            noteToDelete = note
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            shareNote = note
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var byEpisodeSection: some View {
        ForEach(groupedByEpisode(filteredNotes), id: \.key) { episode, notesForEpisode in
            Section(header: Text(episode)) {
                ForEach(notesForEpisode) { note in
                    Button(action: {
                        selectedNote = note
                    }) {
                        NoteCardView(note: note)
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            noteToDelete = note
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        Button {
                            shareNote = note
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .tint(.blue)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var byTagsSection: some View {
        ForEach(groupedByTags(), id: \.tag) { tagGroup in
            Button(action: {
                selectedTag = tagGroup.tag
                showTagNotesSheet = true
            }) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.orange)
                    Text(tagGroup.tag)
                        .font(.body)
                    Spacer()
                    Text("\(tagGroup.count)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search notes and tags...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var segmentedControl: some View {
        Picker("Sort By", selection: $selectedSegment) {
            Text("By Date").tag(0)
            Text("By Episode").tag(1)
            Text("By Tags").tag(2)
        }
        .pickerStyle(.segmented)
        .padding()
    }

    private func groupedByDate(_ notes: [NoteEntity]) -> [(key: String, value: [NoteEntity])] {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let grouped = Dictionary(grouping: notes) { note -> String in
            if let date = note.createdAt {
                return formatter.string(from: date)
            }
            return "Unknown Date"
        }

        return grouped.sorted { $0.key > $1.key }
    }

    private func groupedByEpisode(_ notes: [NoteEntity]) -> [(key: String, value: [NoteEntity])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            if let episode = note.episodeTitle, !episode.isEmpty {
                return episode
            }
            return "Untitled Episode"
        }

        return grouped.sorted { $0.key < $1.key }
    }

    private func getAllTags() -> [String] {
        var allTags = Set<String>()
        for note in notes {
            allTags.formUnion(note.tagsArray)
        }
        return Array(allTags).sorted()
    }

    private func groupedByTags() -> [TagGroup] {
        var tagCounts: [String: Int] = [:]
        for note in notes {
            for tag in note.tagsArray {
                tagCounts[tag, default: 0] += 1
            }
        }
        return tagCounts.map { TagGroup(tag: $0.key, count: $0.value) }.sorted { $0.tag < $1.tag }
    }

    private func getNotesForTag(_ tag: String) -> [NoteEntity] {
        return notes.filter { $0.tagsArray.contains(tag) }
    }

    private func deleteNote(_ note: NoteEntity) {
        viewContext.delete(note)
        try? viewContext.save()
    }
}

// MARK: - Tag Group

struct TagGroup {
    let tag: String
    let count: Int
}

// MARK: - Tag Notes Sheet

struct TagNotesSheet: View {
    let tag: String
    let notes: [NoteEntity]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showShareSheet = false
    @State private var shareNote: NoteEntity?
    @State private var noteToDelete: NoteEntity?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(notes.count) note\(notes.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                List {
                    ForEach(notes) { note in
                        NavigationLink(destination: NoteDetailSheetView(note: note)) {
                            NoteRowDetailView(note: note)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Notes with \(tag)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let note = shareNote {
                    ShareSheet(activityItems: buildShareItems(from: note))
                }
            }
            .alert("Delete Note", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let note = noteToDelete {
                        deleteNote(note)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this note? This action cannot be undone.")
            }
        }
    }

    private func deleteNote(_ note: NoteEntity) {
        viewContext.delete(note)
        try? viewContext.save()
    }
}

// MARK: - Note Row Detail View

struct NoteRowDetailView: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let showTitle = note.showTitle {
                    Text(showTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Spacer()

                if note.isPriority {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }

            if let noteText = note.noteText {
                Text(noteText)
                    .font(.body)
                    .lineLimit(5)
            }

            HStack {
                if let timestamp = note.timestamp {
                    Label(timestamp, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if let createdAt = note.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Podcast Preview View

struct PodcastPreviewView: View {
    let recommendedPodcast: RecommendedPodcast

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var episodes: [RSSEpisode] = []
    @State private var isLoadingEpisodes = false
    @State private var podcastDetails: RSSPodcast?
    @State private var selectedEpisode: RSSEpisode?
    @State private var showPlayer = false
    @State private var isAdded = false

    var body: some View {
        VStack(spacing: 0) {
            if let podcast = podcastDetails {
                // Podcast Header
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.blue)
                                )

                            VStack(spacing: 8) {
                                Text(podcast.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)

                                if let author = podcast.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }

                                if !podcast.description.isEmpty {
                                    Text(podcast.description)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(3)
                                        .padding(.horizontal)
                                }
                            }

                            // Add to Library Button
                            if !isAdded {
                                Button(action: addToLibrary) {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add to Library")
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Added to Library")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.green)
                                }
                                .padding()
                            }
                        }
                        .padding()

                        Divider()

                        // Episodes List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Episodes")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            if isLoadingEpisodes {
                                VStack(spacing: 8) {
                                    ProgressView()
                                    Text("Loading episodes...")
                                        .font(.headline)
                                    Text("Preparing your binge-worthy queue... 🎧")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else if episodes.isEmpty {
                                Text("No episodes found")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            } else {
                                ForEach(episodes) { episode in
                                    Button(action: {
                                        selectedEpisode = episode
                                        showPlayer = true
                                    }) {
                                        EpisodeRowView(episode: episode)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.5)
                    VStack(spacing: 4) {
                        Text("Loading podcast...")
                            .font(.headline)
                        Text("Getting things ready... grab your headphones! 🎵")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle(recommendedPodcast.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadPodcastDetails()
        }
        .sheet(item: Binding(
            get: {
                guard let episode = selectedEpisode, let podcast = podcastDetails else { return nil }
                return PlayerSheetData(episode: episode, podcast: podcast)
            },
            set: { (_: PlayerSheetData?) in }
        )) { data in
            let tempContext = PersistenceController.preview.container.viewContext
            let tempPodcast = createTempPodcast(from: data.podcast, context: tempContext)

            PlayerSheetWrapper(
                episode: data.episode,
                podcast: tempPodcast,
                dismiss: { showPlayer = false }
            )
        }
    }

    private func loadPodcastDetails() {
        isLoadingEpisodes = true
        Task {
            do {
                let podcast = try await PodcastRSSService.shared.fetchPodcast(from: recommendedPodcast.rssURL)
                await MainActor.run {
                    podcastDetails = podcast
                    episodes = podcast.episodes
                    isLoadingEpisodes = false
                }
            } catch {
                await MainActor.run {
                    print("Error loading podcast details: \(error)")
                    isLoadingEpisodes = false
                }
            }
        }
    }

    private func addToLibrary() {
        guard let podcast = podcastDetails else { return }

        let newPodcast = PodcastEntity(context: viewContext)
        newPodcast.id = podcast.id.uuidString
        newPodcast.title = podcast.title
        newPodcast.author = podcast.author
        newPodcast.podcastDescription = podcast.description
        newPodcast.artworkURL = podcast.imageURL
        newPodcast.feedURL = podcast.feedURL

        do {
            try viewContext.save()
            isAdded = true
        } catch {
            print("Error adding podcast to library: \(error)")
        }
    }

    private func createTempPodcast(from podcast: RSSPodcast, context: NSManagedObjectContext) -> PodcastEntity {
        let tempPodcast = PodcastEntity(context: context)
        tempPodcast.id = podcast.id.uuidString
        tempPodcast.title = podcast.title
        tempPodcast.author = podcast.author
        return tempPodcast
    }
}

// MARK: - iTunes Search Service

class iTunesSearchService {
    static let shared = iTunesSearchService()

    private var searchCache: [String: [iTunesPodcast]] = [:]

    struct iTunesPodcast: Identifiable, Codable {
        let trackId: Int
        let trackName: String
        let artistName: String
        let artworkUrl600: String?
        let feedUrl: String?

        var id: Int { trackId }
    }

    struct SearchResponse: Codable {
        let resultCount: Int
        let results: [iTunesPodcast]
    }

    func search(query: String) async throws -> [iTunesPodcast] {
        // Check cache first
        if let cached = searchCache[query.lowercased()] {
            return cached
        }

        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://itunes.apple.com/search?term=\(encodedQuery)&media=podcast&limit=20") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        // Cache results
        searchCache[query.lowercased()] = response.results

        return response.results
    }
}

// MARK: - Podcast Search View

struct PodcastSearchView: View {
    let recommendedPodcasts: [RecommendedPodcast]

    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var podcasts: FetchedResults<PodcastEntity>
    @State private var searchText = ""
    @State private var searchResults: [iTunesSearchService.iTunesPodcast] = []
    @State private var isSearching = false
    @State private var hasPerformedSearch = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isSearchFocused: Bool
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    TextField("Search podcasts...", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)
                        .onChange(of: searchText) { oldValue, newValue in
                            // Cancel previous search task
                            searchTask?.cancel()

                            // Clear results if search is empty
                            if newValue.isEmpty {
                                searchResults = []
                                hasPerformedSearch = false
                                return
                            }

                            // Debounce: wait 0.3s before searching
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                                if !Task.isCancelled {
                                    await performSearchAsync()
                                }
                            }
                        }
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
                            hasPerformedSearch = false
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                Divider()

                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Search Results
                        if isSearching {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                VStack(spacing: 4) {
                                    Text("Searching...")
                                        .font(.headline)
                                    Text("Scouring the podcast universe for your next obsession... 🔍")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            .padding()
                        } else if !searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Search Results")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal)

                                ForEach(searchResults) { podcast in
                                    iTunesPodcastRow(podcast: podcast) {
                                        addPodcast(podcast)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top)
                        } else if !searchText.isEmpty && !isSearching && hasPerformedSearch {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No podcasts found")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 40)
                        }

                        // Recommended Podcasts
                        if searchText.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 40))
                                        .foregroundColor(.blue)
                                    Text("Recommended Podcasts")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                    Text("Get started with these popular podcasts")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)

                                ForEach(recommendedPodcasts) { podcast in
                                    NavigationLink(destination: PodcastPreviewView(recommendedPodcast: podcast)) {
                                        RecommendedPodcastRow(
                                            podcast: podcast,
                                            onAdd: {
                                                addRecommendedPodcast(podcast)
                                            }
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Search Podcasts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Auto-focus search field and show keyboard
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isSearchFocused = true
                }
            }
        }
    }

    private func performSearch() {
        Task {
            await performSearchAsync()
        }
    }

    private func performSearchAsync() async {
        guard !searchText.isEmpty else { return }

        await MainActor.run {
            isSearching = true
            hasPerformedSearch = true
        }

        do {
            let results = try await iTunesSearchService.shared.search(query: searchText)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        } catch {
            // Don't show error for cancellation (happens when user keeps typing)
            if (error as NSError).code != NSURLErrorCancelled {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "Failed to search: \(error.localizedDescription)"
                    showError = true
                }
            } else {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }

    private func addPodcast(_ iTunesPodcast: iTunesSearchService.iTunesPodcast) {
        guard let feedURL = iTunesPodcast.feedUrl else {
            errorMessage = "No RSS feed available for this podcast"
            showError = true
            return
        }

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                await MainActor.run {
                    let newPodcast = PodcastEntity(context: viewContext)
                    newPodcast.id = rssPodcast.id.uuidString
                    newPodcast.title = rssPodcast.title
                    newPodcast.author = rssPodcast.author
                    newPodcast.podcastDescription = rssPodcast.description
                    newPodcast.artworkURL = rssPodcast.imageURL
                    newPodcast.feedURL = rssPodcast.feedURL

                    do {
                        try viewContext.save()
                        dismiss()
                    } catch {
                        errorMessage = "Error saving podcast: \(error.localizedDescription)"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading podcast: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }

    private func addRecommendedPodcast(_ recommended: RecommendedPodcast) {
        // Check if podcast already exists
        let existingPodcast = podcasts.first { $0.feedURL == recommended.rssURL }
        if existingPodcast != nil {
            print("⚠️ Podcast already exists, skipping: \(recommended.title)")
            return
        }

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: recommended.rssURL)
                await MainActor.run {
                    // Double-check after async operation
                    let stillExists = podcasts.first { $0.feedURL == recommended.rssURL }
                    if stillExists != nil {
                        print("⚠️ Podcast was added during fetch, skipping: \(recommended.title)")
                        return
                    }

                    let newPodcast = PodcastEntity(context: viewContext)
                    newPodcast.id = rssPodcast.id.uuidString
                    newPodcast.title = rssPodcast.title
                    newPodcast.author = rssPodcast.author
                    newPodcast.podcastDescription = rssPodcast.description
                    newPodcast.artworkURL = rssPodcast.imageURL
                    newPodcast.feedURL = rssPodcast.feedURL

                    do{
                        try viewContext.save()
                        dismiss()
                    } catch {
                        errorMessage = "Error saving podcast: \(error.localizedDescription)"
                        showError = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error loading podcast: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - iTunes Podcast Row

struct iTunesPodcastRow: View {
    let podcast: iTunesSearchService.iTunesPodcast
    let onAdd: () -> Void
    @State private var isAdding = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "mic.fill")
                        .foregroundColor(.blue)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(podcast.trackName)
                    .font(.headline)
                    .lineLimit(2)
                Text(podcast.artistName)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            if podcast.feedUrl != nil {
                Button(action: {
                    isAdding = true
                    onAdd()
                }) {
                    if isAdding {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .disabled(isAdding)
                .frame(width: 32, height: 32)
            } else {
                Text("No feed")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Player Sheet Wrapper

struct PlayerSheetWrapper: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let dismiss: () -> Void
    var autoPlay: Bool = true
    var seekToTime: TimeInterval? = nil
    @ObservedObject private var player = GlobalPlayerManager.shared
    @ObservedObject private var downloadManager = EpisodeDownloadManager.shared
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Drag indicator at the very top
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                NavigationStack {
                    AudioPlayerView(
                        episode: episode,
                        podcast: podcast,
                        autoPlay: autoPlay,
                        seekToTime: seekToTime
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                let episodeID = episode.id

                                if downloadManager.isDownloading(episodeID) {
                                    Button(role: .destructive, action: {
                                        downloadManager.cancelDownload(episodeID)
                                    }) {
                                        Label("Cancel Download", systemImage: "xmark.circle")
                                    }
                                } else if downloadManager.isDownloaded(episodeID) {
                                    Button(role: .destructive, action: {
                                        showDeleteConfirmation = true
                                    }) {
                                        Label("Delete Download", systemImage: "trash")
                                    }
                                } else {
                                    Button(action: {
                                        downloadManager.downloadEpisode(
                                            episode,
                                            podcastTitle: podcast.title ?? "Unknown Podcast",
                                            podcastFeedURL: podcast.feedURL
                                        )
                                    }) {
                                        Label("Download Episode", systemImage: "arrow.down.circle")
                                    }
                                }

                                Divider()

                                Button(action: {
                                    print("🔽 [PlayerSheet] Hide button tapped - dismissing to mini player")
                                    dismiss()
                                }) {
                                    Label("Hide", systemImage: "chevron.down")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }

            // Buffering overlay to cover drag bar
            if player.isBuffering {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
            }
        }
        .alert("Delete Download", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                downloadManager.deleteDownload(episode.id)
            }
        } message: {
            Text("Are you sure you want to delete this downloaded episode?")
        }
    }
}

struct PlayerSheetData: Identifiable {
    let id = UUID()
    let episode: RSSEpisode
    let podcast: RSSPodcast
}

// MARK: - Note Detail Sheet View

struct NoteDetailSheetView: View {
    let note: NoteEntity
    @State private var showPlayer = false
    @State private var editedNoteText: String = ""
    @State private var editedTags: [String] = []
    @State private var isEditing: Bool = false
    @State private var loadedEpisode: RSSEpisode?
    @State private var loadedPodcast: PodcastEntity?
    @State private var isLoadingEpisode = false
    @State private var loadError: String?
    @State private var showAddTagSheet = false
    @State private var newTagText = ""
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false
    @State private var showMoreMenu = false
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)]
    ) private var podcasts: FetchedResults<PodcastEntity>

    var body: some View {
        ZStack {
            // Background to ensure view always renders
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                // Episode Info
                VStack(alignment: .leading, spacing: 8) {
                    // Episode name (header)
                    if let episodeTitle = note.episodeTitle {
                        Text(episodeTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    // Series name (caption/subheader)
                    if let showTitle = note.showTitle {
                        Text(showTitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Date published
                    if let createdAt = note.createdAt {
                        Text(createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Note Content
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Note")
                            .font(.headline)
                        Spacer()
                        // Edit button moved to Note section
                        if isEditing {
                            Button("Save") {
                                saveChanges()
                                isEditing = false
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        } else {
                            Button("Edit") {
                                editedNoteText = note.noteText ?? ""
                                editedTags = note.tagsArray
                                isEditing = true
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                    }

                    if isEditing {
                        TextEditor(text: $editedNoteText)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        if let noteText = note.noteText {
                            ScrollView {
                                Text(noteText)
                                    .font(.body)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(height: 120)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }

                // Tags Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tags")
                        .font(.headline)

                    if isEditing {
                        FlowLayout(spacing: 8) {
                            ForEach(editedTags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    Button(action: {
                                        editedTags.removeAll { $0 == tag }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(16)
                            }

                            Button(action: {
                                showAddTagSheet = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text("Add Tag")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .foregroundColor(.blue)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(16)
                            }
                        }
                    } else if !note.tagsArray.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(note.tagsArray, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .cornerRadius(16)
                            }
                        }
                    } else {
                        Text("No tags")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }

                // Timestamp info under note
                if let createdAt = note.createdAt {
                    HStack {
                        Text("Created: \(createdAt, style: .date)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 8)
                }

                // Play at Timestamp Button
                if let timestamp = note.timestamp, let _ = note.episodeTitle {
                    Button(action: {
                        loadEpisodeAndPlay()
                    }) {
                        HStack {
                            if isLoadingEpisode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                            }
                            Text(isLoadingEpisode ? "Loading..." : "Play at \(timestamp)")
                                .fontWeight(.semibold)
                            Spacer()
                            if !isLoadingEpisode {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(isLoadingEpisode)

                    // Show error if loading failed
                    if let error = loadError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
            }
        }
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .onAppear {
            editedNoteText = note.noteText ?? ""
            editedTags = note.tagsArray
        }
        .sheet(isPresented: $showPlayer) {
            if let episode = loadedEpisode, let podcast = loadedPodcast {
                PlayerSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    dismiss: {
                        showPlayer = false
                        loadedEpisode = nil
                        loadedPodcast = nil
                    },
                    autoPlay: true,
                    seekToTime: parseTimestamp(note.timestamp ?? "")
                )
            }
        }
        .sheet(isPresented: $showAddTagSheet) {
            AddTagSheet(isPresented: $showAddTagSheet, onAdd: { tag in
                if !editedTags.contains(tag) {
                    editedTags.append(tag)
                }
            })
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: buildShareItems(from: note))
        }
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteNote()
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }

    private func saveChanges() {
        note.noteText = editedNoteText
        note.tagsArray = editedTags

        do {
            try viewContext.save()
        } catch {
            print("Error saving note changes: \(error)")
        }
    }

    private func deleteNote() {
        viewContext.delete(note)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    private func loadEpisodeAndPlay() {
        guard let episodeTitle = note.episodeTitle,
              let showTitle = note.showTitle,
              let podcast = podcasts.first(where: { $0.title == showTitle }),
              let feedURL = podcast.feedURL else {
            loadError = "Could not find podcast information"
            return
        }

        isLoadingEpisode = true
        loadError = nil

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)

                guard let episode = rssPodcast.episodes.first(where: { $0.title == episodeTitle }) else {
                    await MainActor.run {
                        isLoadingEpisode = false
                        loadError = "Could not find episode in podcast feed"
                    }
                    return
                }

                await MainActor.run {
                    loadedEpisode = episode
                    loadedPodcast = podcast
                    isLoadingEpisode = false
                    showPlayer = true
                }
            } catch {
                await MainActor.run {
                    isLoadingEpisode = false
                    loadError = "Failed to load episode: \(error.localizedDescription)"
                }
            }
        }
    }

    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let components = timestamp.split(separator: ":").compactMap { Int($0) }

        if components.count == 2 {
            return TimeInterval(components[0] * 60 + components[1])
        } else if components.count == 3 {
            return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
        }
        return nil
    }
}

// MARK: - OPML Import View

struct OPMLImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var isImporting = false
    @State private var showDocumentPicker = false
    @State private var importedFeeds: [OPMLFeed] = []
    @State private var selectedFeeds: Set<String> = []
    @State private var importStatus: String?
    @State private var isProcessingImport = false
    @State private var successCount = 0
    @State private var errorCount = 0
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if importedFeeds.isEmpty {
                    // Initial state - show file picker
                    VStack(spacing: 20) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Import OPML File")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Import your podcast subscriptions from an OPML file exported from another podcast app.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            showDocumentPicker = true
                        }) {
                            HStack {
                                Image(systemName: "folder")
                                Text("Choose OPML File")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    // Show imported feeds
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Found \(importedFeeds.count) podcast\(importedFeeds.count == 1 ? "" : "s")")
                            .font(.headline)
                            .padding(.horizontal)

                        if isProcessingImport {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                VStack(spacing: 4) {
                                    Text("Importing podcasts...")
                                        .font(.headline)
                                    Text("Building your audio empire, one feed at a time... 📚")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                }
                                if let status = importStatus {
                                    Text(status)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if successCount > 0 {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)

                                Text("Import Complete")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Successfully imported \(successCount) podcast\(successCount == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                if errorCount > 0 {
                                    Text("\(errorCount) failed")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }

                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Done")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                .padding(.top)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List(importedFeeds, id: \.feedURL, selection: $selectedFeeds) { feed in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(feed.title)
                                            .font(.headline)
                                        if let description = feed.description {
                                            Text(description)
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                                .lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                    if selectedFeeds.contains(feed.feedURL) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFeeds.contains(feed.feedURL) {
                                        selectedFeeds.remove(feed.feedURL)
                                    } else {
                                        selectedFeeds.insert(feed.feedURL)
                                    }
                                }
                            }

                            Button(action: {
                                importSelectedFeeds()
                            }) {
                                Text("Import \(selectedFeeds.count) Selected")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(selectedFeeds.isEmpty ? Color.gray : Color.blue)
                                    .cornerRadius(12)
                            }
                            .disabled(selectedFeeds.isEmpty)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Import OPML")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isProcessingImport && successCount == 0 {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .fileImporter(isPresented: $showDocumentPicker, allowedContentTypes: [.xml, .opml]) { result in
                handleFileImport(result: result)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                // Select all by default
                selectedFeeds = Set(importedFeeds.map { $0.feedURL })
            }
        }
    }

    private func handleFileImport(result: Result<URL, Error>) {
        switch result {
        case .success(let fileURL):
            isImporting = true
            Task {
                do {
                    let parser = OPMLImportService()
                    let feeds = try await parser.parsePOML(from: fileURL)

                    await MainActor.run {
                        if feeds.isEmpty {
                            errorMessage = "No podcast feeds found in the OPML file"
                            showError = true
                        } else {
                            importedFeeds = feeds
                            selectedFeeds = Set(feeds.map { $0.feedURL })
                        }
                        isImporting = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = "Failed to parse OPML file: \(error.localizedDescription)"
                        showError = true
                        isImporting = false
                    }
                }
            }
        case .failure(let error):
            errorMessage = "Failed to import file: \(error.localizedDescription)"
            showError = true
        }
    }

    private func importSelectedFeeds() {
        isProcessingImport = true
        successCount = 0
        errorCount = 0

        let feedsToImport = importedFeeds.filter { selectedFeeds.contains($0.feedURL) }

        Task {
            for (index, feed) in feedsToImport.enumerated() {
                await MainActor.run {
                    importStatus = "Importing \(index + 1) of \(feedsToImport.count)..."
                }

                do {
                    let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feed.feedURL)

                    await MainActor.run {
                        let newPodcast = PodcastEntity(context: viewContext)
                        newPodcast.id = rssPodcast.id.uuidString
                        newPodcast.title = rssPodcast.title
                        newPodcast.author = rssPodcast.author
                        newPodcast.podcastDescription = rssPodcast.description
                        newPodcast.artworkURL = rssPodcast.imageURL
                        newPodcast.feedURL = rssPodcast.feedURL

                        do {
                            try viewContext.save()
                            successCount += 1
                        } catch {
                            print("Error saving podcast: \(error)")
                            errorCount += 1
                        }
                    }
                } catch {
                    print("Error fetching podcast: \(error)")
                    await MainActor.run {
                        errorCount += 1
                    }
                }
            }

            await MainActor.run {
                isProcessingImport = false
                importStatus = nil
            }
        }
    }
}

// MARK: - Add Tag Sheet

struct AddTagSheet: View {
    @Binding var isPresented: Bool
    let onAdd: (String) -> Void
    @State private var tagText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Enter tag name", text: $tagText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button(action: {
                    if !tagText.trimmingCharacters(in: .whitespaces).isEmpty {
                        onAdd(tagText.trimmingCharacters(in: .whitespaces))
                        isPresented = false
                    }
                }) {
                    Text("Add Tag")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tagText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(tagText.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Helper Functions

func buildShareItems(from note: NoteEntity) -> [Any] {
    var shareText = ""
    if let episodeTitle = note.episodeTitle {
        shareText += "From: \(episodeTitle)\n"
    }
    if let showTitle = note.showTitle {
        shareText += "Podcast: \(showTitle)\n"
    }
    if let timestamp = note.timestamp {
        shareText += "Timestamp: \(timestamp)\n"
    }
    shareText += "\n"
    if let noteText = note.noteText {
        shareText += noteText
    }
    return [shareText]
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        var lineWidth: CGFloat = 0
        var lineHeight: CGFloat = 0

        for size in sizes {
            if lineWidth + size.width + spacing > proposal.width ?? 0 {
                totalHeight += lineHeight + spacing
                lineWidth = size.width
                lineHeight = size.height
            } else {
                lineWidth += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            totalWidth = max(totalWidth, lineWidth)
        }
        totalHeight += lineHeight

        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var lineX = bounds.minX
        var lineY = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if lineX + size.width > bounds.maxX && lineX > bounds.minX {
                lineY += lineHeight + spacing
                lineHeight = 0
                lineX = bounds.minX
            }
            subview.place(at: CGPoint(x: lineX, y: lineY), proposal: .unspecified)
            lineHeight = max(lineHeight, size.height)
            lineX += size.width + spacing
        }
    }
}

// MARK: - Note Card View

struct NoteCardView: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let showTitle = note.showTitle {
                Text(showTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let noteText = note.noteText {
                Text(noteText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }

            if let timestamp = note.timestamp {
                Text(timestamp)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var downloadManager = EpisodeDownloadManager.shared
    @ObservedObject var historyManager = PlaybackHistoryManager.shared
    @State private var showOnboarding = false
    @State private var showClearCacheAlert = false
    @State private var showOPMLOptions = false
    @State private var showDebugConsole = false

    private var currentPID: String {
        String(ProcessInfo.processInfo.processIdentifier)
    }

    private var appVersion: String {
        return "v0.01 + 2025.11.24.02.05"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                List {
                // Downloaded Episodes Section
                Section {
                    NavigationLink(destination: DownloadedEpisodesView()) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.blue)
                            Text("Downloaded Episodes")
                            Spacer()
                            Text("\(downloadManager.downloadedEpisodes.count)")
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Downloads")
                }

                // OPML Import/Export Section
                Section {
                    Button(action: {
                        showOPMLOptions = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down.circle.fill")
                                .foregroundColor(.green)
                            Text("Import/Export OPML")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                } header: {
                    Text("Podcast Subscriptions")
                } footer: {
                    Text("Import subscriptions from other apps or export your current subscriptions.")
                }

                // Dev Mode Section
                Section {
                    Button(action: {
                        showDebugConsole = true
                    }) {
                        HStack {
                            Image(systemName: "ant.circle.fill")
                                .foregroundColor(.green)
                            Text("Debug Console")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Button(action: {
                        showClearCacheAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear Cache")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: {
                        showOnboarding = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Show Onboarding")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Tools for testing and debugging the app.")
                }
            }
            .navigationTitle("Settings")
            .alert("Clear Cache", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will delete all notes, podcasts, and playback history. This action cannot be undone.")
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isOnboardingComplete: $showOnboarding)
            }
            .sheet(isPresented: $showOPMLOptions) {
                OPMLOptionsView()
            }
            .sheet(isPresented: $showDebugConsole) {
                DebugConsoleView()
            }

                // PID and Version Display at bottom center
                VStack(spacing: 4) {
                    Text("PID: \(currentPID)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(appVersion)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
        }
    }

    private func clearCache() {
        // Clear onboarding status
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")

        // Clear playback history from UserDefaults
        UserDefaults.standard.removeObject(forKey: "playbackHistory")
        PlaybackHistoryManager.shared.recentlyPlayed.removeAll()

        // Delete all notes from Core Data
        let notesFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "NoteEntity")
        let notesDelete = NSBatchDeleteRequest(fetchRequest: notesFetch)

        // Delete all podcasts from Core Data
        let podcastsFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PodcastEntity")
        let podcastsDelete = NSBatchDeleteRequest(fetchRequest: podcastsFetch)

        do {
            try viewContext.execute(notesDelete)
            try viewContext.execute(podcastsDelete)
            try viewContext.save()

            // Reset Core Data context
            viewContext.reset()

            print("✅ Cache cleared: All notes, podcasts, and playback history deleted")
        } catch {
            print("❌ Error clearing cache: \(error)")
        }
    }
}

// MARK: - OPML Options View

struct OPMLOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var podcasts: FetchedResults<PodcastEntity>

    @State private var showImportPicker = false
    @State private var showExportShare = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: {
                        showImportPicker = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import OPML")
                                    .foregroundColor(.primary)
                                Text("Import your podcast subscriptions from other apps")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Button(action: {
                        exportOPML()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Export OPML")
                                    .foregroundColor(.primary)
                                Text("Save your subscriptions (\(podcasts.count) podcasts)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(podcasts.isEmpty)
                }
            }
            .navigationTitle("Import/Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.xml],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
            .sheet(isPresented: $showExportShare) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    private func exportOPML() {
        let opml = generateOPML()

        // Save to temp directory
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "echonotes_subscriptions_\(Date().timeIntervalSince1970).opml"
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try opml.write(to: fileURL, atomically: true, encoding: .utf8)
            exportURL = fileURL
            showExportShare = true
        } catch {
            print("❌ Error exporting OPML: \(error)")
        }
    }

    private func generateOPML() -> String {
        var opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>EchoNotes Subscriptions</title>
                <dateCreated>\(Date())</dateCreated>
            </head>
            <body>
        """

        for podcast in podcasts {
            let title = podcast.title?.replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;") ?? "Unknown"

            let feedURL = podcast.feedURL ?? ""

            opml += """
                    <outline type="rss" text="\(title)" xmlUrl="\(feedURL)" />

            """
        }

        opml += """
            </body>
        </opml>
        """

        return opml
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        do {
            guard let fileURL = try result.get().first else { return }

            // Make sure we can access the file
            guard fileURL.startAccessingSecurityScopedResource() else {
                print("❌ Couldn't access file")
                return
            }

            defer { fileURL.stopAccessingSecurityScopedResource() }

            Task {
                do {
                    let feeds = try await OPMLImportService().parsePOML(from: fileURL)

                    await MainActor.run {
                        print("✅ Found \(feeds.count) feeds in OPML")
                        // Import the feeds
                        for feed in feeds {
                            importPodcast(feedURL: feed.feedURL)
                        }
                        dismiss()
                    }
                } catch {
                    print("❌ Error parsing OPML: \(error)")
                }
            }
        } catch {
            print("❌ Error importing OPML: \(error)")
        }
    }

    private func importPodcast(feedURL: String) {
        // Check if already exists
        if podcasts.first(where: { $0.feedURL == feedURL }) != nil {
            return
        }

        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: feedURL)
                await MainActor.run {
                    let newPodcast = PodcastEntity(context: viewContext)
                    newPodcast.id = rssPodcast.id.uuidString
                    newPodcast.title = rssPodcast.title
                    newPodcast.author = rssPodcast.author
                    newPodcast.podcastDescription = rssPodcast.description
                    newPodcast.artworkURL = rssPodcast.imageURL
                    newPodcast.feedURL = rssPodcast.feedURL

                    try? viewContext.save()
                }
            } catch {
                print("❌ Error importing podcast: \(error)")
            }
        }
    }
}

// MARK: - Downloaded Episodes View

struct DownloadedEpisodesView: View {
    @ObservedObject var downloadManager = EpisodeDownloadManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var podcasts: FetchedResults<PodcastEntity>

    @State private var episodePlayerData: EpisodePlayerData?

    // Group episodes by podcast title
    var groupedEpisodes: [(podcast: String, episodes: [DownloadedEpisodeInfo])] {
        // Get metadata for all downloaded episodes
        let episodesWithInfo = downloadManager.downloadedEpisodes.map { episodeID -> DownloadedEpisodeInfo in
            if let metadata = downloadManager.getMetadata(for: episodeID) {
                return DownloadedEpisodeInfo(
                    episodeID: episodeID,
                    episodeTitle: metadata.episodeTitle,
                    podcastTitle: metadata.podcastTitle,
                    podcastFeedURL: metadata.podcastFeedURL,
                    downloadDate: metadata.downloadDate
                )
            } else {
                // Fallback for episodes without metadata
                return DownloadedEpisodeInfo(
                    episodeID: episodeID,
                    episodeTitle: "Episode \(episodeID.prefix(8))...",
                    podcastTitle: "Unknown Podcast",
                    podcastFeedURL: nil,
                    downloadDate: Date.distantPast
                )
            }
        }

        // Group by podcast title
        let grouped = Dictionary(grouping: episodesWithInfo) { $0.podcastTitle }

        // Sort podcasts alphabetically, then episodes within each podcast
        return grouped.map { (podcast: $0.key, episodes: $0.value.sorted { $0.episodeTitle < $1.episodeTitle }) }
            .sorted { $0.podcast < $1.podcast }
    }

    var body: some View {
        List {
            if downloadManager.downloadedEpisodes.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No Downloaded Episodes")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Episodes you download will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedEpisodes, id: \.podcast) { group in
                    Section(header: Text(group.podcast).font(.headline)) {
                        ForEach(group.episodes, id: \.episodeID) { info in
                            Button(action: {
                                handleDownloadedEpisodeTap(info)
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(info.episodeTitle)
                                            .font(.headline)
                                            .lineLimit(2)
                                            .foregroundColor(.primary)

                                        if info.downloadDate != Date.distantPast {
                                            Text("Downloaded \(info.downloadDate.formatted(date: .abbreviated, time: .omitted))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        } else {
                                            Text("Downloaded")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    }

                                    Spacer()

                                    Button(action: {
                                        downloadManager.deleteDownload(info.episodeID)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .navigationTitle("Downloaded Episodes")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $episodePlayerData) { playerData in
            PlayerSheetWrapper(
                episode: playerData.episode,
                podcast: playerData.podcast,
                dismiss: { episodePlayerData = nil },
                autoPlay: true,
                seekToTime: playerData.seekToTime
            )
        }
    }

    private func handleDownloadedEpisodeTap(_ info: DownloadedEpisodeInfo) {
        print("🎵 Tapped downloaded episode: \(info.episodeTitle)")

        // Try to find podcast by feed URL first (most reliable)
        var podcast: PodcastEntity?
        if let feedURL = info.podcastFeedURL {
            podcast = podcasts.first(where: { $0.feedURL == feedURL })
            print("   Found podcast by feed URL: \(podcast?.title ?? "nil")")
        }

        // Fallback: find by title
        if podcast == nil {
            podcast = podcasts.first(where: { $0.title == info.podcastTitle })
            print("   Found podcast by title: \(podcast?.title ?? "nil")")
        }

        guard let foundPodcast = podcast else {
            print("❌ Could not find podcast for downloaded episode")
            return
        }

        // Get local file URL for downloaded episode
        guard let localURL = downloadManager.getLocalFileURL(for: info.episodeID) else {
            print("❌ Could not get local URL for downloaded episode")
            return
        }

        print("✅ Playing from local file: \(localURL.path)")

        // Verify file exists
        if !FileManager.default.fileExists(atPath: localURL.path) {
            print("❌ Local file does not exist at path: \(localURL.path)")
            return
        }

        // Get file size for verification
        if let attributes = try? FileManager.default.attributesOfItem(atPath: localURL.path),
           let fileSize = attributes[.size] as? Int64 {
            print("📦 Local file size: \(fileSize) bytes")
            if fileSize == 0 {
                print("❌ Local file is empty!")
                return
            }
        }

        // Create RSSEpisode from downloaded metadata
        // IMPORTANT: Must use absoluteString to preserve file:// scheme for AVPlayer
        let episode = RSSEpisode(
            title: info.episodeTitle,
            description: "",
            pubDate: info.downloadDate,
            duration: "",
            audioURL: localURL.absoluteString,
            imageURL: nil
        )

        print("✅ Setting episode player data - sheet will open")
        episodePlayerData = EpisodePlayerData(episode: episode, podcast: foundPodcast)
    }
}

struct DownloadedEpisodeInfo {
    let episodeID: String
    let episodeTitle: String
    let podcastTitle: String
    let podcastFeedURL: String?
    let downloadDate: Date
}

struct EpisodePlayerData: Identifiable {
    let id = UUID()
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let seekToTime: TimeInterval?

    init(episode: RSSEpisode, podcast: PodcastEntity, seekToTime: TimeInterval? = nil) {
        self.episode = episode
        self.podcast = podcast
        self.seekToTime = seekToTime
    }
}

// MARK: - Episode Detail View

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
