//
//  ContinueListeningCard.swift
//  EchoNotes
//
//  Pixel-perfect continue listening card matching Figma design
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
            HStack(spacing: 12) {
                // Artwork
                artworkView

                // Episode Info
                episodeInfoView

                // Play Button
                playButton
            }
            .padding(EchoSpacing.noteCardPadding)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(EchoSpacing.noteCardCornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(episode.title) by \(episode.podcastName)")
        .accessibilityHint("Double tap to open episode. \(episode.timeRemaining) remaining with \(episode.notesCount) notes.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Subviews

    private var artworkView: some View {
        AsyncImage(url: URL(string: episode.artworkURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty, .failure:
                placeholderArtwork
            default:
                placeholderArtwork
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderArtwork: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "podcast.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.5))
            )
    }

    private var episodeInfoView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Episode Title
            Text(episode.title)
                .font(.bodyRoundedMedium())
                .foregroundColor(.white)
                .lineLimit(2)

            // Podcast Name
            Text(episode.podcastName)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            // Progress Bar
            ProgressView(value: episode.progress)
                .tint(Color(red: 0.0, green: 0.784, blue: 0.702))
                .frame(height: 4)

            // Metadata Row
            HStack(spacing: 8) {
                // Notes Indicator
                if episode.notesCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))

                        Text("\(episode.notesCount) notes")
                            .font(.caption2Medium())
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Time Remaining
                Text("\(episode.timeRemaining) left")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var playButton: some View {
        Button(action: onPlayTap) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.0, green: 0.784, blue: 0.702))
                    .frame(width: 48, height: 48)

                Image(systemName: "play.fill")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Color(red: 0.102, green: 0.235, blue: 0.204))
            }
        }
        .buttonStyle(.plain)
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
    .background(Color(red: 0.149, green: 0.149, blue: 0.149))
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
    .background(Color(red: 0.149, green: 0.149, blue: 0.149))
}
