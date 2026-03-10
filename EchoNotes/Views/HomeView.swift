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

    // Fetch all podcasts for Continue Listening cards
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.title, ascending: true)],
        animation: .default
    )
    private var allPodcasts: FetchedResults<PodcastEntity>

    // Fetch followed podcasts
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PodcastEntity.followedAt, ascending: false)],
        predicate: NSPredicate(format: "isFollowing == YES"),
        animation: .default
    )
    private var followedPodcasts: FetchedResults<PodcastEntity>

    // Player state
    @ObservedObject private var player = GlobalPlayerManager.shared
    @ObservedObject private var historyManager = PlaybackHistoryManager.shared

    @State private var showingPlayerSheet = false
    @State private var showingSettings = false
    @State private var selectedPodcast: PodcastEntity?
    @State private var selectedNote: NoteEntity?
    @State private var navigationPath = NavigationPath()
    @State private var showingContinueListeningSheet = false
    @State private var showingYourShowsSheet = false

    // Namespace for matched geometry effect with mini player
    @Namespace private var playerAnimation

    /// Computed property that derives continue listening episodes from historyManager
    /// This ensures HomeView re-renders automatically when recentlyPlayed changes
    private var continueListeningEpisodes: [(historyItem: PlaybackHistoryItem, podcast: PodcastEntity)] {
        let historyItems = historyManager.recentlyPlayed.prefix(5)
        return historyItems.compactMap { historyItem in
            // Find the podcast entity for this history item
            // Try to match by podcastID first, then by podcast title as fallback
            if let foundPodcast = allPodcasts.first(where: { $0.id == historyItem.podcastID }) {
                return (historyItem: historyItem, podcast: foundPodcast)
            } else if let foundPodcast = allPodcasts.first(where: { $0.title == historyItem.podcastTitle }) {
                return (historyItem: historyItem, podcast: foundPodcast)
            }
            return nil
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: EchoSpacing.homeSectionSpacing) {
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
                                navigationPath.append("browse")
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
                    .padding(.horizontal, EchoSpacing.homeSidePadding)
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
            .navigationDestination(for: String.self) { destination in
                if destination == "browse" {
                    PodcastDiscoveryView()
                }
            }
            .background(Color.echoBackground)
            .navigationBarHidden(true)
            .onAppear {
                print("🏠 [HomeView] View appeared")
                print("🏠 [HomeView] Recent notes count: \(recentNotes.count)")
                print("🏠 [HomeView] Followed podcasts count: \(followedPodcasts.count)")
                print("🏠 [HomeView] Player episode loaded: \(player.currentEpisode != nil)")
            }
            .onReceive(NotificationCenter.default.publisher(for: .openSearch)) { _ in
                navigationPath.append("browse")
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(item: $selectedPodcast) { podcast in
            PodcastDetailView(podcast: podcast)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .preferredColorScheme(.dark)
                .onAppear {
                    print("✅ [Home] Sheet opened successfully with podcast: \(podcast.title ?? "nil")")
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
        .sheet(isPresented: $showingContinueListeningSheet) {
            ContinueListeningSheetView(showingPlayerSheet: $showingPlayerSheet)
        }
        .sheet(isPresented: $showingYourShowsSheet) {
            YourShowsSheetView(selectedPodcast: $selectedPodcast)
        }
    }

    // MARK: - Timestamp Jump

    private func jumpToNoteTimestamp(_ note: NoteEntity) {
        guard let timestamp = note.timestamp,
              let podcast = note.podcast else {
            print("⚠️ [Home] Cannot jump: note missing timestamp or podcast")
            return
        }

        // Parse timestamp to seconds
        guard let timeInSeconds = parseTimestamp(timestamp) else {
            print("⚠️ [Home] Cannot parse timestamp: \(timestamp)")
            return
        }

        print("⏭️ [Home] Jumping to timestamp: \(timestamp) (\(timeInSeconds)s)")

        // Check if this episode is in playback history (fastest path)
        let historyItems = PlaybackHistoryManager.shared.recentlyPlayed
        if let historyItem = historyItems.first(where: { item in
            item.episodeTitle == note.episodeTitle && item.podcastTitle == podcast.title
        }) {
            // Found in history - load from there
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
            selectedNote = nil  // Close note sheet
            return
        }

        // Not in history - fetch from RSS
        print("📡 [Home] Episode not in history, fetching from RSS...")
        fetchEpisodeAndPlay(from: podcast, episodeTitle: note.episodeTitle ?? "", seekTo: timeInSeconds)
    }

    private func fetchEpisodeAndPlay(from podcast: PodcastEntity, episodeTitle: String, seekTo: TimeInterval) {
        Task { @MainActor in
            guard let feedURL = podcast.feedURL else {
                print("⚠️ [Home] No feed URL for podcast")
                return
            }

            do {
                let service = PodcastRSSService.shared
                let rssPodcast = try await service.fetchPodcast(from: feedURL)

                // Find episode by title
                if let episode = rssPodcast.episodes.first(where: { $0.title == episodeTitle }) {
                    print("✅ [Home] Found episode in RSS feed: \(episode.title)")
                    GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: seekTo)
                    showingPlayerSheet = true
                    selectedNote = nil
                } else {
                    print("⚠️ [Home] Episode not found in RSS feed: \(episodeTitle)")
                }
            } catch {
                print("❌ [Home] Failed to fetch RSS feed: \(error)")
            }
        }
    }

    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let parts = timestamp.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2: // MM:SS
            return parts[0] * 60 + parts[1]
        case 3: // HH:MM:SS
            return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default:
            return nil
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
        VStack(alignment: .leading, spacing: EchoSpacing.sectionHeaderToContentSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Continue Listening")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)
                Spacer()
                Button {
                    showingContinueListeningSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("View all")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.mintAccent.opacity(0.85))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.mintAccent.opacity(0.85))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

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
                    .padding(.leading, EchoSpacing.homeSidePadding)
                }
                .scrollClipDisabled()
                .onAppear {
                    print("🎧 [HomeView] Showing \(continueListeningEpisodes.count) Continue Listening cards")
                }
            } else {
                Text("No episodes in progress")
                    .font(.bodyEcho())
                    .foregroundColor(.echoTextTertiary)
            }
        }
    }

    // MARK: - Your Shows Section

    private var followingSection: some View {
        VStack(alignment: .leading, spacing: EchoSpacing.sectionHeaderToContentSpacing) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your Podcasts")
                    .font(.title2Echo())
                    .foregroundColor(.echoTextPrimary)
                Spacer()
                Button {
                    showingYourShowsSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("View all")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color.mintAccent.opacity(0.85))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color.mintAccent.opacity(0.85))
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)

            if followedPodcasts.count == 1 {
                // Single podcast: show card
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
                    .padding(.leading, 20)
                }
                .scrollClipDisabled()
            } else {
                // Multiple podcasts: show standard carousel
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
                    .padding(.leading, 20)
                }
                .scrollClipDisabled()
            }
        }
        .onAppear {
            print("🎙️ [HomeView] Showing Your Shows section (\(followedPodcasts.count) podcasts)")
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

        GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: item.currentTime)
        showingPlayerSheet = true
    }

    // MARK: - Recent Notes Section

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: EchoSpacing.sectionHeaderToContentSpacing) {
            Text("Recent Notes")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            ForEach(recentNotes.prefix(5)) { note in
                NoteCardView(note: note)
                    .onTapGesture {
                        print("📝 [HomeView] Note tapped: \(note.noteText?.prefix(50) ?? "No text")...")
                        selectedNote = note
                    }
            }
        }
        .padding(.horizontal, EchoSpacing.homeSidePadding)
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
                navigationPath.append("browse")
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
        .padding(.horizontal, EchoSpacing.homeSidePadding)
        .frame(maxWidth: .infinity)
        .onAppear {
            print("🏠 [HomeView] Showing empty state")
        }
    }
}

