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

// MARK: - Liquid Glass Edge ViewModifier

struct LiquidGlassEdge: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) {
                // The iOS 26 "Liquid Glass" hairline edge
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 0.33) // Standard Retina hairline
            }
            .glassEffect(.regular.interactive())
    }
}

extension View {
    func liquidGlassFooter() -> some View {
        self.modifier(LiquidGlassEdge())
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
        ZStack(alignment: .bottom) {
            // LAYER 1: Scrollable Content (Mid-Section)
            ScrollView {
                VStack(spacing: 0) {
                    // Space for fixed header
                    Spacer(minLength: 70)

                    // Segmented Control (in scroll area)
                    segmentedControlSection

                    // Tab content
                    switch selectedSegment {
                    case 0:
                        ListeningSegmentView(
                            episode: episode,
                            podcast: podcast,
                            namespace: namespace,
                            addNoteAction: { showingNoteCaptureSheet = true }
                        )
                    case 1:
                        NotesSegmentView(
                            notes: Array(notes),
                            addNoteAction: { showingNoteCaptureSheet = true }
                        )
                    case 2:
                        InfoSegmentView(
                            episode: episode,
                            podcast: podcast
                        )
                    default:
                        EmptyView()
                    }
                }
                // Reserve space so the list can clear the fixed footer
                .padding(.bottom, 280)
            }
            .background(Color.echoBackground)

            // LAYER 2: The Persistent Footer (Fixed at bottom)
            VStack(spacing: 20) {
                // Metadata (Always visible, 2 lines max)
                episodeMetadataView

                // Contextual CTA: Only fixed in "Listening" view (segment 0)
                if selectedSegment == 0 {
                    addNoteButton
                        .sensoryFeedback(.impact, trigger: showingNoteCaptureSheet)
                }

                // Scrubber
                timeProgressWithMarkers

                // Playback controls
                playbackControlButtons

                // Utility toolbar
                secondaryActionsRow
            }
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.top, 20)
            .padding(.bottom, 24)
            .liquidGlassFooter()
            .ignoresSafeArea(edges: .bottom)
        }
        .background(Color.echoBackground)
        .sheet(isPresented: $showingNoteCaptureSheet) {
            NoteCaptureSheetWrapper(
                episode: episode,
                podcast: podcast,
                currentTime: player.currentTime
            )
        }
    }

    // MARK: - Segmented Control (Fixed Header)

    private var segmentedControlSection: some View {
        VStack(spacing: 0) {
            // Dismiss handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            // Segmented control
            Picker("", selection: $selectedSegment) {
                Text("Listening").tag(0)
                Text("Notes").tag(1)
                Text("Episode Info").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, EchoSpacing.screenPadding)
            .padding(.bottom, 16)
            .sensoryFeedback(.selection, trigger: selectedSegment)
        }
        .background(Color.echoBackground)
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
    }

    // MARK: - Player Controls

    private var timeProgressWithMarkers: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.mintAccent)
                        .frame(width: progressWidth(geometry.size.width), height: 4)

                    ForEach(notes.filter { $0.timestamp != nil }) { note in
                        if let timestamp = note.timestamp,
                           let timeInSeconds = parseTimestamp(timestamp),
                           player.duration > 0 {
                            Circle()
                                .fill(Color.mintAccent)
                                .frame(width: 8, height: 8)
                                .offset(x: markerPosition(timeInSeconds, width: geometry.size.width))
                                .offset(y: -2)
                        }
                    }
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let newTime = (value.location.x / geometry.size.width) * player.duration
                            player.seek(to: max(0, min(newTime, player.duration)))
                        }
                )
            }
            .frame(height: 20)

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

    private var secondaryActionsRow: some View {
        HStack {
            downloadButton

            Spacer()

            playbackSpeedButton

            Spacer()

            shareButton

            Spacer()

            moreOptionsButton
        }
    }

    private var downloadButton: some View {
        Button {
            print("Download button tapped")
        } label: {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.echoTextSecondary)
        }
        .buttonStyle(.plain)
    }

    private var playbackSpeedButton: some View {
        Button {
            print("Playback speed button tapped - TODO: Implement speed control")
        } label: {
            Text("1.0×")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.echoTextSecondary)
        }
        .buttonStyle(.plain)
    }

    private var shareButton: some View {
        Button {
            print("Share button tapped")
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.echoTextSecondary)
        }
        .buttonStyle(.plain)
    }

    private var moreOptionsButton: some View {
        Button {
            print("More options tapped")
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.echoTextSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    private func skipButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
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
        VStack(spacing: 24) {
            albumArtworkView
                .padding(.horizontal, EchoSpacing.screenPadding)

            Spacer(minLength: 80)
        }
        .padding(.top, 8)
    }

    private var albumArtworkView: some View {
        GeometryReader { geometry in
            AsyncImage(url: URL(string: podcast.artworkURL ?? episode.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))

                        ProgressView()
                            .tint(.white)
                    }
                    .matchedGeometryEffect(id: "artwork", in: namespace)

                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .matchedGeometryEffect(id: "artwork", in: namespace)

                case .failure:
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.2))

                        Image(systemName: "music.note")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .matchedGeometryEffect(id: "artwork", in: namespace)

                default:
                    EmptyView()
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.width)
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
        .aspectRatio(1, contentMode: .fit)
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
            .padding(.horizontal, EchoSpacing.screenPadding)

            if notes.isEmpty {
                emptyNotesState
            } else {
                notesListView
            }

            Spacer(minLength: 20)
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

            Spacer(minLength: 20)
        }
        .padding(.horizontal, EchoSpacing.screenPadding)
        .padding(.top, 8)
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
                        .foregroundColor(.secondary)
                    Text(episode.title)
                        .foregroundColor(.secondary)
                    Text(formatTime(currentTime))
                        .foregroundColor(.accentColor)
                }

                Section(header: Text("Note")) {
                    ZStack(alignment: .topLeading) {
                        if noteText.isEmpty {
                            Text("Enter your note...")
                                .foregroundColor(.gray)
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

        // Save tags
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        newNote.tags = tagList.joined(separator: ",")

        try? viewContext.save()
        dismiss()
    }
}
