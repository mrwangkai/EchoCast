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

struct EpisodePlayerView: View {
    // MARK: - Properties

    let episode: RSSEpisode
    let podcast: PodcastEntity
    var namespace: Namespace.ID

    @ObservedObject private var player = GlobalPlayerManager.shared
    @State private var selectedSegment = 0
    @State private var showingNoteCaptureSheet = false

    // Note marker popover state
    @State private var selectedMarkerNote: NoteEntity? = nil

    // Go Back button state
    @State private var showGoBackButton = false
    @State private var previousPlaybackPosition: TimeInterval = 0
    @State private var goBackTimer: Timer?
    @State private var goBackCountdown: CGFloat = 8.0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest private var notes: FetchedResults<NoteEntity>

    // MARK: - Initialization

    init(episode: RSSEpisode, podcast: PodcastEntity, namespace: Namespace.ID) {
        self.episode = episode
        self.podcast = podcast
        self.namespace = namespace

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
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // --- SECTION 1: HEADER (FIXED HEIGHT: ~68px) ---
            VStack(spacing: 0) {
                segmentedControlSection
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, 16)

            // --- SECTION 2: MID-SECTION (FIXED HEIGHT: 377px) ---
            Group {
                switch selectedSegment {
                case 0:
                    // Listening: Static Art (Not scrollable)
                    ListeningSegmentView(
                        episode: episode,
                        podcast: podcast,
                        namespace: namespace,
                        addNoteAction: { showingNoteCaptureSheet = true }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)

                case 1:
                    // Notes: Scrollable List
                    ScrollView {
                        NotesSegmentView(
                            notes: Array(notes),
                            addNoteAction: { showingNoteCaptureSheet = true },
                            player: player,
                            selectedSegment: $selectedSegment
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollIndicators(.hidden)
                    .padding(.top, 40)

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
                    .padding(.top, 40)

                default:
                    EmptyView()
                }
            }
            .frame(height: 377)

            Spacer(minLength: 0) // Pushes footer to bottom

            // --- SECTION 3: FOOTER (FIXED HEIGHT: ~290px) ---
            VStack(spacing: 16) {
                // Metadata (Always visible, 2 lines max)
                episodeMetadataView

                // Scrubber
                timeProgressWithMarkers

                // Playback controls
                playbackControlButtons

                // Add Note CTA (Always visible with player controls)
                addNoteButton
                    .sensoryFeedback(.impact, trigger: showingNoteCaptureSheet)
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.top, 20)
            .background(Color.echoBackground)
            .footerPadding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.echoBackground)
        .presentationDetents([.fraction(0.90)])
        .presentationDragIndicator(.visible) // Native drag bar
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showingNoteCaptureSheet) {
            NoteCaptureSheetWrapper(
                episode: episode,
                podcast: podcast,
                currentTime: player.currentTime
            )
        }
        .sheet(item: $selectedMarkerNote) { note in
            NotePreviewPopover(
                note: note,
                notesAtSameTimestamp: notesAtTimestamp(note.timestamp ?? ""),
                onJumpToTime: {
                    if let timestamp = note.timestamp,
                       let timeInSeconds = parseTimestamp(timestamp) {
                        player.seek(to: timeInSeconds)
                        selectedMarkerNote = nil
                    }
                },
                onDismiss: {
                    selectedMarkerNote = nil
                }
            )
            .presentationDetents([.height(200)])
            .presentationDragIndicator(.visible)
        }
        .onDisappear {
            goBackTimer?.invalidate()
        }
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
        VStack(spacing: 2) {
            Text(episode.title)
                .font(.bodyRoundedMedium())
                .foregroundColor(.echoTextPrimary)
                .lineLimit(2)

            Text(podcast.title ?? "Unknown Podcast")
                .font(.caption2Medium())
                .foregroundColor(.echoTextSecondary)
                .lineLimit(1)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Add Note Button

    private var addNoteButton: some View {
        Button {
            showingNoteCaptureSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "note.text.badge.plus")
                    .font(.system(size: 15, weight: .medium))

                Text("Add note at current time")
                    .font(.bodyRoundedMedium())
            }
            .foregroundColor(.mintButtonText)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.mintButtonBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Player Controls

    private var timeProgressWithMarkers: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Inactive track
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)
                        .frame(maxHeight: .infinity, alignment: .center)

                    // Active track
                    Capsule()
                        .fill(Color.mintAccent)
                        .frame(
                            width: geo.size.width * CGFloat(
                                player.duration > 0
                                    ? min(player.currentTime / player.duration, 1.0)
                                    : 0
                            ),
                            height: 4
                        )
                        .frame(maxHeight: .infinity, alignment: .center)

                    // Scrubber knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(
                            x: geo.size.width * CGFloat(player.duration > 0
                                ? min(player.currentTime / player.duration, 1.0)
                                : 0) - 7,
                            y: 0
                        )
                        .frame(maxHeight: .infinity, alignment: .center)

