//
//  EpisodePlayerView.swift
//  EchoNotes
//
//  Unified episode player with 3 tabs (Listening, Notes, Episode Info)
//  iOS 26 Liquid Glass architecture with ZStack and fixed footer
//

import SwiftUI
import CoreData

// MARK: - String Extension for HTML Stripping

extension String {
    var htmlStripped: String {
        // Remove HTML tags
        var result = self.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )

        // Decode HTML entities
        result = result.replacingOccurrences(of: "&nbsp;", with: " ")
        result = result.replacingOccurrences(of: "&amp;", with: "&")
        result = result.replacingOccurrences(of: "&lt;", with: "<")
        result = result.replacingOccurrences(of: "&gt;", with: ">")
        result = result.replacingOccurrences(of: "&quot;", with: "\"")
        result = result.replacingOccurrences(of: "&#39;", with: "'")

        // Trim whitespace
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Footer Padding Modifier

struct FooterPadding: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.bottom, 34) // Safe area for home indicator
    }
}

extension View {
    func footerPadding() -> some View {
        self.modifier(FooterPadding())
    }
}

// MARK: - Main Episode Player View

// MARK: - Player Sheet Enum
private enum PlayerSheet: Identifiable {
    case noteCapture

    var id: String { "noteCapture" }
}

struct EpisodePlayerView: View {
    // MARK: - Properties

    let episode: RSSEpisode
    let podcast: PodcastEntity
    var namespace: Namespace.ID

    @ObservedObject var player: GlobalPlayerManager
    @State private var selectedSegment = 0

    // Unified sheet state
    @State private var activeSheet: PlayerSheet? = nil

    // Note preview overlay state
    @State private var previewNote: NoteEntity? = nil
    @State private var showingNotePreview: Bool = false

    // Bookmark preview overlay state
    @State private var previewBookmark: BookmarkEntity? = nil
    @State private var showingBookmarkPreview: Bool = false
    @State private var recentBookmarkTime: TimeInterval? = nil
    @State private var bookmarkUndoTimer: Timer? = nil

    // Go Back button state
    @State private var showGoBackButton = false
    @State private var previousPlaybackPosition: TimeInterval = 0
    @State private var goBackTimer: Timer?
    @State private var goBackCountdown: CGFloat = 8.0

    // Toast notification state
    @State private var toastMessage: ToastMessage? = nil

    // Scrubber drag state
    @State private var isDragging = false
    @State private var dragTime: TimeInterval = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var notes: FetchedResults<NoteEntity>
    @FetchRequest private var bookmarks: FetchedResults<BookmarkEntity>

    // MARK: - Computed Properties

    /// Check if player has loaded enough data to display
    private var isPlayerReady: Bool {
        player.duration > 0
    }

    /// Display time for scrubber visual - uses dragTime when dragging, otherwise actual player time
    private var displayTime: TimeInterval {
        isDragging ? dragTime : player.currentTime
    }

    // MARK: - Initialization

