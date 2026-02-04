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
                ContinueListeningPlaceholder(
                    episodeTitle: episode.title,
                    podcastTitle: podcast.title ?? "Unknown Podcast",
                    progress: player.duration > 0 ? player.currentTime / player.duration : 0
                )
                .onTapGesture {
                    showingPlayerSheet = true
                }
            } else {
                Text("No episodes playing")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextTertiary)
            }
        }
        .sheet(isPresented: $showingPlayerSheet) {
            if let episode = player.currentEpisode, let _ = player.currentPodcast {
                // TODO: Replace with EpisodePlayerView when created
                Text("Player for: \(episode.title)")
                    .padding()
            }
        }
    }

    // MARK: - Recent Notes Section

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            ForEach(recentNotes.prefix(5)) { note in
                NoteCardPlaceholder(note: note)
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

// MARK: - Placeholder Components (Temporary)

struct ContinueListeningPlaceholder: View {
    let episodeTitle: String
    let podcastTitle: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(episodeTitle)
                .font(.bodyRoundedMedium())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)

            Text(podcastTitle)
                .font(.captionRounded())
                .foregroundColor(.echoTextSecondary)

            ProgressView(value: progress)
                .tint(.mintAccent)
        }
        .padding(EchoSpacing.noteCardPadding)
        .background(Color.noteCardBackground)
        .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

struct NoteCardPlaceholder: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let showTitle = note.showTitle {
                Text(showTitle)
                    .font(.captionRounded())
                    .foregroundColor(.echoTextSecondary)
            }

            if let noteText = note.noteText {
                Text(noteText)
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(3)
            }

            if let timestamp = note.timestamp {
                Text(timestamp)
                    .font(.caption2Medium())
                    .foregroundColor(.mintAccent)
            }
        }
        .padding(EchoSpacing.noteCardPadding)
        .background(Color.noteCardBackground)
        .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
