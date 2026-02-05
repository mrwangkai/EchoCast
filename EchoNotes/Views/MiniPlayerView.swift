//
//  MiniPlayerView.swift
//  EchoNotes
//
//  Persistent mini player that shows at bottom of screen
//

import SwiftUI

// MARK: - Sheet Identifier

struct SheetIdentifier: Identifiable, Equatable {
    let id = UUID()  // Use unique ID each time to force sheet refresh
    let episode: RSSEpisode
    let podcast: PodcastEntity

    static func == (lhs: SheetIdentifier, rhs: SheetIdentifier) -> Bool {
        lhs.id == rhs.id
    }
}

struct MiniPlayerView: View {
    @Binding var showFullPlayer: Bool
    @ObservedObject var player = GlobalPlayerManager.shared
    @State private var showNoteCaptureSheet = false
    @State private var currentTimestamp = ""
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let episode = player.currentEpisode, let _ = player.currentPodcast {
                // STATE B: Episode playing - single row layout
                HStack(spacing: 12) {
                    // Artwork
                    artworkView(for: episode)

                    // Episode info
                    episodeInfoView(for: episode)

                    Spacer()

                    // Action buttons
                    HStack(spacing: 8) {
                        addNoteButton
                        playPauseButton
                    }
                }
                .padding(12)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: -2)
                .padding(.horizontal, 12)
                .padding(.bottom, 74)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Only open full player if not tapping buttons
                    showFullPlayer = true
                }
            }
        }
        .sheet(isPresented: $showNoteCaptureSheet) {
            NoteCaptureView()
        }
    }

    // MARK: - Component Views

    private func artworkView(for episode: RSSEpisode) -> some View {
        AsyncImage(url: URL(string: episode.imageURL ?? player.currentPodcast?.artworkURL ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .empty, .failure:
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "podcast.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.5))
                    )
            default:
                EmptyView()
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func episodeInfoView(for episode: RSSEpisode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(episode.title)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            if let podcastTitle = player.currentPodcast?.title {
                Text(podcastTitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
    }

    private var addNoteButton: some View {
        Button(action: {
            currentTimestamp = formatTime(player.currentTime)
            player.pause()
            showNoteCaptureSheet = true
        }) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702))
        }
        .frame(width: 40, height: 40)
        .buttonStyle(.plain)
    }

    private var playPauseButton: some View {
        Button(action: {
            if player.isPlaying {
                player.pause()
            } else {
                player.play()
            }
        }) {
            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702))
        }
        .frame(width: 40, height: 40)
        .buttonStyle(.plain)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
