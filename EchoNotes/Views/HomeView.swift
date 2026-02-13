//
//  HomeView.swift
//  EchoNotes
//
//  Main home screen showing continue listening and recent notes
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch recent notes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var recentNotes: FetchedResults<NoteEntity>

    // Fetch all podcasts for Continue Listening cards
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default
    )
    private var allPodcasts: FetchedResults<PodcastEntity>

    // Fetch followed podcasts
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        predicate: NSPredicate(format: "isFollowing == YES"),
        animation: .default
    )
    private var followedPodcasts: FetchedResults<PodcastEntity>

    // Player state
    @ObservedObject private var player = GlobalPlayerManager.shared

    @State private var showingPlayerSheet = false
    @State private var showingSettings = false
    @State private var selectedPodcast: PodcastEntity?
    @State private var selectedNote: NoteEntity?

    // Recently played episodes for Continue Listening section
    @State private var continueListeningEpisodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] = []

    // Namespace for matched geometry effect with mini player
    @Namespace private var playerAnimation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header with inline buttons
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EchoCast")
                                .font(.largeTitleEcho())
                                .foregroundColor(.echoTextPrimary)

                            Text(greetingText)
                                .font(.bodyEcho())
                                .foregroundColor(.echoTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Buttons inline with header
                        HStack(spacing: 16) {
                            Button(action: {
                                print("🔍 [HomeView] Browse button tapped")
                                selectedTab = 1  // Switch to Browse tab
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.body)
                                    .foregroundColor(.echoTextPrimary)
                                    .frame(width: 44, height: 44)
                            }

                            Button(action: {
                                print("⚙️ [HomeView] Settings button tapped")
                                showingSettings = true
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.body)
                                    .foregroundColor(.echoTextPrimary)
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.horizontal, EchoSpacing.screenPadding)
                    .padding(.top, EchoSpacing.headerTopPadding)

                    // Continue Listening Section
                    if player.currentEpisode != nil || !recentNotes.isEmpty {
                        continueListeningSection
                    }

                    // Following Section
                    if !followedPodcasts.isEmpty {
                        followingSection
                    }

                    // Recent Notes Section
                    if !recentNotes.isEmpty {
                        recentNotesSection
                    }

                    // Empty state - only show when there's no content at all
                    if player.currentEpisode == nil && recentNotes.isEmpty && followedPodcasts.isEmpty {
                        emptyStateView
                    }
                }
                .padding(.bottom, 100)
            }
            .background(Color.echoBackground)
            .navigationBarHidden(true)
            .onAppear {
                print("🏠 [HomeView] View appeared")
                print("🏠 [HomeView] Recent notes count: \(recentNotes.count)")
                print("🏠 [HomeView] Followed podcasts count: \(followedPodcasts.count)")
                print("🏠 [HomeView] Player episode loaded: \(player.currentEpisode != nil)")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $selectedPodcast) { podcast in
            PodcastDetailView(podcast: podcast)
                .onAppear {
                    print("✅ [Home] Sheet opened successfully with podcast: \(podcast.title ?? "nil")")
                }
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note)
        }
        .sheet(isPresented: $showingPlayerSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                NavigationStack {
                    EpisodePlayerView(episode: episode, podcast: podcast, namespace: playerAnimation)
                        .navigationBarTitleDisplayMode(.inline)
                        .onAppear {
                            print("👁️ [HomeView Player Sheet] EpisodePlayerView appeared")
                        }
                        .onDisappear {
                            print("👁️ [HomeView Player Sheet] EpisodePlayerView disappeared")
                        }
                }
                .presentationDragIndicator(.visible)
                .presentationDetents([.large])
                .presentationCornerRadius(20)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EchoCast")
                .font(.largeTitleEcho())
                .foregroundColor(.echoTextPrimary)

            Text(greetingText)
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    // MARK: - Continue Listening Section

    private var continueListeningSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Continue Listening")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .padding(.horizontal, EchoSpacing.screenPadding)

            if !continueListeningEpisodes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(continueListeningEpisodes, id: \.historyItem.id) { item in
                            ContinueListeningCard(
                                episode: continueListeningEpisodeFromHistory(historyItem: item.historyItem, podcast: item.podcast),
                                onTap: {
                                    print("🎧 [HomeView] Continue Listening card tapped: \(item.historyItem.episodeTitle)")
                                    // Load and play this episode
                                    loadEpisodeFromHistory(item: item.historyItem, podcast: item.podcast)
                                },
                                onPlayTap: {
                                    print("🎮 [HomeView] Play button tapped")
                                    // Load and play this episode
                                    loadEpisodeFromHistory(item: item.historyItem, podcast: item.podcast)
                                }
                            )
                            .frame(width: 327)
                        }
                    }
                    .padding(.horizontal, EchoSpacing.screenPadding)
                }
                .onAppear {
                    print("🎧 [HomeView] Showing \(continueListeningEpisodes.count) Continue Listening cards")
                }
            } else {
                Text("No episodes in progress")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextTertiary)
                    .padding(.horizontal, EchoSpacing.screenPadding)
            }
        }
        .onAppear {
            loadContinueListeningEpisodes()
        }
        .onChange(of: allPodcasts.count) { _ in
            loadContinueListeningEpisodes()
        }
    }

    // MARK: - Following Section

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Following podcasts")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .padding(.horizontal, EchoSpacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(followedPodcasts) { podcast in
                        PodcastFollowingCard(podcast: podcast)
                            .onTapGesture {
                                print("🎙️ [HomeView] Podcast tapped: \(podcast.title ?? "Unknown")")
                                print("🔓 [HomeView] Opening podcast detail sheet")
                                selectedPodcast = podcast  // Sheet opens automatically
                            }
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
            }
        }
        .onAppear {
            print("🎙️ [HomeView] Showing Following section (\(followedPodcasts.count) podcasts)")
        }
    }

    // MARK: - Helper Methods

    private func continueListeningEpisodeFromPlayer(episode: RSSEpisode, podcast: PodcastEntity) -> ContinueListeningEpisode {
        let notesCount = recentNotes.filter { $0.episodeTitle == episode.title }.count
        let remaining = (player.duration - player.currentTime)
        let timeRemaining = formatTimeRemaining(remaining)

        return ContinueListeningEpisode(
            id: episode.id,
            title: episode.title,
            podcastName: podcast.title ?? "Unknown Podcast",
            artworkURL: episode.imageURL ?? podcast.artworkURL,
            progress: player.duration > 0 ? player.currentTime / player.duration : 0,
            notesCount: notesCount,
            timeRemaining: timeRemaining,
            audioURL: episode.audioURL,
            duration: player.duration,
            currentTime: player.currentTime
        )
    }

    private func formatTimeRemaining(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    /// Formats a duration TimeInterval as a string (e.g., "MM:SS" or "H:MM:SS")
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let mins = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
    }

    // MARK: - Continue Listening from History

    /// Loads recently played episodes from playback history and matches them with podcast entities
    private func loadContinueListeningEpisodes() {
        let historyItems = PlaybackHistoryManager.shared.getRecentlyPlayed(limit: 5)

        var episodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] = []

        for historyItem in historyItems {
            // Find the podcast entity for this history item
            // Try to match by podcastID first, then by podcast title as fallback
            let podcast: PodcastEntity?

            if let foundPodcast = allPodcasts.first(where: { $0.id == historyItem.podcastID }) {
                podcast = foundPodcast
            } else if let foundPodcast = allPodcasts.first(where: { $0.title == historyItem.podcastTitle }) {
                podcast = foundPodcast
            } else {
                podcast = nil
            }

            if let p = podcast {
                episodes.append((historyItem: historyItem, podcast: p))
            }
        }

        continueListeningEpisodes = episodes

        print("🎧 [HomeView] Loaded \(continueListeningEpisodes.count) continue listening episodes")
    }

    /// Converts a playback history item to a ContinueListeningEpisode
    private func continueListeningEpisodeFromHistory(historyItem: PlaybackHistoryItem, podcast: PodcastEntity) -> ContinueListeningEpisode {
        let notesCount = recentNotes.filter { $0.episodeTitle == historyItem.episodeTitle }.count
        let remaining = max(0, historyItem.duration - historyItem.currentTime)
        let timeRemaining = formatTimeRemaining(remaining)

        return ContinueListeningEpisode(
            id: historyItem.id,
            title: historyItem.episodeTitle,
            podcastName: historyItem.podcastTitle,
            artworkURL: podcast.artworkURL,
            progress: historyItem.progress,
            notesCount: notesCount,
            timeRemaining: timeRemaining,
            audioURL: historyItem.audioURL,
            duration: historyItem.duration,
            currentTime: historyItem.currentTime
        )
    }

    /// Loads an episode from playback history into the player
    private func loadEpisodeFromHistory(item: PlaybackHistoryItem, podcast: PodcastEntity) {
        // Create RSSEpisode from history item
        let episode = RSSEpisode(
            title: item.episodeTitle,
            description: nil,
            pubDate: nil,
            duration: formatDuration(item.duration),  // Convert TimeInterval to String
            audioURL: item.audioURL,
            imageURL: podcast.artworkURL
        )

        print("🔍 [Debug] audioURL being passed: '\(item.audioURL)'")
        print("🔍 [Debug] podcast: \(podcast.title ?? "nil"), id: \(podcast.id ?? "nil")")

        GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: item.currentTime)
        showingPlayerSheet = true
    }

    // MARK: - Recent Notes Section

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)
                .padding(.horizontal, EchoSpacing.screenPadding)

            ForEach(recentNotes.prefix(5)) { note in
                NoteCardView(note: note)
                    .padding(.horizontal, EchoSpacing.screenPadding)
                    .onTapGesture {
                        print("📝 [HomeView] Note tapped: \(note.noteText?.prefix(50) ?? "No text")...")
                        selectedNote = note
                    }
            }
        }
        .onAppear {
            print("📝 [HomeView] Showing Recent Notes section (\(recentNotes.count) notes)")
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 100)

            Image(systemName: "waveform")
                .font(.system(size: 72))
                .foregroundColor(.mintAccent)

            VStack(spacing: 8) {
                Text("No notes yet")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)

                Text("Start listening to a podcast and add notes as you go")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Find a podcast CTA
            Button(action: {
                selectedTab = 1  // Switch to Browse tab
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                    Text("Find a podcast")
                        .font(.bodyRoundedMedium())
                }
                .foregroundColor(.mintButtonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.vertical, 16)
                .background(Color.mintButtonBackground)
                .cornerRadius(12)
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .buttonStyle(.plain)

            Spacer()
                .frame(height: 32)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            print("🏠 [HomeView] Showing empty state")
        }
    }
}

// MARK: - Podcast Following Card

struct PodcastFollowingCard: View {
    let podcast: PodcastEntity

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Album artwork
            CachedAsyncImage(url: URL(string: podcast.artworkURL ?? "")) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.noteCardBackground)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 32))
                            .foregroundColor(.echoTextTertiary)
                    )
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Podcast title - fixed height to prevent misalignment
            Text(podcast.title ?? "Unknown Podcast")
                .font(.captionRounded())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
                .frame(width: 120, height: 16, alignment: .top)
        }
        .frame(height: 160)  // Fixed total height for consistent alignment
        .contentShape(Rectangle())
    }
}

