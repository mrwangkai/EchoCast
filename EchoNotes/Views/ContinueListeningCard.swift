//
//  ContinueListeningCard.swift
//  EchoNotes
//
//  Figma-accurate continue listening card (node-id=1878-4000)
//  Displays podcast episode with playback progress
//

import SwiftUI

// MARK: - Data Model

struct ContinueListeningEpisode: Identifiable {
    let id: String
    let title: String
    let podcastName: String
    let artworkURL: String?
    let progress: Double         // 0.0 to 1.0
    let notesCount: Int         // Number of notes taken
    let timeRemaining: String   // Formatted string (e.g., "0:48", "1:23:45")
    let audioURL: String?

    // Optional: Additional metadata
    let duration: TimeInterval?
    let currentTime: TimeInterval?
}

// MARK: - Continue Listening Card

struct ContinueListeningCard: View {
    // MARK: - Properties
    let episode: ContinueListeningEpisode
    let onTap: () -> Void
    let onPlayTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    // Album artwork with play button overlay
                    ZStack(alignment: .center) {
                        CachedAsyncImage(url: URL(string: episode.artworkURL ?? "")) {
                            Rectangle()
                                .fill(Color.noteCardBackground)
                                .frame(width: 88, height: 88)
                                .overlay {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 32))
                                        .foregroundColor(.echoTextTertiary)
                                }
                        }
                        .frame(width: 88, height: 88)
                        .clipped()
                        .cornerRadius(8)

                        // Play button overlay
                        Circle()
                            .fill(Color.black.opacity(0.6))
                            .frame(width: 36, height: 36)
                            .overlay {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                    }

                    // Episode metadata
                    VStack(alignment: .leading, spacing: 6) {
                        Text(episode.title)
                            .font(.bodyRoundedMedium())
                            .foregroundColor(.echoTextPrimary)
                            .lineLimit(2)

                        Text(episode.podcastName)
                            .font(.captionRounded())
                            .foregroundColor(.echoTextSecondary)
                            .lineLimit(1)

                        Spacer()
                    }

                    Spacer()
                }

                // Progress bar with time
                VStack(spacing: 4) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Track
                            Rectangle()
                                .fill(Color.echoTextTertiary.opacity(0.2))
                                .frame(height: 4)

                            // Progress
                            Rectangle()
                                .fill(Color.mintAccent)
                                .frame(width: geometry.size.width * episode.progress, height: 4)

                            // Note markers (future: show as 8pt circles at specific positions)
                            // TODO: Add note markers based on note timestamps
                        }
                    }
                    .frame(height: 4)
                    .cornerRadius(2)

                    // Time remaining + notes count
                    HStack {
                        // Notes indicator (LEFT)
                        if episode.notesCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundColor(.echoTextTertiary)
                                Text("\(episode.notesCount) note\(episode.notesCount == 1 ? "" : "s")")
                                    .font(.caption2Medium())
                                    .foregroundColor(.echoTextTertiary)
                            }
                        }

                        Spacer()

                        // Time remaining (RIGHT)
                        Text("-\(episode.timeRemaining)")
                            .font(.caption2Medium())
                            .foregroundColor(.echoTextTertiary)
                    }
                }
            }
            .padding(16)
            .background(Color.noteCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(episode.title) by \(episode.podcastName)")
        .accessibilityHint("Double tap to open episode. \(episode.timeRemaining) remaining with \(episode.notesCount) notes.")
        .accessibilityAddTraits(.isButton)
        .onTapGesture {
            print("🎧 [ContinueListening] Card tapped: \(episode.title)")
            onTap()
        }
    }
}

// MARK: - Preview

#Preview("Continue Listening Card - With Notes") {
    ContinueListeningCard(
        episode: ContinueListeningEpisode(
            id: "1",
            title: "I Hate Mysteries",
            podcastName: "This American Life",
            artworkURL: "https://example.com/artwork.jpg",
            progress: 0.65,
            notesCount: 9,
            timeRemaining: "0:48",
            audioURL: "https://example.com/audio.mp3",
            duration: 3600,
            currentTime: 2340
        ),
        onTap: { print("Card tapped") },
        onPlayTap: { print("Play tapped") }
    )
    .frame(width: 327)
    .padding()
    .background(Color.echoBackground)
}

#Preview("Continue Listening Card - No Notes") {
    ContinueListeningCard(
        episode: ContinueListeningEpisode(
            id: "2",
            title: "The Fall of Civilizations: 20. Persia - An Empire in Ashes",
            podcastName: "The Fall of Civilizations Podcast",
            artworkURL: nil,
            progress: 0.23,
            notesCount: 0,
            timeRemaining: "2:14:30",
            audioURL: nil,
            duration: 8000,
            currentTime: 6160
        ),
        onTap: { print("Card tapped") },
        onPlayTap: { print("Play tapped") }
    )
    .frame(width: 327)
    .padding()
    .background(Color.echoBackground)
}
