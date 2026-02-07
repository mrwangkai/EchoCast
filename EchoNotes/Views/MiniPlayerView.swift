//
//  MiniPlayerView.swift
//  EchoNotes
//
//  Persistent mini player that shows at bottom of screen
//

import SwiftUI

struct MiniPlayerView: View {
    @Binding var showFullPlayer: Bool
    @ObservedObject private var player = GlobalPlayerManager.shared
    @State private var showingAddNote = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let episode = player.currentEpisode {
            // STATE: Episode playing
            HStack(spacing: 12) {
                artworkView(for: episode)
                episodeInfoView(for: episode)
                Spacer()
                HStack(spacing: 8) {
                    addNoteButton
                    playPauseButton
                }
            }
            .padding(12)
            .background(Color(red: 0.2, green: 0.2, blue: 0.2))
            .cornerRadius(12, corners: [.topLeft, .topRight])
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: -2)
            .onTapGesture {
                showFullPlayer = true
            }
            .sheet(isPresented: $showingAddNote) {
                NoteCaptureView()
            }
        } else {
            // STATE: No episode - hide mini player
            EmptyView()
        }
    }

    // MARK: - Supporting Views

    private func artworkView(for episode: RSSEpisode) -> some View {
        Group {
            if let imageURL = episode.imageURL ?? player.currentPodcast?.artworkURL,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "podcast.fill")
                        .resizable()
                        .foregroundColor(.gray)
                        .padding(8)
                }
            } else {
                Image(systemName: "podcast.fill")
                    .resizable()
                    .foregroundColor(.gray)
                    .padding(8)
            }
        }
        .frame(width: 48, height: 48)
        .cornerRadius(8)
        .clipped()
    }

    private func episodeInfoView(for episode: RSSEpisode) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(episode.title)
                .font(.custom("SF Pro Rounded", size: 15).weight(.medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let podcastTitle = player.currentPodcast?.title {
                Text(podcastTitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
    }

    private var addNoteButton: some View {
        Button(action: {
            showingAddNote = true
        }) {
            Image(systemName: "note.text.badge.plus")
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702)) // Mint #00c8b3
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
                .font(.system(size: 20))
                .foregroundColor(Color(red: 0.0, green: 0.784, blue: 0.702)) // Mint #00c8b3
        }
        .frame(width: 40, height: 40)
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

