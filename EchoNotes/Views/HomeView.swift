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

    // Player state
    @ObservedObject private var player = GlobalPlayerManager.shared

    @State private var showingPlayerSheet = false
    @State private var showingBrowse = false
    @State private var showingSettings = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingBrowse = true
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.body)
                                .foregroundColor(.echoTextPrimary)
                        }

                        Button(action: {
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
                        showingPlayerSheet = true
                    },
                    onPlayTap: {
                        // Resume/toggle playback
                        if player.isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
                )
                .frame(width: 327)
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
            }
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
    }
}