    init(episode: RSSEpisode, podcast: PodcastEntity, namespace: Namespace.ID, player: GlobalPlayerManager) {
        self.episode = episode
        self.podcast = podcast
        self.namespace = namespace
        self.player = player

        let episodeTitle = episode.title
        let podcastTitle = podcast.title ?? ""

        _notes = FetchRequest<NoteEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: false)],
            predicate: NSPredicate(
                format: "episodeTitle ==[c] %@ AND showTitle ==[c] %@",
                episodeTitle, podcastTitle
            ),
            animation: .default
        )

        _bookmarks = FetchRequest<BookmarkEntity>(
            sortDescriptors: [NSSortDescriptor(keyPath: \BookmarkEntity.timestamp, ascending: true)],
            predicate: NSPredicate(
                format: "episodeTitle ==[c] %@ AND showTitle ==[c] %@",
                episodeTitle, podcastTitle
            ),
            animation: .default
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Actual player content
            VStack(spacing: 0) {
                // --- SECTION 1: HEADER (FIXED HEIGHT: ~68px) ---
                VStack(spacing: 0) {
                    segmentedControlSection
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 20)

                // --- SECTION 2: MID-SECTION (FIXED HEIGHT: 377px) ---
                ZStack(alignment: .bottom) {
                    Group {
                        switch selectedSegment {
                        case 0:
                            // Listening: Static Art (Not scrollable)
                            ListeningSegmentView(
                                episode: episode,
                                podcast: podcast,
                                namespace: namespace,
                                addNoteAction: { openNoteCapture() }
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 8)

                        case 1:
                            // Notes: Scrollable List
                            ScrollView {
                                NotesSegmentView(
                                    notes: Array(notes),
                                    addNoteAction: { openNoteCapture() },
                                    player: player,
                                    selectedSegment: $selectedSegment,
                                    onNoteTap: { note in
                                        withAnimation(.spring(response: 0.3)) {
                                            previewNote = note
                                            showingNotePreview = true
                                        }
                                    }
                                )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scrollIndicators(.hidden)
                            .padding(.top, 16)

                        case 2:
                            // Info: Scrollable Text
                            ScrollView {
                                InfoSegmentView(
                                    episode: episode,
                                    podcast: podcast
                                )
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scrollIndicators(.hidden)
                            .padding(.top, 16)

                        default:
                            EmptyView()
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.bottom, 0)

                    // Floating Go Back button overlay (CENTERED)
                    if showGoBackButton {
                        goBackButtonOverlay
                            .padding(.bottom, 16)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .zIndex(100)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // --- SECTION 3: FOOTER (FIXED HEIGHT: ~290px) ---
                VStack(spacing: 24) {
                    // Metadata (Always visible, 2 lines max)
                    episodeMetadataView

                    // Scrubber
                    timeProgressWithMarkers

                    // Playback controls
                    playbackControlButtons
                        .padding(.bottom, 8)

                    // Add Note CTA (Always visible with player controls)
                    addNoteButton
                        .padding(.horizontal, 16)
                        .sensoryFeedback(.impact, trigger: activeSheet == .noteCapture)
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.top, 24)
                .background(Color.echoBackground)
                .padding(.bottom, 24)
            }

            // Skeleton loading overlay (shown when player is loading)
            if !isPlayerReady {
                playerLoadingSkeleton
                    .transition(.opacity)
            }

            // Note preview overlay card
            if showingNotePreview, let note = previewNote {
                // Dimming background tap to dismiss
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingNotePreview = false
                            previewNote = nil
                        }
                    }

                NoteOverlayCard(
                    note: note,
                    allNotesAtTimestamp: notesAtTimestamp(note.timestamp ?? ""),
                    onJump: {
                        if let timestamp = note.timestamp,
                           let timeInSeconds = parseTimestamp(timestamp) {
                            player.seek(to: timeInSeconds)
                            withAnimation(.spring(response: 0.3)) {
                                showingNotePreview = false
                                previewNote = nil
                                selectedSegment = 0
                            }
                        }
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            showingNotePreview = false
                            previewNote = nil
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Bookmark preview overlay card
            if showingBookmarkPreview, let bookmark = previewBookmark {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showingBookmarkPreview = false
                            previewBookmark = nil
                        }
                    }

                BookmarkOverlayCard(
                    bookmark: bookmark,
                    onJump: {
                        player.seek(to: bookmark.timestamp)
                        withAnimation(.spring(response: 0.3)) {
                            showingBookmarkPreview = false
                            previewBookmark = nil
                        }
                    },
                    onDismiss: {
                        withAnimation(.spring(response: 0.3)) {
                            showingBookmarkPreview = false
                            previewBookmark = nil
                        }
                    }
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Toast overlay
            if let toast = toastMessage {
                VStack {
                    ToastView(toast: toast)
                        .padding(.top, 60)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(1000)
                .transition(
                    .asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPlayerReady)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.echoBackground)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .noteCapture:
                NoteCaptureSheetWrapper(
                    episode: episode,
                    podcast: podcast,
                    currentTime: player.currentTime
                )
            }
        }
        .onDisappear {
            goBackTimer?.invalidate()
        }
    }

    // MARK: - Helper Functions

    private func openNoteCapture() {
        activeSheet = .noteCapture
    }

    // MARK: - Segmented Control

    private var segmentedControlSection: some View {
        HStack(spacing: 2) {
            ForEach(["Listening", "Notes", "Episode Info"].indices, id: \.self) { index in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = index
                    }
                } label: {
                    Text(["Listening", "Notes", "Episode Info"][index])
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            selectedSegment == index
                                ? Color.white
                                : Color.white.opacity(0.4)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(
                            selectedSegment == index
                                ? Color.white.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
    }

    // MARK: - Episode Metadata (in Footer - 2 lines max)

    private var episodeMetadataView: some View {
        VStack(spacing: 10) {
            Text(episode.title)
                .font(.bodyRoundedMedium())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)

            Text(podcast.title ?? "Unknown Podcast")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.echoTextSecondary)
                .lineLimit(1)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Add Note Button

    private var addNoteButton: some View {
        HStack(spacing: 8) {
            // 80% — Add note button (unchanged)
            Button {
                openNoteCapture()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color(red: 0.647, green: 0.898, blue: 0.847))

                    Text("Add note at current time")
                        .font(.bodyRoundedMedium())
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(red: 0.231, green: 0.306, blue: 0.290))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)

            // 20% — Bookmark button
            Button {
                addBookmark()
            } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(red: 0.647, green: 0.898, blue: 0.847))
                    .frame(width: 56, height: 56)
                    .background(Color(red: 0.231, green: 0.306, blue: 0.290))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    private func addBookmark() {
        let currentTime = player.currentTime

        // If tapped within 10s of the last bookmark → undo (remove it)
        if let lastTime = recentBookmarkTime, abs(currentTime - lastTime) <= 10 {
            let fetchRequest: NSFetchRequest<BookmarkEntity> = BookmarkEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(
                format: "episodeTitle ==[c] %@ AND showTitle ==[c] %@ AND timestamp >= %f AND timestamp <= %f",
                player.currentEpisode?.title ?? "",
                player.currentPodcast?.title ?? "",
                lastTime - 1.0,
                lastTime + 1.0
            )
            if let results = try? viewContext.fetch(fetchRequest) {
                results.forEach { viewContext.delete($0) }
                try? viewContext.save()
            }
            bookmarkUndoTimer?.invalidate()
            recentBookmarkTime = nil
            showToast("Bookmark at \(formatTime(lastTime)) removed", icon: "bookmark.slash.fill")
            return
        }

        // Otherwise create new bookmark
        let bookmark = BookmarkEntity(context: viewContext)
        bookmark.id = UUID()
        bookmark.timestamp = currentTime
        bookmark.episodeTitle = player.currentEpisode?.title
        bookmark.showTitle = player.currentPodcast?.title
        bookmark.createdAt = Date()
        try? viewContext.save()
        showToast("Bookmark at \(formatTime(currentTime)) added", icon: "bookmark.fill")

        recentBookmarkTime = currentTime
        bookmarkUndoTimer?.invalidate()
        bookmarkUndoTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
            recentBookmarkTime = nil
        }
    }

    private func showToast(_ message: String, icon: String) {
        withAnimation(.spring(response: 0.3)) {
            toastMessage = ToastMessage(message: message, icon: icon)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.spring(response: 0.3)) {
                toastMessage = nil
            }
        }
    }

    // MARK: - Player Controls

    private var timeProgressWithMarkers: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                // Note markers (grouped by proximity) - computed once, available to all
                let groupedNotes: [(position: TimeInterval, notes: [NoteEntity])] = {
                    var groups: [(position: TimeInterval, notes: [NoteEntity])] = []
                    let threshold = player.duration * 0.05
                    for note in notes {
                        guard let timestamp = note.timestamp,
                              let seconds = parseTimestamp(timestamp),
                              player.duration > 1 else { continue }
                        if let idx = groups.firstIndex(where: {
                            abs($0.position - seconds) < threshold
                        }) {
                            groups[idx].notes.append(note)
                        } else {
                            groups.append((position: seconds, notes: [note]))
                        }
                    }
                    return groups
                }()

                // Outer ZStack for layout - markers sit alongside inner track ZStack
                ZStack(alignment: .leading) {
                    // Inner ZStack: track + scrubber with DragGesture
                    ZStack(alignment: .leading) {
                        // Inactive track
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)
                            .frame(maxHeight: .infinity, alignment: .center)

                        // Active track
                        Capsule()
                            .fill(Color.mintAccent)
                            .frame(
                                width: geo.size.width * CGFloat(
                                    player.duration > 0
                                        ? min(displayTime / player.duration, 1.0)
                                        : 0
                                ),
                                height: 6
                            )
                            .frame(maxHeight: .infinity, alignment: .center)

                        // Scrubber knob
                        Circle()
                            .fill(Color.white)
                            .frame(width: 20, height: 20)
                            .offset(
                                x: geo.size.width * CGFloat(player.duration > 0
                                    ? min(displayTime / player.duration, 1.0)
                                    : 0) - 10,
                                y: 0
                            )
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                // Save position on first drag (scrub start)
                                if !showGoBackButton && previousPlaybackPosition == 0 {
                                    previousPlaybackPosition = player.currentTime
                                }
                                isDragging = true
                                let fraction = max(0, min(value.location.x / geo.size.width, 1))
                                dragTime = fraction * player.duration
                            }
                            .onEnded { value in
                                // Perform actual seek on drag end
                                let fraction = max(0, min(value.location.x / geo.size.width, 1))
                                player.seek(to: fraction * player.duration)
                                isDragging = false

                                // Show go back button when scrub ends
                                showGoBackButton = true
                                goBackCountdown = 8.0

                                // Cancel existing timer
                                goBackTimer?.invalidate()

                                // Set 8-second timer with countdown
                                goBackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                                    goBackCountdown -= 0.1
                                    if goBackCountdown <= 0 {
                                        timer.invalidate()
                                        withAnimation {
                                            showGoBackButton = false
                                        }
                                        previousPlaybackPosition = 0
                                    }
                                }
                            }
                    )

                    // Markers sit ALONGSIDE the inner ZStack, outside DragGesture
                    ForEach(Array(groupedNotes.enumerated()), id: \.offset) { _, group in
                        let xPos = (group.position / player.duration) * geo.size.width - 14

                        Button {
                            // Show overlay with first note at this position
                            if let firstNote = group.notes.first {
                                withAnimation(.spring(response: 0.3)) {
                                    previewNote = firstNote
                                    showingNotePreview = true
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.mintAccent.opacity(0.75))
                                    .frame(width: 28, height: 28)

                                if group.notes.count > 1 {
                                    Text("\(group.notes.count)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                        .position(x: xPos + 14, y: -11)
                    }

                    // Bookmark markers
                    ForEach(bookmarks, id: \.id) { bookmark in
                        let xPos = player.duration > 0
                            ? (bookmark.timestamp / player.duration) * geo.size.width - 14
                            : 0

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                previewBookmark = bookmark
                                showingBookmarkPreview = true
                            }
                        } label: {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.mintAccent)
                                .frame(width: 20, height: 20)
                                .rotationEffect(.degrees(45))
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 8)
                        .position(x: xPos + 14, y: -11)
                    }
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 24)

            HStack {
                Text(formatTime(displayTime))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)

                Spacer()

                Text("-\(formatTime(player.duration - displayTime))")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
            }
        }
    }

    private var playbackControlButtons: some View {
        HStack(spacing: 24) {
            skipButton(systemName: "gobackward.15", action: { player.skipBackward(15) })

            Button {
                if player.isPlaying {
                    player.pause()
                } else {
                    player.play()
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 64, height: 64)

                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PressEffectButtonStyle())

            skipButton(systemName: "goforward.30", action: { player.skipForward(30) })
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Go Back Button Overlay

    private var goBackButtonOverlay: some View {
        HStack(spacing: 10) {
            // Circular countdown indicator (LARGER, more prominent)
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2.5)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: goBackCountdown / 8.0)
                    .stroke(Color.mintAccent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear, value: goBackCountdown)
            }

            Button {
                // Jump back to previous position
                player.seek(to: previousPlaybackPosition)

                // Hide button immediately
                withAnimation {
                    showGoBackButton = false
                }
                goBackTimer?.invalidate()
                previousPlaybackPosition = 0

            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 15, weight: .semibold))
                    Text("go back")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.75))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.6))
        )
        .shadow(color: Color.black.opacity(0.5), radius: 12, x: 0, y: 4)
    }

    // MARK: - Helper Methods

    private func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
        }
        .buttonStyle(PressEffectButtonStyle())
    }

    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return (player.currentTime / player.duration) * totalWidth
    }

    private func markerPosition(_ timestamp: TimeInterval, width: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return (timestamp / player.duration) * width - 4
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

    private func notesAtTimestamp(_ timestamp: String) -> [NoteEntity] {
        notes.filter { $0.timestamp == timestamp }
    }

    private func normalizeTimestamp(_ time: TimeInterval) -> String {
        // Always render as H:MM:SS regardless of duration
        let totalSeconds = Int(max(0, time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        return normalizeTimestamp(seconds)
    }

    // MARK: - Loading Skeleton

    private var playerLoadingSkeleton: some View {
        ZStack {
            Color.echoBackground

            VStack(spacing: 0) {
                // Spacer for header
                Spacer()
                    .frame(height: 56)

                // Content area skeleton
                VStack(spacing: 16) {
                    // Album art skeleton
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .redacted(reason: .placeholder)

                    // Episode title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 20)
                        .frame(maxWidth: 280)
                        .redacted(reason: .placeholder)

                    // Podcast name skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)
                        .frame(maxWidth: 200)
                        .redacted(reason: .placeholder)

                    Spacer()
                }
                .padding(.top, 40)

                // Footer skeleton
                VStack(spacing: 16) {
                    // Progress bar skeleton
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .redacted(reason: .placeholder)

                    // Controls skeleton
                    HStack(spacing: 16) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .redacted(reason: .placeholder)
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 50, height: 50)
                            .redacted(reason: .placeholder)
                        Spacer()
                    }

                    // Add note button skeleton
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 48)
                        .redacted(reason: .placeholder)
                }
                .padding(.horizontal, EchoSpacing.screenPadding)
                .padding(.top, 12)
                .padding(.bottom, 48)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Press Effect Button Style

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Segment Views

// MARK: - Segment Views

// MARK: - Listening Segment View (Segment 0)

struct ListeningSegmentView: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    var namespace: Namespace.ID
    let addNoteAction: () -> Void

    var body: some View {
        albumArtworkView
            .padding(.horizontal, EchoSpacing.screenPadding)
    }

    private var albumArtworkView: some View {
        CachedAsyncImage(url: URL(string: podcast.artworkURL ?? episode.imageURL ?? "")) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.2, green: 0.2, blue: 0.2))

                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .frame(width: 240, height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .matchedGeometryEffect(id: "artwork", in: namespace, isSource: true)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
}

// MARK: - Notes Segment View (Segment 1)

struct NotesSegmentView: View {
    let notes: [NoteEntity]
    let addNoteAction: () -> Void
    @ObservedObject var player: GlobalPlayerManager
    @Binding var selectedSegment: Int
    let onNoteTap: (NoteEntity) -> Void
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if notes.isEmpty {
                emptyNotesState
            } else {
                notesListView
            }

            Spacer(minLength: 24)
        }
        .padding(.top, 8)
    }

    private var emptyNotesState: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 60)

            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("No notes yet")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            Text("Tap the button below while listening to capture your thoughts.")
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var notesListView: some View {
        VStack(spacing: 0) {
            ForEach(notes, id: \.id) { note in
                NoteRowView(note: note) {
                    // Show preview popover via callback
                    onNoteTap(note)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteNote(note)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .contextMenu {
                    // TODO: wire edit when AddNoteSheet/NoteCaptureSheetWrapper supports existingNote
                    Button(role: .destructive) {
                        deleteNote(note)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .padding(.horizontal, 32)
    }

    private func deleteNote(_ note: NoteEntity) {
        withAnimation {
            viewContext.delete(note)
            do {
                try viewContext.save()
            } catch {
                print("❌ Failed to delete note: \(error)")
            }
        }
    }
}

// MARK: - Note Row (Timeline style)

struct NoteRow: View {
    let note: NoteEntity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 16) {
                if let timestamp = note.timestamp {
                    HStack {
                        Text(timestamp)
                            .font(.body.monospacedDigit())
                            .foregroundColor(.mintAccent)
                            .padding(.top, 4)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.echoTextTertiary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let noteText = note.noteText, !noteText.isEmpty {
                        Text(noteText)
                            .font(.subheadline)
                            .foregroundColor(.echoTextPrimary)
                            .lineLimit(3)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .padding(EchoSpacing.noteCardPadding)
        .background(Color.noteCardBackground)
        .cornerRadius(EchoSpacing.noteCardCornerRadius)
    }
}

// MARK: - Info Segment View (Segment 2)

struct InfoSegmentView: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            if let description = episode.description, !description.isEmpty {
                episodeDescriptionSection(description)
            }

            if let podcastDesc = podcast.podcastDescription, !podcastDesc.isEmpty {
                podcastDescriptionSection(podcastDesc)
            }

            episodeMetadataSection
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.top, 40)
    }

    private func episodeDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Episode Description")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            Text(description.htmlStripped)
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
                .lineSpacing(6)
        }
    }

    private func podcastDescriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About the Podcast")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            Text(description.htmlStripped)
                .font(.bodyEcho())
                .foregroundColor(.echoTextSecondary)
                .lineSpacing(6)
        }
    }

    private var episodeMetadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.title2Echo())
                .foregroundColor(.echoTextPrimary)

            VStack(alignment: .leading, spacing: 12) {
                if let pubDate = episode.pubDate {
                    MetadataRow(label: "Published", value: formatPublishDate(pubDate))
                }

                if let duration = episode.duration {
                    MetadataRow(label: "Duration", value: duration)
                }
            }
        }
    }

    private func formatPublishDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.bodyEcho())
                .foregroundColor(.echoTextTertiary)

            Spacer()

            Text(value)
                .font(.bodyEcho())
                .foregroundColor(.echoTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Note Capture Sheet Wrapper

struct NoteCaptureSheetWrapper: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    let currentTime: TimeInterval

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var noteText: String = ""
    @State private var tags: String = ""
    @State private var saveErrorMessage: String? = nil
    @State private var showSaveError: Bool = false

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Static context — no label
                        VStack(alignment: .leading, spacing: 2) {
                            Text(podcast.title ?? "Unknown Podcast")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            Text(episode.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            HStack(spacing: 5) {
                                Image(systemName: "clock")
                                    .font(.system(size: 11))
                                Text(formatTime(currentTime))
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                        }
                        .padding(.top, 8)

                        // Note input — label + field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Note")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            ZStack(alignment: .topLeading) {
                                if noteText.isEmpty {
                                    Text("What's on your mind?")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                }
                                TextEditor(text: $noteText)
                                    .font(.system(size: 15))
                                    .frame(minHeight: 110)
                                    .scrollContentBackground(.hidden)
                            }
                            .padding(12)
                            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                            .cornerRadius(12)
                        }

                        // Tags input — label + field + persistent hint
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tags")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            TextField("interesting, quote...", text: $tags)
                                .font(.system(size: 15))
                                .padding(12)
                                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(12)
                            Text("Separate tags with commas")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .padding(.leading, 2)
                        }

                        // Save button
                        Button(action: saveNote) {
                            Text("Save Note")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color.mintAccent)
                                .frame(maxWidth: .infinity)
                                .padding(14)
                                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .background(Color(red: 0.149, green: 0.149, blue: 0.149))
                .navigationTitle("Add Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }

            if showSaveError, let message = saveErrorMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(10)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation { showSaveError = false }
                            }
                        }
                }
                .animation(.easeInOut, value: showSaveError)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        // Always render as H:MM:SS regardless of duration
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let second = totalSeconds % 60
        return String(format: "%d:%02d:%02d", hours, minutes, second)
    }

    private func saveNote() {
        let newNote = NoteEntity(context: viewContext)
        newNote.id = UUID()
        newNote.showTitle = podcast.title
        newNote.episodeTitle = episode.title
        newNote.timestamp = formatTime(currentTime)
        newNote.noteText = noteText
        newNote.createdAt = Date()
        newNote.podcast = podcast
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        newNote.tags = tagList.joined(separator: ",")

        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("[EchoCast] saveNote() failed: \(error)")
            saveErrorMessage = "Couldn't save note. Please try again."
            showSaveError = true
        }
    }
}

