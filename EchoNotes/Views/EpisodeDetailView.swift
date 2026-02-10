//
//  EpisodeDetailView.swift
//  EchoNotes
//
//  Episode detail view with notes and playback
//

import SwiftUI
import CoreData

struct EpisodeDetailView: View {
    let episode: RSSEpisode
    let podcast: PodcastEntity
    @ObservedObject var player = GlobalPlayerManager.shared
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showNoteCaptureSheet = false

    init(episode: RSSEpisode, podcast: PodcastEntity) {
        self.episode = episode
        self.podcast = podcast
    }

    // Dynamically fetch notes for this episode
    private var episodeNotes: [NoteEntity] {
        let request: NSFetchRequest<NoteEntity> = NoteEntity.fetchRequest()
        request.predicate = NSPredicate(format: "episodeTitle == %@", episode.title)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Error fetching episode notes: \(error)")
            return []
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Episode Artwork
                CachedAsyncImage(url: episode.imageURL ?? podcast.artworkURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 250)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                        )
                }

                VStack(alignment: .leading, spacing: 16) {
                    // Episode Title & Metadata
                    VStack(alignment: .leading, spacing: 8) {
                        Text(episode.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(podcast.title ?? "Unknown Podcast")
                            .font(.subheadline)
                            .foregroundColor(.echoTextSecondary)

                        HStack(spacing: 8) {
                            if let pubDate = episode.pubDate {
                                Text(formatDate(pubDate))
                                    .font(.caption)
                                    .foregroundColor(.echoTextSecondary)
                            }

                            if let duration = episode.duration {
                                Text("•")
                                    .font(.caption)
                                    .foregroundColor(.echoTextSecondary)
                                Text(duration)
                                    .font(.caption)
                                    .foregroundColor(.echoTextSecondary)
                            }
                        }
                    }

                    // Play Button
                    Button(action: playEpisode) {
                        HStack {
                            Image(systemName: "play.fill")
                                .font(.headline)
                            Text("Play Episode")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }

                    // Description
                    if let description = episode.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.headline)

                            Text(description.trimmingCharacters(in: .whitespacesAndNewlines))
                                .font(.subheadline)
                                .foregroundColor(.echoTextSecondary)
                        }
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Notes")
                                .font(.headline)

                            Spacer()

                            Button(action: { showNoteCaptureSheet = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Note")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }

                        if episodeNotes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "note.text")
                                    .font(.system(size: 40))
                                    .foregroundColor(.echoTextSecondary)
                                Text("No notes for this episode yet")
                                    .font(.subheadline)
                                    .foregroundColor(.echoTextSecondary)
                                Button("Add Your First Note") {
                                    showNoteCaptureSheet = true
                                }
                                .buttonStyle(.bordered)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(episodeNotes) { note in
                                    NoteCardCompact(note: note)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Episode")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.echoBackground, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.mintAccent)
        .sheet(isPresented: $showNoteCaptureSheet) {
            NoteCaptureView()
        }
    }

    private func playEpisode() {
        player.loadEpisode(episode, podcast: podcast)
        player.play()
        player.showMiniPlayer = true
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Note Card Compact

struct NoteCardCompact: View {
    let note: NoteEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let timestamp = note.timestamp {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(timestamp)
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
                }

                Spacer()

                if let createdAt = note.createdAt {
                    Text(formatDate(createdAt))
                        .font(.caption2)
                        .foregroundColor(.echoTextSecondary)
                }
            }

            if let noteText = note.noteText, !noteText.isEmpty {
                Text(noteText)
                    .font(.body)
                    .foregroundColor(.echoTextPrimary)
                    .lineLimit(3)
            }

            if !note.tagsArray.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(note.tagsArray.sorted(), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.noteCardBackground)
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
