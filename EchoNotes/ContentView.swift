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

        // Dev status overlay
        DevStatusOverlay()
        }
    }
}

// MARK: - Home View

struct HomeView: View {
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
                        podcastsSection
                        recentlyPlayedSection

                        Divider()
                            .padding(.horizontal)

                        recentNotesSection

                        Spacer(minLength: 80)
                    }
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
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
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
                    Text("\(recentNotes.count)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)

            if recentNotes.isEmpty {
                EmptyNotesHomeView()
            } else {
                VStack(spacing: 12) {
                    ForEach(recentNotes.prefix(10)) { note in
                        NavigationLink(destination: NoteDetailSheetView(note: note)) {
                            NoteCardView(note: note)
                        }
                        .buttonStyle(PlainButtonStyle())
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.2))
                .frame(width: 140, height: 140)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                )

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

    init(historyItem: PlaybackHistoryItem, onTap: @escaping () -> Void) {
        self.historyItem = historyItem
        self.onTap = onTap

        _episodeNotes = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "episodeTitle == %@", historyItem.episodeTitle)
        )
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    )

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

                    // Progress indicator
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .font(.caption2)
                        Text("\(Int(historyItem.progress * 100))%")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(PlainButtonStyle())
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

    @State private var showAddPodcastSheet = false

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
                VStack(spacing: 0) {
                    // My Podcasts Section
                    if !podcasts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("My Podcasts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                                .padding(.top, 8)

                            ForEach(podcasts) { podcast in
                                NavigationLink(destination: PodcastDetailView(podcast: podcast)) {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Image(systemName: "music.note")
                                                    .foregroundColor(.blue)
                                            )

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(podcast.title ?? "Unknown Podcast")
                                                .font(.headline)
                                                .lineLimit(2)
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
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                    }

                    // Recommended Podcasts Section
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            Text("Recommended Podcasts")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(podcasts.isEmpty ? "Get started with these popular podcasts" : "Discover more podcasts")
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
            .navigationTitle("Podcasts")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddPodcastSheet) {
                PodcastDiscoveryView()
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

// MARK: - Player Sheet Wrapper

struct PlayerSheetWrapper: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let dismiss: () -> Void
    var autoPlay: Bool = true
    var seekToTime: TimeInterval? = nil

    var body: some View {
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
            .safeAreaInset(edge: .top, spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(Color(.systemBackground))
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
                        showPlayer = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title3)
                            Text("Play at \(timestamp)")
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
            if let episodeTitle = note.episodeTitle,
               let podcast = findPodcast(for: note.showTitle),
               let episode = findEpisode(title: episodeTitle, in: podcast) {
                PlayerSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    dismiss: { showPlayer = false },
                    autoPlay: false,
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

    private func findPodcast(for title: String?) -> PodcastEntity? {
        guard let title = title else { return nil }
        return podcasts.first { $0.title == title }
    }

    private func findEpisode(title: String, in podcast: PodcastEntity) -> RSSEpisode? {
        // This is a placeholder - in a real app, you'd fetch episodes from the podcast
        // For now, return nil and we'll handle this gracefully
        return nil
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
