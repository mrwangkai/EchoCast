//
//  AudioPlayerView.swift
//  EchoNotes
//
//  Audio player with timestamped note capture
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    var autoPlay: Bool = true
    var seekToTime: TimeInterval? = nil

    @ObservedObject private var player = GlobalPlayerManager.shared
    @State private var showNoteCaptureSheet = false
    @State private var currentTimestamp = ""
    @State private var episodeNotes: [NoteEntity] = []
    @State private var selectedNote: NoteEntity?
    @State private var showNoteDetail = false
    @State private var isLoading = false
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest private var allNotes: FetchedResults<NoteEntity>

    init(episode: RSSEpisode, podcast: PodcastEntity, autoPlay: Bool = true, seekToTime: TimeInterval? = nil) {
        self.episode = episode
        self.podcast = podcast
        self.autoPlay = autoPlay
        self.seekToTime = seekToTime

        print("🎵 AudioPlayerView init - Episode: \(episode.title)")
        print("   Podcast: \(podcast.title ?? "Unknown")")
        print("   Audio URL: \(episode.audioURL ?? "No URL")")
        print("   AutoPlay: \(autoPlay)")

        // Fetch notes for this episode
        _allNotes = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: true)],
            predicate: NSPredicate(format: "episodeTitle == %@", episode.title)
        )
    }

    var body: some View {
        ZStack {
            // Main content (inner ZStack for existing structure)
            ScrollView {
                VStack(spacing: 20) {
                    // Episode Artwork
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Group {
                                if isLoading || player.isBuffering {
                                    VStack(spacing: 12) {
                                        ProgressView()
                                            .scaleEffect(1.5)
                                        Text("Loading...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                } else if let error = player.playerError {
                                    VStack(spacing: 12) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 60))
                                            .foregroundColor(.orange)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                } else {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 80))
                                        .foregroundColor(.blue)
                                }
                            }
                        )
                        .shadow(radius: 10)
                        .padding(.top, 20)

                // Episode Info
                VStack(spacing: 8) {
                    Text(episode.title)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)

                    Text(podcast.title ?? "Unknown Podcast")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 32)

                // Progress Slider with Timeline Markers
                VStack(spacing: 8) {
                    ZStack(alignment: .leading) {
                        Slider(
                            value: Binding(
                                get: { player.currentTime },
                                set: { player.seek(to: $0) }
                            ),
                            in: 0...max(player.duration, 1)
                        )
                        .tint(.blue)

                        // Timeline markers for notes
                        if player.duration > 0 {
                            GeometryReader { geometry in
                                ForEach(groupedNotesByTimestamp(), id: \.timestamp) { group in
                                    let position = CGFloat(group.timestamp / player.duration) * geometry.size.width
                                    VStack(spacing: 2) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.orange)
                                                .frame(width: 20, height: 20)

                                            Text("\(group.notes.count)")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .offset(y: -20)
                                    }
                                    .frame(width: 20, height: 20)
                                    .position(x: position, y: 10)
                                    .onTapGesture {
                                        player.seek(to: group.timestamp)
                                    }
                                }
                            }
                            .frame(height: 20)
                            .allowsHitTesting(true)
                        }
                    }

                    HStack {
                        Text(formatTime(player.currentTime))
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text(formatTime(player.duration))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 32)

                // Playback Controls
                HStack(spacing: 40) {
                    Button(action: { player.skipBackward(30) }) {
                        Image(systemName: "gobackward.30")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }
                    .disabled(player.playerError != nil || player.isBuffering)

                    Button(action: { player.togglePlayPause() }) {
                        Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(player.playerError != nil ? .gray : .blue)
                    }
                    .disabled(player.playerError != nil || player.isBuffering)

                    Button(action: { player.skipForward(30) }) {
                        Image(systemName: "goforward.30")
                            .font(.system(size: 32))
                            .foregroundColor(.primary)
                    }
                    .disabled(player.playerError != nil || player.isBuffering)
                }
                .padding(.vertical, 8)

                // Notes Section
                if !allNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.horizontal, 32)
                            .padding(.top, 12)

                        Text("Notes for this Episode")
                            .font(.headline)
                            .padding(.horizontal, 32)

                        VStack(spacing: 12) {
                            ForEach(Array(allNotes.sorted(by: { n1, n2 in
                                guard let t1 = n1.timestamp, let t2 = n2.timestamp,
                                      let time1 = parseTimestamp(t1), let time2 = parseTimestamp(t2) else {
                                    return false
                                }
                                return time1 < time2
                            }))) { note in
                                EpisodeNoteRow(note: note, onTap: {
                                    selectedNote = note
                                    showNoteDetail = true
                                    if let timestamp = note.timestamp, let time = parseTimestamp(timestamp) {
                                        player.seek(to: time)
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 20)
                }

                Spacer(minLength: 20)
            }
            }
        .navigationTitle(episode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            print("👀 AudioPlayerView appeared")
            print("   Episode: \(episode.title)")
            print("   Audio URL: \(episode.audioURL ?? "No URL")")

            isLoading = true

            // Only load episode if it's not already the current episode
            let isSameEpisode = player.currentEpisode?.audioURL == episode.audioURL
            print("   Is same episode as current: \(isSameEpisode)")

            if !isSameEpisode {
                print("   Loading episode into player...")
                player.loadEpisode(episode, podcast: podcast)
            } else {
                print("   Episode already loaded, skipping load")
            }

            // Seek to specific time if provided
            if let seekTime = seekToTime {
                player.seek(to: seekTime)
            }

            // Auto-play if requested
            if autoPlay && !player.isPlaying {
                player.play()
            }

            player.showMiniPlayer = false

            // Wait a brief moment for player to load, then hide loading indicator
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isLoading = false
            }
        }
        .onDisappear {
            // Only show mini player if there's still an active episode
            if player.currentEpisode != nil {
                player.showMiniPlayer = true
            }
        }
        .sheet(isPresented: $showNoteCaptureSheet) {
            QuickNoteCaptureView(
                podcast: podcast,
                episode: episode,
                timestamp: currentTimestamp
            )
        }
        .safeAreaInset(edge: .bottom) {
            // Add Note Button - Always visible at bottom
            Button(action: {
                currentTimestamp = formatTime(player.currentTime)
                player.pause()
                showNoteCaptureSheet = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "note.text.badge.plus")
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Note")
                            .font(.headline)
                        Text("at \(formatTime(player.currentTime))")
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .shadow(radius: 4)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showNoteDetail) {
            if let note = selectedNote {
                NoteDetailView(note: note, player: player)
            }
        }

            // Full-screen loading overlay - at outer ZStack level to cover everything
            if isLoading || player.isBuffering {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)

                            VStack(spacing: 8) {
                                Text(player.isBuffering ? "Buffering..." : "Loading Episode...")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                if let error = player.playerError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                } else {
                                    Text("Please wait")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    )
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    private func parseTimestamp(_ timestamp: String) -> TimeInterval? {
        let components = timestamp.split(separator: ":").compactMap { Int($0) }

        if components.count == 2 {
            // Format: MM:SS
            return TimeInterval(components[0] * 60 + components[1])
        } else if components.count == 3 {
            // Format: HH:MM:SS
            return TimeInterval(components[0] * 3600 + components[1] * 60 + components[2])
        }
        return nil
    }

    private func groupedNotesByTimestamp() -> [(timestamp: TimeInterval, notes: [NoteEntity])] {
        let grouped = Dictionary(grouping: Array(allNotes)) { note -> TimeInterval? in
            guard let timestamp = note.timestamp else { return nil }
            return parseTimestamp(timestamp)
        }

        return grouped
            .compactMap { key, value -> (TimeInterval, [NoteEntity])? in
                guard let key = key else { return nil }
                return (key, value)
            }
            .sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - Episode Note Row

struct EpisodeNoteRow: View {
    let note: NoteEntity
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let timestamp = note.timestamp {
                        Label(timestamp, systemImage: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }

                    Spacer()

                    if note.isPriority {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                if let noteText = note.noteText {
                    Text(noteText)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let createdAt = note.createdAt {
                    Text(createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Note Capture View

struct QuickNoteCaptureView: View {
    let podcast: PodcastEntity
    let episode: RSSEpisode
    let timestamp: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var noteText = ""
    @State private var isPriority = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Episode Info")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(episode.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("at \(timestamp)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Section(header: Text("Your Note")) {
                    TextEditor(text: $noteText)
                        .frame(minHeight: 120)
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

                Section {
                    Button(action: saveNote) {
                        HStack {
                            Spacer()
                            Text("Save Note")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(noteText.isEmpty)
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func saveNote() {
        let persistence = PersistenceController.shared
        persistence.createNote(
            showTitle: podcast.title,
            episodeTitle: episode.title,
            timestamp: timestamp,
            noteText: noteText,
            isPriority: isPriority,
            tags: [],
            sourceApp: "EchoNotes Player"
        )
        dismiss()
    }
}

// MARK: - Note Detail View

struct NoteDetailView: View {
    let note: NoteEntity
    let player: GlobalPlayerManager

    @Environment(\.dismiss) private var dismiss
    @State private var editedNoteText: String = ""
    @State private var editedIsPriority: Bool = false
    @State private var isEditing: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Episode Info
                    VStack(alignment: .leading, spacing: 8) {
                        if let showTitle = note.showTitle {
                            Text(showTitle)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }

                        if let episodeTitle = note.episodeTitle {
                            Text(episodeTitle)
                                .font(.headline)
                                .lineLimit(2)
                        }

                        HStack {
                            if let timestamp = note.timestamp {
                                Label(timestamp, systemImage: "clock.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }

                            Spacer()

                            if let createdAt = note.createdAt {
                                Text(createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Divider()

                    // Note Content
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Note")
                                .font(.headline)
                            Spacer()
                            if isEditing {
                                Toggle(isOn: $editedIsPriority) {
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text("Important")
                                            .font(.caption)
                                    }
                                }
                                .toggleStyle(.button)
                            } else if note.isPriority {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("Important")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        if isEditing {
                            TextEditor(text: $editedNoteText)
                                .frame(minHeight: 200)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        } else {
                            if let noteText = note.noteText {
                                Text(noteText)
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Note Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                            isEditing = false
                        }
                    } else {
                        Button("Edit") {
                            editedNoteText = note.noteText ?? ""
                            editedIsPriority = note.isPriority
                            isEditing = true
                        }
                    }
                }
            }
            .onAppear {
                editedNoteText = note.noteText ?? ""
                editedIsPriority = note.isPriority
            }
        }
    }

    private func saveChanges() {
        note.noteText = editedNoteText
        note.isPriority = editedIsPriority

        do {
            try note.managedObjectContext?.save()
        } catch {
            print("Error saving note changes: \(error)")
        }
    }
}

#Preview {
    let episode = RSSEpisode(
        title: "Sample Episode",
        description: "A great episode",
        pubDate: Date(),
        duration: "45:30",
        audioURL: "https://example.com/audio.mp3",
        imageURL: nil
    )

    let context = PersistenceController.preview.container.viewContext
    let podcast = PodcastEntity(context: context)
    podcast.id = "preview"
    podcast.title = "Sample Podcast"

    return AudioPlayerView(episode: episode, podcast: podcast)
}