// MARK: - Continue Listening Sheet

private struct ContinueListeningSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var historyManager = PlaybackHistoryManager.shared
    @ObservedObject private var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showingPlayerSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Listening")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.echoTextPrimary)
                    Text("\(historyManager.recentlyPlayed.count) episodes in progress")
                        .font(.system(size: 12))
                        .foregroundColor(.echoTextTertiary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.mintAccent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            // List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(historyManager.recentlyPlayed) { item in
                        ContinueListeningSheetRow(item: item, showingPlayerSheet: $showingPlayerSheet)

                        if item.id != historyManager.recentlyPlayed.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }
}

private struct ContinueListeningSheetRow: View {
    let item: PlaybackHistoryItem
    @ObservedObject private var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showingPlayerSheet: Bool

    // Fetch podcast for this item to get artwork URL
    private var podcast: PodcastEntity? {
        let request: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", item.podcastID)
        return (try? viewContext.fetch(request))?.first
    }

    // Fetch notes for this episode to show pips
    private var notesForEpisode: [NoteEntity] {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "episodeTitle == %@", item.episodeTitle)
        return (try? viewContext.fetch(request)) ?? []
    }

    private var progress: Double {
        guard item.duration > 0 else { return 0 }
        return item.currentTime / item.duration
    }

    private var timeRemainingText: String {
        let remaining = item.duration - item.currentTime
        let mins = Int(remaining) / 60
        return mins > 0 ? "\(mins) min left" : "Almost done"
    }

    private var noteCountText: String? {
        let count = notesForEpisode.count
        guard count > 0 else { return nil }
        return "· \(count) \(count == 1 ? "note" : "notes")"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork - look up PodcastEntity for artwork
            CachedAsyncImage(url: podcast?.artworkURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "headphones")
                    .font(.system(size: 20))
                    .foregroundColor(.echoTextTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.06))
            }
            .frame(width: 52, height: 52)
            .cornerRadius(9)
            .clipped()

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(item.podcastTitle)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.mintAccent)
                    .textCase(.uppercase)
                    .lineLimit(1)

                Text(item.episodeTitle)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(timeRemainingText)
                    if let noteText = noteCountText {
                        Text(noteText)
                    }
                }
                .font(.system(size: 11))
                .foregroundColor(.echoTextTertiary)

                // Progress bar with note pips
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 2)
                            .cornerRadius(1)

                        // Fill
                        Rectangle()
                            .fill(Color.mintAccent.opacity(0.7))
                            .frame(width: geo.size.width * progress, height: 2)
                            .cornerRadius(1)

                        // Note pips
                        ForEach(notesForEpisode, id: \.objectID) { note in
                            if let pipPosition = pipPosition(for: note, width: geo.size.width) {
                                Circle()
                                    .fill(Color(red: 1, green: 0.816, blue: 0.376))
                                    .frame(width: 5, height: 5)
                                    .offset(x: pipPosition - 2.5, y: -1.5)
                            }
                        }
                    }
                }
                .frame(height: 5)
                .padding(.top, 2)
            }

            // Play button
            Button {
                resumePlayback()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.mintAccent)
                        .frame(width: 30, height: 30)
                    Image(systemName: "play.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private func pipPosition(for note: NoteEntity, width: CGFloat) -> CGFloat? {
        guard item.duration > 0,
              let timestampString = note.timestamp else { return nil }
        let seconds = parseTimestampToSeconds(timestampString)
        guard seconds > 0 else { return nil }
        return (seconds / item.duration) * width
    }

    private func parseTimestampToSeconds(_ timestamp: String) -> TimeInterval {
        let parts = timestamp.split(separator: ":").compactMap { Double($0) }
        switch parts.count {
        case 2: return parts[0] * 60 + parts[1]
        case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
        default: return 0
        }
    }

    private func resumePlayback() {
        guard let podcast = podcast else { return }
        // Construct RSSEpisode from PlaybackHistoryItem
        let episode = RSSEpisode(
            title: item.episodeTitle,
            description: nil,
            pubDate: nil,
            duration: formatDuration(item.duration),
            audioURL: item.audioURL,
            imageURL: podcast.artworkURL
        )
        GlobalPlayerManager.shared.loadEpisodeAndPlay(episode, podcast: podcast, seekTo: item.currentTime)
        // Show the player sheet after resuming playback
        showingPlayerSheet = true
    }

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
}

