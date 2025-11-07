//
//  MiniPlayerView.swift
//  EchoNotes
//
//  Persistent mini player that shows at bottom of screen
//

import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var player = GlobalPlayerManager.shared
    @State private var showFullPlayer = false

    var body: some View {
        if player.showMiniPlayer, let episode = player.currentEpisode {
            VStack(spacing: 0) {
                // Drag indicator
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                // Mini player controls
                HStack(spacing: 12) {
                    // Artwork
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        )

                    // Episode info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(episode.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            if let podcastTitle = player.currentPodcast?.title {
                                Text(podcastTitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }

                            Text("•")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(formatTime(player.currentTime))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Controls
                    HStack(spacing: 16) {
                        Button(action: {
                            player.togglePlayPause()
                        }) {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.primary)
                        }

                        Button(action: {
                            player.stop()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .background(Color(.systemBackground))
                .onTapGesture {
                    showFullPlayer = true
                }

                // Progress bar at bottom
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * CGFloat(player.currentTime / max(player.duration, 1)), height: 3)
                }
                .frame(height: 3)
            }
            .background(
                Color(.systemBackground)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: -2)
            )
            .fullScreenCover(isPresented: $showFullPlayer) {
                if let episode = player.currentEpisode, let podcast = player.currentPodcast {
                    PlayerSheetWrapper(
                        episode: episode,
                        podcast: podcast,
                        dismiss: { showFullPlayer = false }
                    )
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Full Player View (Sheet)

struct FullPlayerView: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    @ObservedObject var player = GlobalPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showNoteCaptureSheet = false
    @State private var currentTimestamp = ""
    @State private var selectedNote: NoteEntity?
    @State private var showNoteDetail = false
    @FetchRequest private var allNotes: FetchedResults<NoteEntity>

    init(episode: RSSEpisode, podcast: PodcastEntity) {
        self.episode = episode
        self.podcast = podcast

        _allNotes = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \NoteEntity.createdAt, ascending: true)],
            predicate: NSPredicate(format: "episodeTitle == %@", episode.title)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Episode Artwork
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 280, height: 280)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 80))
                                .foregroundColor(.blue)
                        )
                        .shadow(radius: 10)
                        .padding(.top, 20)

                    // Episode Info
                    VStack(spacing: 8) {
                        Text(episode.title)
                            .font(.title3)
                            .fontWeight(.bold)
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

                        Button(action: { player.togglePlayPause() }) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.blue)
                        }

                        Button(action: { player.skipForward(30) }) {
                            Image(systemName: "goforward.30")
                                .font(.system(size: 32))
                                .foregroundColor(.primary)
                        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                player.showMiniPlayer = false
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
            .sheet(isPresented: $showNoteDetail) {
                if let note = selectedNote {
                    NoteDetailView(note: note, player: player)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Add Note Button
                Button(action: {
                    currentTimestamp = formatTime(player.currentTime)
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