// MARK: - Note Preview Popover

struct NotePreviewPopover: View {
    let note: NoteEntity
    let notesAtSameTimestamp: [NoteEntity]
    let onJumpToTime: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // If multiple notes at same timestamp
                    if notesAtSameTimestamp.count > 1 {
                        Text("\(notesAtSameTimestamp.count) notes at this time")
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextSecondary)
                    }

                    // Note preview(s)
                    ForEach(notesAtSameTimestamp) { noteItem in
                        VStack(alignment: .leading, spacing: 8) {
                            // Note text (max 3 lines)
                            Text(noteItem.noteText ?? "")
                                .font(.system(size: 17, weight: .regular, design: .serif))
                                .foregroundColor(.echoTextPrimary)
                                .lineLimit(3)

                            // Tags if present
                            if !noteItem.tagsArray.isEmpty {
                                FlowLayout(spacing: 6) {
                                    ForEach(noteItem.tagsArray.prefix(3), id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2Medium())
                                            .foregroundColor(.echoTextSecondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.white.opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)

                        if noteItem != notesAtSameTimestamp.last {
                            Divider()
                        }
                    }
                }
                .padding(EchoSpacing.screenPadding)
            }
            .navigationTitle("Note at \(note.timestamp ?? "")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                    .foregroundColor(.mintAccent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Jump to Time") {
                        onJumpToTime()
                    }
                    .foregroundColor(.mintAccent)
                    .font(.bodyRoundedMedium())
                }
            }
        }
    }
}

// MARK: - Note Overlay Card

private struct NoteOverlayCard: View {
    let note: NoteEntity
    let allNotesAtTimestamp: [NoteEntity]
    let onJump: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Dismiss handle area — tap anywhere outside card dismisses
            // (handled by the parent ZStack tap)

            VStack(alignment: .leading, spacing: 12) {

                // Header row: timestamp badge + close button
                HStack {
                    if let timestamp = note.timestamp {
                        Text(timestamp)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.mintAccent)
                            .clipShape(Capsule())
                    }

                    if allNotesAtTimestamp.count > 1 {
                        Text("\(allNotesAtTimestamp.count) notes here")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()

                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                }

                // Note text
                if let text = note.noteText, !text.isEmpty {
                    Text(text)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Tags
                let tags = note.tagsArray
                if !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.white.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Jump button
                Button(action: onJump) {
                    HStack {
                        Image(systemName: "arrow.forward.circle.fill")
                        Text("Jump to time")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.mintAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.mintAccent.opacity(0.15))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.14, green: 0.14, blue: 0.16))
                    .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: -4)
            )
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
