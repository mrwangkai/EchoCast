//
//  ContentView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var player = GlobalPlayerManager.shared
    @StateObject private var devStatus = DevStatusManager.shared
    @State private var showSiriNoteCaptureSheet = false
    @State private var siriNoteTimestamp = ""
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        ZStack {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            PodcastsListView()
                .tabItem {
                    Label("Podcasts", systemImage: "mic.fill")
                }
                .tag(1)

            NotesListView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(2)
        }
        .tint(.blue)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.showMiniPlayer {
                MiniPlayerView()
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
        .sheet(isPresented: $showSiriNoteCaptureSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                QuickNoteCaptureView(
                    podcast: podcast,
                    episode: episode,
                    timestamp: siriNoteTimestamp
                )
            }
        }

        // Dev status overlay
        DevStatusOverlay()
        }
    }

    private func checkForSiriIntent() {
        if UserDefaults.standard.bool(forKey: "shouldShowNoteCaptureFromSiri") {
            siriNoteTimestamp = UserDefaults.standard.string(forKey: "siriNoteTimestamp") ?? ""
            showSiriNoteCaptureSheet = true
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default)
    private var podcasts: FetchedResults<PodcastEntity>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default)
    private var recentNotes: FetchedResults<NoteEntity>

    @ObservedObject private var historyManager = PlaybackHistoryManager.shared
    @State private var showAddPodcastSheet = false
    @State private var showRecentEpisodePlayer = false
    @State private var selectedRecentEpisode: RSSEpisode?
    @State private var selectedRecentPodcast: PodcastEntity?
    @State private var selectedRecentTimestamp: TimeInterval = 0

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) {
                        recentlyPlayedSection

                        Divider()
                            .padding(.horizontal)

                        recentNotesSection
                    }
                    .padding(.bottom, 100)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DevStatusToggleButton()
                }
            }
            .sheet(isPresented: $showAddPodcastSheet) {
                PodcastDiscoveryView()
            }
            .sheet(isPresented: $showRecentEpisodePlayer) {
                recentEpisodePlayerSheet
            }
        }
    }

    @ViewBuilder
    private var recentEpisodePlayerSheet: some View {
        if let episode = selectedRecentEpisode, let podcast = selectedRecentPodcast {
            PlayerSheetWrapper(
                episode: episode,
                podcast: podcast,
                dismiss: { showRecentEpisodePlayer = false },
                autoPlay: true,
                seekToTime: selectedRecentTimestamp
            )
        }
    }

    private var addPodcastButton: some View {
        Button(action: {
            showAddPodcastSheet = true
        }) {
            HStack {
                Text("Add URL")
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var podcastsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Podcasts")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if !podcasts.isEmpty {
                    NavigationLink(destination: PodcastsListView()) {
                        Text("view all")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if podcasts.isEmpty {
                EmptyPodcastsHomeView(onAddPodcast: {
                    showAddPodcastSheet = true
                })
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(getRecentPodcasts()) { podcast in
                            NavigationLink(destination: PodcastDetailView(podcast: podcast)) {
                                PodcastCardView(podcast: podcast)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    @ViewBuilder
    private var recentlyPlayedSection: some View {
        if !historyManager.recentlyPlayed.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recently Played")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: {
                        selectedTab = 1
                    }) {
                        Text("view all")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 16) {
                        ForEach(historyManager.getRecentlyPlayed(limit: 3)) { item in
                            RecentlyPlayedCardView(historyItem: item) {
                                handleRecentEpisodeTap(item)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Notes")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                if !recentNotes.isEmpty {
                    NavigationLink(destination: NotesListView()) {
                        Text("view all")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(.horizontal)

            if recentNotes.isEmpty {
                EmptyNotesHomeView()
            } else {
                VStack(spacing: 12) {
                    ForEach(recentNotes.prefix(5)) { note in
                        NavigationLink(destination: NoteDetailSheetView(note: note)) {
                            NoteCardView(note: note)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // View all link at bottom
                    if recentNotes.count > 5 {
                        NavigationLink(destination: NotesListView()) {
                            HStack {
                                Spacer()
                                Text("view all (\(recentNotes.count) notes)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func getRecentPodcasts() -> [PodcastEntity] {
        // Get unique podcast IDs from recently played history
        let recentPodcastIDs = historyManager.recentlyPlayed
            .map { $0.podcastID }
            .reduce(into: [String]()) { result, id in
                if !result.contains(id) {
                    result.append(id)
                }
            }

        // Map to PodcastEntity and take first 3
        let recentPodcasts = recentPodcastIDs.compactMap { podcastID in
            podcasts.first(where: { $0.id == podcastID })
        }

        // If less than 3, fill with other podcasts
        if recentPodcasts.count < 3 {
            let remainingPodcasts = podcasts.filter { podcast in
                !recentPodcastIDs.contains(podcast.id ?? "")
            }
            return Array((recentPodcasts + remainingPodcasts).prefix(3))
        }

        return Array(recentPodcasts.prefix(3))
    }

    private func handleRecentEpisodeTap(_ item: PlaybackHistoryItem) {
        if let podcast = podcasts.first(where: { $0.id == item.podcastID }) {
            let episode = RSSEpisode(
                title: item.episodeTitle,
                description: "",
                pubDate: item.lastPlayed,
                duration: String(Int(item.duration)),
                audioURL: item.audioURL,
                imageURL: nil
            )
            selectedRecentEpisode = episode
            selectedRecentPodcast = podcast
            selectedRecentTimestamp = item.currentTime
            showRecentEpisodePlayer = true
        }
    }
}

// MARK: - Podcast Card

struct PodcastCardView: View {
    let podcast: PodcastEntity

    var body: some View {
        VStack(spacing: 8) {
            CachedAsyncImage(url: podcast.artworkURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    )
            }

            VStack(spacing: 4) {
                Text(podcast.title ?? "Unknown")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if let author = podcast.author {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 140)
        }
    }
}

// MARK: - Recently Played Card

struct RecentlyPlayedCardView: View {
    let historyItem: PlaybackHistoryItem
    let onTap: () -> Void

    @FetchRequest private var episodeNotes: FetchedResults<NoteEntity>
    @FetchRequest private var podcast: FetchedResults<PodcastEntity>

    init(historyItem: PlaybackHistoryItem, onTap: @escaping () -> Void) {
        self.historyItem = historyItem
        self.onTap = onTap

        _episodeNotes = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "episodeTitle == %@", historyItem.episodeTitle)
        )

        _podcast = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "title == %@", historyItem.podcastTitle)
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail with progress indicator
                ZStack {
                    CachedAsyncImage(url: podcast.first?.artworkURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .overlay(
                                Image(systemName: "music.note")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                            )
                    }

                    // Circular progress indicator
                    Circle()
                        .trim(from: 0, to: historyItem.progress)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                }

                // Episode info
                VStack(alignment: .leading, spacing: 4) {
                    // Episode name (header)
                    Text(historyItem.episodeTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Series name (caption)
                    Text(historyItem.podcastTitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)

                    // Note count
                    if !episodeNotes.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "note.text")
                                .font(.caption2)
                            Text("\(episodeNotes.count) note\(episodeNotes.count == 1 ? "" : "s")")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }

                    // Time remaining indicator
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("\(formatTimeRemaining(current: historyItem.currentTime, duration: historyItem.duration)) left")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func formatTimeRemaining(current: TimeInterval, duration: TimeInterval) -> String {
        let remaining = max(0, duration - current)
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) / 60 % 60
        let seconds = Int(remaining) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Note Card

struct NoteCardView: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Episode title (header)
            if let episodeTitle = note.episodeTitle {
                Text(episodeTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            // Series name (caption/subtitle)
            if let showTitle = note.showTitle {
                Text(showTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Note text
            if let noteText = note.noteText {
                Text(noteText)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(3)
            }

            // Timestamp only (removed time elapsed)
            HStack {
                if let timestamp = note.timestamp {
                    Label(timestamp, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                if note.isPriority {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
            Text("No podcasts yet")
                .font(.subheadline)
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
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No notes yet")
                .font(.subheadline)
                .foregroundColor(.gray)
            Text("Listen to a podcast and tap '+ Add Note' to get started")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    @State private var selectedEpisode: RSSEpisode?
    @State private var selectedPodcast: PodcastEntity?
    @State private var isLoadingEpisode = false

    // Recommended podcasts for zero state
    private let recommendedPodcasts = [
        RecommendedPodcast(
            title: "The Tim Ferriss Show",
            description: "Interviews with world-class performers",
            rssURL: "https://rss.art19.com/tim-ferriss-show"
        ),
        RecommendedPodcast(
            title: "Huberman Lab",
            description: "Science-based tools for everyday life",
            rssURL: "https://feeds.megaphone.fm/hubermanlab"
        ),
        RecommendedPodcast(
            title: "Lex Fridman Podcast",
            description: "Conversations about AI, science, and technology",
            rssURL: "https://lexfridman.com/feed/podcast/"
        ),
        RecommendedPodcast(
            title: "How I Built This",
            description: "Stories behind the world's best known companies",
            rssURL: "https://feeds.npr.org/510313/podcast.xml"
        ),
        RecommendedPodcast(
            title: "The Daily",
            description: "The biggest stories of our time",
            rssURL: "https://feeds.simplecast.com/54nAGcIl"
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

                    // My Podcasts Section (Carousel)
                    if !podcasts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Podcasts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(podcasts.prefix(5))) { podcast in
                                        NavigationLink(destination: PodcastDetailView(podcast: podcast)) {
                                            PodcastCardView(podcast: podcast)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }

                    // Empty state
                    if podcasts.isEmpty && getIndividualEpisodes().isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "mic.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No podcasts yet")
                                .font(.title3)
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
            .overlay {
                if isLoadingEpisode {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Loading episode...")
                                    .foregroundColor(.white)
                            }
                        }
                }
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

    private func addRecommendedPodcast(_ recommended: RecommendedPodcast) {
        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: recommended.rssURL)
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

        // Get episodes with notes
        for note in allNotes {
            if let episodeTitle = note.episodeTitle,
               let podcastTitle = note.showTitle,
               !seenEpisodes.contains(episodeTitle) {
                seenEpisodes.insert(episodeTitle)

                // Get podcast artwork
                let podcast = podcasts.first { $0.title == podcastTitle }
                let noteCount = allNotes.filter { $0.episodeTitle == episodeTitle }.count

                // Check if also downloaded
                let playbackItem = PlaybackHistoryManager.shared.recentlyPlayed.first { $0.episodeTitle == episodeTitle }
                let isDownloaded = playbackItem.map { downloadManager.isDownloaded($0.id) } ?? false

                episodes.append(IndividualEpisodeItem(
                    episodeTitle: episodeTitle,
                    podcastTitle: podcastTitle,
                    episodeImageURL: nil, // Will be loaded from RSS when needed
                    podcastImageURL: podcast?.artworkURL,
                    noteCount: noteCount,
                    isDownloaded: isDownloaded
                ))
            }
        }

        // Get downloaded episodes from playback history
        for item in PlaybackHistoryManager.shared.recentlyPlayed {
            let isDownloaded = downloadManager.isDownloaded(item.id)
            if isDownloaded && !seenEpisodes.contains(item.episodeTitle) {
                seenEpisodes.insert(item.episodeTitle)

                // Get podcast artwork
                let podcast = podcasts.first { $0.title == item.podcastTitle }
                let noteCount = allNotes.filter { $0.episodeTitle == item.episodeTitle }.count

                episodes.append(IndividualEpisodeItem(
                    episodeTitle: item.episodeTitle,
                    podcastTitle: item.podcastTitle,
                    episodeImageURL: nil, // Will be loaded from RSS when needed
                    podcastImageURL: podcast?.artworkURL,
                    noteCount: noteCount,
                    isDownloaded: true
                ))
            }
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
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Series name
                    Text(item.podcastTitle)
                        .font(.caption)
                        .foregroundColor(.gray)
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
                    .lineLimit(2)
                Text(item.podcastTitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
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
}

// MARK: - Recommended Podcast Row

struct RecommendedPodcastRow: View {
    let podcast: RecommendedPodcast
    let onAdd: () -> Void
    @State private var isAdding = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "mic.fill")
                            .foregroundColor(.blue)
                    )

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
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Notes List View

struct NotesListView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default)
    private var notes: FetchedResults<NoteEntity>

    @State private var selectedSegment = 0
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Sort By", selection: $selectedSegment) {
                    Text("By Date").tag(0)
                    Text("By Episode").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if notes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No notes yet")
                            .font(.title3)
                            .foregroundColor(.gray)
                        Text("Listen to a podcast and add notes")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if selectedSegment == 0 {
                            // By Date
                            ForEach(groupedByDate(), id: \.key) { date, notesForDate in
                                Section(header: Text(date)) {
                                    ForEach(notesForDate) { note in
                                        NoteRowDetailView(note: note)
                                    }
                                }
                            }
                        } else {
                            // By Episode
                            ForEach(groupedByEpisode(), id: \.key) { episode, notesForEpisode in
                                Section(header: Text(episode)) {
                                    ForEach(notesForEpisode) { note in
                                        NoteRowDetailView(note: note)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .padding(.bottom, 100)
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func groupedByDate() -> [(key: String, value: [NoteEntity])] {
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

    private func groupedByEpisode() -> [(key: String, value: [NoteEntity])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            if let episode = note.episodeTitle, !episode.isEmpty {
                return episode
            }
            return "Untitled Episode"
        }

        return grouped.sorted { $0.key < $1.key }
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
                    .lineLimit(3)
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
                                ProgressView("Loading episodes...")
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
                ProgressView("Loading podcast...")
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
    @State private var searchText = ""
    @State private var searchResults: [iTunesSearchService.iTunesPodcast] = []
    @State private var isSearching = false
    @State private var showError = false
    @State private var errorMessage = ""

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
                        .onSubmit {
                            performSearch()
                        }

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                            searchResults = []
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
                            ProgressView("Searching...")
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
                        } else if !searchText.isEmpty && !isSearching {
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        isSearching = true
        Task {
            do {
                let results = try await iTunesSearchService.shared.search(query: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "Failed to search: \(error.localizedDescription)"
                    showError = true
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
        Task {
            do {
                let rssPodcast = try await PodcastRSSService.shared.fetchPodcast(from: recommended.rssURL)
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
                            Button(action: dismiss) {
                                Image(systemName: "xmark.circle.fill")
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
    @State private var editedIsPriority: Bool = false
    @State private var isEditing: Bool = false
    @State private var loadedEpisode: RSSEpisode?
    @State private var loadedPodcast: PodcastEntity?
    @State private var isLoadingEpisode = false
    @State private var loadError: String?
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)]
    ) private var podcasts: FetchedResults<PodcastEntity>

    var body: some View {
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
                                editedIsPriority = note.isPriority
                                isEditing = true
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                    }

                    HStack {
                        if isEditing {
                            Toggle(isOn: $editedIsPriority) {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("Important")
                                        .font(.caption)
                                }
                            }
                            .toggleStyle(.button)
                        } else if note.isPriority {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Important")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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
        .navigationTitle("Note Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedNoteText = note.noteText ?? ""
            editedIsPriority = note.isPriority
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
    }

    private func saveChanges() {
        note.noteText = editedNoteText
        note.isPriority = editedIsPriority

        do {
            try viewContext.save()
        } catch {
            print("Error saving note changes: \(error)")
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

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
