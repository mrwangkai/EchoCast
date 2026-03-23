//
//  LibraryView.swift
//  EchoNotes
//
//  Created on 10/29/25.
//

import SwiftUI
import CoreData

struct LibraryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = NoteViewModel()
    @ObservedObject private var player = GlobalPlayerManager.shared

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default
    ) private var followedPodcasts: FetchedResults<PodcastEntity>

    @State private var showingSortOptions = false
    @State private var selectedNote: NoteEntity?
    @State private var showingPlayerSheet = false
    @State private var noteToDelete: NoteEntity?
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var shareItem: ShareSheetItem?
    @State private var navigationPath = NavigationPath()
    @State private var showingContinueListeningSheet = false
    @State private var showingTagOverflow = false

    // Namespace for matched geometry effect with mini player
    @Namespace private var playerAnimation

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Search and Filter Section
                    searchAndFilterSection
                        .padding(.horizontal, EchoSpacing.screenPadding)
                        .padding(.top, 12)

                    // Notes Section
                    if viewModel.notes.isEmpty {
                        emptyStateView
                    } else {
                        notesSection
                            .padding(.horizontal, EchoSpacing.screenPadding)
                    }
                }
            }
            .background(Color.echoBackground)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.echoBackground, for: .navigationBar)
            .preferredColorScheme(.dark)
            .confirmationDialog("Sort By", isPresented: $showingSortOptions) {
                Button("Date (Newest First)") {
                    viewModel.sortOrder = .dateDescending
                }
                Button("Date (Oldest First)") {
                    viewModel.sortOrder = .dateAscending
                }
                Button("Show Title") {
                    viewModel.sortOrder = .showTitle
                }
                Button("Timestamp") {
                    viewModel.sortOrder = .timestamp
                }
                Button("Cancel", role: .cancel) {}
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "browse" {
                    PodcastDiscoveryView()
                }
            }
        }
        .sheet(item: $selectedNote) { note in
            NoteDetailSheet(note: note) {
                jumpToNoteTimestamp(note)
            }
        }
        .sheet(isPresented: $showingPlayerSheet) {
            if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                EpisodePlayerView(episode: episode, podcast: podcast, namespace: playerAnimation, player: GlobalPlayerManager.shared)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.large])
                    .presentationCornerRadius(20)
                    .preferredColorScheme(.dark)
            }
        }
        .alert("Delete Note", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let note = noteToDelete {
                    viewModel.deleteNote(note)
                    noteToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this note?")
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.text])
        }
    }

    // MARK: - Timestamp Jump

    private func jumpToNoteTimestamp(_ note: NoteEntity) {
        guard let timestamp = note.timestamp,
              let podcast = note.podcast else {
            print("⚠️ [Library] Cannot jump: note missing timestamp or podcast")
            return
        }

        guard let timeInSeconds = parseTimestamp(timestamp) else {
            print("⚠️ [Library] Cannot parse timestamp: \(timestamp)")
            return
        }

        print("⏭️ [Library] Jumping to timestamp: \(timestamp) (\(timeInSeconds)s)")

        let historyItems = PlaybackHistoryManager.shared.recentlyPlayed
        if let historyItem = historyItems.first(where: { item in
            item.episodeTitle == note.episodeTitle && item.podcastTitle == podcast.title
        }) {
            let episode = RSSEpisode(
                title: historyItem.episodeTitle,
                description: nil,
                pubDate: nil,
                duration: formatDuration(historyItem.duration),
                audioURL: historyItem.audioURL,
                imageURL: podcast.artworkURL
            )
            GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: timeInSeconds)
            showingPlayerSheet = true
            selectedNote = nil
            return
        }

        print("📡 [Library] Episode not in history, fetching from RSS...")
        fetchEpisodeAndPlay(from: podcast, episodeTitle: note.episodeTitle ?? "", seekTo: timeInSeconds)
    }

    private func fetchEpisodeAndPlay(from podcast: PodcastEntity, episodeTitle: String, seekTo: TimeInterval) {
        Task { @MainActor in
            guard let feedURL = podcast.feedURL else {
                print("⚠️ [Library] No feed URL for podcast")
                return
            }

            do {
                let service = PodcastRSSService.shared
                let rssPodcast = try await service.fetchPodcast(from: feedURL)

                if let episode = rssPodcast.episodes.first(where: { $0.title == episodeTitle }) {
                    print("✅ [Library] Found episode in RSS feed: \(episode.title)")
                    GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: seekTo)
                    showingPlayerSheet = true
                    selectedNote = nil
                } else {
                    print("⚠️ [Library] Episode not found in RSS feed: \(episodeTitle)")
                }
            } catch {
                print("❌ [Library] Failed to fetch RSS feed: \(error)")
            }
        }
    }

    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let parts = timestamp.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2:
            return parts[0] * 60 + parts[1]
        case 3:
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default:
            return nil
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }

    // MARK: - Share Note

    private func shareNote(_ note: NoteEntity) {
        guard let noteText = note.noteText,
              let showTitle = note.showTitle,
              let episodeTitle = note.episodeTitle,
              let timestamp = note.timestamp else {
            return
        }

        let shareText = """
        📝 Note from \(showTitle)

        "\(noteText)"

        — \(episodeTitle) @ \(timestamp)
        """

        shareItem = ShareSheetItem(text: shareText)
    }

    // MARK: - Search and Filter Section

    private var searchAndFilterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.echoTextTertiary)
                    .font(.system(size: 17))
                TextField("Search notes...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextPrimary)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.echoTextTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.searchFieldBackground)
            .cornerRadius(8)

            // Tag filter bar
            if !viewModel.allTags.isEmpty {
                tagFilterBar
            }

            // Notes count
            HStack {
                Text("\(viewModel.notes.count) notes")
                    .font(.caption2Medium())
                    .foregroundColor(.echoTextTertiary)
                Spacer()
            }
        }
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.groupedNotes(), id: \.key) { show, notes in
                VStack(alignment: .leading, spacing: 12) {
                    // Section header with show title
                    Text(show)
                        .font(.headline)
                        .foregroundColor(.echoTextPrimary)
                        .padding(.top, 8)
                    
                    // Notes in this show
                    ForEach(notes) { note in
                        NoteCardView(note: note)
                            .onTapGesture {
                                selectedNote = note
                            }
                            .contextMenu {
                                Button(action: {
                                    shareNote(note)
                                }) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }

                                Button(role: .destructive, action: {
                                    noteToDelete = note
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State View

    private var emptyStateView: some View {
        Group {
            if let activeTag = viewModel.activeTagFilter {
                VStack(spacing: 12) {
                    Image(systemName: "tag")
                        .font(.system(size: 36))
                        .foregroundColor(.echoTextTertiary)
                    Text("No notes tagged \"#\(activeTag)\"")
                        .font(.title2Echo())
                        .foregroundColor(.echoTextPrimary)
                    Button("Clear filter") {
                        viewModel.activeTagFilter = nil
                    }
                    .font(.bodyEcho())
                    .foregroundColor(.mintAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                VStack(spacing: 16) {
                    if followedPodcasts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "note.text")
                                .font(.system(size: 36))
                                .foregroundColor(.echoTextTertiary)
                            Text("Your notes live here")
                                .font(.title2Echo())
                                .foregroundColor(.echoTextPrimary)
                            Text("Play any episode and tap the note button to capture ideas as you listen.")
                                .font(.bodyEcho())
                                .foregroundColor(.echoTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("navigateToBrowse"),
                                    object: nil
                                )
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 15, weight: .medium))
                                    Text("Browse podcasts")
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
                        }
                    } else {
                        HStack(spacing: 12) {
                            Text("Play an episode and capture what stays with you")
                                .font(.bodyEcho())
                                .foregroundColor(.echoTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Button(action: {
                                showingContinueListeningSheet = true
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.mintAccent.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.mintAccent)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.mintAccent.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.mintAccent.opacity(0.15), lineWidth: 1)
                        )
                        .padding(.horizontal, EchoSpacing.screenPadding)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
                .sheet(isPresented: $showingContinueListeningSheet) {
                    ContinueListeningSheetView()
                }
            }
        }
    }

    // MARK: - Tag Filter Bar

    private var tagFilterBar: some View {
        let visibleTags = Array(viewModel.allTags.prefix(4))
        let overflowCount = viewModel.allTags.count - visibleTags.count

        return HStack(spacing: 8) {
            tagChip(label: "All", isActive: viewModel.activeTagFilter == nil) {
                viewModel.activeTagFilter = nil
            }
            ForEach(visibleTags, id: \.self) { tag in
                tagChip(label: "#\(tag)", isActive: viewModel.activeTagFilter == tag) {
                    viewModel.activeTagFilter = (viewModel.activeTagFilter == tag) ? nil : tag
                }
            }
            if overflowCount > 0 {
                tagChip(label: "+\(overflowCount) more", isActive: false) {
                    showingTagOverflow = true
                }
            }
            Spacer()
        }
        .sheet(isPresented: $showingTagOverflow) {
            tagOverflowSheet
        }
    }

    private func tagChip(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption2Medium())
                .foregroundColor(isActive ? Color.black : Color.echoTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isActive ? Color.mintAccent : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(isActive ? Color.mintAccent : Color.echoTextTertiary.opacity(0.4), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var tagOverflowSheet: some View {
        NavigationStack {
            List {
                Button(action: {
                    viewModel.activeTagFilter = nil
                    showingTagOverflow = false
                }) {
                    HStack {
                        Text("All notes")
                            .font(.bodyEcho())
                            .foregroundColor(.echoTextPrimary)
                        Spacer()
                        if viewModel.activeTagFilter == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.mintAccent)
                        }
                    }
                }
                .listRowBackground(Color.noteCardBackground)

                ForEach(viewModel.allTags, id: \.self) { tag in
                    Button(action: {
                        viewModel.activeTagFilter = tag
                        showingTagOverflow = false
                    }) {
                        HStack {
                            Text("#\(tag)")
                                .font(.bodyEcho())
                                .foregroundColor(.echoTextPrimary)
                            Spacer()
                            if viewModel.activeTagFilter == tag {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.mintAccent)
                            }
                        }
                    }
                    .listRowBackground(Color.noteCardBackground)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.echoBackground)
            .navigationTitle("Filter by tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showingTagOverflow = false }
                        .foregroundColor(.mintAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Share Sheet

struct ShareSheetItem: Identifiable {
    let id = UUID()
    let text: String
}

#Preview {
    LibraryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
