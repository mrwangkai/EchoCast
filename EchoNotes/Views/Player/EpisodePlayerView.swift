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
                format: "episodeTitle == %@ AND showTitle == %@",
                episodeTitle, podcastTitle
            ),
            animation: .default
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // --- SECTION 1: HEADER (FIXED HEIGHT: ~68px) ---
            segmentedControlSection
                .frame(height: 36)
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .padding(.horizontal, 12)

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

                case 1:
                    // Notes: Scrollable List
                    ScrollView {
                        NotesSegmentView(
                            notes: Array(notes),
                            addNoteAction: { showingNoteCaptureSheet = true }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollIndicators(.hidden)

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

                    // Note markers
                    ForEach(notes.filter { $0.timestamp != nil }) { note in
                        if let timestamp = note.timestamp,
                           let timeInSeconds = parseTimestamp(timestamp),
                           player.duration > 0 {
                            Circle()
                                .fill(Color.mintAccent)
                                .frame(width: 8, height: 8)
                                .offset(x: markerPosition(timeInSeconds, width: geo.size.width))
                                .offset(y: -2)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let pct = min(max(0, value.location.x / geo.size.width), 1.0)
                            player.seek(to: pct * player.duration)
                        }
                )
            }
            .frame(height: 24)
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
        }
    }

    private var playbackControlButtons: some View {
        HStack(spacing: 24) {
            skipButton(systemName: "gobackward.30", action: { player.skipBackward(30) })
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
            .buttonStyle(.plain)

            skipButton(systemName: "goforward.15", action: { player.skipForward(15) })
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
        .buttonStyle(.plain)
    }

    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return (player.currentTime / player.duration) * totalWidth
    }

    private func markerPosition(_ timestamp: TimeInterval, width: CGFloat) -> CGFloat {
        guard player.duration > 0 else { return 0 }
        return (timestamp / player.duration) * width - 4
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let components = timestamp.split(separator: ":").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
    }
}

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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add Note button (scrollable in Notes tab)
            Button(action: addNoteAction) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16, weight: .medium))

                    Text("Add note at current time")
                        .font(.bodyRoundedMedium())
                }
                .foregroundColor(.mintButtonText)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.mintButtonBackground.opacity(0.8))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, EchoSpacing.screenPadding)

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

            Text("Tap 'Add note at current time' while listening to capture your thoughts")
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
                NoteRow(note: note)
            }
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
    }
}

// MARK: - Note Row (Timeline style)

struct NoteRow: View {
    let note: NoteEntity

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let timestamp = note.timestamp {
                Text(timestamp)
                    .font(.body.monospacedDigit())
                    .foregroundColor(.mintAccent)
                    .padding(.top, 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let noteText = note.noteText, !noteText.isEmpty {
                    Text(noteText)
                        .font(.subheadline)
                        .foregroundColor(.echoTextPrimary)
                        .lineLimit(3)
                }

                Divider()
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
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
        let hrs = Int(seconds) / 3600
        let mins = Int(seconds) / 60 % 60
        let secs = Int(seconds) % 60
        if hrs > 0 {
            return String(format: "%d:%02d:%02d", hrs, mins, secs)
        } else {
            return String(format: "%d:%02d", mins, secs)
        }
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