// MARK: - Your Shows Sheet

private struct YourShowsSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var followedShows: [PodcastEntity] = []
    @Binding var selectedPodcast: PodcastEntity?

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.15))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Podcasts")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.echoTextPrimary)
                    Text("\(followedShows.count) shows saved")
                        .font(.system(size: 12))
                        .foregroundColor(.echoTextTertiary)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.mintAccent)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 1)

            ScrollView {
                VStack(spacing: 0) {
                    // Context blurb
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(Color.mintAccent.opacity(0.7))
                            .padding(.top, 1)
                        Text("Shows you save here are easy to come back to — tap any show to jump straight to its latest episodes.")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.45))
                            .lineSpacing(2)
                    }
                    .padding(14)
                    .background(Color.mintAccent.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.mintAccent.opacity(0.18), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Show rows
                    ForEach(followedShows) { show in
                        YourShowsSheetRow(show: show, selectedPodcast: $selectedPodcast)

                        if show.id != followedShows.last?.id {
                            Rectangle()
                                .fill(Color.white.opacity(0.07))
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Add a show row
                    Button {
                        dismiss()
                        // Post notification to open search
                        NotificationCenter.default.post(name: .openSearch, object: nil)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.25))
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Add a show")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.echoTextSecondary)
                                Text("Search to find a podcast")
                                    .font(.system(size: 11))
                                    .foregroundColor(.echoTextTertiary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.118, green: 0.118, blue: 0.118))
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onAppear { loadFollowedShows() }
    }

    private func loadFollowedShows() {
        // Fetch from Core Data - followed podcasts
        let request: NSFetchRequest<PodcastEntity> = PodcastEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isFollowing == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PodcastEntity.followedAt, ascending: false)]
        followedShows = (try? viewContext.fetch(request)) ?? []
    }
}

private struct YourShowsSheetRow: View {
    let show: PodcastEntity
    @ObservedObject private var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedPodcast: PodcastEntity?

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: show.artworkURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundColor(.echoTextTertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.06))
            }
            .frame(width: 52, height: 52)
            .cornerRadius(10)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(show.title ?? "Unknown Podcast")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                unfollowShow()
            } label: {
                Label("Remove", systemImage: "minus.circle")
            }
        }
        .onTapGesture {
            // Set selected podcast and dismiss to open series detail
            selectedPodcast = show
            dismiss()
        }
    }

    private func unfollowShow() {
        show.isFollowing = false
        show.followedAt = nil
        do {
            try viewContext.save()
        } catch {
            print("❌ Failed to unfollow show: \(error)")
        }
    }
}

// MARK: - Notification for Search

extension Notification.Name {
    static let openSearch = Notification.Name("EchoCast.openSearch")
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