                    // Note markers (grouped by proximity)
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

                    ForEach(Array(groupedNotes.enumerated()), id: \.offset) { _, group in
                        let xPos = (group.position / player.duration) * geo.size.width - 14

                        Button {
                            // Show popover with first note at this position
                            selectedMarkerNote = group.notes.first
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
                        .offset(x: xPos, y: -24)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Save position on first drag (scrub start)
                            if !showGoBackButton && previousPlaybackPosition == 0 {
                                previousPlaybackPosition = player.currentTime
                            }
                            let pct = min(max(0, value.location.x / geo.size.width), 1.0)
                            player.seek(to: pct * player.duration)
                        }
                        .onEnded { _ in
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
            }
            .frame(height: 36)
            .padding(.horizontal, EchoSpacing.screenPadding)

            HStack {
                Text(formatTime(player.currentTime))
                    .font(.caption2Medium())
                    .foregroundColor(.echoTextTertiary)

                Spacer()

                Text("-\(formatTime(player.duration - player.currentTime))")
                    .font(.caption2Medium())
                    .foregroundColor(.echoTextTertiary)
            }

            // Go Back button overlay (appears above timeline after scrubbing)
            if showGoBackButton {
                HStack(spacing: 8) {
                    // Circular countdown indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            .frame(width: 24, height: 24)

                        Circle()
                            .trim(from: 0, to: goBackCountdown / 8.0)
                            .stroke(Color.mintAccent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .frame(width: 24, height: 24)
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
                                .font(.system(size: 14, weight: .medium))
                            Text("go back")
                                .font(.caption2Medium())
                        }
                        .foregroundColor(.mintAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
                .padding(.top, 8)
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

    // MARK: - Helper Methods

    private func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
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
            .frame(width: 300, height: 300)
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
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if notes.isEmpty {
                emptyNotesState
            } else {
                notesListView
            }

            Spacer(minLength: 32)
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

            // CTA button inline in empty state
            Button(action: addNoteAction) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.system(size: 15, weight: .medium))

                    Text("Add note at current time")
                        .font(.bodyRoundedMedium())
                }
                .foregroundColor(.mintButtonText)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.mintButtonBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var notesListView: some View {
        VStack(spacing: 12) {
            ForEach(notes, id: \.id) { note in
                NoteRow(note: note) {
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    // Seek to timestamp
                    if let timestamp = note.timestamp {
                        let components = timestamp.split(separator: ":").compactMap { Int($0) }
                        let timeInSeconds: TimeInterval?
                        if components.count == 2 {
                            timeInSeconds = TimeInterval(components[0] * 60 + components[1])
                        } else if components.count == 3 {
                            timeInSeconds = TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
                        } else {
                            timeInSeconds = nil
                        }

                        if let timeInSeconds = timeInSeconds {
                            player.seek(to: timeInSeconds)
                            withAnimation {
                                selectedSegment = 0
                            }
                        }
                    }
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
        .padding(.horizontal, EchoSpacing.screenPadding)
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
    @State private var isPriority: Bool = false
    @State private var tags: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Podcast Info")) {
                    Text(podcast.title ?? "Unknown Podcast")
                        .foregroundColor(.echoTextSecondary)
                    Text(episode.title)
                        .foregroundColor(.echoTextSecondary)
                    Text(formatTime(currentTime))
                        .foregroundColor(.mintAccent)
                }

                Section(header: Text("Note")) {
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("Enter your note...")
                                .foregroundColor(.echoTextSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        TextEditor(text: $noteText)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    Toggle(isOn: $isPriority) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Mark as Important")
                        }
                    }
                }

                Section(header: Text("Tags (comma separated)")) {
                    TextField("e.g., interesting, funny, quote", text: $tags)
                }

                Section {
                    Button(action: saveNote) {
                        HStack {
                            Spacer()
                            Text("Save Note")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
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
        newNote.isPriority = isPriority
        newNote.createdAt = Date()
        newNote.podcast = podcast

        // Save tags
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        newNote.tags = tagList.joined(separator: ",")

        try? viewContext.save()
        dismiss()
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
                                .font(.bodyEcho())
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
