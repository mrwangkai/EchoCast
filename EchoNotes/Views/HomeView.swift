//
//  HomeView.swift
//  EchoNotes
//
//  Main home screen showing continue listening and recent notes
//

import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Fetch recent notes
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
        animation: .default
    )
    private var recentNotes: FetchedResults<NoteEntity>

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
    @State private var showingBrowse = false
    @State private var showingSettings = false
    @State private var selectedPodcast: PodcastEntity?
    @State private var showingPodcastDetail = false
    @State private var selectedNote: NoteEntity?
    @State private var showingNoteDetail = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Header
                    headerSection

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
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.top, EchoSpacing.headerTopPadding)
            }
            .background(Color.echoBackground)
            .onAppear {
                print("🏠 [HomeView] View appeared")
                print("🏠 [HomeView] Recent notes count: \(recentNotes.count)")
                print("🏠 [HomeView] Followed podcasts count: \(followedPodcasts.count)")
                print("🏠 [HomeView] Player episode loaded: \(player.currentEpisode != nil)")
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            print("🔍 [HomeView] Browse button tapped")
                            showingBrowse = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.body)
                                .foregroundColor(.echoTextPrimary)
                        }

                        Button(action: {
                            print("⚙️ [HomeView] Settings button tapped")
                            showingSettings = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.body)
                                .foregroundColor(.echoTextPrimary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingBrowse) {
            PodcastDiscoveryView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPodcastDetail) {
            if let podcast = selectedPodcast {
                PodcastDetailView(podcast: podcast)
            }
        }
        .sheet(isPresented: $showingNoteDetail) {
            if let note = selectedNote {
                NoteDetailSheet(note: note)
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

            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                ContinueListeningCard(
                    episode: continueListeningEpisodeFromPlayer(episode: episode, podcast: podcast),
                    onTap: {
                        print("🎧 [HomeView] Continue Listening card tapped: \(episode.title)")
                        showingPlayerSheet = true
                    },
                    onPlayTap: {
                        print("🎮 [HomeView] Play button tapped, current state: \(player.isPlaying)")
                        // Resume/toggle playback
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
                )
                .frame(width: 327)
                .onAppear {
                    print("🎧 [HomeView] Showing Continue Listening section")
                }
            } else {
                Text("No episodes playing")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextTertiary)
            }
        }
        .sheet(isPresented: $showingPlayerSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                EpisodePlayerView(episode: episode, podcast: podcast)
            }
        }
    }

    // MARK: - Following Section

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Following")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(followedPodcasts) { podcast in
                        PodcastFollowingCard(podcast: podcast)
                            .onTapGesture {
                                print("🎙️ [HomeView] Podcast tapped: \(podcast.title ?? "Unknown")")
                                print("🔓 [HomeView] Setting selectedPodcast BEFORE opening sheet")
                                selectedPodcast = podcast

                                // Dispatch to next run loop to ensure state is set
                                DispatchQueue.main.async {
                                    print("🔓 [HomeView] Opening sheet for: \(podcast.title ?? "Unknown")")
                                    showingPodcastDetail = true
                                }
                            }
                    }
                }
                .padding(.trailing, EchoSpacing.screenPadding)
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

    // MARK: - Recent Notes Section

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            ForEach(recentNotes.prefix(5)) { note in
                NoteCardView(note: note)
                    .onTapGesture {
                        print("📝 [HomeView] Note tapped: \(note.noteText?.prefix(50) ?? "No text")...")
                        selectedNote = note
                        showingNoteDetail = true
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

            Spacer()
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
        VStack(spacing: 8) {
            // Album artwork
            AsyncImage(url: URL(string: podcast.artworkURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.noteCardBackground)
                        .frame(width: 120, height: 120)
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.noteCardBackground)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 32))
                                .foregroundColor(.echoTextTertiary)
                        )
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.noteCardBackground)
                        .frame(width: 120, height: 120)
                }
            }

            // Podcast title
            Text(podcast.title ?? "Unknown Podcast")
                .font(.captionRounded())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 120)

            // Follow indicator
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.mintAccent)
                Text("Following")
                    .font(.caption2)
                    .foregroundColor(.echoTextSecondary)
            }
        }
        .contentShape(Rectangle())
    }
}

